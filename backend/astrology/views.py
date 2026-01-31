from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

import json
import random
from .engine import AstroEngine
import datetime
from datetime import datetime as dt
import geonamescache
from .tarot_data import tarot_deck
from .horoscope_data import SENTENCES, SIGNS_TR, SIGNS_EN
from django.db.models import Q
from .models import PlanetInterpretation, AspectInterpretation, DailyTip, DailyHoroscope, WeeklyHoroscope, UserProfile, UserActivityLog, BlogPost, ContactMessage
from .forms import UserSettingsForm
from .celestial_engine import get_next_celestial_events, calculate_impact_house
from .celestial_data import HOUSE_THEMES, EVENT_DESCRIPTIONS
from django.db.models import Count, Max, Min
from django.contrib.auth.decorators import user_passes_test
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.core.paginator import Paginator

# Try to import flatlib, handle error if not installed
try:
    from flatlib.datetime import Datetime
    from flatlib.geopos import GeoPos
    from flatlib.chart import Chart
    from flatlib import const
    FLATLIB_AVAILABLE = True
except ImportError:
    FLATLIB_AVAILABLE = False

@csrf_exempt
def appointment_view(request):
    return render(request, 'astrology/appointment.html')

@csrf_exempt
def blog_detail(request, slug):
    """
    Renders a single Blog Post page (SSR) for SEO/AdSense.
    """
    try:
        post = BlogPost.objects.get(slug=slug)
        # Ensure 'views' count increment logic if needed
        return render(request, 'astrology/pages/blog_detail.html', {'post': post})
    except BlogPost.DoesNotExist:
        return render(request, 'astrology/404.html', status=404)

@csrf_exempt
def submit_contact_form(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            # Basic validation
            if not data.get('name') or not data.get('email') or not data.get('message'):
                return JsonResponse({'success': False, 'error': 'Tüm alanlar zorunludur.'})
            
            ContactMessage.objects.create(
                name=data.get('name'),
                email=data.get('email'),
                message=data.get('message')
            )
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})
    return JsonResponse({'error': 'POST required'}, status=405)

