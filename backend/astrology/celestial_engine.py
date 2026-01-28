from skyfield.api import load
from skyfield import almanac
from datetime import timedelta
import datetime

# Cache for efficiency
_EPH = None

def get_next_celestial_events(limit=2):
    """
    Returns the next significant lunar events (New Moon, Full Moon).
    Calculates their Sign and Degree.
    """
    global _EPH
    if _EPH is None:
        try:
             _EPH = load('de421.bsp')
        except:
             return [] # Fail gracefully if file missing

    ts = load.timescale()
    t0 = ts.now()
    # Look ahead 60 days
    t1 = ts.utc(t0.utc_datetime() + timedelta(days=60))
    
    # Almanac search
    f = almanac.moon_phases(_EPH)
    times, phases = almanac.find_discrete(t0, t1, f)
    
    events = []
    
    ZODIAC = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
              'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']
    
    for t, phase in zip(times, phases):
        if phase not in [0, 2]: continue # Skip quarters
        
        event_type = "New Moon" if phase == 0 else "Full Moon"
        
        # Calculate Position of Sun/Moon to find Sign
        # For New Moon: Moon is same sign as Sun
        # For Full Moon: Moon is opposite Sun (We track Moon position for impact)
        
        observer = _EPH['earth']
        moon = _EPH['moon']
        
        # Get apparent position
        astrometric = observer.at(t).observe(moon)
        _, lon, _ = astrometric.apparent().ecliptic_latlon()
        
        deg = lon.degrees
        sign_idx = int(deg / 30)
        sign_name = ZODIAC[sign_idx]
        degree_in_sign = int(deg % 30)
        
        date_obj = t.utc_datetime()
        
        events.append({
            "type": event_type,
            "date": date_obj.strftime("%Y-%m-%d"),
            "time": date_obj.strftime("%H:%M"),
            "sign": sign_name,
            "sign_index": sign_idx + 1, # 1-based logic for house calc
            "degree": degree_in_sign
        })
        
        if len(events) >= limit: break
        
    return events

def calculate_impact_house(rising_sign_name, event_sign_name):
    """
    Calculates which house the event falls into based on Whole Sign Houses.
    """
    ZODIAC = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
              'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']
              
    try:
        r_idx = ZODIAC.index(rising_sign_name) # 0 for Aries
        e_idx = ZODIAC.index(event_sign_name)  # 0 for Aries
        
        # Formula: (Event - Rising + 12) % 12 + 1
        house = (e_idx - r_idx + 12) % 12 + 1
        return house
    except:
        return 1 # Fallback
