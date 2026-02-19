import os
import django
import sys

# Django Setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings') 
django.setup()

from astrology.models import UserProfile as OldProfile
from users.models import Profile as NewProfile
from django.contrib.auth.models import User

def run():
    print("Migrating User Profiles to new 'users' app...")
    old_profiles = OldProfile.objects.all()
    count = 0
    
    for old in old_profiles:
        try:
            user = old.user
            # Check if new profile already exists
            new_p, created = NewProfile.objects.get_or_create(user=user)
            
            # Copy data
            new_p.birth_date = old.birth_date
            new_p.birth_time = old.birth_time
            new_p.birth_place = old.birth_place
            new_p.lat = old.lat
            new_p.lon = old.lon
            new_p.sun_sign = old.sun_sign
            new_p.rising_sign = old.rising_sign
            new_p.membership_level = old.membership_level
            
            new_p.save()
            
            action = "Created" if created else "Updated"
            print(f"[{action}] {user.username}")
            count += 1
            
        except Exception as e:
            print(f"[ERROR] User {old.user.username}: {e}")

    print(f"\nTotal {count} profiles migrated successfully.")

if __name__ == '__main__':
    run()