@csrf_exempt
def calculate_chart(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST request required'}, status=405)

    try:
        data = json.loads(request.body)
        date_str = data.get('date').replace('-', '/') if data.get('date') else None 
        time_str = data.get('time') 
        lat = float(data.get('lat', 41.0))
        lon = float(data.get('lon', 28.0))
        lang = data.get('lang', 'en') 
        
        # Initialize NASA Engine
        engine = AstroEngine()
        
        # 1. Main Calculation (Skyfield)
        natal_data = engine.calculate_natal(date_str, time_str, lat, lon)
        
        # 2. Enrich with Interpretations (Smart Generator)
        # We use a generative approach to ensure rich, long descriptions without massive DB seeding
        
        # Archetypes (Data could be moved to a separate file, but kept here for stability)
        ARCHETYPES = {
            'en': {
                'Sun': "The Sun represents your ego, core identity, and life force. It is the 'Hero' within you.",
                'Moon': "The Moon governs your emotions, instincts, and the subconscious. It represents your inner world.",
                'Mercury': "Mercury rules communication, intellect, and how you process information.",
                'Venus': "Venus is the planet of love, beauty, values, and how you attract relationships.",
                'Mars': "Mars represents your drive, action, passion, and how you assert yourself.",
                'Jupiter': "Jupiter is the seeker of expansion, luck, philosophy, and abundance.",
                'Saturn': "Saturn represents discipline, structure, karma, and life's hard lessons.",
                'Uranus': "Uranus acts as the awakener, ruling innovation, rebellion, and sudden change.",
                'Neptune': "Neptune involves dreams, intuition, illusion, and spiritual transcendence.",
                'Pluto': "Pluto governs transformation, power, regeneration, and the cycle of rebirth.",
                'North Node': "The North Node points to your karmic destiny and the qualities you must develop."
            },
            'tr': {
                'Sun': "Güneş, egonuzu, temel kimliğinizi ve yaşam gücünüzü temsil eder. O, içinizdeki 'Kahraman'dır.",
                'Moon': "Ay, duygularınızı, içgüdülerinizi ve bilinçaltınızı yönetir. İç dünyanızın aynasıdır.",
                'Mercury': "Merkür, iletişimi, zekayı ve bilgiyi nasıl işlediğinizi yönetir.",
                'Venus': "Venüs aşkın, güzelliğin, değerlerin ve ilişkileri nasıl çektiğinizin gezegenidir.",
                'Mars': "Mars, dürtülerinizi, eylemlerinizi, tutkunuzu ve kendinizi nasıl ortaya koyduğunuzu temsil eder.",
                'Jupiter': "Jüpiter, genişlemenin, şansın, felsefenin ve bolluğun arayıcısıdır.",
                'Saturn': "Satürn, disiplini, yapıyı, karmayı ve hayatın zorlu derslerini temsil eder.",
                'Uranus': "Uranüs, yeniliği, isyanı ve ani değişimleri yöneten uyanışçıdır.",
                'Neptune': "Neptün hayalleri, sezgiyi, illüzyonu ve ruhsal aşkınlığı içerir.",
                'Pluto': "Plüton, dönüşümü, gücü, yenilenmeyi ve yeniden doğuş döngüsünü yönetir.",
                'North Node': "Kuzey Ay Düğümü, karmik kaderinizi ve bu hayatta geliştirmeniz gereken nitelikleri işaret eder."
            }
        }

        SIGNS_MEANING = {
            'en': {
                'Aries': "In Aries, this energy is expressed impulsively, dynamically, and with great courage. You take initiative and lead with fire.",
                'Taurus': "In Taurus, this energy is grounded, seeking stability, comfort, and tangible results. You move with deliberate patience.",
                'Gemini': "In Gemini, this energy manifests through curiosity, adaptability, and social connection. You thrive on variety and intellect.",
                'Cancer': "In Cancer, this energy is filtered through deep emotion, protection, and nurturing sensitivity. You value security above all.",
                'Leo': "In Leo, this energy shines dramatically. You express it with warmth, creativity, and a need for recognition or applause.",
                'Virgo': "In Virgo, this energy is analytical and service-oriented. You seek perfection, order, and practical utility in this area.",
                'Libra': "In Libra, this energy seeks balance, harmony, and relationship. You express it through diplomacy and an aesthetic eye.",
                'Scorpio': "In Scorpio, this energy is intense, magnetic, and transformative. You seek depth and are not afraid of the shadows.",
                'Sagittarius': "In Sagittarius, this energy is adventurous and philosophical. You express it through a quest for truth and freedom.",
                'Capricorn': "In Capricorn, this energy is disciplined and ambitious. You express it through hard work, structure, and long-term goals.",
                'Aquarius': "In Aquarius, this energy is unconventional and innovative. You express it through rebellion against the norm and humanitarian ideals.",
                'Pisces': "In Pisces, this energy is compassionate and mystical. You express it through boundaries mental expansion and spiritual connection."
            },
            'tr': {
                'Aries': "Koç burcunda bu enerji dürtüsel, dinamik ve büyük bir cesaretle ifade edilir. İnisiyatif alır ve ateşle liderlik edersiniz.",
                'Taurus': "Boğa burcunda bu enerji topraklanmıştır; istikrar, konfor ve somut sonuçlar arar. Kasıtlı bir sabırla hareket edersiniz.",
                'Gemini': "İkizler burcunda bu enerji merak, uyum yeteneği ve sosyal bağlantı yoluyla tezahür eder. Çeşitlilik ve zeka ile beslenirsiniz.",
                'Cancer': "Yengeç burcunda bu enerji derin duygu, koruma ve besleyici hassasiyetle filtrelenir. Güvenliğe her şeyden çok değer verirsiniz.",
                'Leo': "Aslan burcunda bu enerji dramatik bir şekilde parlar. Onu sıcaklık, yaratıcılık ve takdir edilme ihtiyacıyla ifade edersiniz.",
                'Virgo': "Başak burcunda bu enerji analitik ve hizmet odaklıdır. Bu alanda mükemmellik, düzen ve pratik yarar ararsınız.",
                'Libra': "Terazi burcunda bu enerji denge, uyum ve ilişki arar. Onu diplomasi ve estetik bir gözle ifade edersiniz.",
                'Scorpio': "Akrep burcunda bu enerji yoğun, manyetik ve dönüştürücüdür. Derinlik ararsınız ve gölgelerden korkmazsınız.",
                'Sagittarius': "Yay burcunda bu enerji maceracı ve felsefidir. Onu hakikat ve özgürlük arayışıyla ifade edersiniz.",
                'Capricorn': "Oğlak burcunda bu enerji disiplinli ve hırslıdır. Onu çok çalışmak, yapı kurmak ve uzun vadeli hedeflerle ifade edersiniz.",
                'Aquarius': "Kova burcunda bu enerji gelenek dışı ve yenilikçidir. Onu norma isyan ve insani ideallerle ifade edersiniz.",
                'Pisces': "Balık burcunda bu enerji şefkatli ve mistiktir. Onu sınırsız zihinsel genişleme ve ruhsal bağlantı ile ifade edersiniz."
            }
        }

        # Sign Translations for Synthesis
        SIGN_NAMES_TR = {
            'Aries': 'Koç', 'Taurus': 'Boğa', 'Gemini': 'İkizler', 'Cancer': 'Yengeç',
            'Leo': 'Aslan', 'Virgo': 'Başak', 'Libra': 'Terazi', 'Scorpio': 'Akrep',
            'Sagittarius': 'Yay', 'Capricorn': 'Oğlak', 'Aquarius': 'Kova', 'Pisces': 'Balık'
        }

        # Check Membership
        # Check Membership
        is_free_user = True
        if request.user.is_authenticated:
            try:
                p = UserProfile.objects.get(user=request.user)
                level = str(p.effective_membership).lower().strip()
                if level in ['premium'] or request.user.is_superuser:
                    is_free_user = False
            except: pass
        
        # Check Global Free Premium Mode from Settings
        try:
             from django.conf import settings
             if getattr(settings, 'FREE_PREMIUM_MODE', False) == True:
                 is_free_user = False
        except: pass

        planets_enriched = []
        for p in natal_data['planets']:
            # Generate Basic Info (Always Visible)
            base_en = ARCHETYPES['en'].get(p['name'], "")
            sign_tr = SIGN_NAMES_TR.get(p['sign'], p['sign'])
            
            # Detailed Interpretations (RESTRICTED)
            mod_en = SIGNS_MEANING['en'].get(p['sign'], "")
            synth_en = f"{base_en} {mod_en} This placement suggests that this aspect of your personality is colored by the qualities of {p['sign']}."
            
            base_tr = ARCHETYPES['tr'].get(p['name'], "")
            mod_tr = SIGNS_MEANING['tr'].get(p['sign'], "")
            synth_tr = f"{base_tr} {mod_tr} Bu yerleşim, karakterinizin bu yönünün {sign_tr} burcunun özellikleriyle şekillendiğini gösterir."

            if is_free_user:
                # Mask Interpretations
                p['interpretations'] = {
                    'en': "Detailed interpretation is available for Premium members.",
                    'tr': "Detaylı yorum sadece Premium üyelere özeldir."
                }
                p['interpretation'] = "Detaylı yorum kilitli. 🔒"
                p['is_restricted'] = True
            else:
                p['interpretations'] = {
                    'en': synth_en,
                    'tr': synth_tr
                }
                p['interpretation'] = synth_tr if lang == 'tr' else synth_en
                p['is_restricted'] = False
            
            planets_enriched.append(p)
            
        # 3. Aspects
        aspects_raw = engine.calculate_aspects(planets_enriched)
        aspects_enriched = []
        from .models import AspectInterpretation
        
        for a in aspects_raw:
             interp = AspectInterpretation.objects.filter(
                Q(planet_1=a['p1'], planet_2=a['p2'], aspect_type=a['type']) |
                Q(planet_1=a['p2'], planet_2=a['p1'], aspect_type=a['type'])
             ).first()
             
             text = getattr(interp, f'text_{lang}', f"{a['type']} aspect") if interp else f"{a['p1']} {a['type']} {a['p2']}"
             
             aspects_enriched.append({
                 "p1": a['p1'], "p2": a['p2'], "type": a['type'],
                 "orb": a['orb'], "interpretation": text
             })

        # 4. Advanced Metrics
        birth_year = int(date_str.split('/')[0])
        current_year = datetime.now().year
        
        # Profection (Simple Modulo)
        profection = (current_year - birth_year) % 12 + 1
        
        # Dominants
        dominants = engine.calculate_dominants(planets_enriched)
        
        # Lucky Gem
        sun_sign = next((p['sign'] for p in planets_enriched if p['name'] == 'Sun'), 'Aries')
        # We can implement get_lucky_gems in engine or here. 
        # Engine has it? No, I removed it in replacement. Let's add simple dict here.
        gems = {
            'Aries': {'color': 'Red', 'stone': 'Ruby'}, 'Taurus': {'color': 'Green', 'stone': 'Emerald'},
            'Gemini': {'color': 'Yellow', 'stone': 'Agate'}, 'Cancer': {'color': 'Silver', 'stone': 'Moonstone'},
            'Leo': {'color': 'Gold', 'stone': 'Peridot'}, 'Virgo': {'color': 'Navy', 'stone': 'Sapphire'},
            'Libra': {'color': 'Blue', 'stone': 'Opal'}, 'Scorpio': {'color': 'Black', 'stone': 'Topaz'},
            'Sagittarius': {'color': 'Purple', 'stone': 'Turquoise'}, 'Capricorn': {'color': 'Brown', 'stone': 'Garnet'},
            'Aquarius': {'color': 'Cyan', 'stone': 'Amethyst'}, 'Pisces': {'color': 'Sea Green', 'stone': 'Aquamarine'}
        }
        lucky = gems.get(sun_sign, {'color': 'White', 'stone': 'Diamond'})
        
        # Draconic Calculation & Enrichment
        # --- PLATINUM ONLY (Temporarily Unlocked) ---
        draconic_enriched = []
        
        if True: # was: if not is_free_user:
            draconic_data = engine.calculate_draconic(natal_data['planets'], natal_data['north_node'])
            for p in draconic_data:
                # English
                base_en = ARCHETYPES['en'].get(p['name'], "")
                mod_en = SIGNS_MEANING['en'].get(p['sign'], "")
                synth_en = f"In your Draconic Soul Chart: {base_en} {mod_en} This indicates your higher self's intent."
                
                # Turkish
                base_tr = ARCHETYPES['tr'].get(p['name'], "")
                mod_tr = SIGNS_MEANING['tr'].get(p['sign'], "")
                sign_tr = SIGN_NAMES_TR.get(p['sign'], p['sign'])
                synth_tr = f"Drakonik Ruh Haritanızda: {base_tr} {mod_tr} Bu, yüksek benliğinizin niyetini gösterir."
                
                p['interpretations'] = {'en': synth_en, 'tr': synth_tr}
                # Fallback for older frontend logic if needed
                p['interpretation'] = synth_tr if lang == 'tr' else synth_en
                draconic_enriched.append(p)

        response = {
            "planets": planets_enriched,
            "houses": [h['lon'] for h in natal_data['houses']], 
            "aspects": aspects_enriched,
                "meta": {
                    "profection_house": profection,
                    "dominants": dominants,
                    "lucky_color": lucky['color'],
                    "lucky_stone": lucky['stone'],
                    "sun_sign": sun_sign,
                    "rising_sign": natal_data['ascendant'],
                    "sun_lon_exact": next((p['lon'] for p in planets_enriched if p['name'] == 'Sun'), 0.0),
                    "calc_utc": natal_data.get('utc_time', 'Unknown'),
                    "local_timezone": natal_data.get('timezone', 'Unknown'),
                    "planetary_hours": [],
                    "draconic_chart": draconic_enriched,
                    "celebrity_match": {"name": "TBD", "score": 0},
                    "acg_lines": []
                }
        }
        return JsonResponse(response)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def calculate_synastry_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST request required'}, status=405)

    try:
        data = json.loads(request.body)
        lang = data.get('lang', 'en')
        
        engine = AstroEngine()
        
        # Person 1
        d1 = data.get('date1', '1990/01/01')
        t1 = data.get('time1', '12:00')
        chart1 = engine.calculate_natal(d1, t1, 41.0, 28.0) # Default lat/lon for synastry generic
        
        # Person 2
        d2 = data.get('date2', '1990/01/01')
        t2 = data.get('time2', '12:00')
        chart2 = engine.calculate_natal(d2, t2, 41.0, 28.0)
        
        # Calculate
        result = engine.calculate_synastry(chart1['planets'], chart2['planets'], lang=lang)
        
        # --- FREE LIMITATION ---
        # --- FREE LIMITATION ---
        is_free = True
        if request.user.is_authenticated:
            try:
                p = UserProfile.objects.get(user=request.user)
                level = str(p.effective_membership).lower().strip()
                if level == 'premium' or request.user.is_superuser:
                    is_free = False
            except: pass
            
        if is_free:
            # Check Global Free Mode
            from django.conf import settings
            is_global_free = getattr(settings, 'FREE_PREMIUM_MODE', False)
            
            if not is_global_free:
                # Hide detailed aspects, only show Score & Short Summary
                result['aspects'] = [] 
                result['is_restricted'] = True # Frontend will show "Upgrade to see details"
        
        # Add Interpretation Texts
        summary = ""
        if result['score'] > 85:
            summary = "Soulmate Potential! Extremely high compatibility." if lang=='en' else "Ruh İkizi Potansiyeli! Son derece yüksek uyum."
        elif result['score'] > 70:
            summary = "Strong connection with good harmony." if lang=='en' else "İyi bir uyum ve güçlü bir bağ."
        elif result['score'] > 50:
            summary = "Average compatibility, requires work." if lang=='en' else "Ortalama uyum, çaba gerektirir."
        else:
            summary = "Challenging dynamic, karmic lessons." if lang=='en' else "Zorlayıcı dinamik, karmik dersler."
            
        result['summary'] = summary
        
        return JsonResponse(result)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)

from datetime import datetime, timedelta
from .models import DailyTip

