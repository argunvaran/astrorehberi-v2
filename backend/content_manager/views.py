from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import user_passes_test
from django.http import JsonResponse
from .models import WeeklyForecast
from astrology.models import BlogPost # Import BlogPost
from django.utils.text import slugify # Import Slugify
from datetime import datetime, timedelta
import json
import random
from django.core.paginator import Paginator
from django.contrib.auth.models import User
from interactive.models import WallPost, Appointment
from django.db.models import Count, Q

# Check if user is admin/staff
def is_admin_user(user):
    return user.is_authenticated and (user.is_superuser or user.is_staff)

@user_passes_test(is_admin_user)
def editor_dashboard(request):
    forecasts = WeeklyForecast.objects.order_by('-created_at')
    return render(request, 'content_manager/editor.html', {'forecasts': forecasts})

@user_passes_test(is_admin_user)
def save_forecast(request):
    if request.method == 'POST':
        try:
            # Handle both JSON (legacy/text) and Multipart (file upload)
            data = {}
            if request.content_type == 'application/json':
                data = json.loads(request.body)
            else:
                data = request.POST
            
            # Create or Update logic could go here, for now simpler CREATE
            custom_date_str = data.get('date', None)
            custom_date = None
            if custom_date_str:
                try:
                    custom_date = datetime.strptime(custom_date_str, "%Y-%m-%dT%H:%M")
                except:
                    custom_date = datetime.now()
            else:
                custom_date = datetime.now()
            
            print(f"DEBUG: Parsed Date: {custom_date} from String: {custom_date_str}")

            wf = WeeklyForecast.objects.create(
                author=request.user,
                title=data.get('title', 'Haftalık Yorum'),
                week_start=custom_date.date(), # Use custom date
                week_end=custom_date.date() + timedelta(days=7),
                content_html=data.get('content', ''),
                is_published=True if str(data.get('published')).lower() == 'true' else False
            )

            # Handle Image Upload for WeeklyForecast
            if request.FILES.get('image'):
                wf.banner_image = request.FILES['image']
                wf.save() # Save trigger compression logic in model
            
            # Manually update created_at to support backdating
            if custom_date:
                wf.created_at = custom_date
                wf.save()
                
            # Synced Creation: Create BlogPost entry for "Kozmik Yazılar"
            # This ensures content appears in both places
            if str(data.get('published')).lower() == 'true':
                base_slug = slugify(data.get('title', 'untitled'))
                unique_slug = f"{base_slug}-{int(custom_date.timestamp())}"

                # Random Image Pool for Default Assignment
                random_images = [
                    'https://images.unsplash.com/photo-1506318137071-a8bcbf6755dd?auto=format&fit=crop&w=800&q=80', # Aurora
                    'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?auto=format&fit=crop&w=800&q=80', # Milky Way
                    'https://images.unsplash.com/photo-1516339901601-2e1b62dc0c45?auto=format&fit=crop&w=800&q=80', # Galaxy
                    'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=800&q=80', # Nebula
                    'https://images.unsplash.com/photo-1532968961962-8a0cb3a2d4f5?auto=format&fit=crop&w=800&q=80', # Default
                    'https://images.unsplash.com/photo-1502481851541-bf54a438bedc?auto=format&fit=crop&w=800&q=80', # Stars
                    'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?auto=format&fit=crop&w=800&q=80', # Night Sky
                    'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800&q=80', # Fantasy
                ]
                
                bp = BlogPost.objects.create(
                    title=data.get('title', 'Haftalık Yorum'),
                    slug=unique_slug,
                    content=data.get('content', ''), # Using HTML content
                    image_url=random.choice(random_images), # Assign random default
                    is_published=True
                )

                # FORCE DATE OVERRIDE
                # Problem: auto_now_add=True in BlogPost prevents created_at from being set during create()
                # We must set it AFTER creation and call save()
                
                # Handle Image Upload (Directly from request to avoid file pointer issues)
                if request.FILES.get('image'):
                    # We utilize the file from request directly. 
                    # Note: Django handles multiple reads safely for InMemoryUploadedFile
                    bp.banner_image = request.FILES['image']
                elif wf.banner_image:
                     # Fallback to WF image if available (and not in request, tho they should be same)
                     bp.banner_image = wf.banner_image

                # Save with Date Override
                if custom_date:
                    bp.created_at = custom_date
                    # We must use update() to bypass auto_now properties if save() overrides it?
                    # actually save() works fine for auto_now_add if the field is editable=True (default default)
                    # BUT let's be explicit.
                    bp.save() 
                else:
                    bp.save()
                
            return JsonResponse({'success': True, 'id': wf.id})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'POST only'}, status=405)

