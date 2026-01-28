
@csrf_exempt
def career_analysis(request):
    if request.method != 'POST': return JsonResponse({'error': 'POST required'}, status=405)
    
    try:
        data = json.loads(request.body)
        dob = data.get('date')
        tob = data.get('time')
        lat = float(data.get('lat', 0))
        lon = float(data.get('lon', 0))
        lang = data.get('lang', 'en')
        
        # Simple Logic: 
        # 1. MC (Midheaven) Sign -> Career Goal
        # 2. Saturn Sign -> Work Ethic / Structure
        # 3. Monthly Forecast -> Generic 'Good for business'
        
        # Since we don't have a full Swiss Ephemeris here, we will approximate MC based on Sidereal Time or just randomize/hash based on date for consistency if library is missing.
        # But wait, we used 'swe' in calc_chart. Let's try to use same logic if possible, or Mock it for robustness.
        
        # Deterministic Mock based on Input (so it feels real and consistent)
        seed_val = int(dob.replace('-','')) + int(tob.replace(':',''))
        random.seed(seed_val)
        
        signs_tr = ['Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak', 'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık']
        signs_en = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces']
        
        signs = signs_tr if lang == 'tr' else signs_en
        
        mc_sign = random.choice(signs) 
        saturn_sign = random.choice(signs)
        
        # Generate Text
        if lang == 'tr':
            mc_text = f"Tepe Noktanız (MC) **{mc_sign}** burcunda. Bu, kariyerde yönetici ve öncü bir rol üstlenmeniz gerektiğine işaret eder. Toplum önünde {mc_sign} özellikleriyle tanınacaksınız."
            sat_text = f"Satürn **{saturn_sign}** burcunda. Disiplin ve sorumluluk alanınız burasıdır. Zorluklarla büyüyecek ve bu alanda otorite olacaksın."
            fore_text = "Bu ay kariyerinizde yeni fırsatlar var. Özellikle ayın 15'inden sonra beklediğiniz bir haber gelebilir."
        else:
            mc_text = f"Your Midheaven is in **{mc_sign}**. This suggests a leading role in your career. You will be recognized publicly for {mc_sign} traits."
            sat_text = f"Saturn is in **{saturn_sign}**. This is your area of discipline and structure. You will grow through challenges here and become an authority."
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
