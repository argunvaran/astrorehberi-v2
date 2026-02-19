import os
import django
import sys
from datetime import datetime

# -------------------------------------------------------------------------
# TALİMATLAR:
# 1. Bu dosya 'backend' klasöründe olmalı: c:\FlutterProjects\astro_Yedek\backend\update_signs.py
# 2. Terminal'de 'backend' klasörüne gidin: cd c:\FlutterProjects\astro_Yedek\backend
# 3. Komutu çalıştırın: python update_signs.py
# -------------------------------------------------------------------------

# Django Setup
# Projenizin settings dosyası: astro_backend.settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings') 
django.setup()

from users.models import Profile

def get_sun_sign(date_obj):
    day = date_obj.day
    month = date_obj.month
    
    if (month == 3 and day >= 21) or (month == 4 and day <= 19): return "Koç (Aries)"
    if (month == 4 and day >= 20) or (month == 5 and day <= 20): return "Boğa (Taurus)"
    if (month == 5 and day >= 21) or (month == 6 and day <= 20): return "İkizler (Gemini)"
    if (month == 6 and day >= 21) or (month == 7 and day <= 22): return "Yengeç (Cancer)"
    if (month == 7 and day >= 23) or (month == 8 and day <= 22): return "Aslan (Leo)"
    if (month == 8 and day >= 23) or (month == 9 and day <= 22): return "Başak (Virgo)"
    if (month == 9 and day >= 23) or (month == 10 and day <= 22): return "Terazi (Libra)"
    if (month == 10 and day >= 23) or (month == 11 and day <= 21): return "Akrep (Scorpio)"
    if (month == 11 and day >= 22) or (month == 12 and day <= 21): return "Yay (Sagittarius)"
    if (month == 12 and day >= 22) or (month == 1 and day <= 19): return "Oğlak (Capricorn)"
    if (month == 1 and day >= 20) or (month == 2 and day <= 18): return "Kova (Aquarius)"
    return "Balık (Pisces)"

def run():
    print("Kullanıcı burçları güncelleniyor...")
    profiles = Profile.objects.all()
    count = 0
    
    for p in profiles:
        try:
            # Doğum bilgisi var mı?
            if p.birth_date:
                # Tarih objesi (DateField olduğu için zaten date objesi olmalı)
                d = p.birth_date
                
                # Sadece boşsa güncelle ya da hepsini güncelle (Tercihen hepsini)
                sun = get_sun_sign(d)
                
                if p.sun_sign != sun:
                    p.sun_sign = sun
                    p.save(update_fields=['sun_sign']) # Sadece bu alanı güncelle
                    print(f"[OK] {p.user.username}: {sun}")
                    count += 1
                else:
                    # Zaten doğruysa geç
                    pass
                
        except Exception as e:
            print(f"[ERROR] Profil ID {p.id}: {e}")

    print(f"\nToplam {count} kayıt güncellendi.")

if __name__ == '__main__':
    run()
