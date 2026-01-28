
import os
import django
import sys
import json

# Setup Django
sys.path.append('c:/FlutterProjects/astro/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.test import RequestFactory
from astrology import views

factory = RequestFactory()

def test_view(name, view_func, path):
    print(f"Testing {name}...")
    try:
        request = factory.get(path)
        response = view_func(request)
        print(f"Status: {response.status_code}")
        if response.status_code != 200:
             print(f"Content: {response.content.decode()}")
        else:
             print("OK")
    except Exception as e:
        print(f"CRASH: {e}")
        import traceback
        traceback.print_exc()

test_view("Get Countries", views.get_countries, '/api/countries/')
test_view("Daily Horoscopes", views.get_daily_horoscopes_api, '/daily-horoscopes/')
test_view("Celestial Events", views.get_celestial_events_view, '/celestial-events/')
test_view("Planetary Hours", views.get_planetary_hours, '/planetary-hours/?lat=41&lon=29')
