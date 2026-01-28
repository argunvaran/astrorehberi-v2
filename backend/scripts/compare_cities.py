import requests
import json

def get_hours(lat, lon, name):
    url = f"http://127.0.0.1:8000/api/planetary-hours/?lat={lat}&lon={lon}"
    r = requests.get(url)
    data = r.json()
    if 'hours' in data and len(data['hours']) > 0:
        print(f"--- {name} ({lat}, {lon}) ---")
        print(f"Sunrise (UTC): {data['hours'][0]['start']}")
        print(f"Sunset  (UTC): {data['hours'][12]['start']}") # Approx sunset start
    else:
        print(f"{name}: Error or empty")

get_hours(41.0082, 28.9784, "Istanbul")
get_hours(38.5012, 43.3729, "Van")
