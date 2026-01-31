from django.db import models
from django.contrib.auth.models import User
from PIL import Image
from io import BytesIO
from django.core.files.base import ContentFile

class PlanetInterpretation(models.Model):
    PLANETS = [
        ('Sun', 'Sun'), ('Moon', 'Moon'), ('Mercury', 'Mercury'), ('Venus', 'Venus'),
        ('Mars', 'Mars'), ('Jupiter', 'Jupiter'), ('Saturn', 'Saturn'),
        ('Uranus', 'Uranus'), ('Neptune', 'Neptune'), ('Pluto', 'Pluto'),
        ('Chiron', 'Chiron'), ('North Node', 'North Node')
    ]
    SIGNS = [
        ('Aries', 'Aries'), ('Taurus', 'Taurus'), ('Gemini', 'Gemini'),
        ('Cancer', 'Cancer'), ('Leo', 'Leo'), ('Virgo', 'Virgo'),
        ('Libra', 'Libra'), ('Scorpio', 'Scorpio'), ('Sagittarius', 'Sagittarius'),
        ('Capricorn', 'Capricorn'), ('Aquarius', 'Aquarius'), ('Pisces', 'Pisces')
    ]

    planet = models.CharField(max_length=20, choices=PLANETS)
    sign = models.CharField(max_length=20, choices=SIGNS)
    house = models.IntegerField(default=0, help_text="0 for generic sign interpretation, 1-12 for specific house")
    
    text_en = models.TextField(help_text="English Interpretation")
    text_tr = models.TextField(help_text="Turkish Interpretation")

    class Meta:
        unique_together = ('planet', 'sign', 'house')

    def __str__(self):
        return f"{self.planet} in {self.sign} (House {self.house})"

class AspectInterpretation(models.Model):
    ASPECTS = [
       ('Conjunction', 'Conjunction (0)'),
       ('Opposition', 'Opposition (180)'),
       ('Trine', 'Trine (120)'),
       ('Square', 'Square (90)'),
       ('Sextile', 'Sextile (60)')
    ]

    planet_1 = models.CharField(max_length=20)
    planet_2 = models.CharField(max_length=20)
    aspect_type = models.CharField(max_length=20, choices=ASPECTS)
    
    text_en = models.TextField()
    text_tr = models.TextField()

    def __str__(self):
        return f"{self.planet_1} {self.aspect_type} {self.planet_2}"

class Celebrity(models.Model):
    name = models.CharField(max_length=100)
    birth_date = models.CharField(max_length=10, help_text="YYYY/MM/DD")
    birth_time = models.CharField(max_length=5, help_text="HH:MM")
    lat = models.FloatField()
    lon = models.FloatField()
    
    # Pre-calculated data to save compute? Or calculate on fly?
    # Let's simple calculate on fly or store Sun/Moon sign as cache
    sun_sign = models.CharField(max_length=20, blank=True)
    moon_sign = models.CharField(max_length=20, blank=True)
    asc_sign = models.CharField(max_length=20, blank=True)
    
    def __str__(self):
        return self.name

class DailyTip(models.Model):
    PHASES = [
        ('New Moon', 'New Moon'),
        ('Waxing', 'Waxing'),
        ('Full Moon', 'Full Moon'),
        ('Waning', 'Waning')
    ]
    
    phase = models.CharField(max_length=20, choices=PHASES)
    category = models.CharField(max_length=50, help_text="Beauty, Garden, Diet, Business")
    text_en = models.TextField()
    text_tr = models.TextField()

    def __str__(self):
        return f"{self.phase} - {self.category}"

class DailyHoroscope(models.Model):
    date = models.DateField(unique=True)
    summary_en = models.TextField()
    summary_tr = models.TextField()
    aspects = models.JSONField(default=list) 

    def __str__(self):
        return f"Horoscope for {self.date}"

class WeeklyHoroscope(models.Model):
    # Identifies the week by its Monday date
    start_date = models.DateField() 
    sign = models.CharField(max_length=20) # Aries, Taurus, etc.
    
    text_en = models.TextField(blank=True)
    text_tr = models.TextField(blank=True)
    
    theme_en = models.CharField(max_length=200, blank=True)
    theme_tr = models.CharField(max_length=200, blank=True)
    
    class Meta:
        unique_together = ('start_date', 'sign')
        ordering = ['-start_date', 'sign']

    def __str__(self):
        return f"{self.sign} - {self.start_date}"

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    birth_date = models.DateField(null=True, blank=True)
    birth_time = models.TimeField(null=True, blank=True)
    birth_place = models.CharField(max_length=100, default="Unknown")
    lat = models.FloatField(default=0.0)
    lon = models.FloatField(default=0.0)
    
    # Store calculated sign for quick access?
    sun_sign = models.CharField(max_length=20, blank=True)
    rising_sign = models.CharField(max_length=20, blank=True)

    MEMBERSHIP_CHOICES = [
        ('free', 'Free'),
        ('premium', 'Premium'),
    ]
    membership_level = models.CharField(max_length=10, choices=MEMBERSHIP_CHOICES, default='free')

    def __str__(self):
        return f"{self.user.username} Profile ({self.membership_level})"

    @property
    def effective_membership(self):
        from django.conf import settings
        if getattr(settings, 'FREE_PREMIUM_MODE', False) and self.membership_level == 'free':
            return 'premium'
        return self.membership_level

class UserActivityLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    action = models.CharField(max_length=255) # e.g. "Calculate Chart", "Visit Home"
    path = models.CharField(max_length=255)
    method = models.CharField(max_length=10)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    # Optional: Additional meta data (e.g., duration on page, JSON details)
    details = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f"{self.user} - {self.action} - {self.timestamp}"


class BlogPost(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    content = models.TextField()
    image_url = models.CharField(max_length=500, default='https://images.unsplash.com/photo-1532968961962-8a0cb3a2d4f5?auto=format&fit=crop&w=800&q=80')
    banner_image = models.ImageField(upload_to='blog_images/', blank=True, null=True, help_text="Upload a custom image (overrides image_url)")
    created_at = models.DateTimeField(auto_now_add=True)
    is_published = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        if self.banner_image:
            try:
                # Open image
                img = Image.open(self.banner_image)
                
                # Convert to RGB (in case of RGBA/Palette)
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                
                # Resize if too large (max width 1000px)
                max_width = 1000
                if img.width > max_width:
                    ratio = max_width / img.width
                    new_height = int(img.height * ratio)
                    img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                
                # Compress to JPEG
                output = BytesIO()
                img.save(output, format='JPEG', quality=80, optimize=True)
                output.seek(0)
                
                # Change extension and save
                self.banner_image.file = ContentFile(output.read(), name=os.path.splitext(self.banner_image.name)[0] + '.jpg')
            except Exception as e:
                print(f"Image processing failed: {e}")
                
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title

class ContactMessage(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.name} - {self.email} ({self.created_at.strftime('%Y-%m-%d')})"
