from django.core.management.base import BaseCommand
from astrology.models import DailyHoroscope
from datetime import datetime
from skyfield.api import load
from skyfield.framelib import ecliptic_frame

class Command(BaseCommand):
    help = 'Generates Daily Horoscope content based on NASA Skyfield data'

    def handle(self, *args, **options):
        self.stdout.write("Downloading/Loading NASA Ephemeris data...")
        # Load NASA JPL ephemeris (DE421 covers 1900-2050)
        eph = load('de421.bsp')
        
        sun = eph['sun']
        earth = eph['earth']
        moon = eph['moon']
        mercury = eph['mercury']
        venus = eph['venus']
        mars = eph['mars']
        jupiter = eph['jupiter barycenter']
        saturn = eph['saturn barycenter']
        uranus = eph['uranus barycenter']
        neptune = eph['neptune barycenter']
        pluto = eph['pluto barycenter']
        
        planets_map = {
            'Sun': sun, 'Moon': moon, 'Mercury': mercury, 'Venus': venus,
            'Mars': mars, 'Jupiter': jupiter, 'Saturn': saturn,
            'Uranus': uranus, 'Neptune': neptune, 'Pluto': pluto
        }

        ts = load.timescale()
        now = datetime.now()
        t = ts.now()
        
        self.stdout.write(f"Calculating positions for {now.date()}...")
        
        # Calculate Ecliptic Longitude for each planet
        planet_positions = {}
        for name, body in planets_map.items():
            # Geocentric position
            astrometric = earth.at(t).observe(body)
            # Apparent position (light time, aberration, etc.)
            apparent = astrometric.apparent()
            # Ecliptic coordinates
            lat, lon, dist = apparent.frame_latlon(ecliptic_frame)
            planet_positions[name] = lon.degrees

        active_aspects = []
        
        p_names = list(planet_positions.keys())
        ORB = 5 # degrees
        
        for i in range(len(p_names)):
            for j in range(i + 1, len(p_names)):
                p1_name = p_names[i]
                p2_name = p_names[j]
                
                lon1 = planet_positions[p1_name]
                lon2 = planet_positions[p2_name]
                
                diff = abs(lon1 - lon2) % 360
                if diff > 180: diff = 360 - diff
                
                aspect_type = None
                
                if diff <= ORB: aspect_type = 'Conjunction'
                elif abs(diff - 180) <= ORB: aspect_type = 'Opposition'
                elif abs(diff - 120) <= ORB: aspect_type = 'Trine'
                elif abs(diff - 90) <= ORB: aspect_type = 'Square'
                elif abs(diff - 60) <= 4: aspect_type = 'Sextile' # Tighter orb for sextile
                
                if aspect_type:
                     # Create descriptive text
                     text_en = f"{p1_name} is {aspect_type} {p2_name}"
                     text_tr = f"{p1_name} ile {p2_name} {aspect_type} açısında"
                     
                     active_aspects.append({
                         "p1": p1_name,
                         "p2": p2_name,
                         "aspect": aspect_type,
                         "orb": round(diff, 1),
                         "text_en": text_en,
                         "text_tr": text_tr
                     })

        # Generate Summary
        summary_en = f"NASA Data Analysis for {now.strftime('%Y-%m-%d')}: The sky dynamic is active. "
        summary_tr = f"NASA Veri Analizi ({now.strftime('%Y-%m-%d')}): Gökyüzü dinamiği aktif. "
        
        if len(active_aspects) > 4:
            summary_en += "There is high planetary activity today, suggesting a busy or intense day. "
            summary_tr += "Bugün yüksek gezegen aktivitesi var, bu da yoğun bir güne işaret ediyor. "
        elif len(active_aspects) < 2:
            summary_en += "The energies are relatively subtle today. "
            summary_tr += "Enerjiler bugün nispeten sakin. "
            
        # Add primary aspect description
        for a in active_aspects:
            if a['p1'] in ['Sun', 'Moon'] or a['p2'] in ['Sun', 'Moon']:
                summary_en += f"Focus on {a['p1']} and {a['p2']} themes. "
                summary_tr += f"{a['p1']} ve {a['p2']} temalarına odaklanın. "
                break

        # Save to DB
        DailyHoroscope.objects.update_or_create(
            date=now.date(),
            defaults={
                'summary_en': summary_en,
                'summary_tr': summary_tr,
                'aspects': active_aspects
            }
        )
        
        self.stdout.write(self.style.SUCCESS(f"Successfully generated dynamic horoscope using Skyfield!"))
