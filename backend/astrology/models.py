from django.db import models
from django.contrib.auth.models import User

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
