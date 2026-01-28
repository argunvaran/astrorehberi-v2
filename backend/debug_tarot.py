
import os
import django
import json
import sys

# Setup Django
sys.path.append('c:/FlutterProjects/astro/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings')
django.setup()

from astrology.views import draw_tarot
from django.test import RequestFactory

# Create a request
factory = RequestFactory()
data = {
    "lang": "tr",
    "cards": [
        {"id": "ace_wands", "reversed": False},
        {"id": "three_cups", "reversed": True},
        {"id": "world", "reversed": False}
    ]
}
request = factory.post('/api/draw-tarot/', data=json.dumps(data), content_type='application/json')

# Execute view
try:
    response = draw_tarot(request)
    print("Status Code:", response.status_code)
    print("Content:", response.content.decode('utf-8'))
except Exception as e:
    print("CRASH:", e)
    import traceback
    traceback.print_exc()
