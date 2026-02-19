
import os
import django
import sys
from datetime import datetime

# -------------------------------------------------------------------------
# TALİMATLAR:
# 1. Bu dosya 'backend' klasöründe olmalı: c:\FlutterProjects\astro_Yedek\backend\migrate_production_data.py
# 2. Terminal'de 'backend' klasörüne gidin: cd c:\FlutterProjects\astro_Yedek\backend
# 3. YENİ KODLARI ÇEKMİŞ OLABİLİRSİNİZ VE ZATEN 'userprofile' MODELİ SİLİNMİŞ OLABİLİR.
#    BU YÜZDEN BU SCRIPT RAW SQL (SAF SQL) KULLANARAK ESKİ TABLODAN VERİ OKUR.
# -------------------------------------------------------------------------

# Django Setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings') 
django.setup()

from django.db import connection
from django.contrib.auth.models import User
from users.models import Profile

def run():
    print("MIGRATION STARTING: UserProfile (Old) -> Profile (New)")
    
    # Check if old table exists
    with connection.cursor() as cursor:
        try:
            # Check for PostgreSQL/MySQL/SQLite table existence specifically?
            # Or just try to select and catch error.
            cursor.execute("SELECT id, user_id, birth_date, birth_time, birth_place, lat, lon, membership_level FROM astrology_userprofile")
            rows = cursor.fetchall()
            print(f"Found {len(rows)} profiles in old table 'astrology_userprofile'.")
        except Exception as e:
            print(f"ERROR: Could not read from 'astrology_userprofile'. Maybe it is already deleted?\nError: {e}")
            return

        count_migrated = 0
        count_skipped = 0

        for row in rows:
            # Unpack based on SELECT order
            old_id = row[0]
            user_id = row[1]
            birth_date = row[2]
            birth_time = row[3]
            birth_place = row[4]
            lat = row[5]
            lon = row[6]
            membership_level = row[7]

            try:
                user = User.objects.get(id=user_id)
                
                # Check if new profile exists
                profile, created = Profile.objects.get_or_create(user=user)
                
                # Update fields if either created OR existing but missing data
                # We overwrite with old data to be safe, or check complexity?
                # Simple overwrite is safer for migration.
                
                profile.birth_date = birth_date
                profile.birth_time = birth_time
                profile.birth_place = birth_place if birth_place else "Unknown"
                profile.lat = lat if lat is not None else 0.0
                profile.lon = lon if lon is not None else 0.0
                profile.membership_level = membership_level if membership_level else 'free'
                
                # Calculate signs if possible (using simple helper or just leave blank for auto-calc later)
                # Let's leave blank, the system auto-calcs on demand or we can trigger it.
                
                profile.save()
                
                if created:
                    print(f"[CREATED] User: {user.username} (ID: {user_id})")
                else:
                    print(f"[UPDATED] User: {user.username} (ID: {user_id})")
                
                count_migrated += 1
                
            except User.DoesNotExist:
                print(f"[SKIP] User ID {user_id} not found in Auth User table.")
                count_skipped += 1
            except Exception as e:
                print(f"[ERROR] Failed to migrate User ID {user_id}: {e}")

    print(f"\nMigration Complete.")
    print(f"Migrated/Updated: {count_migrated}")
    print(f"Skipped/Errors: {count_skipped}")
    
    # Optional: Suggest user to drop table manually later
    print("\nNOTE: This script does NOT delete the old table 'astrology_userprofile'.")
    print("If data migration looks good, you can proceed with 'python manage.py migrate' which might drop it if the migration file 0012_delete_userprofile is applied.")

if __name__ == '__main__':
    run()
