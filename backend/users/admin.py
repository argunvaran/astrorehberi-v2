from django.contrib import admin
from .models import Profile

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'birth_date', 'birth_time', 'sun_sign', 'rising_sign', 'membership_level', 'effective_membership')
    search_fields = ('user__username', 'user__email', 'sun_sign', 'rising_sign')
    list_filter = ('membership_level', 'sun_sign')
    
    def effective_membership(self, obj):
        return obj.effective_membership
