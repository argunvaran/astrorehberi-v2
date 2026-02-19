from django.urls import path
from . import views

urlpatterns = [
    path('appointment/create/', views.create_appointment, name='create_appointment'),
    path('inbox/', views.inbox_view, name='inbox_view'),
    path('api/inbox/', views.get_inbox_api, name='get_inbox_api'),
    path('inbox/mark-read/', views.mark_read, name='mark_read'),
    path('inbox/mark-single/<int:notif_id>/', views.mark_single_read, name='mark_single_read'),
    
    # Social URLs
    path('wall/', views.wall_view, name='wall'),
    path('explore/', views.explore_view, name='explore'),
    path('messages/', views.messages_page_view, name='messages'),
    path('user/<str:username>/', views.user_profile_view, name='user_profile'),
    
    # API
    path('wall/api/posts/', views.get_posts_api, name='get_posts'),
    path('wall/api/create/', views.create_post, name='create_post'),
    path('wall/api/like/', views.toggle_like_api, name='toggle_like'),
    path('wall/api/comment/', views.add_comment_api, name='add_comment'),
    path('wall/api/comments/<int:post_id>/', views.get_comments_api, name='get_comments'),
    path('api/follow/', views.toggle_follow, name='toggle_follow'),
    path('api/following-list/', views.get_following_api, name='get_following_list'),
    
    # Search & Messages API
    path('api/search-users/', views.search_users_api, name='search_users'),
    path('api/messages/conversations/', views.get_conversations_api, name='get_conversations'),
    path('api/messages/send/', views.send_message_api, name='send_message'),
    path('api/messages/<str:username>/', views.get_messages_api, name='get_messages'),
    
    # Admin API
    path('admin/appointments/', views.get_admin_appointments, name='admin_appointments'),
    path('admin/review-appointment/', views.review_appointment, name='admin_review_appointment'),
    path('admin/send-notification/', views.admin_send_notification, name='admin_send_notification'),
]
