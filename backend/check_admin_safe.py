import geonamescache
import json

gc = geonamescache.GeonamesCache()
cities = gc.get_cities()

# Filter for Turkey
tr_cities = [c for c in cities.values() if c['countrycode'] == 'TR']

# Group by Admin1
admin_map = {}
for c in tr_cities:
    code = c.get('admin1code')
    if code not in admin_map:
        admin_map[code] = []
    admin_map[code].append(c['name'])

print(f"Total Admin Codes: {len(admin_map)}")
print("--- SAMPLES ---")
for code, names in list(admin_map.items())[:10]:
    # Print only ASCII compatible characters
    safe_names = [n.encode('ascii', 'ignore').decode() for n in names]
    print(f"Code {code}: {safe_names}")