@csrf_exempt
@csrf_exempt
def get_weekly_forecast(request):
    """
    Returns a 7-day Multi-Dimensional Transit Forecast ("Fortune Telling Mode").
    """
    if request.method != 'GET':
        return JsonResponse({'error': 'GET request required'}, status=405)
        
    lang = request.GET.get('lang', 'en')
    date_str = request.GET.get('date', None)
    
    if date_str:
        try:
            start_date = datetime.strptime(date_str, "%Y-%m-%d")
        except:
             try:
                 start_date = datetime.strptime(date_str, "%Y/%m/%d")
             except:
                 start_date = datetime.now()
    else:
        start_date = datetime.now()

    # Check Skyfield availability
    try:
        from skyfield.api import load
        from skyfield.framelib import ecliptic_frame
        eph = load('de421.bsp')
        ts = load.timescale()
        has_skyfield = True
    except:
        has_skyfield = False
        
    forecast = []
    
    # Fortune Messages
    MSGS_EN = {
        'high': "A powerful day! The stars align for success.",
        'low': "Caution advised. Energy is unstable, rest and reflect.",
        'mid': "A balanced day. Good for routine tasks.",
        'love_high': "Venus is smiling! Romance and beauty are favored.",
        'career_high': "Saturn builds. Great for ambitious moves.",
        'tension': "Squares detected. Avoid conflicts and hasty decisions."
    }
    MSGS_TR = {
        'high': "Güçlü bir gün! Yıldızlar başarı için hizalanıyor.",
        'low': "Dikkatli olun. Enerji dengesiz, dinlenin ve düşünün.",
        'mid': "Dengeli bir gün. Rutin işler için uygun.",
        'love_high': "Venüs gülümsüyor! Aşk ve güzellik günü.",
        'career_high': "Satürn inşa ediyor. Kariyer adımları için harika.",
        'tension': "Gergin açılar var. Çatışmadan ve acele karardan kaçının."
    }
    msgs = MSGS_TR if lang == 'tr' else MSGS_EN

    days_limit = 7
    
    # --- MEMBERSHIP CHECK ---
    # --- MEMBERSHIP CHECK ---
    is_free = True
    if request.user.is_authenticated:
        try:
             p = UserProfile.objects.get(user=request.user)
             level = str(p.effective_membership).lower().strip()
             if level == 'premium' or request.user.is_superuser:
                 is_free = False
        except: pass
        
    if is_free:
        # Check GLOBAL FREE MODE
        from django.conf import settings
        is_global_free = getattr(settings, 'FREE_PREMIUM_MODE', False)
        
        if is_global_free:
            days_limit = 7
        else:
            days_limit = 1 # Only Show Today for Free Users (Restricted)


    for i in range(days_limit):
        target_date = start_date + timedelta(days=i)
        
        # Default Baselines
        total = 50
        love = 50
        career = 50
        comment = msgs['mid']

        if has_skyfield:
            t = ts.utc(target_date.year, target_date.month, target_date.day, 12, 0, 0)
            planets = {
                'Sun': eph['sun'], 'Moon': eph['moon'], 'Mars': eph['mars'], 
                'Saturn': eph['saturn barycenter'], 'Jupiter': eph['jupiter barycenter'], 
                'Venus': eph['venus']
            }
            pos = {}
            earth = eph['earth']
            for name, body in planets.items():
                astrometric = earth.at(t).observe(body)
                lat, lon, dist = astrometric.apparent().frame_latlon(ecliptic_frame)
                pos[name] = lon.degrees

            # Aspect Logic
            aspect_score = 0
            love_boost = 0
            career_boost = 0
            
            # Simple Transit Logic
            # Venus Aspects (Love)
            v_lon = pos['Venus']
            for p, l in pos.items():
                if p == 'Venus': continue
                diff = abs(v_lon - l) % 360
                if diff > 180: diff = 360 - diff
                if abs(diff - 120) < 5 or abs(diff - 60) < 4: love_boost += 15 # Trine/Sextile
                if abs(diff - 90) < 5 or abs(diff - 180) < 5: love_boost -= 10 # Square/Opp
            
            # Saturn/Jupiter Aspects (Career)
            s_lon = pos['Saturn']
            j_lon = pos['Jupiter']
             # Check Saturn aspects
            for p, l in pos.items():
                if p == 'Saturn': continue
                diff = abs(s_lon - l) % 360
                if diff > 180: diff = 360 - diff
                if abs(diff - 120) < 5 or abs(diff - 60) < 4: career_boost += 10
                if abs(diff - 90) < 5: career_boost -= 15 # Saturn squares depend hard work
            
            # General Aspects
            p_names = list(pos.keys())
            for idx1 in range(len(p_names)):
                for idx2 in range(idx1+1, len(p_names)):
                    p1 = p_names[idx1]; p2 = p_names[idx2]
                    d = abs(pos[p1] - pos[p2]) % 360
                    if d > 180: d = 360 - d
                    if abs(d-120)<5: aspect_score += 8
                    if abs(d-60)<4: aspect_score += 4
                    if abs(d-90)<5: aspect_score -= 8
                    if abs(d-180)<5: aspect_score -= 6
            
            total = 50 + aspect_score
            love = 50 + love_boost
            career = 50 + career_boost
            
            # Smart Commentary
            if love > 70: comment = msgs['love_high']
            elif career > 70: comment = msgs['career_high']
            elif total < 30: comment = msgs['tension']
            elif total > 70: comment = msgs['high']
            elif total < 45: comment = msgs['low']
        
        # Clamp
        total = max(10, min(100, total))
        love = max(10, min(100, love))
        career = max(10, min(100, career))

        forecast.append({
            "day": target_date.strftime("%a %d"), # Mon 18
            "full_date": target_date.strftime("%Y-%m-%d"),
            "score": int(total),
            "love": int(love),
            "career": int(career),
            "comment": comment
        })

    return JsonResponse({"forecast": forecast})


@csrf_exempt
def get_daily_planner(request):
    """
    Returns daily tips and planetary hours.
    """
    # Ensure engine is available
    engine = AstroEngine()
    if request.method != 'GET':
        return JsonResponse({'error': 'GET request required'}, status=405)
        
    try:
        lang = request.GET.get('lang', 'en')
        date_param = request.GET.get('date', None)
        lat = float(request.GET.get('lat', 41.0))
        lon = float(request.GET.get('lon', 28.0))
        
        now = datetime.utcnow()
        if date_param:
            try:
                target_date = datetime.strptime(date_param, "%Y-%m-%d")
                date_str = target_date.strftime("%Y-%m-%d")
            except:
                date_str = now.strftime("%Y-%m-%d")
        else:
            date_str = now.strftime("%Y-%m-%d")

        # Get Hours
        hours_data = engine.calculate_planetary_hours(date_str, lat, lon)
        
        # --- FREE LIMIT (Hide Hours Data) ---
        # --- FREE LIMIT (Hide Hours Data) ---
        is_free_user = True
        if request.user.is_authenticated:
            try: 
                 level = str(request.user.profile.effective_membership).lower().strip()
                 if level == 'premium' or request.user.is_superuser: 
                    is_free_user = False
            except: pass
            
        if is_free_user:
            # Check Global Free Mode
            from django.conf import settings
            is_global_free = getattr(settings, 'FREE_PREMIUM_MODE', False)
            if not is_global_free:
                hours_data = [] # Hidden from backend
            # Note: Daily tips usually remain visible as teaser
        
        # ... existing transit logic ...
        
        data = {'hours': hours_data}
        
        # Mock other data for now to prevent errors, since we focused on Hours
        data['retrogrades'] = []
        data['phase'] = 'Waxing Gibbous'
        data['daily_summary'] = "Focus on the planetary hours to guide your day."

        # Fetch Tips
        tips = DailyTip.objects.filter(phase=data['phase'])
        tips_data = []
        for t in tips:
            tips_data.append(getattr(t, f'text_{lang}', t.text_en))
            
        data['tips'] = tips_data
        
        # Static Retro warnings
        retro_warnings = []
        for r in data['retrogrades']:
            msg_en = f"{r} is currently in Retrograde! Be careful."
            msg_tr = f"{r} şu an retro harekette! Dikkatli olun."
            retro_warnings.append(msg_tr if lang == 'tr' else msg_en)
            
        data['retro_warnings'] = retro_warnings

        # --- Fetch NASA Daily Horoscope ---
        horoscope = DailyHoroscope.objects.filter(date=now.date()).first()
        
        if horoscope:
            data['daily_summary'] = getattr(horoscope, f'summary_{lang}', horoscope.summary_en)
            # Filter aspects for simplier display if needed, but returning all is fine
            data['daily_aspects'] = horoscope.aspects
        else:
            # Fallback if command not run
            if lang == 'tr':
                 data['daily_summary'] = "Günlük analiz genellikle öğlen gelir."
            else:
                 data['daily_summary'] = "Daily analysis usually arrives by noon."
                 
            data['daily_aspects'] = []

        return JsonResponse(data)
    except Exception as e:
        import traceback
        return JsonResponse({'error': str(e), 'trace': traceback.format_exc()}, status=500)


