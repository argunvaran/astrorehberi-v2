import geonamescache
import json

gc = geonamescache.GeonamesCache()
cities = gc.get_cities()

# Filter for Turkey
tr_cities = [c for c in cities.values() if c['countrycode'] == 'TR']

# Check keys available
if tr_cities:
    print(f"Sample City Keys: {tr_cities[0].keys()}")

# Look at specific examples
examples = ['Istanbul', 'Ankara', 'Kadikoy', 'Umraniye', 'Cankaya']
for name in examples:
    matches = [c for c in tr_cities if c['name'] == name]
    if matches:
        print(f"Found {name}: {matches[0]}")
    else:
        print(f"Not Found: {name}")

# Check Admin1 Codes
# Group simple count by admin1code
admin_counts = {}
for c in tr_cities:
    a1 = c.get('admin1code', 'N/A')
    admin_counts[a1] = admin_counts.get(a1, 0) + 1

print(f"Total Admin1 Codes: {len(admin_counts)}")
print(f"Sample Admin1 Counts: {list(admin_counts.items())[:5]}")
