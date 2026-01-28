import geonamescache

gc = geonamescache.GeonamesCache()
cities = gc.get_cities()

# Filter for Turkey, Admin Code 34 (Istanbul)
istanbul_districts = []
for c in cities.values():
    if c['countrycode'] == 'TR' and c['admin1code'] == '34':
        istanbul_districts.append(c['name'])

print(f"Istanbul (34) Districts Found: {len(istanbul_districts)}")
print(sorted(istanbul_districts))