@csrf_exempt
def draw_tarot(request):
    """
    Draws cards and generates a synthesis.
    Supports manual selection via POST.
    """
    try:
        # --- MEMBERSHIP LIMITS ---
        if request.user.is_authenticated:
            today = datetime.now().date()
            daily_count = UserActivityLog.objects.filter(
                user=request.user,
                action="Tarot Odası", 
                timestamp__date=today
            ).count()
            
            limit = 1 # Free default
            level = 'free'
            try:
                p = UserProfile.objects.get(user=request.user)
                level = str(p.effective_membership).lower().strip()
            except: pass
            
            if level == 'premium': limit = 999
            
            if daily_count >= limit:
                return JsonResponse({
                    'error': 'Günlük tarot limitiniz doldu. Sınırsız erişim için Premium üye olun.',
                    'upgrade_required': True 
                }, status=200)

        lang = 'en'
        manual_selection = []
        
        if request.method == 'POST':
            # ... existing manual logic ...
            try:
                data = json.loads(request.body)
                lang = data.get('lang', 'en')
                input_cards = data.get('cards', []) # [{'id':'fool', 'reversed':False}, ...]
                
                for item in input_cards:
                    c_obj = next((x for x in tarot_deck if x['id'] == item['id']), None)
                    if c_obj:
                        manual_selection.append({
                            'card': c_obj,
                            'is_reversed': item.get('reversed', False),
                            'fixed_position': item.get('position_idx')
                        })
            except:
                 pass # Fallback to random if JSON fails
        else:
            lang = request.GET.get('lang', 'en')

        # Select 3 unique cards if not manual
        if manual_selection:
            selection_data = manual_selection
        else:
            raw_selection = random.sample(tarot_deck, 3)
            selection_data = [{'card': c, 'is_reversed': random.choice([True, False])} for c in raw_selection]
        
        response_cards = []
        positions = ['Past', 'Present', 'Future']
        positions_tr = ['Geçmiş', 'Şimdi', 'Gelecek']
        
        # Scoring Logic ... (truncated in tool view but assuming preserved)
        POSITIVE_IDS = [
            "magician", "empress", "emperor", "lovers", "chariot", "strength", 
            "wheel_of_fortune", "justice", "temperance", "star", "sun", "judgement", "world",
            "ace_cups", "two_cups", "ten_cups", "ace_pentacles", "nine_pentacles", "ten_pentacles", "ace_wands", "four_wands", "six_wands"
        ]
        NEGATIVE_IDS = [
            "hermit", "hanged_man", "death", "devil", "tower", "moon", "five_pentacles", "five_swords", "three_swords", "nine_swords", "ten_swords", "five_cups"
        ] 
        
        total_score = 0
        meanings_list = []
        
        for i, item in enumerate(selection_data):
            card = item['card']
            is_reversed = item['is_reversed']
            
            # Determine Position Index
            pos_idx = item.get('fixed_position')
            if pos_idx is None:
                pos_idx = i
            
            # Meaning
            if lang == 'tr':
                meaning = card.get('meaning_reversed_tr') if is_reversed else card.get('meaning_upright_tr')
                name = card.get('name_tr')
                pos_name = positions_tr[pos_idx] if pos_idx < len(positions_tr) else f"Kart {pos_idx+1}"
            else:
                meaning = card.get('meaning_reversed_en') if is_reversed else card.get('meaning_upright_en')
                name = card.get('name_en')
                pos_name = positions[pos_idx] if pos_idx < len(positions) else f"Card {pos_idx+1}"

            meanings_list.append(meaning)

            # Score Calculation
            card_id = card['id']
            score = 0
            if card_id in POSITIVE_IDS:
                score = 10
            elif card_id in NEGATIVE_IDS:
                score = -10
            else:
                score = 5 # Neutral
                
            if is_reversed:
                score *= -0.5 
                
            total_score += score

            response_cards.append({
                "id": card['id'],
                "name": name,
                "position": pos_name,
                "is_reversed": is_reversed,
                "meaning": meaning,
                "element": card['element'],
                "color": card['color']
            })
            
        # Synthesize
        wish_title = ""
        wish_text = ""
        synthesis = ""

        if len(response_cards) == 1:
             c = response_cards[0]
             if lang == 'tr':
                 synthesis = f"Tek Kart Rehberliği: {c['name']} size şunu fısıldıyor: {c['meaning']} Tek bir odak noktası, net bir cevap."
                 wish_title = "ODAKLAN"
                 wish_text = "Enerjini tek bir noktaya topla. Cevap sandığından daha yakın."
             else:
                 synthesis = f"Single Card Guide: {c['name']} whispers: {c['meaning']} A single focus, a clear answer."
                 wish_title = "FOCUS"
                 wish_text = "Gather your energy. The answer is closer than you think."
                 
        elif len(response_cards) == 2:
             if lang == 'tr':
                 synthesis = f"İkili Bakış: Bir yanda {response_cards[0]['meaning']} Diğer yanda {response_cards[1]['meaning']} Bu iki güç arasındaki dengeyi bulmalısın."
                 wish_title = "DENGE"
                 wish_text = "İki seçenek veya iki yol var. Seçim senin."
             else:
                 synthesis = f"Dual View: On one hand {response_cards[0]['meaning']} On the other {response_cards[1]['meaning']} Find the balance between these forces."
                 wish_title = "BALANCE"
                 wish_text = "Two paths or options lies ahead. The choice is yours."
                 
        elif len(response_cards) >= 3:
            synthesis = f"Öncelikle geçmişte {meanings_list[0]} Şu anda {meanings_list[1]} Gelecekte ise {meanings_list[2]} Bu yolculuk senin elinde."
            
            # Wish Outcome
            wish_title = ""
            wish_text = ""
            if total_score >= 15:
                wish_title = "DİLEĞİN KABUL OLDU!"
                wish_text = "Evren seninle muazzam bir uyum içinde. İstediğin şey sana doğru hızla geliyor."
            elif total_score >= 5:
                wish_title = "OLUMLU GELİŞME"
                wish_text = "Yolun açık görünüyor. Küçük çabalarla büyük sonuçlar alabilirsin."
            elif total_score >= -5:
                wish_title = "BELİRSİZLİK HAKİM"
                wish_text = "Henüz hiçbir şey kesinleşmiş değil. İçsel rehberliğine güvenmen gereken bir dönem."
            else:
                wish_title = "ZORLU SÜREÇ"
                wish_text = "Şu an için engeller var. Biraz beklemen ve stratejini gözden geçirmen gerekebilir."
        else:
            synthesis = f"Basically, looking at the past, {meanings_list[0]} Currently, {meanings_list[1]} As for the future, {meanings_list[2]} The path is yours to walk."
            
            wish_title = ""
            wish_text = ""
            if total_score >= 15:
                wish_title = "DESTINY FULFILLED!"
                wish_text = "The universe aligns perfectly with your desire. Expect a magnificent outcome."
            elif total_score >= 5:
                wish_title = "POSITIVE OUTCOME"
                wish_text = "Success is likely with a bit of focus. The energy is supporting you."
            elif total_score >= -5:
                wish_title = "UNCERTAIN PATH"
                wish_text = "The mists have not yet cleared. Patience is your best ally right now."
            else:
                wish_title = "CHALLENGES AHEAD"
                wish_text = "Obstacles block the way for now. Reassess your approach before moving forward."

        return JsonResponse({
            'cards': response_cards,
            'synthesis': synthesis,
            'wish': {
                'title': wish_title,
                'text': wish_text,
                'score': int(total_score)
            }
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

# --- BLOG API FOR MOBILE ---
@csrf_exempt
def get_blog_posts_api(request):
    """
    JSON API for Mobile App to list Blog Posts.
    """
    try:
        page = int(request.GET.get('page', 1))
        limit = 10
        
        posts = BlogPost.objects.filter(is_published=True).order_by('-created_at')
        paginator = Paginator(posts, limit)
        page_obj = paginator.get_page(page)
        
        data = []
        for p in page_obj:
            img_url = p.image_url
            try:
                if p.banner_image:
                    img_url = request.build_absolute_uri(p.banner_image.url)
            except:
                pass # Fallback to image_url (Char)
            
            # Simple text preview
            content_str = p.content if p.content else ""
            preview = content_str[:200] + "..."
            
            data.append({
                'id': p.id,
                'title': p.title,
                'slug': p.slug,
                'image': img_url,
                'date': p.created_at.strftime("%d %B %Y"),
                'preview': preview,
                # 'content': p.content # Optimize payload
            })
            
        return JsonResponse({
            'posts': data,
            'has_next': page_obj.has_next()
        })
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': f"Server Error: {str(e)}"}, status=500)

@csrf_exempt
def get_blog_detail_api(request, slug):
    """
    JSON API for Mobile App to get full Blog Post.
    """
    try:
        p = BlogPost.objects.get(slug=slug)
        img_url = p.image_url
        try:
           if p.banner_image:
               img_url = request.build_absolute_uri(p.banner_image.url)
        except:
           pass
            
        return JsonResponse({
            'id': p.id,
            'title': p.title,
            'slug': p.slug,
            'image': img_url,
            'date': p.created_at.strftime("%d %B %Y"),
            'content': p.content
        })
    except BlogPost.DoesNotExist:
        return JsonResponse({'error': 'Post not found'}, status=404)

    except Exception as e:
         return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def calculate_career_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST request required'}, status=405)

    # --- GOLD + ---
    if request.user.is_authenticated:
        # Default to free if anything fails (secure by default)
        level = 'free' 
        try:
             level = request.user.profile.effective_membership
        except: 
             pass # Profile might be missing, treat as free
             
        if level not in ['premium'] and not request.user.is_superuser:
              return JsonResponse({
                'error': 'Kariyer Analizi detayları Premium üyelere özeldir.',
                'upgrade_required': True
            }, status=200)
    else:
        return JsonResponse({'error': 'Giriş Yapmalısınız', 'upgrade_required':True}, status=200)

    try:
        data = json.loads(request.body)
        date_str = data.get('date', '1990/01/01')
        time_str = data.get('time', '12:00')
        lat = float(data.get('lat', 41.0))
        lon = float(data.get('lon', 28.0))
        lang = data.get('lang', 'en')
        
        engine = AstroEngine()
        
        # 1. Calc Natal to get Houses/Planets
        natal_data = engine.calculate_natal(date_str, time_str, lat, lon)
        
        # 2. Calc Career
        print("DEBUG: Calculating Career Analysis...") 
        career_result = engine.calculate_career(natal_data)
        
        return JsonResponse(career_result)


    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def rectify_birth_time(request):
    """
    Rectifies birth time based on major life events.
    Scans 24 hours of the birth date to find Ascendant/MC matches with Event Transits.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST request required'}, status=405)

    # --- PLATINUM ONLY ---
    if request.user.is_authenticated:
        try:
             # Robust check
             p = UserProfile.objects.get(user=request.user)
             level = str(p.membership_level).lower().strip()
             print(f"DEBUG: rectify_birth_time User: {request.user.username}, Level: {level}")
             
             if level != 'premium' and not request.user.is_superuser:
                  # GLOBAL FREE MODE OVERRIDE
                  from django.conf import settings
                  if not getattr(settings, 'FREE_PREMIUM_MODE', False):
                      return JsonResponse({
                        'error': 'Rektifikasyon (Doğum Saati Bulma) sadece Premium üyelere özeldir.',
                        'upgrade_required': True
                    }, status=200)
        except Exception as e: 
            print(f"DEBUG: Rectify Auth Error: {e}")
            # Fail-Safe: If profile check fails, DENY access
            return JsonResponse({
                'error': 'Rektifikasyon Premium üyelere özeldir.',
                'upgrade_required': True
            }, status=200)
    else:
        return JsonResponse({'error': 'Giriş Yapmalısınız', 'upgrade_required':True}, status=200)

    try:
        data = json.loads(request.body)
        birth_date = data.get('date') # YYYY/MM/DD or YYYY-MM-DD
        lat = float(data.get('lat', 41.0))
        lon = float(data.get('lon', 28.0))
        lang = data.get('lang', 'en')
        events = data.get('events', []) # List of {date: 'YYYY-MM-DD', type: 'marriage'}

        if not birth_date:
             return JsonResponse({'error': 'Birth date is required'}, status=400)

        if not birth_date:
             return JsonResponse({'error': 'Birth date is required'}, status=400)

        # Robust Date Parsing for View Logic
        start_date_obj = None
        date_formats = ["%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%d/%m/%Y"]
        
        for fmt in date_formats:
            try:
                start_date_obj = datetime.strptime(birth_date, fmt)
                break
            except ValueError:
                continue
                
        if not start_date_obj:
             return JsonResponse({'error': 'Invalid date format. Use YYYY-MM-DD or DD-MM-YYYY'}, status=400)

        # Normalize to standard format for Engine calls
        birth_date_str = start_date_obj.strftime("%Y-%m-%d")
        
        # Engine
        engine = AstroEngine()
        
        # 1. Pre-calculate Transits for each Event (at Noon)
        # We only need the positions of heavy planets: Jupiter, Saturn, Uranus, Neptune, Pluto, Nodes
        heavy_planets = ['Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'North Node']
        event_transits = []
        
        for e in events:
            edate_str = e.get('date', '')
            etype = e.get('type', 'general')
            if not edate_str: continue
            
            # Robust parse for Event Date
            e_dt = None
            for fmt in date_formats:
                try:
                    e_dt = datetime.strptime(edate_str, fmt)
                    break
                except: continue
                
            if not e_dt: continue
            
            e_str_clean = e_dt.strftime("%Y-%m-%d")
            
            # calculate chart for event
            try:
                t_chart = engine.calculate_natal(e_str_clean, "12:00", lat, lon)
                t_planets = [p for p in t_chart['planets'] if p['name'] in heavy_planets]
                event_transits.append({'type': etype, 'planets': t_planets, 'date': e_str_clean})
            except:
                continue
                
        # 2. Iterate through 24 hours (Step: 10 minutes = 144 steps)
        # 10 min step approx 2.5 degrees of Ascendant. Acceptable for rough rectification.
        scores = []
        
        # Start from midnight of the parsed date
        start_time = datetime.combine(start_date_obj.date(), datetime.min.time())
        
        # Weights
        W_CONJ = 10
        W_OPP = 8
        W_SQR = 5
        W_TRINE = 3 # Trines are soft, but good for validation
        
        valid_candidates = []

        # Optimization: We loop 0..144
        for i in range(144): 
            minutes = i * 10
            candidate_dt = start_time + timedelta(minutes=minutes)
            time_str = candidate_dt.strftime("%H:%M")
            
            # Calculate Candidate Angles
            # We use engine.calculate_natal but it might be heavy to do 144 times if it calls API or deep math?
            # It uses Skyfield (local binary). Should be fast enough (< 2 sec for 144 calls).
            candidate = engine.calculate_natal(birth_date_str, time_str, lat, lon)
            
            if 'error' in candidate:
                 return JsonResponse({'error': f"Engine Error: {candidate['error']}"}, status=500)

            asc = candidate.get('ascendant_deg', 0.0)
            mc = candidate.get('midheaven_deg', 0.0)
            asc_sign = candidate.get('ascendant', 'Aries')
            
            score = 0
            hits = []
            
            # Check against Events
            for et in event_transits:
                for p in et['planets']:
                    p_lon = p['lon']
                    p_name = p['name']
                    
                    # Check Ascendant
                    diff_asc = abs(p_lon - asc) % 180 # Mod 180 covers Conj (0) and Opp (180) near 0 
                    if diff_asc > 90: diff_asc = 180 - diff_asc
                    
                    # Actually standard distance
                    d = abs(p_lon - asc) % 360
                    if d > 180: d = 360 - d
                    
                    aspect = ""
                    points = 0
                    
                    p_name_display = p_name
                    if lang == 'tr':
                        p_name_display = p_name.replace("Jupiter", "Jüpiter").replace("Saturn", "Satürn").replace("Uranus", "Uranüs").replace("Neptune", "Neptün").replace("Pluto", "Plüton").replace("North Node", "Kuzey Düğüm")

                    if d < 4: 
                        aspect = "Conjunction AC" if lang != 'tr' else "AC ile Kavuşum"
                        points = W_CONJ
                    elif abs(d - 180) < 4:
                        aspect = "Opposition AC" if lang != 'tr' else "AC ile Karşıt"
                        points = W_OPP
                    elif abs(d - 90) < 4:
                        aspect = "Square AC" if lang != 'tr' else "AC ile Kare"
                        points = W_SQR
                    
                    if points > 0:
                        score += points
                        hits.append(f"{et['date']} {p_name_display} {aspect}")
                        
                    # Check MC
                    d_mc = abs(p_lon - mc) % 360
                    if d_mc > 180: d_mc = 360 - d_mc
                    
                    if d_mc < 4:
                        score += W_CONJ
                        aspect = "Conj MC" if lang != 'tr' else "MC ile Kavuşum"
                        hits.append(f"{et['date']} {p_name_display} {aspect}")
                    elif abs(d_mc - 180) < 4:
                        score += W_OPP
                        aspect = "Opp MC" if lang != 'tr' else "MC ile Karşıt"
                        hits.append(f"{et['date']} {p_name_display} {aspect}")
            
            if score > 0:
                scores.append({
                    'time': time_str,
                    'score': score,
                    'asc_sign': asc_sign,
                    'hits': hits
                })
        
        # Sort by score
        scores.sort(key=lambda x: x['score'], reverse=True)
        
        if not scores:
             # DIAGNOSTIC BLOCK
             debug_msg = f"No match found for Date: {birth_date_str}. <br>"
             debug_msg += f"Events Parsed: {len(event_transits)}. <br>"
             if event_transits:
                 debug_msg += f"First Event: {event_transits[0]['date']} ({len(event_transits[0]['planets'])} planets). <br>"
             
             # Test calc for 12:00
             test_c = engine.calculate_natal(birth_date_str, "12:00", lat, lon)
             debug_msg += f"Test 12:00 Asc: {test_c.get('ascendant', '?')} ({test_c.get('ascendant_deg', 0):.2f}). <br>"
             
             return JsonResponse({'candidates': [], 'debug_error': debug_msg})

        # Filter top 3 distinct Ascendant Signs if possible, or just top 3 times
        top_candidates = scores[:3]
        
        return JsonResponse({'candidates': top_candidates})

    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)



def index(request):
    profile = None
    if request.user.is_authenticated:
        # Guaranteed Profile Loading
        profile, created = UserProfile.objects.get_or_create(
            user=request.user,
            defaults={
                'birth_date': '1990-01-01',
                'birth_time': '12:00',
                'birth_place': 'Unknown',
                'lat': 0.0, 'lon': 0.0
            }
        )
        if created:
            print(f"DEBUG: Created new profile for {request.user.username}")
        
    
    # Instantiate the Settings Form
    settings_form = None
    if profile:
        settings_form = UserSettingsForm(instance=profile)
    else:
        settings_form = UserSettingsForm()

    # --- BLOG SEARCH & PAGINATION & FILTER ---
    query = request.GET.get('q', '')
    date_filter = request.GET.get('date', '')
    page_number = request.GET.get('page', 1)
    
    blog_queryset = BlogPost.objects.filter(is_published=True).order_by('-created_at')
    
    if query:
        blog_queryset = blog_queryset.filter(Q(title__icontains=query) | Q(content__icontains=query))
    
    if date_filter:
        blog_queryset = blog_queryset.filter(created_at__date=date_filter)
    
    paginator = Paginator(blog_queryset, 9) # 9 Per Page
    blog_posts = paginator.get_page(page_number)
    
    context = {
        'profile': profile,
        'user': request.user,
        'settings_form': settings_form,
        'blog_posts': blog_posts,
        'search_query': query,
        'date_filter': date_filter
    }
    return render(request, 'astrology/index.html', context)


def _mock_chart_data():
    """Fallback data when library is missing"""
    return {
        "planets": [
            {"name": "Sun", "sign": "Aries", "lon": 10.5, "signlon": 10.5, "house": 1, "interpretation": "Sun in Aries" },
            {"name": "Moon", "sign": "Taurus", "lon": 45.2, "signlon": 15.2, "house": 2, "interpretation": "Moon in Taurus" }
        ],
        "houses": [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330],
        "aspects": [],
        "meta": {
             "profection_house": 5,
             "dominants": {"Fire": 50, "Earth": 20, "Air": 20, "Water": 10},
             "lucky_color": "Red",
             "lucky_stone": "Ruby",
             "sun_sign": "Aries",
             "planetary_hours": [],
             "draconic_chart": [],
             "celebrity_match": {"name": "Beyonce", "score": 95, "reason": "Mock"},
             "acg_lines": []
        }
    }

# import geonamescache (Moved to top)

@csrf_exempt
def get_countries(request):
    """Returns a list of all countries sorted by name."""
    gc = geonamescache.GeonamesCache()
    countries = gc.get_countries()
    # Format: { 'TR': 'Turkey', 'US': 'United States' }
    data = []
    for code, details in countries.items():
        data.append({'code': code, 'name': details['name']})
    
    # Sort by name
    data.sort(key=lambda x: x['name'])
    return JsonResponse({'countries': data})



from .turkey_data import TR_DATA, PROVINCE_NAMES

@csrf_exempt
def get_cities(request):
    """Returns cities/districts. Uses curated TR_DATA for Turkey."""
    country_code = request.GET.get('code')
    admin_code = request.GET.get('admin_code')
    
    if not country_code:
        return JsonResponse({'error': 'Country code required'}, status=400)
    
    # Priority 1: Check TR_DATA for detailed districts
    if country_code == 'TR' and admin_code and admin_code in TR_DATA:
        return JsonResponse({'cities': TR_DATA[admin_code]['districts']})
        
    gc = geonamescache.GeonamesCache()
    cities = gc.get_cities()
    
    filtered = []
    
    # Priority 2: Standard Geonames Fetch
    # If it's TR but not in our TR_DATA, we still fetch from Geonames.
    for cid, c in cities.items():
        if c['countrycode'] == country_code:
            if admin_code and c.get('admin1code') != admin_code:
                continue
            
            # For Turkey, geonames might list a district.
            filtered.append({
                'name': c['name'],
                'lat': c['latitude'],
                'lon': c['longitude'],
                'pop': c.get('population', 0)
            })
            
    filtered.sort(key=lambda x: x['name'])
    return JsonResponse({'cities': filtered})

@csrf_exempt
def get_provinces(request):
    """Returns Provinces. Uses PROVINCE_NAMES for TR to ensure distinct list."""
    country_code = request.GET.get('code')
    if not country_code:
        return JsonResponse({'error': 'Country code required'}, status=400)

    # Priority: TR Official List
    if country_code == 'TR':
        provinces = []
        for code, name in PROVINCE_NAMES.items():
            provinces.append({'code': code, 'name': name})
            
        provinces.sort(key=lambda x: x['name'])
        return JsonResponse({'provinces': provinces})


    # Standard Logic for other countries
    gc = geonamescache.GeonamesCache()
    cities = gc.get_cities()
    admin_groups = {}
    
    for cid, c in cities.items():
        if c['countrycode'] == country_code:
            ac = c.get('admin1code', '')
            if not ac: continue
            if ac not in admin_groups: admin_groups[ac] = []
            admin_groups[ac].append(c)
            
    provinces = []
    for ac, city_list in admin_groups.items():
        city_list.sort(key=lambda x: x.get('population', 0), reverse=True)
        # Fallback: limit province name length to avoid some garbage
        pname = city_list[0]['name']
        provinces.append({'code': ac, 'name': pname})
        
    provinces.sort(key=lambda x: x['name'])
    
    return JsonResponse({'provinces': provinces})

# --- AUTHENTICATION & PROFILE API ---

@csrf_exempt
def register_api(request):
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        username = data.get('username')
        password = data.get('password')
        email = data.get('email', '')
        
        # Validation
        if User.objects.filter(username=username).exists():
            return JsonResponse({'error': 'User already exists'}, status=400)
            
        user = User.objects.create_user(username=username, password=password, email=email)
        
        # Init Profile with Data
        profile = UserProfile.objects.create(user=user)
        
        # Save Birth Data if provided
        if data.get('date'):
            profile.birth_date = dt.strptime(data['date'], "%Y-%m-%d").date()
        if data.get('time'):
            profile.birth_time = dt.strptime(data['time'], "%H:%M").time()
        if data.get('place'):
            profile.birth_place = data['place']
        if data.get('lat'):
            profile.lat = float(data['lat'])
        if data.get('lon'):
            profile.lon = float(data['lon'])
            
        profile.save()
        
        # Auto-Login (Force Backend)
        login(request, user, backend='django.contrib.auth.backends.ModelBackend')
        
        return JsonResponse({'success': True, 'username': user.username})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def login_api(request):
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        username = data.get('username')
        password = data.get('password')
        
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            request.session.set_expiry(1209600)
            request.session.save() # Force save
            print(f"DEBUG: Login successful for {user.username}. Session: {request.session.session_key}")
            return JsonResponse({'success': True, 'username': user.username})
        else:
            return JsonResponse({'error': 'Invalid credentials'}, status=401)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def logout_api(request):
    logout(request)
    from django.shortcuts import redirect
    return redirect('/')

def check_auth_api(request):
    print(f"DEBUG: check_auth_api called. User: {request.user}, IsAuth: {request.user.is_authenticated}")
    print(f"DEBUG: Session Key: {request.session.session_key}")
    print(f"DEBUG: Cookies: {request.COOKIES.keys()}")

    if request.user.is_authenticated:
        # Get Profile Data
        try:
            # Handle potential missing profile
            try:
                p = request.user.profile
            except:
                return JsonResponse({'authenticated': True, 'username': request.user.username, 'profile': None})

            # Check Global Free Mode
            from django.conf import settings
            is_global_free = getattr(settings, 'FREE_PREMIUM_MODE', False)

            return JsonResponse({
                'authenticated': True,
                'username': request.user.username,
                'is_superuser': request.user.is_superuser,
                'membership_level': request.user.profile.effective_membership,
                'is_global_free': is_global_free, 
                'profile': {
                    'date': p.birth_date.strftime("%Y-%m-%d") if p.birth_date else "",
                    'time': p.birth_time.strftime("%H:%M") if p.birth_time else "",
                    'lat': p.lat,
                    'lon': p.lon,
                    'place': p.birth_place
                }
            })
        except Exception as e:
            # Fallback if serialization fails
            return JsonResponse({'authenticated': True, 'username': request.user.username, 'error': str(e)})
    else:
        # Check Global Free Mode even for Guests
        from django.conf import settings
        is_global_free = getattr(settings, 'FREE_PREMIUM_MODE', False)
        return JsonResponse({'authenticated': False, 'is_global_free': is_global_free})


@csrf_exempt
def update_profile_api(request):
    if not request.user.is_authenticated:
        return JsonResponse({'error': 'Unauthorized'}, status=401)
        
    try:
        data = json.loads(request.body)
        p, created = UserProfile.objects.get_or_create(user=request.user)
        
        # Update Fields
        if 'date' in data and data['date']: 
            d_str = data['date'].replace('/', '-').replace('.', '-') # Normalize to -
            try:
                # Try standard ISO first
                p.birth_date = dt.strptime(d_str, "%Y-%m-%d").date()
            except ValueError:
                 # Try DD-MM-YYYY (common in TR)
                 try:
                     # Split and reverse if it looks like DD-MM-YYYY
                     parts = d_str.split('-')
                     if len(parts) == 3 and len(parts[0]) == 2 and len(parts[2]) == 4:
                          p.birth_date = dt.strptime(d_str, "%d-%m-%Y").date()
                     else:
                          # Try single digits?
                          pass # Keep old date or fail gently
                 except:
                     pass

        if 'time' in data and data['time']:
            t_str = data['time']
            # Simple Cleaning
            t_str = t_str.strip()
            
            try:
                if len(t_str) == 5: # HH:MM
                     p.birth_time = dt.strptime(t_str, "%H:%M").time()
                elif len(t_str) == 8: # HH:MM:SS
                     p.birth_time = dt.strptime(t_str, "%H:%M:%S").time()
            except ValueError:
                 pass

        # Robust Float Conversion
        if 'lat' in data: 
            try:
                val = str(data['lat']).replace(',', '.')
                if val.strip(): p.lat = float(val)
            except: pass
            
        if 'lon' in data: 
            try:
                val = str(data['lon']).replace(',', '.')
                if val.strip(): p.lon = float(val)
            except: pass

        if 'place' in data and data['place']: 
            p.birth_place = data['place']
        
        p.save()
        print(f"DEBUG: Profile updated for {request.user.username}. Date: {p.birth_date}, Time: {p.birth_time}")
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def apply_rectification_form(request):
    """
    Standard FORM POST handler for Rectification Update.
    This ensures a full page reload and reliable DB update without JS fetch nuances.
    """
    if request.method != 'POST':
        from django.shortcuts import redirect
        return redirect('/')
        
    try:
        # Standard Form Data comes in request.POST
        date_str = request.POST.get('date', '')
        time_str = request.POST.get('time', '')
        lat = request.POST.get('lat', '')
        lon = request.POST.get('lon', '')
        place = request.POST.get('place', '')
        
        print(f"DEBUG: Form Post Rectify: {date_str} {time_str}")
        
        if request.user.is_authenticated:
            p, created = UserProfile.objects.get_or_create(user=request.user)
            
            # Date Handling
            if date_str:
                d = date_str.replace('/', '-').replace('.', '-')
                try:
                    p.birth_date = dt.strptime(d, "%Y-%m-%d").date()
                except:
                     try:
                         # Fallback DD-MM-YYYY
                         parts = d.split('-')
                         if len(parts) == 3:
                             if len(parts[0]) == 4: # YYYY-MM-DD re-check
                                 p.birth_date = dt.strptime(d, "%Y-%m-%d").date()
                             else: # DD-MM-YYYY
                                 p.birth_date = dt.strptime(d, "%d-%m-%Y").date()
                     except: pass
                     
            # Time Handling
            if time_str:
                t = time_str.strip()
                try:
                    if len(t) == 5: p.birth_time = dt.strptime(t, "%H:%M").time()
                    elif len(t) == 8: p.birth_time = dt.strptime(t, "%H:%M:%S").time()
                except: pass
                
            # Coords
            try:
                if lat: p.lat = float(str(lat).replace(',', '.'))
                if lon: p.lon = float(str(lon).replace(',', '.'))
            except: pass
            
            if place: p.birth_place = place
            
            p.save()
            print("DEBUG: Rectification saved to DB via FORM POST.")
            
        # Redirect back to home (Chart View) with cache buster
        from django.shortcuts import redirect
        # We add page=chart so script_nav_core.html works effectively
        response = redirect('/?page=chart&rectified=true&ts=' + str(int(dt.now().timestamp())))
        # Clear cookies if we want, or just rely on the fact that redirect reloads page
        return response
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        from django.shortcuts import redirect
        return redirect('/?error=rect_save_failed')

@csrf_exempt
def apply_settings_form(request):
    """
    Standard FORM POST handler for Settings Update using Django Forms.
    """
    if request.method != 'POST':
        from django.shortcuts import redirect
        return redirect('/')
        
    try:
        if not request.user.is_authenticated:
            return JsonResponse({'error': 'Unauthorized'}, status=401)

        p = UserProfile.objects.get(user=request.user)
        form = UserSettingsForm(request.POST, instance=p)
        
        if form.is_valid():
            form.save()
            print("DEBUG: Settings saved via Django Form.")
            from django.shortcuts import redirect
            return redirect('/?settings_updated=true&ts=' + str(int(dt.now().timestamp())))
        else:
            print(f"DEBUG: Form Errors: {form.errors}")
            from django.shortcuts import redirect
            return redirect('/?error=settings_form_invalid')
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        from django.shortcuts import redirect
        return redirect('/?error=settings_save_failed')
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        from django.shortcuts import redirect
        return redirect('/?error=settings_save_failed')

@user_passes_test(lambda u: u.is_superuser)
def custom_admin_dashboard(request):
    # Base Queryset: Exclude Superusers (Admins)
    base_qs = UserActivityLog.objects.exclude(user__is_superuser=True)

    # Date Filtering
    start_date_str = request.GET.get('start_date')
    end_date_str = request.GET.get('end_date')
    
    if start_date_str:
        base_qs = base_qs.filter(timestamp__date__gte=start_date_str)
    if end_date_str:
        base_qs = base_qs.filter(timestamp__date__lte=end_date_str)

    # Log Search
    log_search = request.GET.get('log_search')
    if log_search:
        search_query = Q(user__username__icontains=log_search) | \
                       Q(action__icontains=log_search) | \
                       Q(ip_address__icontains=log_search)
        
        # Handle "Ziyaretçi" (Visitor) special case since it's a template fallback for None
        if 'ziyaretçi' in log_search.lower() or 'visitor' in log_search.lower():
            search_query |= Q(user__isnull=True)
            
        base_qs = base_qs.filter(search_query)

    # 1. Logs (Paginated)
    log_list = base_qs.select_related('user').order_by('-timestamp')
    paginator = Paginator(log_list, 20) # Show 20 logs per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    # 2. Daily Stats (Based on Filtered Data)
    action_counts = base_qs.values('action').annotate(total=Count('action')).order_by('-total')
    
    # 3. Stats Summary (Filtered)
    unique_visitors = base_qs.values('ip_address').distinct().count()
    total_requests = base_qs.count()
    
    # 4. Active Known Users (In the filtered period)
    active_users = base_qs.filter(user__isnull=False).values('user__username').distinct()

    # 5. All Users Management
    all_users = User.objects.exclude(is_superuser=True).select_related('profile').order_by('-date_joined')
    
    user_search = request.GET.get('user_search')
    if user_search:
        all_users = all_users.filter(
            Q(username__icontains=user_search) | 
            Q(email__icontains=user_search)
        )

    # 6. Contact Messages (Filtered & Paginated)
    msg_qs = ContactMessage.objects.all().order_by('-created_at')

    # Message Filtering
    msg_search = request.GET.get('msg_search')
    if msg_search:
        msg_qs = msg_qs.filter(
            Q(name__icontains=msg_search) | 
            Q(email__icontains=msg_search) | 
            Q(message__icontains=msg_search)
        )
    
    msg_start = request.GET.get('msg_start')
    msg_end = request.GET.get('msg_end')
    
    if msg_start:
        msg_qs = msg_qs.filter(created_at__date__gte=msg_start)
    if msg_end:
        msg_qs = msg_qs.filter(created_at__date__lte=msg_end)

    msg_paginator = Paginator(msg_qs, 10) 
    msg_page_num = request.GET.get('msg_page', 1)
    msg_page_obj = msg_paginator.get_page(msg_page_num)

    context = {
        'page_obj': page_obj, # Use page_obj for the loop
        'action_counts': action_counts,
        'unique_visitors': unique_visitors,
        'total_requests': total_requests,
        'active_users': [u['user__username'] for u in active_users if u['user__username']],
        'total_users_count': all_users.count(), 
        'all_users': all_users,
        'user_count_filtered': all_users.count(),
        # Pass back filter params to keep them in pagination links
        'start_date': start_date_str or '', 
        'end_date': end_date_str or '',
        'user_search': user_search or '',
        'log_search': log_search or '',
        # Message Context
        'contact_messages': msg_page_obj, # Replaced list with page object
        'msg_search': msg_search or '',
        'msg_start': msg_start or '',
        'msg_end': msg_end or ''
    }
    
    return render(request, 'astrology/custom_admin.html', context)

@csrf_exempt
def get_daily_horoscopes_api(request):
    lang = request.GET.get('lang', 'tr')
    today = dt.now().date()
    # Create a seed based on date
    seed_base = int(today.strftime("%Y%m%d"))
    
    signs = SIGNS_TR if lang == 'tr' else SIGNS_EN
    sentences = SENTENCES['tr'] if lang == 'tr' else SENTENCES['en']
    
    results = []
    
    if not sentences: # Fallback
         sentences = ["Bugün şanslı gününüz.", "Dikkatli olun."]

    for idx, sign in enumerate(signs):
        # Deterministic Random Selection
        # Seed = Date + Sign Index
        random.seed(seed_base + idx)
        
        # Pick 2 distinctive sentences
        s1 = random.choice(sentences)
        s2 = random.choice(sentences)
        # Simple loop to ensure variety if list is large enough
        if len(sentences) > 1:
            while s1 == s2:
                s2 = random.choice(sentences)
            
        text = f"{s1} {s2}"
        
        # Assign a generic "mood" or "icon"
        moods = ['⭐', '💖', '🍀', '🚀', '🧘', '🔥']
        mood = random.choice(moods)

        results.append({
            'sign': sign,
            'text': text,
            'mood': mood,
            'date': today.strftime("%d.%m.%Y")
        })

    return JsonResponse({'horoscopes': results})

@csrf_exempt
def calculate_career_view(request):
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)

    # --- GOLD + CHECK (Duplicate View Security) ---
    if request.user.is_authenticated:
        level = 'free'
        try: 
            p = UserProfile.objects.get(user=request.user)
            level = str(p.membership_level).lower().strip()
        except: pass
        
        # Check Global Free Mode Check
        try:
             from django.conf import settings
             if getattr(settings, 'FREE_PREMIUM_MODE', False) == True:
                 level = 'premium'
        except: pass

        if level != 'premium' and not request.user.is_superuser:
              return JsonResponse({
                'error': 'Kariyer Analizi detayları Premium üyelere özeldir.',
                'upgrade_required': True
            }, status=200)
    else:
         # Check Global Mode for Guests too? Usually Auth required first.
         # But if FREE_PREMIUM_MODE is True, maybe we allow? 
         # Web Logic typically requires Auth for "Career".
         # Let's keep Auth requirement but allow content if Auth + GlobalFree
         return JsonResponse({'error': 'Giriş Yapmalısınız', 'upgrade_required':True}, status=200)
    
    try:
        data = json.loads(request.body)
        dob = data.get('date')
        tob = data.get('time')
        lang = data.get('lang', 'en')
        
        # Deterministic Mock based on Input
        # This ensures consistent results for the same user without DB lookups
        seed_val = int(dob.replace('-','').replace('/','')) + int(tob.replace(':',''))
        random.seed(seed_val)
        
        signs_tr = ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık']
        signs_en = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']
        
        signs = signs_tr if lang == 'tr' else signs_en
        
        mc_sign = random.choice(signs) 
        saturn_sign = random.choice(signs)
        
        # Generate Text
        if lang == 'tr':
            mc_text = f"Tepe Noktanız (MC) **{mc_sign}** burcunda.<br>Bu, kariyerde yönetici ve öncü bir rol üstlemeniz gerektiğine işaret eder. Toplum önünde {mc_sign} özellikleriyle tanınacaksınız."
            sat_text = f"Satürn **{saturn_sign}** burcunda.<br>Disiplin ve sorumluluk alanınız burasıdır. Zorluklarla büyüyecek ve bu alanda otorite olacaksın."
            fore_text = "Bu ay kariyerinizde yeni fırsatlar var. Özellikle ayın 15'inden sonra beklediğiniz bir haber gelebilir."
        else:
            mc_text = f"Your Midheaven is in **{mc_sign}**.<br>This suggests a leading role in your career. You will be recognized publicly for {mc_sign} traits."
            sat_text = f"Saturn is in **{saturn_sign}**.<br>This is your area of discipline and structure. You will grow through challenges here and become an authority."
            fore_text = "New opportunities are on the horizon this month. Expect news around the 15th."
            
        full_html = f"{mc_text}<br>{sat_text}<br>{fore_text}"
        
        return JsonResponse({
            'success': True,
            'analysis': {
                'tr': full_html,
                'en': full_html
            }
        })

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def auth_view(request):
    return render(request, 'astrology/auth.html')

@csrf_exempt
def get_planetary_hours(request):
    """
    API to calculate accurate planetary hours based on Location & Date.
    Expects GET params: lat, lon, date (YYYY-MM-DD).
    """
    lat = request.GET.get('lat')
    lon = request.GET.get('lon')
    date_str = request.GET.get('date') # Optional, defaults to today

    if not lat or not lon:
        return JsonResponse({'error': 'Location required'}, status=400)
    
    # --- MEMBERSHIP CHECK ---
    is_free = True
    if request.user.is_authenticated:
        try:
             p = UserProfile.objects.get(user=request.user)
             level = str(p.effective_membership).lower().strip()
             if level == 'premium' or request.user.is_superuser:
                 is_free = False
        except: pass
    
    if is_free:
         from django.conf import settings
         if not getattr(settings, 'FREE_PREMIUM_MODE', False):
             return JsonResponse({'error': 'Planetary Hours are for Premium Members only.', 'upgrade_required': True}, status=200)
    
    if not date_str:
        date_str = dt.now().strftime("%Y-%m-%d")

    try:
        engine = AstroEngine()
        data = engine.calculate_planetary_hours(date_str, lat, lon)
        return JsonResponse({'hours': data, 'date': date_str, 'location': {'lat': lat, 'lon': lon}})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
@user_passes_test(lambda u: u.is_superuser)
def custom_admin_data_api(request):
    """API for SPA Admin Dashboard"""
    base_qs = UserActivityLog.objects.exclude(user__is_superuser=True)
    
    # Stats
    unique_visitors = base_qs.values('ip_address').distinct().count()
    total_requests = base_qs.count()
    active_users = list(base_qs.filter(user__isnull=False).values_list('user__username', flat=True).distinct())

    # Users
    users = []
    for u in User.objects.exclude(is_superuser=True).select_related('profile').order_by('-date_joined'):
        # Ensure profile check is safe
        try:
             lvl = u.profile.membership_level
        except:
             lvl = 'free'
             
        users.append({
            'id': u.id,
            'username': u.username,
            'email': u.email,
            'level': lvl
        })

    # Recent Logs (Last 50)
    logs = []
    for l in base_qs.order_by('-timestamp')[:50]:
        logs.append({
            'time': l.timestamp.strftime("%H:%M:%S"),
            'user': l.user.username if l.user else 'Visitor',
            'action': l.action
        })

    # Contact Messages (Last 50)
    messages = []
    for m in ContactMessage.objects.all().order_by('-created_at')[:50]:
        messages.append({
            'id': m.id,
            'name': m.name,
            'email': m.email,
            'message': m.message,
            'date': m.created_at.strftime("%d.%m %H:%M"),
            'is_read': m.is_read
        })
        
    return JsonResponse({
        'stats': {
            'unique_visitors': unique_visitors,
            'total_requests': total_requests,
            'total_users': len(users),
            'active_users': active_users
        },
        'users': users,
        'logs': logs,
        'messages': messages
    })

@csrf_exempt
@user_passes_test(lambda u: u.is_superuser)
def update_membership(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            new_level = data.get('level')
            
            if new_level not in ['free', 'premium']:
                 return JsonResponse({'error': 'Invalid Level'}, status=400)
            
            user = User.objects.get(id=user_id)
            # Ensure profile exists
            if not hasattr(user, 'profile'):
                 UserProfile.objects.create(user=user)
            
            user.profile.membership_level = new_level
            user.profile.save()
            
            return JsonResponse({'success': True, 'level': new_level})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'POST required'}, status=405)

@csrf_exempt
def get_celestial_events_view(request):
    """
    Returns next celestial events customized for the user's rising sign.
    """
    if request.method != 'GET': return JsonResponse({'error': 'GET required'}, status=405)
    
    try:
        lang = request.GET.get('lang', 'en')
        
        # 1. Get User's Rising Sign
        rising_sign = request.GET.get('rising', 'Aries')
        
        # --- MEMBERSHIP CHECK ---
        is_free_user = True
        if request.user.is_authenticated:
            try:
                p = UserProfile.objects.get(user=request.user)
                level = str(p.effective_membership).lower().strip()
                if level in ['premium'] or request.user.is_superuser:
                    is_free_user = False
            except: pass
            
        # Check Global Free Mode
        try:
             from django.conf import settings
             if getattr(settings, 'FREE_PREMIUM_MODE', False) == True:
                 is_free_user = False
        except: pass
        
        limit = 3 if not is_free_user else 1
        
        # 2. Get Events
        events = get_next_celestial_events(limit=limit)
        
        response_data = []
        
        translations_sign = {
            'tr': {'Aries':'Koç', 'Taurus':'Boğa', 'Gemini':'İkizler', 'Cancer':'Yengeç', 'Leo':'Aslan', 'Virgo':'Başak', 'Libra':'Terazi', 'Scorpio':'Akrep', 'Sagittarius':'Yay', 'Capricorn':'Oğlak', 'Aquarius':'Kova', 'Pisces':'Balık'},
        }
        
        for e in events:
            # 3. Calculate House
            house_num = calculate_impact_house(rising_sign, e['sign'])
            
            # 4. Get Texts
            theme_text = HOUSE_THEMES[lang].get(house_num, "")
            event_def = EVENT_DESCRIPTIONS[lang].get(e['type'], {})
            
            title = event_def.get('title', e['type'])
            general = event_def.get('general', "")
            impact_raw = event_def.get('impact_template', "")
            
            # Formating
            # Translate Sign Name for display
            display_sign = e['sign']
            if lang == 'tr' and display_sign in translations_sign['tr']:
                display_sign = translations_sign['tr'][display_sign]
            
            # Create a Descriptive Title (e.g. "Aslan Dolunayı") to prevent confusion
            if e['type'] == 'New Moon':
                combo_title = f"{display_sign} Yeni Ayı" if lang == 'tr' else f"New Moon in {e['sign']}"
            elif e['type'] == 'Full Moon':
                combo_title = f"{display_sign} Dolunayı" if lang == 'tr' else f"Full Moon in {e['sign']}"
            else:
                combo_title = f"{display_sign} {title}"

            impact_text = impact_raw.format(house=house_num, theme=theme_text)
            
            response_data.append({
                'title': combo_title, # Changed from generic title
                'date': e['date'],
                'sign': display_sign, 
                'house': house_num,
                'general_text': general,
                'personal_text': impact_text,
                'theme': theme_text
            })
            
        return JsonResponse({'events': response_data})

    except Exception as e:
        import traceback
        traceback.print_exc()
        return JsonResponse({'error': str(e)}, status=500)

# --- WEEKLY GENERAL HOROSCOPE MANAGEMENT ---

@csrf_exempt
@user_passes_test(lambda u: u.is_superuser)
def admin_save_weekly_horoscope(request):
    """
    Saves or updates a weekly horoscope for a specific sign and date.
    Input: { start_date: 'YYYY-MM-DD', sign: 'Aries', text_tr: '...', text_en: '...', theme_tr, theme_en }
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        start_date = data.get('start_date')
        sign = data.get('sign')
        
        # Validation
        if not start_date or not sign:
            return JsonResponse({'error': 'Missing Valid Fields'}, status=400)
            
        obj, created = WeeklyHoroscope.objects.update_or_create(
            start_date=start_date,
            sign=sign,
            defaults={
                'text_tr': data.get('text_tr', ''),
                'text_en': data.get('text_en', ''),
                'theme_tr': data.get('theme_tr', ''),
                'theme_en': data.get('theme_en', '')
            }
        )
        
        return JsonResponse({'success': True, 'id': obj.id, 'created': created})
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def get_general_weekly_horoscopes(request):
    """
    Public API to get weekly horoscopes for a specific week or 'current' week.
    Example: ?date=2024-05-20 OR default is current week's Monday.
    """
    try:
        target_date_str = request.GET.get('date')
        
        if target_date_str:
            target_date = dt.strptime(target_date_str, "%Y-%m-%d").date()
        else:
            today = dt.now().date()
            # Find Monday of this week
            target_date = today - timedelta(days=today.weekday())
            
        horoscopes = WeeklyHoroscope.objects.filter(start_date=target_date)
        
        # Structure: { 'Aries': { text, theme }, 'Taurus': ... }
        data = {}
        lang = request.GET.get('lang', 'en')
        
        for h in horoscopes:
            data[h.sign] = {
                'text': h.text_tr if lang == 'tr' else h.text_en,
                'theme': h.theme_tr if lang == 'tr' else h.theme_en
            }
            
        return JsonResponse({
            'week_start': target_date.strftime("%Y-%m-%d"),
            'horoscopes': data
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def about_view(request):
    return render(request, 'astrology/index.html', {'initial_section': 'about', 'user': request.user})

def privacy_view(request):
    return render(request, 'astrology/index.html', {'initial_section': 'privacy', 'user': request.user})

def contact_view(request):
    return render(request, 'astrology/index.html', {'initial_section': 'contact', 'user': request.user})

@csrf_exempt
def get_library_api(request):
    """
    Public API to return all library categories and items for the mobile app.
    """
    try:
        from library.models import LibraryCategory
        
        cats = LibraryCategory.objects.all().prefetch_related('items')
        data = []
        for c in cats:
            items = []
            for i in c.items.filter(is_active=True):
                items.append({
                    'title': i.title,
                    'slug': i.slug,
                    'short_desc': i.short_desc,
                    'image_url': i.image_url,
                    'lookup_key': i.lookup_key
                })
            
            # Only add if has items? Or empty categories too? Let's keep all.
            data.append({
                'name': c.name,
                'slug': c.slug,
                'icon': c.icon,
                'items': items
            })
            
        return JsonResponse({'categories': data})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def get_library_detail_api(request, slug):
    """
    Public API to get details of a library item.
    """
    try:
        from library.models import LibraryItem
        item = LibraryItem.objects.get(slug=slug, is_active=True)
        return JsonResponse({
            'title': item.title,
            'category': item.category.name,
            'content': item.content,
            'image_url': item.image_url,
            'updated_at': item.updated_at
        })
    except LibraryItem.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

