from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import user_passes_test
from .models import LibraryCategory, LibraryItem
import json

from django.core.paginator import Paginator

def library_index(request):
    """
    Returns the FULL HTML for the Library Main Page (Server Side Render).
    Includes Server-Side Filtering and Pagination.
    """
    cat_id = request.GET.get('category')
    search_query = request.GET.get('q')
    page_number = request.GET.get('page')

    # Base Query
    items = LibraryItem.objects.all().select_related('category').order_by('category', 'title')

    # Filter
    if cat_id and cat_id != 'all':
        items = items.filter(category_id=cat_id)
    
    if search_query:
        items = items.filter(title__icontains=search_query) | items.filter(short_desc__icontains=search_query)
        items = items.distinct()

    # Pagination (12 items per page)
    paginator = Paginator(items, 12)
    page_obj = paginator.get_page(page_number)

    # Categories for navigation
    categories = LibraryCategory.objects.all()

    context = {
        'items': page_obj,
        'categories': categories,
        'current_cat': cat_id if cat_id else 'all',
        'search_query': search_query if search_query else ''
    }
    return render(request, 'astrology/library_index.html', context)

def library_detail(request, slug):
    """
    Returns specific item detail partial. 
    (Used by AJAX modal in library_index.html)
    """
    try:
        item = LibraryItem.objects.get(slug=slug)
        # Detail template can remain partial since it is loaded into modal
        return render(request, 'astrology/partials/lib_detail.html', {'item': item})
    except LibraryItem.DoesNotExist:
        return JsonResponse({'error': 'Item not found'}, status=404)

@csrf_exempt
@user_passes_test(lambda u: u.is_superuser)
def admin_library_editor(request):
    """
    Admin View to Add/Edit Library Items via Frontend.
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            action = data.get('action')
            
            if action == 'save':
                item_id = data.get('id')
                cat_id = data.get('category_id')
                
                if item_id:
                    item = LibraryItem.objects.get(id=item_id)
                else:
                    item = LibraryItem()
                    
                item.title = data.get('title')
                item.content = data.get('content', '')
                item.short_desc = data.get('short_desc', '')
                item.image_url = data.get('image_url', '')
                item.lookup_key = data.get('lookup_key', '')
                
                if cat_id:
                    item.category_id = cat_id
                    
                item.save()
                return JsonResponse({'success': True, 'id': item.id})
                
            elif action == 'delete':
                item_id = data.get('id')
                LibraryItem.objects.filter(id=item_id).delete()
                return JsonResponse({'success': True})

            elif action == 'create_category':
                 name = data.get('name')
                 icon = data.get('icon', 'fas fa-book')
                 LibraryCategory.objects.create(name=name, icon=icon)
                 return JsonResponse({'success': True})
                 
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    # GET: Return Editor Interface (FULL PAGE)
    categories = LibraryCategory.objects.all()
    items = LibraryItem.objects.all()
    # Use full page template
    return render(request, 'astrology/library_editor.html', {'categories': categories, 'items': items})
