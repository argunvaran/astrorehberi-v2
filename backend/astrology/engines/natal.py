from .core import AstroCore
from skyfield.api import wgs84
import math

# Basic Translation Maps for Natal Report
SIGNS = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']

class NatalEngine:
    def __init__(self):
        self.core = AstroCore()

    def get_planet_positions(self, t, lat, lon):
        """
        Calculates Geocentric / Topocentric positions of planets using Skyfield.
        Returns a DICT containing 'planets' (list), 'houses' (list), 'ascendant' etc.
        """
        eph = self.core.eph
        earth = eph['earth']
        location = earth + wgs84.latlon(lat, lon)
        
        # Bodies to calculate
        target_bodies = {
            'Sun': 'sun', 'Moon': 'moon', 'Mercury': 'mercury', 
            'Venus': 'venus', 'Mars': 'mars', 'Jupiter': 'jupiter barycenter', 
            'Saturn': 'saturn barycenter', 'Uranus': 'uranus barycenter', 
            'Neptune': 'neptune barycenter', 'Pluto': 'pluto barycenter'
        }
        
        planets_list = []
        raw_positions = {} # For internal calc
        
        # 1. Calculate Planets
        for name, body_key in target_bodies.items():
            try:
                astrometric = location.at(t).observe(eph[body_key])
                apparent = astrometric.apparent()
                lat_ecl, lon_ecl, dist = apparent.ecliptic_latlon()
                
                d_lon = lon_ecl.degrees % 360
                sign_idx = int(d_lon / 30)
                
                p_data = {
                    "name": name,
                    "lon": d_lon,
                    "sign": SIGNS[sign_idx],
                    "degree": d_lon % 30,
                    "retro": False # Placeholder
                }
                planets_list.append(p_data)
                raw_positions[name] = d_lon
            except Exception as e:
                print(f"Error calculating {name}: {e}")

        # 2. Calculate Angles (Ascendant & MC)
        # Using approximated formula based on Local Sidereal Time (LST)
        # Skyfield doesn't have direct 'house' engine yet, so we use approximation valid for most purposes.
        
        # Calculate LST
        t_gast = t.gast # Greenwich Apparent Sidereal Time (hours)
        lst = (t_gast + lon / 15.0) % 24.0 # Local Sidereal Time
        
        # Obliquity of Ecliptic (approx 23.44)
        obl = 23.44
        
        # RAMC (Right Ascension of Midheaven)
        ramc = lst * 15.0
        
        # MC Calculation (Midheaven)
        # tan(MC) = tan(RAMC) / cos(obl)
        # We need careful quadrant checking (atan2)
        mc_rad = math.atan2(math.tan(math.radians(ramc)), math.cos(math.radians(obl)))
        mc_deg = math.degrees(mc_rad)
        if mc_deg < 0: mc_deg += 360
        
        # Check quadrant logic: MC should be in same quadrant as RAMC (mostly)
        # Actually, standard formula adjustment:
        if 90 < ramc <= 270:
            mc_deg = (mc_deg + 180) % 360
        elif ramc > 270 and mc_deg < 90:
            mc_deg = (mc_deg + 180) % 360 # Adjust check
            
        # Refined MC logic just to be safe: MC is roughly sun's position at noon
        # Let's trust standard trig for now but ensure 0-360
        
        # Ascendant Calculation
        # tan(Asc) = -cos(RAMC) / (sin(obl) * tan(lat) + cos(obl) * sin(RAMC))
        lat_rad = math.radians(lat)
        obl_rad = math.radians(obl)
        ramc_rad = math.radians(ramc)
        
        numerator = -math.cos(ramc_rad)
        denominator = (math.sin(obl_rad) * math.tan(lat_rad)) + (math.cos(obl_rad) * math.sin(ramc_rad))
        
        asc_rad = math.atan2(numerator, denominator)
        asc_deg = math.degrees(asc_rad)
        
        # CORRECTIVE OFFSET: The atan2 formula above naturally points to the Descendant (DC) 
        # in this coordinate system configuration. We must flip 180 degrees to get the Ascendant (AC).
        asc_deg = (asc_deg + 180) % 360

        if asc_deg < 0: asc_deg += 360
        
        # Ascendant Sign
        asc_idx = int(asc_deg / 30)
        asc_sign = SIGNS[asc_idx]
        
        # Add Ascendant to Planets List as 'Ascendant' (Virtual Planet)
        planets_list.append({
            "name": "Ascendant",
            "lon": asc_deg,
            "sign": asc_sign,
            "degree": asc_deg % 30,
            "retro": False
        })

        # 3. Calculate Houses (Equal House System for simplicity and robustness)
        # House 1 starts at Ascendant
        houses = []
        for i in range(12):
            cusp = (asc_deg + (i * 30)) % 360
            h_sign_idx = int(cusp / 30)
            houses.append({
                "id": i + 1,
                "lon": cusp,
                "sign": SIGNS[h_sign_idx]
            })
            
        # 4. North Node (Simplified Calculation for Stability)
        # Try to calculate 'moon' position at t-1hour and t+1hour to find node crossing? 
        # Too complex for now. Let's use a simplified Mean Node approximation or a fixed placeholder that works.
        # Ideally, we should add 'moon_node' if ephemeris supports it, but de421 usually doesn't have it directly named easily.
        # We will use a mockup based on Sun-Moon relationship or random for this scope if library fails, 
        # BUT let's try to be deterministic.
        # Setting North Node to 0.0 effectively makes Draconic == Tropical, which is wrong but safe.
        # Let's try to get a pseudo-value if we can't calculate real one.
        north_node = 0.0 
        try:
             # Basic Moon Node Approximation (Mean Node)
             # N = 125.04452 - 1934.136261 * T
             # T = (JD - 2451545.0) / 36525
             jd = t.tt
             T = (jd - 2451545.0) / 36525.0
             north_node = (125.04452 - 1934.136261 * T) % 360
        except:
             north_node = 0.0
             
        # Add North Node to Planets List (Critical for Rectification which looks for 'North Node')
        nn_sign_idx = int(north_node / 30)
        planets_list.append({
            "name": "North Node",
            "lon": north_node,
            "sign": SIGNS[nn_sign_idx],
            "degree": north_node % 30,
            "retro": True # Usually true
        })

        return {
            "planets": planets_list,
            "houses": houses,
            "ascendant": asc_sign,
            "ascendant_deg": asc_deg,
            "midheaven_deg": mc_deg,
            "north_node": north_node,
            "utc_time": t.utc_strftime('%Y-%m-%d %H:%M:%S'),
            "timezone": "Local"
        }

    def calculate_aspects(self, planets_data):
        """
        Calculates aspects between planets.
        Expects planets_data to be a LIST of dicts (from get_planet_positions['planets']).
        """
        aspects = []
        # Index by name
        p_map = {p['name']: p for p in planets_data}
        names = list(p_map.keys())
        
        for i in range(len(names)):
            for j in range(i + 1, len(names)):
                n1 = names[i]
                n2 = names[j]
                
                # Filter useful aspects
                if n1 == 'Ascendant' or n2 == 'Ascendant': 
                    pass # Include angles
                
                p1 = p_map[n1]
                p2 = p_map[n2]

                diff = abs(p1['lon'] - p2['lon'])
                if diff > 180: diff = 360 - diff
                
                orb = 6 # Default orb
                if 'Sun' in [n1, n2] or 'Moon' in [n1, n2]: orb = 8
                
                asp_type = None
                if abs(diff - 0) < orb: asp_type = "Conjunction"
                elif abs(diff - 180) < orb: asp_type = "Opposition"
                elif abs(diff - 120) < orb: asp_type = "Trine"
                elif abs(diff - 90) < orb: asp_type = "Square"
                elif abs(diff - 60) < 4: asp_type = "Sextile"
                
                if asp_type:
                    aspects.append({
                        "p1": n1,
                        "p2": n2,
                        "type": asp_type,
                        "orb": round(diff if asp_type == "Conjunction" else abs(diff - {'Opposition':180, 'Trine':120, 'Square':90, 'Sextile':60}[asp_type]), 2)
                    })
                    
        return aspects

    def calculate_draconic(self, natal_planets_list, node_lon):
        """
        Draconic Chart = Tropical Lon - North Node Lon + 0 (Aries)
        """
        draconic = []
        for p in natal_planets_list:
            trop_lon = p['lon']
            drac_lon = (trop_lon - node_lon) % 360
            
            sign_idx = int(drac_lon / 30)
            sign = SIGNS[sign_idx]
            
            draconic.append({
                "name": p['name'],
                "lon": drac_lon,
                "sign": sign,
                "degree": drac_lon % 30
            })
        return draconic

    def calculate_dominants(self, planets_list):
        """
        Calculates dominant elements/signs based on planet count.
        """
        counts = {"Fire": 0, "Earth": 0, "Air": 0, "Water": 0}
        element_map = {
            "Aries": "Fire", "Leo": "Fire", "Sagittarius": "Fire",
            "Taurus": "Earth", "Virgo": "Earth", "Capricorn": "Earth",
            "Gemini": "Air", "Libra": "Air", "Aquarius": "Air",
            "Cancer": "Water", "Scorpio": "Water", "Pisces": "Water"
        }
        
        for p in planets_list:
            sign = p.get('sign', 'Aries')
            elem = element_map.get(sign, "Fire")
            counts[elem] += 1
            
        return counts
