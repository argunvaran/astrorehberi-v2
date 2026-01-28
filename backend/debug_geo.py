import geonamescache
import json

gc = geonamescache.GeonamesCache()
countries = gc.get_countries()
print(f"Total Countries: {len(countries)}")
print(f"TR data: {countries.get('TR')}")

cities = gc.get_cities()
print(f"Total Cities: {len(cities)}")

# Check cities for TR
tr_cities = [c['name'] for c in cities.values() if c['countrycode'] == 'TR']
print(f"Cities in TR: {len(tr_cities)}")
print(f"Sample TR cities: {tr_cities[:5]}")