# Public API to get latest published forecast
def get_latest_weekly(request):
    try:
        latest = WeeklyForecast.objects.filter(is_published=True).order_by('-created_at').first()
        if latest:
            return JsonResponse({
                'title': latest.title,
                'content': latest.content_html,
                'date': f"{latest.week_start} - {latest.week_end}"
            })
        else:
            return JsonResponse({'empty': True})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

def get_forecast_list(request):
    try:
        start_date = request.GET.get('start')
        end_date = request.GET.get('end')
        page_num = request.GET.get('page', 1)
        
        q = WeeklyForecast.objects.filter(is_published=True).order_by('-created_at')
        
        if start_date:
            q = q.filter(created_at__date__gte=start_date)
        if end_date:
            q = q.filter(created_at__date__lte=end_date)
            
        # Pagination: 6 items per page (3x2 grid)
        paginator = Paginator(q, 6)
        page_obj = paginator.get_page(page_num)
        
        data = []
        for item in page_obj:
            data.append({
                'id': item.id,
                'title': item.title,
                'preview': item.content_html[:150] + '...' if len(item.content_html) > 150 else item.content_html,
                'content': item.content_html,
                'date_range': f"{item.week_start} - {item.week_end}",
                'date_range': f"{item.week_start} - {item.week_end}",
                'published_date': item.created_at.strftime("%Y-%m-%d"),
                'image_url': item.banner_image.url if item.banner_image else None
            })
            
        return JsonResponse({
            'posts': data,
            'pagination': {
                'has_next': page_obj.has_next(),
                'has_prev': page_obj.has_previous(),
                'current': page_obj.number,
                'total_pages': paginator.num_pages
            }
        })
        return JsonResponse({'error': str(e)}, status=500)

@user_passes_test(is_admin_user)
def moderation_dashboard(request):
    # User Management
    users = User.objects.annotate(
        post_count=Count('posts', filter=Q(posts__is_public=True))
    ).order_by('-date_joined')
    
    # Post Management (Latest 50)
    posts = WallPost.objects.select_related('user').order_by('-created_at')[:50]
    
    return render(request, 'content_manager/moderation.html', {
        'users': users,
        'posts': posts
    })

@user_passes_test(is_admin_user)
def ban_user(request, user_id):
    if request.method == 'POST':
        try:
            user = User.objects.get(id=user_id)
            if user.is_superuser:
                 return JsonResponse({'error': 'Cannot ban superuser'}, status=403)
            
            user.is_active = False
            user.save()
            return JsonResponse({'success': True})
        except User.DoesNotExist:
            return JsonResponse({'error': 'User not found'}, status=404)
    return JsonResponse({'error': 'POST only'}, status=405)

@user_passes_test(is_admin_user)
def delete_user_posts(request, user_id):
    if request.method == 'POST':
        try:
            # Delete all posts by this user
            count, _ = WallPost.objects.filter(user_id=user_id).delete()
            return JsonResponse({'success': True, 'deleted': count})
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    return JsonResponse({'error': 'POST only'}, status=405)

@user_passes_test(is_admin_user)
def delete_single_post(request, post_id):
    if request.method == 'POST':
        try:
            post = WallPost.objects.get(id=post_id)
            post.delete()
            return JsonResponse({'success': True})
        except WallPost.DoesNotExist:
             return JsonResponse({'error': 'Post not found'}, status=404)
    return JsonResponse({'error': 'POST only'}, status=405)
