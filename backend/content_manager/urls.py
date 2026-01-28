from django.urls import path
from . import views

urlpatterns = [
    path('editor/', views.editor_dashboard, name='cms_editor'),
    path('save/', views.save_forecast, name='cms_save'),
    path('latest/', views.get_latest_weekly, name='cms_latest'),
    path('list/', views.get_forecast_list, name='cms_list'),
]
