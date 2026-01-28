
# RUN THIS VIA: python manage.py shell < debug_friend.py
# But that doesn't work easily on Windows PowerShell piping.
# Instead, let's fix the env setup.
import os, sys, django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from astrology.engine import NASAEngine

# 4 Nov 1990, 04:30, Istanbul
lat = 40.9856
lon = 29.0274

print("--- DEBUG FRIEND CHART ---")
engine = NASAEngine()
data = engine.calculate_chart("1990-11-04", "04:30", lat, lon, "tr")

print(f"Sun Sign: {data['meta']['sun_sign']}")
print(f"Rising Sign: {data['meta']['rising_sign']}")
print(f"Timezone: {data['meta']['local_timezone']}")
print(f"First House: {data['houses'][0]}")

