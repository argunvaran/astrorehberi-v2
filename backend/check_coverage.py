import geonamescache

gc = geonamescache.GeonamesCache()
cities = gc.get_cities()

# Check sample admins: 14 (Bolu), 53 (Rize), 66 (Yozgat), 47 (Mardin)
samples = ['14', '53', '66', '47']

print("--- Geonamescache Coverage Check ---")
for code in samples:
    districts = [c['name'] for c in cities.values() 
                 if c['countrycode'] == 'TR' and c['admin1code'] == code]
    print(f"Code {code}: Found {len(districts)} districts/places: {districts}")
