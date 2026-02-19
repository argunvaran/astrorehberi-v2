from django.shortcuts import render, redirect, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from .models import Appointment, Notification, WallPost, Follow, DirectMessage
from django.contrib.auth.models import User
from django.db.models import Q
from django.core.paginator import Paginator
import json

@csrf_exempt
@login_required
def create_appointment(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            Appointment.objects.create(
                user=request.user,
                topic=data.get('topic'),
                contact_info=data.get('contact'),
                message=data.get('message')
            )
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)
    return JsonResponse({'error': 'POST required'})

@login_required
def inbox_view(request):
    return render(request, 'interactive/inbox.html')

@login_required
def get_inbox_api(request):
    notifs = Notification.objects.filter(user=request.user).order_by('-created_at')
    
    paginator = Paginator(notifs, 5)
    page = request.GET.get('page', 1)
    
    try:
        page_obj = paginator.get_page(page)
    except:
        page_obj = paginator.get_page(1)
        
    data = []
    for n in page_obj:
        data.append({
            'id': n.id,
            'title': n.title,
            'message': n.message,
            'is_read': n.is_read,
            'date': n.created_at.strftime("%Y-%m-%d %H:%M")
        })
    return JsonResponse({'notifications': data, 'has_next': page_obj.has_next()})

@csrf_exempt
@login_required
def mark_read(request):
    if request.method == 'POST':
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return JsonResponse({'success': True})

@csrf_exempt
@login_required
def mark_single_read(request, notif_id):
    if request.method == 'POST':
        Notification.objects.filter(id=notif_id, user=request.user).update(is_read=True)
        return JsonResponse({'success': True})

# --- WALL / SOCIAL ---

@login_required
def wall_view(request):
    return render(request, 'interactive/wall.html')

@login_required
def user_profile_view(request, username):
    target_user = get_object_or_404(User, username=username)
    is_following = Follow.objects.filter(follower=request.user, following=target_user).exists()
    follower_count = target_user.followers.count()
    following_count = target_user.following.count()
    
    context = {
        'target_user': target_user,
        'is_following': is_following,
        'follower_count': follower_count,
        'following_count': following_count,
        'is_self': (request.user == target_user)
    }
    return render(request, 'interactive/user_profile.html', context)

# --- COMPATIBILITY ALGORITHM ---
ELEMENTS = {
    'Fire': ['Aries', 'Leo', 'Sagittarius'],
    'Earth': ['Taurus', 'Virgo', 'Capricorn'],
    'Air': ['Gemini', 'Libra', 'Aquarius'],
    'Water': ['Cancer', 'Scorpio', 'Pisces'],
}

def get_element(sign):
    for el, signs in ELEMENTS.items():
        if sign in signs: return el
    return None

def calculate_compatibility(sign1, sign2):
    if not sign1 or not sign2: return 50
    # Extract English name from format "Burç (Sign)"
    def extract_en(s):
        if '(' in s and ')' in s:
            return s.split('(')[1].split(')')[0].strip().capitalize()
        return s.strip().capitalize()
    
    s1 = extract_en(sign1)
    s2 = extract_en(sign2)
    
    el1 = get_element(s1)
    el2 = get_element(s2)
    
    if el1 == el2: return 95
    if (el1 == 'Fire' and el2 == 'Air') or (el1 == 'Air' and el2 == 'Fire'): return 88
    if (el1 == 'Earth' and el2 == 'Water') or (el1 == 'Water' and el2 == 'Earth'): return 88
    
    return 65

