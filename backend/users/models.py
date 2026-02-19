from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    birth_date = models.DateField(null=True, blank=True)
    birth_time = models.TimeField(null=True, blank=True)
    birth_place = models.CharField(max_length=100, default="Unknown")
    lat = models.FloatField(default=0.0)
    lon = models.FloatField(default=0.0)
    
    # Store calculated sign for quick access
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
