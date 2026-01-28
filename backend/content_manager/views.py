from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import user_passes_test
from django.http import JsonResponse
from .models import WeeklyForecast
from datetime import datetime, timedelta
import json
from django.core.paginator import Paginator

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
            data = json.loads(request.body)
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
            
            wf = WeeklyForecast.objects.create(
                author=request.user,
                title=data.get('title', 'Haftalık Yorum'),
                week_start=custom_date.date(), # Use custom date
                week_end=custom_date.date() + timedelta(days=7),
                content_html=data.get('content', ''),
                is_published=data.get('published', False)
            )
            
            # Manually update created_at to support backdating
            if custom_date:
                wf.created_at = custom_date
                wf.save()
                
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
                'published_date': item.created_at.strftime("%Y-%m-%d")
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
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