def get_posts_api(request):
    filter_type = request.GET.get('filter', 'all')
    target_username = request.GET.get('username', None)
    search_query = request.GET.get('q', '').strip()
    
    posts = WallPost.objects.filter(is_public=True).select_related('user', 'user__profile')
    
    # 1. Scope Filter
    if filter_type == 'following' and request.user.is_authenticated:
        following_ids = Follow.objects.filter(follower=request.user).values_list('following_id', flat=True)
        posts = posts.filter(user_id__in=following_ids)
    elif target_username:
        posts = posts.filter(user__username=target_username)

    if search_query:
        posts = posts.filter(content__icontains=search_query)

    # Calculate scores if user is logged in
    user_sign = None
    if request.user.is_authenticated:
        try:
            user_sign = request.user.profile.sun_sign
        except: pass

    post_list = []
    for p in posts:
        score = 50
        if user_sign and p.user.id != request.user.id:
            try:
                author_sign = p.user.profile.sun_sign
                score = calculate_compatibility(user_sign, author_sign)
            except: pass
            
        post_list.append({
            'post': p,
            'score': score
        })

    # Sort by compatibility score then by date
    if user_sign and not target_username:
        post_list.sort(key=lambda x: (x['score'], x['post'].created_at), reverse=True)
    else:
        post_list.sort(key=lambda x: x['post'].created_at, reverse=True)

    # Pagination manually on the list
    paginator = Paginator(post_list, 15)
    page_num = request.GET.get('page', 1)
    try:
        page_obj = paginator.get_page(page_num)
    except:
        page_obj = []

    data = []
    for item in page_obj:
        p = item['post']
        data.append({
            'id': p.id,
            'user': p.user.username,
            'content': p.content,
            'created_at': p.created_at.strftime("%Y-%m-%d %H:%M"),
            'likes': p.like_count,
            'is_liked': request.user in p.likes.all() if request.user.is_authenticated else False,
            'compatibility': item['score'],
            'comment_count': p.comment_count
        })

    return JsonResponse({'posts': data, 'has_next': page_obj.has_next() if hasattr(page_obj, 'has_next') else False})

@csrf_exempt
@login_required
def toggle_like_api(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            post = get_object_or_404(WallPost, id=data.get('post_id'))
            if request.user in post.likes.all():
                post.likes.remove(request.user)
                liked = False
            else:
                post.likes.add(request.user)
                liked = True
                
                # Notify author
                if post.user != request.user:
                    Notification.objects.create(
                        user=post.user,
                        title="Kozmik Beğeni!",
                        message=f"{request.user.username} senin yazını beğendi ✨"
                    )
                    
            return JsonResponse({'success': True, 'liked': liked, 'count': post.like_count})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)
    return JsonResponse({'error': 'POST required'})

@csrf_exempt
@login_required
def add_comment_api(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            post = get_object_or_404(WallPost, id=data.get('post_id'))
            content = data.get('content', '').strip()
            
            if not content:
                return JsonResponse({'error': 'Mesaj boş olamaz'}, status=400)
                
            comment = PostComment.objects.create(post=post, user=request.user, content=content)
            
            # Notify author
            if post.user != request.user:
                Notification.objects.create(
                    user=post.user,
                    title="Yeni Yorum!",
                    message=f"{request.user.username} yazına yorum yaptı: {content[:30]}..."
                )
                
            return JsonResponse({
                'success': True, 
                'comment': {
                    'id': comment.id,
                    'user': comment.user.username,
                    'content': comment.content,
                    'created_at': comment.created_at.strftime("%H:%M")
                }
            })
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=400)
    return JsonResponse({'error': 'POST required'})

def get_comments_api(request, post_id):
    comments = PostComment.objects.filter(post_id=post_id).order_by('created_at')
    data = [{
        'id': c.id,
        'user': c.user.username,
        'content': c.content,
        'created_at': c.created_at.strftime("%Y-%m-%d %H:%M")
    } for c in comments]
    return JsonResponse({'comments': data})

