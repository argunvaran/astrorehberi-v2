from django.contrib import admin
from .models import PlanetInterpretation, AspectInterpretation, Celebrity, DailyTip

@admin.register(PlanetInterpretation)
class PlanetAdmin(admin.ModelAdmin):
    list_display = ('planet', 'sign', 'house', 'text_en_preview', 'text_tr_preview')
    list_filter = ('planet', 'sign', 'house')
    search_fields = ('text_en', 'text_tr')

    def text_en_preview(self, obj):
        return obj.text_en[:50]
    
    def text_tr_preview(self, obj):
        return obj.text_tr[:50]

@admin.register(AspectInterpretation)
class AspectAdmin(admin.ModelAdmin):
    list_display = ('planet_1', 'planet_2', 'aspect_type')
    list_filter = ('aspect_type', 'planet_1')

@admin.register(Celebrity)
class CelebrityAdmin(admin.ModelAdmin):
    list_display = ('name', 'sun_sign', 'moon_sign')

@admin.register(DailyTip)
class TipAdmin(admin.ModelAdmin):
    list_display = ('phase', 'category')
    list_filter = ('phase', 'category')
