from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('calculate-chart/', views.calculate_chart, name='calculate_chart'),
    path('calculate-synastry/', views.calculate_synastry_view, name='calculate_synastry'),
    path('daily-planner/', views.get_daily_planner, name='daily_planner'),
    path('weekly-forecast/', views.get_weekly_forecast, name='weekly_forecast'),
    path('draw-tarot/', views.draw_tarot, name='draw_tarot'),
    path('career-analysis/', views.calculate_career_view, name='career_analysis'),
    path('rectify-time/', views.rectify_birth_time, name='rectify_time'),
    path('countries/', views.get_countries, name='get_countries'),
    path('provinces/', views.get_provinces, name='get_provinces'),
    path('cities/', views.get_cities, name='get_cities'),
    path('daily-horoscopes/', views.get_daily_horoscopes_api, name='daily_horoscopes'),
    path('planetary-hours/', views.get_planetary_hours, name='planetary_hours'),
    path('celestial-events/', views.get_celestial_events_view, name='celestial_events'),
    path('appointment/', views.appointment_view, name='appointment'),
    
    # Auth
    path('auth/', views.auth_view, name='auth'),
    path('register/', views.register_api, name='register'),
    path('login/', views.login_api, name='login'),
    path('logout/', views.logout_api, name='logout'),
    path('check-auth/', views.check_auth_api, name='check_auth'),
    path('update-profile/', views.update_profile_api, name='update_profile'),
    path('apply-rectification-form/', views.apply_rectification_form, name='apply_rectification_form'),
    path('custom-admin/update-membership/', views.update_membership, name='update_membership'),
    path('custom-admin/data/', views.custom_admin_data_api, name='custom_admin_data'),
    path('apply-settings-form/', views.apply_settings_form, name='apply_settings_form'),
    path('general-weekly-horoscopes/', views.get_general_weekly_horoscopes, name='general_weekly_horoscopes'),
    path('admin/save-weekly-horoscope/', views.admin_save_weekly_horoscope, name='admin_save_weekly_horoscope'),
    path('custom-admin/', views.custom_admin_dashboard, name='custom_admin'),
    
    # Static Pages (For AdSense)
    path('about-us/', views.about_view, name='about_us'),
    path('privacy-policy/', views.privacy_view, name='privacy_policy'),
    path('contact/', views.contact_view, name='contact'),
    path('blog/<slug:slug>/', views.blog_detail, name='blog_detail'),
    path('api/blog/', views.get_blog_posts_api, name='api_blog_list'),
    path('api/blog/<slug:slug>/', views.get_blog_detail_api, name='api_blog_detail'),
    
    path('api/library/', views.get_library_api, name='api_library_list'),
    path('api/library/<slug:slug>/', views.get_library_detail_api, name='api_library_detail'),
    
    path('submit-contact/', views.submit_contact_form, name='submit_contact'),
]
# Force Reload Trigger (Auto)
