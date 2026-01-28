from django.urls import path
from . import views

urlpatterns = [
    path('', views.library_index, name='library_index'),
    path('item/<slug:slug>/', views.library_detail, name='library_detail'),
    path('admin-editor/', views.admin_library_editor, name='admin_library_editor'),
]
