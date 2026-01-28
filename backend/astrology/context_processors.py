from django.conf import settings

def global_settings(request):
    return {
        'FREE_PREMIUM_MODE': getattr(settings, 'FREE_PREMIUM_MODE', False)
    }
