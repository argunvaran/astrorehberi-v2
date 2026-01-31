from django.urls import path
from . import views

urlpatterns = [
    path('editor/', views.editor_dashboard, name='cms_editor'),
    path('save/', views.save_forecast, name='cms_save'),
    path('latest/', views.get_latest_weekly, name='cms_latest'),
    path('list/', views.get_forecast_list, name='cms_list'),
    
    # Moderation
    path('moderation/', views.moderation_dashboard, name='moderation_dashboard'),
    path('moderation/ban/<int:user_id>/', views.ban_user, name='ban_user'),
    path('moderation/delete-posts/<int:user_id>/', views.delete_user_posts, name='delete_user_posts'),
    path('moderation/delete-post/<int:post_id>/', views.delete_single_post, name='delete_single_post'),
]
