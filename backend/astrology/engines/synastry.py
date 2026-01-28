from .core import AstroCore
from ..synastry_data import SYNASTRY_DATA, get_generic_text

class SynastryEngine:
    def __init__(self):
        pass

    def compare_charts(self, p1_planets, p2_planets, lang='en'):
        """
        Compares two sets of planetary positions.
        Returns score, aspect list, and summary.
        """
        aspects = []
        score = 0
        total_possible = 0
        
        # Major Inter-Aspects
        # P1 Planet vs P2 Planet
        
        for name1, data1 in p1_planets.items():
            for name2, data2 in p2_planets.items():
                
                # Only Major Planets usually (Sun, Moon, Venus, Mars)
                if name1 not in ['Sun', 'Moon', 'Venus', 'Mars', 'Ascendant'] or name2 not in ['Sun', 'Moon', 'Venus', 'Mars', 'Ascendant']:
                    continue
                    
                diff = abs(data1['lon'] - data2['lon'])
                if diff > 180: diff = 360 - diff
                
                orb = 5
                is_match = False
                points = 0
                theme = "Neutral"
                
                if abs(diff - 0) < orb: 
                    type_ ='Conjunction'
                    is_match = True
                    points = 10
                    theme = "Fusion"
                elif abs(diff - 120) < orb: 
                    type_ = 'Trine'
                    is_match = True
                    points = 8
                    theme = "Flow"
                elif abs(diff - 60) < 3: 
                    type_ = 'Sextile'
                    is_match = True
                    points = 6
                    theme = "Opportunity"
                elif abs(diff - 180) < orb: 
                    type_ = 'Opposition'
                    is_match = True
                    points = 5 # Intense but can be good
                    theme = "Attraction/Tension"
                elif abs(diff - 90) < orb: 
                    type_ = 'Square'
                    is_match = True
                    points = -5 # Challenge
                    theme = "Friction"
                
                if is_match:
                    # Weighting based on planets
                    weight = 1.0
                    if 'Sun' in [name1, name2] and 'Moon' in [name1, name2]: weight = 2.0 # Soulmate
                    if 'Venus' in [name1, name2] and 'Mars' in [name1, name2]: weight = 1.8 # Sexual
                    
                    final_points = points * weight
                    score += final_points
                    
                    # Lookup Interpretation
                    planets = sorted([name1, name2])
                    key = f"{planets[0]}_{planets[1]}_{type_}"
                    
                    text = SYNASTRY_DATA.get(lang, {}).get(key)
                    if not text:
                         text = get_generic_text(planets[0], planets[1], type_, lang)
                    
                    # Categoriation Logic for UI
                    category = 'spiritual'
                    if type_ in ['Square', 'Opposition']:
                        category = 'growth'
                    elif 'Venus' in [name1, name2] or 'Mars' in [name1, name2]:
                        category = 'passion'
                    
                    aspects.append({
                        "p1": name1,
                        "p2": name2,
                        "type": type_,
                        "theme": theme,
                        "interpretation": text,
                        "category": category,
                        "is_romance": True if 'Venus' in [name1, name2] or 'Mars' in [name1, name2] else False
                    })

        # Score Normalization (approx)
        normalized_score = max(0, min(100, 50 + score)) # Base 50
        
        summary = "Average Compatibility"
        if normalized_score > 80: summary = "Cosmic Soulmates!"
        elif normalized_score > 60: summary = "Great Potential"
        elif normalized_score < 40: summary = "Karmic Challenges"
        
        if lang == 'tr':
            if normalized_score > 80: summary = "Kozmik Ruh Eşleri!"
            elif normalized_score > 60: summary = "Büyük Potansiyel"
            elif normalized_score < 40: summary = "Karmik Zorluklar"
            else: summary = "Ortalama Uyum"

        return {
            "score": int(normalized_score),
            "summary": summary,
            "aspects": aspects
        }
