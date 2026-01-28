from .engines.core import AstroCore
from .engines.natal import NatalEngine
from .engines.synastry import SynastryEngine
from .engines.tarot import TarotEngine
from skyfield.api import wgs84
from skyfield import almanac
import datetime
import pytz

class AstroEngine:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(AstroEngine, cls).__new__(cls)
            cls._instance._init_engines()
        return cls._instance

    def _init_engines(self):
        # Initialize Sub-Engines
        self.natal_engine = NatalEngine()
        self.synastry_engine = SynastryEngine()
        self.tarot_engine = TarotEngine()
        self.core = AstroCore() # Ensures data is loaded

    def eph(self):
        return self.core.eph
        
    def ts(self):
        return self.core.ts

    # --- PROXY METHODS (Do not break existing code) ---

    def calculate_natal(self, date_str, time_str, lat, lon):
        try:
            # Handle Slash/Dash date
            date_str = date_str.replace('/', '-')
            # Correct Timezone Handling (Critical for Ascendant)
            local_tz = pytz.timezone('Europe/Istanbul')
            
            # Robust Date Parsing
            dt_naive = None
            dt_str = f"{date_str} {time_str}" 
            formats_to_try = ["%Y-%m-%d %H:%M", "%d-%m-%Y %H:%M", "%d/%m/%Y %H:%M", "%Y/%m/%d %H:%M"]
            
            for fmt in formats_to_try:
                try:
                    dt_naive = datetime.datetime.strptime(dt_str, fmt)
                    break 
                except ValueError:
                    continue
            
            if dt_naive is None:
                # Fatal Parse Error Fallback
                print(f"Date Parse Failed for: {dt_str}")
                return {"planets": [], "houses": [], "ascendant": "Unknown", "north_node":0}

            # 2. Localize (This handles DST for Turkey history correctly)
            dt_local = local_tz.localize(dt_naive)
            
            # 3. Convert to UTC
            dt_utc = dt_local.astimezone(pytz.utc)
            
            ts = self.core.ts
            t = ts.from_datetime(dt_utc)
            
            # NatalEngine now returns FULL structure: {planets:[], houses:[], ascendant:...}
            # This MATCHES what Views.py expects.
            result = self.natal_engine.get_planet_positions(t, float(lat), float(lon))
            return result
        except Exception as e:
            print(f"Natal Calc Error: {e}")
            # Return structure to prevent View crash 'planets' key error
            return {"planets": [], "houses": [], "ascendant": "Unknown", "north_node":0, "error": str(e)}

    def calculate_aspects(self, planets_data):
        # planets_data is expected to be a LIST of planets (from result['planets'])
        return self.natal_engine.calculate_aspects(planets_data)

    def calculate_synastry(self, p1_list, p2_list, lang='en'):
        p1_dict = {p['name']: p for p in p1_list}
        p2_dict = {p['name']: p for p in p2_list}
        return self.synastry_engine.compare_charts(p1_dict, p2_dict, lang)

    def calculate_draconic(self, natal_planets, node_lon):
        return self.natal_engine.calculate_draconic(natal_planets, node_lon)

    def calculate_dominants(self, planets):
         return self.natal_engine.calculate_dominants(planets)

    # --- TAROT ---
    
    def draw_tarot_card(self, count=3):
        return self.tarot_engine.draw_cards(count)
        
    def interpret_tarot(self, cards, lang='tr'):
        return self.tarot_engine.interpret_spread(cards, lang)

    # --- PLANETARY HOURS (NEW) ---
    
    def calculate_planetary_hours(self, date_str, lat, lon):
        try:
            # 1. Setup Time and Location
            ts = self.ts()
            eph = self.eph()
            
            # Using WGS84 for location
            loc = wgs84.latlon(float(lat), float(lon))
            observer = eph['earth'] + loc
            
            # Parse Date logic
            dt_base = datetime.datetime.strptime(date_str, "%Y-%m-%d")
            
            # Create a time range: Previous Midnight to Next Midnight roughly (UTC)
            # Parse Date logic
            dt_base = datetime.datetime.strptime(date_str, "%Y-%m-%d")
            
            # Create a time range: Previous Midnight to Next Midnight roughly (UTC)
            t0 = ts.utc(dt_base.year, dt_base.month, dt_base.day, 0)
            t1 = ts.utc(dt_base.year, dt_base.month, dt_base.day, 23, 59)
            
            # 2. Calculate Sunrise/Sunset
            f = almanac.sunrise_sunset(eph, loc)
            times, events = almanac.find_discrete(t0, t1, f)
            
            # BYPASS: Convert to Python Datetimes immediately to avoid Skyfield slicing issues
            dt_list = times.utc_datetime()
            
            t_rise, t_set = None, None
            for i, e in enumerate(events):
                dt_val = dt_list[i]
                if e == 1: # Rise
                    t_rise = dt_val
                elif e == 0: # Set
                    t_set = dt_val
            
            if t_rise is None or t_set is None:
                 return []
            
            # 3. Handle Timings & Lengths
            dt_rise = t_rise
            dt_set = t_set
            
            diff_day = (dt_set - dt_rise).total_seconds()
            len_day = diff_day / 12.0
            len_night = (86400 - diff_day) / 12.0 # Approx
            
            # 4. Rulers & Day of Week
            dow = dt_base.weekday() # 0=Mon, ... 6=Sun
            day_ruler_map = ['Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Sun']
            first_ruler = day_ruler_map[dow]
            
            # Chaldean Sequence
            chaldean_seq = ['Saturn', 'Jupiter', 'Mars', 'Sun', 'Venus', 'Mercury', 'Moon']
            start_idx = chaldean_seq.index(first_ruler)
            
            hours_data = []
            
            # TR OFFSET: UTC+3
            tr_offset = datetime.timedelta(hours=3)

            # Generate 12 Day Hours
            current_time = dt_rise
            for i in range(12):
                end_time = current_time + datetime.timedelta(seconds=len_day)
                ruler = chaldean_seq[(start_idx + i) % 7]
                
                # Format to Local TR Time
                s_local = (current_time + tr_offset).strftime("%H:%M")
                e_local = (end_time + tr_offset).strftime("%H:%M")

                hours_data.append({
                    'start': s_local,
                    'end': e_local,
                    'ruler': ruler,
                    'type': 'day'
                })
                current_time = end_time

            # Generate 12 Night Hours
            current_time = dt_set
            night_start_idx = (start_idx + 12) 
            
            for i in range(12):
                end_time = current_time + datetime.timedelta(seconds=len_night)
                ruler = chaldean_seq[(night_start_idx + i) % 7]
                
                s_local = (current_time + tr_offset).strftime("%H:%M")
                e_local = (end_time + tr_offset).strftime("%H:%M")

                hours_data.append({
                    'start': s_local,
                    'end': e_local,
                    'ruler': ruler,
                    'type': 'night'
                })
                current_time = end_time

            return hours_data

        except Exception as e:
            print(f"Planetary Hours Error: {e}")
            return []

    # --- CAREER (LEGACY) ---

    def calculate_career(self, natal_data):
        # 1. Get Midheaven (MC)
        mc_deg = natal_data.get('midheaven_deg', 0)
        signs_en = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']
        signs_tr = ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık']
        
        sign_idx = int(mc_deg / 30)
        mc_sign_en = signs_en[sign_idx]
        mc_sign_tr = signs_tr[sign_idx]

        # 2. Get Saturn Sign
        saturn_sign_en = 'Aries' # Default
        if 'planets' in natal_data:
            for p in natal_data['planets']:
                if p['name'] == 'Saturn':
                    saturn_sign_en = p['sign']
                    break
        
        # Map Saturn EN sign to TR
        try:
            saturn_idx = signs_en.index(saturn_sign_en)
            saturn_sign_tr = signs_tr[saturn_idx]
        except:
            saturn_sign_tr = 'Koç'

        # --- DATA STORE (Rich Content) ---
        
        MC_INTERPRETATIONS = {
            'Aries': "Kariyerinizde bir savaşçı ruhuna sahipsiniz. Öncü olmak, inisiyatif almak ve rekabet etmek sizin doğanızda var. Rutin ve durağan işler enerjinizi söndürebilir. Girişimcilik, askerlik, spor veya bireysel performans gerektiren alanlarda parlayabilirsiniz. Hedefinize kilitlendiğinizde sizi kimse durduramaz.",
            'Taurus': "Kariyerde güven, istikrar ve somut sonuçlar ararsınız. Finans, bankacılık, gayrimenkul, sanat veya lüks tüketim alanları size uygundur. Sabırlı ve adım adım ilerleyen yapınızla, zamanla büyük bir servet veya statü inşa edebilirsiniz. Risk almaktansa garantici olmayı tercih edersiniz.",
            'Gemini': "İletişim, zeka ve çeşitlilik kariyerinizin anahtarıdır. Medya, yazarlık, öğretmenlik, satış veya teknoloji alanlarında başarılı olabilirsiniz. Aynı anda birden fazla işle ilgilenmek sizi yormaz, aksine besler. Kelimeleri kullanma yeteneğiniz en büyük silahınızdır.",
            'Cancer': "Kariyere duygusal bir bağ kurarak yaklaşırsınız. İnsanlara yardım etmek, beslemek veya korumak istersiniz. Sağlık sektörü, psikoloji, gıda, otelcilik veya insan kaynakları alanları uygundur. İş yerinizde aile ortamı yaratmak sizin için önemlidir.",
            'Leo': "Sahne ışıkları altında olmak, yönetmek ve takdir edilmek istersiniz. Eğlence sektörü, oyunculuk, yöneticilik, siyaset veya yaratıcı sanatlar tam size göre. Karizmanızla kitleleri etkileyebilir, doğal bir lider olarak otorite kurabilirsiniz. Sıradanlık size göre değildir.",
            'Virgo': "Kariyerde detaylar, analiz ve hizmet ön plandadır. Sağlık, mühendislik, muhasebe, editörlük veya veri analizi gibi dikkat gerektiren işlerde mükemmelsiniz. Arka planda sistemi çalıştıran, sorunları çözen o vazgeçilmez kişi sizsiniz. Düzen ve nizam sizin başarınızın sırrıdır.",
            'Libra': "Diplomasi, sanat, hukuk ve ilişkiler kariyer yolunuzu çizer. Adalet arayışı, estetik kaygılar veya danışmanlık rolleri size uygundur. İş ortamında huzur ve uyum ararsınız. Ortaklıklar kurarak veya insanları bir araya getirerek yükselirsiniz.",
            'Scorpio': "Kriz yönetimi, araştırma, psikoloji, cerrahi veya dedektiflik gibi derinlik gerektiren alanlar size göredir. Gizli olanı açığa çıkarmak, dönüştürmek ve güç sahibi olmak istersiniz. Kariyerinizde tutku olmazsa olmazdır. Zorluklar sizi güçlendirir.",
            'Sagittarius': "Uluslararası işler, akademi, turizm, hukuk veya yayıncılık alanlarında parlayabilirsiniz. Özgürlüğünüze düşkün olduğunuz için masa başı işler sizi sıkabilir. Vizyoner yapınızla başkalarına ilham verebilir, öğretmen veya rehber olabilirsiniz.",
            'Capricorn': "Zirveye tırmanmak sizin kaderinizdir. Yöneticilik, devlet işleri, kurumsal yapılar veya mühendislik alanlarında başarılı olursunuz. Hırslı, disiplinli ve stratejik yapınızla en tepeye ulaşana kadar durmazsınız. Saygı görmek ve yetki sahibi olmak ana motivasyonunuzdur.",
            'Aquarius': "Teknoloji, bilim, astroloji, havacılık veya toplumsal reformlar kariyer alanınız olabilir. Geleceği inşa etmek, yenilikçi fikirler sunmak istersiniz. Kurallara uymak yerine kendi kurallarınızı koyarsınız. Ekip çalışmaları ve hümanist projeler size uygundur.",
            'Pisces': "Sanat, şifa, müzik, sinema veya ruhsal rehberlik alanları size çağrıda bulunur. Hayal gücünüz sınırsızdır ve bunu kariyere dökmelisiniz. Katı kurallar yerine ilhamla çalışırsınız. Başkalarının acılarını dindirmek veya onlara hayaller sunmak görevinizdir."
        }
        
        SATURN_INTERPRETATIONS = {
            'Aries': "Otorite kurmakta başlarda zorlanabilir, kendi gücünüze güvenmeyi zamanla öğrenirsiniz. Sabırsızlık en büyük sınavınızdır.",
            'Taurus': "Maddi konularda korkularınız olabilir ancak disiplinli birikimle büyük bir finansal kale inşa edeceksiniz. Güvenlik takıntısına dikkat.",
            'Gemini': "Fikirlerinizi ifade etmekte çekingenlik yaşayabilirsiniz. Ancak kelimelerle ustalaştığınızda ciddi bir yazar veya konuşmacı olursunuz.",
            'Cancer': "Duygusal sorumluluklar kariyerinize yük olabilir. Aile ve iş dengesini kurmak yaşam dersinizdir.",
            'Leo': "Kendinizi göstermekten korkabilir, sahnede olmaktan çekinebilirsiniz. Özgüveninizi kazandığınızda gerçek bir kral/kraliçe olacaksınız.",
            'Virgo': "Mükemmeliyetçilik sizi kilitleyebilir. Hata yapmaktan korkmayın. Detaylarda boğulmak yerine bütünü görmeyi öğrenmelisiniz.",
            'Libra': "İlişkilerde sınır koymakta zorlanabilirsiniz. İş hayatında 'hayır' demeyi ve adaleti kendi lehinize de kullanmayı öğrenmelisiniz.",
            'Scorpio': "Güç savaşları ve güven sorunları yaşayabilirsiniz. Kontrolü bırakmayı ve dönüşüme izin vermeyi öğrendiğinizde yenilmez olursunuz.",
            'Sagittarius': "İnançlarınızı veya vizyonunuzu somutlaştırmakta zorlanabilirsiniz. Felsefenizi pratik hayata dökmek sizin sınavınızdır.",
            'Capricorn': "Zaten kendi burcunda güçlüdür. Ancak aşırı işkoliklik ve katılık riski vardır. Başarı kadar iç huzura da önem vermelisiniz.",
            'Aquarius': "Topluma uyum sağlamakta zorlanabilirsiniz. Sürüden ayrılmak korkutucu gelse de, sizi özel kılan 'farklı' olmanızdır.",
            'Pisces': "Gerçeklerden kaçma eğilimi veya kurban psikolojisi gelişebilir. Sınırlarınızı çizmeyi ve hayallerinizi somutlaştırmayı öğrenmelisiniz."
        }

        # --- GENERATE TEXT ---
        if natal_data.get('lang', 'en') == 'tr' or True: 
            mc_text = f"Tepe Noktanız (MC) **{mc_sign_tr}** burcunda.<br><br>{MC_INTERPRETATIONS.get(mc_sign_en, '')}"
            sat_text = f"Satürn **{saturn_sign_tr}** burcunda.<br><br>{SATURN_INTERPRETATIONS.get(saturn_sign_en, '')}"
            forecast_text = "Gezegen transitlerine göre bu dönem kariyerinizde stratejik adımlar atma zamanı. Önümüzdeki 4 hafta içinde beklenmedik fırsatlar kapınızı çalabilir, hazırlıklı olun."
            
            final_tr = f"{mc_text}<br>{sat_text}<br>{forecast_text}"
            
            final_en = f"Midheaven in {mc_sign_en}.<br>Saturn in {saturn_sign_en}.<br>Check back for detailed analysis."
            
            return {
                "en": final_en,
                "tr": final_tr
            }