@csrf_exempt
@login_required
def create_post(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        content = data.get('content')
        if content:
            WallPost.objects.create(user=request.user, content=content)
            # Notify followers
            followers = request.user.followers.all()
            for f in followers:
                Notification.objects.create(
                    user=f.follower,
                    title=f"Yeni Paylaşım: {request.user.username}",
                    message=f"{request.user.username} yeni bir gönderi paylaştı..."
                )
            return JsonResponse({'success': True})
    return JsonResponse({'error': 'No content'})

@csrf_exempt
def toggle_follow(request):
    if not request.user.is_authenticated:
        return JsonResponse({'status': False, 'error': 'Oturum açmanız gerekiyor.'}, status=200)

    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            target_username = data.get('username')
            target_user = User.objects.get(username=target_username)
            if target_user == request.user: 
                return JsonResponse({'error': 'Kendini takip edemezsin'})
            
            follow, created = Follow.objects.get_or_create(follower=request.user, following=target_user)
            if not created:
                follow.delete()
                return JsonResponse({'status': 'unfollowed'})
            else:
                 Notification.objects.create(user=target_user, title="Yeni Takipçi!", message=f"{request.user.username} seni takip etmeye başladı.")
                 return JsonResponse({'status': 'followed'})
        except User.DoesNotExist:
            return JsonResponse({'error': 'User not found'})
        except Exception as e:
            return JsonResponse({'error': str(e)})

    return JsonResponse({'error': 'POST required'})

@login_required
def get_following_api(request):
    """Get list of users the current user follows with search and pagination"""
    query = request.GET.get('q', '').strip()
    page = request.GET.get('page', 1)
    
    followings = Follow.objects.filter(follower=request.user).select_related('following').order_by('following__username')
    
    if query:
        followings = followings.filter(following__username__icontains=query)
    
    paginator = Paginator(followings, 5) # 5 users per page
    
    try:
        page_obj = paginator.get_page(page)
    except:
        page_obj = paginator.get_page(1)
    
    data = []
    for f in page_obj:
        user = f.following
        data.append({
            'username': user.username,
            'id': user.id
        })
        
    return JsonResponse({'users': data, 'has_next': page_obj.has_next()})

# --- MESSAGING & SEARCH ---

@login_required
def explore_view(request):
    return render(request, 'interactive/explore.html')

def search_users_api(request):
    query = request.GET.get('q', '')
    if len(query) < 2: return JsonResponse({'users': []})
    
    users = User.objects.filter(username__icontains=query).exclude(id=request.user.id)[:10]
    
    following_ids = set()
    if request.user.is_authenticated:
        following_ids = set(Follow.objects.filter(follower=request.user).values_list('following_id', flat=True))
        
    data = []
    for u in users:
        data.append({
            'username': u.username, 
            'id': u.id,
            'is_following': u.id in following_ids
        })
    return JsonResponse({'users': data})

@login_required
def messages_page_view(request):
    """Renders the main messaging UI"""
    return render(request, 'interactive/messages.html')

@login_required
def get_conversations_api(request):
    """Get list of people the user has talked to"""
    # Find all users where a message was sent OR received
    sent = request.user.sent_messages.values_list('recipient', flat=True)
    received = request.user.received_messages.values_list('sender', flat=True)
    user_ids = set(list(sent) + list(received))
    
    users = User.objects.filter(id__in=user_ids)
    data = []
    for u in users:
        # Get last message
        last_msg = DirectMessage.objects.filter(
            Q(sender=request.user, recipient=u) | Q(sender=u, recipient=request.user)
        ).order_by('-created_at').first()
        
        data.append({
            'username': u.username,
            'last_message': last_msg.body[:30] if last_msg else '',
            'timestamp': last_msg.created_at.strftime("%d %b %H:%M") if last_msg else '',
        })
    
    # Sort by recent activity
    return JsonResponse({'conversations': data})

@login_required
def get_messages_api(request, username):
    other_user = get_object_or_404(User, username=username)
    msgs = DirectMessage.objects.filter(
        Q(sender=request.user, recipient=other_user) | 
        Q(sender=other_user, recipient=request.user)
    ).order_by('created_at')
    
    # Mark read
    DirectMessage.objects.filter(sender=other_user, recipient=request.user, is_read=False).update(is_read=True)
    
    data = [{
        'sender': m.sender.username,
        'body': m.body,
        'is_me': (m.sender == request.user),
        'created_at': m.created_at.strftime("%H:%M")
    } for m in msgs]
    
    return JsonResponse({'messages': data})

@csrf_exempt
def send_message_api(request):
    if not request.user.is_authenticated:
        return JsonResponse({'success': False, 'error': 'Oturum açmanız gerekiyor.'}, status=200)

    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            target = data.get('to')
            body = data.get('body')
            
            if not body:
                return JsonResponse({'success': False, 'error': 'Boş mesaj gönderilemez'})

            recipient = User.objects.get(username=target)
            DirectMessage.objects.create(sender=request.user, recipient=recipient, body=body)
            
            # Notify
            Notification.objects.create(
                user=recipient,
                title=f"Yeni Mesaj: {request.user.username}",
                message=f"Seni mesaj gönderdi: {body[:20]}..."
            )
            return JsonResponse({'success': True})
        except User.DoesNotExist:
            return JsonResponse({'success': False, 'error': 'Kullanıcı bulunamadı'})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

    return JsonResponse({'success': False, 'error': 'POST required'})

# --- ADMIN API ---

@csrf_exempt
def get_admin_appointments(request):
    if not (request.user.is_staff or request.user.is_superuser): 
        return JsonResponse({'error': f'Unauthorized (User: {request.user}, IsStaff: {request.user.is_staff}, IsSuper: {request.user.is_superuser})'}, status=403)
    
    status_filter = request.GET.get('status')
    apps = Appointment.objects.all().order_by('-created_at')
    
    if status_filter and status_filter != 'all':
        apps = apps.filter(status=status_filter)
        
    paginator = Paginator(apps, 10) # 10 appointments per page
    page_number = request.GET.get('page', 1)
    try:
        page_obj = paginator.get_page(page_number)
    except:
        page_obj = paginator.get_page(1)
        
    data = [{'id': a.id, 'user': a.user.username, 'topic': a.topic, 'message': a.message, 'contact': a.contact_info, 'status': a.status, 'date': a.created_at.strftime("%Y-%m-%d")} for a in page_obj]
    
    return JsonResponse({
        'appointments': data,
        'has_next': page_obj.has_next(),
        'has_previous': page_obj.has_previous(),
        'current_page': page_obj.number,
        'total_pages': paginator.num_pages
    })

@csrf_exempt
def review_appointment(request):
    if not (request.user.is_staff or request.user.is_superuser): 
        return JsonResponse({'error': f'Unauthorized (User: {request.user})'}, status=403)
    if request.method == 'POST':
        data = json.loads(request.body)
        app = Appointment.objects.get(id=data.get('id'))
        app.status = 'approved' if data.get('action') == 'approve' else 'rejected'
        app.admin_response = data.get('note', '')
        app.save()
        
        Notification.objects.create(user=app.user, title=f"Randevu Durumu: {app.status}", message=f"Yönetici notu: {app.admin_response}")
        return JsonResponse({'success': True})
    return JsonResponse({'error': 'Invalid'})

@csrf_exempt
def admin_send_notification(request):
    """
    API for admin to send notifications to users.
    Can send to a specific ID or 'all' for broadcast.
    """
    if not (request.user.is_staff or request.user.is_superuser):
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            target = data.get('user_id') # 'all' or int ID
            title = data.get('title', 'Kozmik Bildirim')
            message = data.get('message')
            
            if not message:
                return JsonResponse({'error': 'Mesaj boş olamaz'}, status=400)
                
            if target == 'all':
                users = User.objects.all()
                notifs = [Notification(user=u, title=title, message=message) for u in users]
                Notification.objects.bulk_create(notifs)
                return JsonResponse({'success': True, 'count': len(notifs)})
            else:
                user = User.objects.get(id=target)
                Notification.objects.create(user=user, title=title, message=message)
                return JsonResponse({'success': True})
                
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    return JsonResponse({'error': 'POST required'}, status=405)
