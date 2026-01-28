from skyfield.api import load, wgs84, Star, utc
from skyfield.framelib import ecliptic_frame
from skyfield.data import hipparcos
import numpy as np
import os
from datetime import datetime, timedelta

# Singleton Core Engine
class AstroCore:
    _instance = None
    _eph = None
    _ts = None
    _stars = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(AstroCore, cls).__new__(cls)
            cls._instance._load_data()
        return cls._instance

    def _load_data(self):
        print(" [NASA] Loading Ephemeris Data...")
        # PROD: Absolute Path Check
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        # Adjust if needed to point to 'de421.bsp' in parent or current
        # Assuming de421.bsp is in `backend/` root or `astrology/`
        # Current Layout: backend/de421.bsp
        eph_path = os.path.join(base_dir, '..', 'de421.bsp') 
        
        # Fallback if not found
        if not os.path.exists(eph_path):
            eph_path = 'de421.bsp' # Try local relative

        try:
            self._eph = load(eph_path)
        except Exception as e:
            print(f" [ERROR] Ephemeris Load Failed: {e}. Trying download...")
            self._eph = load('de421.bsp') # Auto download
            
        self._ts = load.timescale()
        # self._stars = hipparcos.load_dataframe(hipparcos.URL) # Heavy, load only if needed
        print(" [NASA] Engine Ready.")

    @property
    def eph(self):
        return self._eph
    
    @property
    def ts(self):
        return self._ts
