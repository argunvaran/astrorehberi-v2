from django.contrib import admin
from .models import Appointment, Notification, WallPost

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'topic', 'status', 'created_at')
    list_filter = ('status', 'topic')
    search_fields = ('user__username', 'contact_info')
    readonly_fields = ('created_at',)

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'is_read', 'created_at')
    list_filter = ('is_read',)

@admin.register(WallPost)
class WallPostAdmin(admin.ModelAdmin):
    list_display = ('user', 'content', 'created_at', 'is_public')
