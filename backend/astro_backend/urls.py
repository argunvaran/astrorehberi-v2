from django.contrib import admin
from django.urls import path, include

from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('astrology.urls')),
    path('cms/', include('content_manager.urls')), # CMS Routes
    path('library/', include('library.urls')), # Library App
    path('', include('astrology.urls')),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
