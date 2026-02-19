
import json
from .models import UserActivityLog
from django.contrib.sessions.models import Session
from django.contrib.auth.models import User
from django.utils import timezone

class HeaderAuthMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # 1. Check if user is already authenticated (via Cookies)
        if not hasattr(request, 'user') or not request.user.is_authenticated:
            # 2. Try Authorization Header (Bearer Token)
            auth_header = request.headers.get('Authorization')
            if auth_header and auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                try:
                    # Session store contains session data if key exists and NOT expired
                    s = Session.objects.get(session_key=token, expire_date__gt=timezone.now())
                    uid = s.get_decoded().get('_auth_user_id')
                    if uid:
                        # Success: Manual Auth
                        request.user = User.objects.get(pk=uid)
                except Exception:
                    pass

        return self.get_response(request)

class ActivityMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # 1. Bearer Token Auth (Fallback for Mobile)
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            if token and not request.user.is_authenticated:
                from django.contrib.sessions.models import Session
                from django.contrib.auth.models import User
                try:
                    session = Session.objects.get(session_key=token)
                    uid = session.get_decoded().get('_auth_user_id')
                    user = User.objects.get(pk=uid)
                    request.user = user
                except Exception as e:
                    print(f"DEBUG: Bearer Auth Error: {e}")

        # Process request
        response = self.get_response(request)
        
        # Log Logic
        # Filter out static, admin, and favicon
        if request.path.startswith('/static') or request.path.startswith('/admin') or 'favicon' in request.path:
            return response

        # Filter out anonymous users if you ONLY want to track registered users
        # But user asked: "siteye girenlerin" (visitors), but also "sessionlari takip edicem" implies login.
        # "Kimler siteye girmis" -> usually implies identity.
        # Let's track everyone but mark user if available.
        # However, to avoid SPAM in logs, maybe only track API calls or Main Page loads.
        
        user = request.user if request.user.is_authenticated else None
        
        # Determine Action Name (Area Tracking)
        path = request.path
        action = "Sayfa Görüntüleme"
        
        # Action Mapping
        if path == '/':
            action = "Ana Sayfa"
        elif '/api/calculate-chart' in path:
            action = "Doğum Haritası"
        elif '/api/draw-tarot' in path: 
            action = "Tarot Odası"
        elif '/api/calculate-synastry' in path: 
            action = "Aşk Uyumu"
        elif '/api/daily-horoscopes' in path:
            action = "Günlük Burçlar"
        elif '/api/career-analysis' in path:
            action = "Kariyer Yolu"
        elif '/api/planetary-hours' in path:
            action = "Gezegen Saatleri"
        elif '/api/draconic' in path:
            action = "Drakonik Analiz"
        elif '/api/draconic' in path:
            action = "Drakonik Analiz"
        elif '/api/weekly-forecast' in path:
            action = "Haftalık Yorum"
        elif '/api/daily-planner' in path:
            action = "Günlük Plan"
        elif '/library' in path:
            action = "Kozmik Kütüphane"
        elif '/api/login' in path:
            action = "Giriş Yapıldı"
        elif '/api/register' in path:
            action = "Kayıt Olundu"
        elif '/api/logout' in path:
            action = "Çıkış Yapıldı"
        elif path.startswith('/custom-admin'):
            action = "Yönetim Paneli"
            
        # Skip Generic API Calls unless critical (to keep logs clean)
        if action == "Sayfa Görüntüleme" and path.startswith('/api/'):
             # Optional: Ignore technical APIs like check-auth or country list
             if 'check-auth' in path or 'countries' in path or 'provinces' in path:
                 return response
             action = "Sistem İsteği" # Generic API

        # Create Log (NO IP)
        should_log = False
        if user: should_log = True
        elif action != "Sistem İsteği" and action != "Sayfa Görüntüleme": should_log = True # Log important anonymous actions
        elif path == '/': should_log = True # Log home visiits

        if should_log and not path.endswith('.js') and not path.endswith('.css'):
            try:
                UserActivityLog.objects.create(
                    user=user,
                    action=action,
                    path=path,
                    method=request.method,
                    ip_address=None # User requested NO IP logging
                )
            except Exception as e:
                print(f"Logging Error: {e}")

        return response
