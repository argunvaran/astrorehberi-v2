import os
import django
from collections import defaultdict

# Setup Django Environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "astro_backend.settings")
django.setup()

from library.models import LibraryItem

def remove_duplicates():
    print("Scanning for duplicate Library Items...")
    
    # Get all items
    items = LibraryItem.objects.all().order_by('id')
    
    # Dictionary to track uniqueness based on slug or title
    seen = defaultdict(list)
    
    for item in items:
        # Key can be slug or title (more reliable if slug changed)
        key = item.slug
        seen[key].append(item.id)
        
    duplicates_deleted = 0
    
    for key, ids in seen.items():
        if len(ids) > 1:
            # Keep the first one (lowest ID), delete others
            keep_id = ids[0]
            delete_ids = ids[1:]
            
            print(f"Duplicate found for '{key}': Keeping {keep_id}, Deleting {delete_ids}")
            LibraryItem.objects.filter(id__in=delete_ids).delete()
            duplicates_deleted += len(delete_ids)
            
    print(f"Cleanup complete. Removed {duplicates_deleted} duplicate items.")

if __name__ == "__main__":
    remove_duplicates()
