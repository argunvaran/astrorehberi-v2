from django.core.management.base import BaseCommand
from astrology.models import PlanetInterpretation, AspectInterpretation
import json
import os
from django.conf import settings

class Command(BaseCommand):
    help = 'Imports initial data from interpretations.json to DB'

    def handle(self, *args, **kwargs):
        path = os.path.join(settings.BASE_DIR, 'data', 'interpretations.json')
        if not os.path.exists(path):
            self.stdout.write(self.style.ERROR('JSON file not found'))
            return

        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # 1. Planets
        planets = data.get('planets', {})
        count_p = 0
        for p_name, signs in planets.items():
            for s_name, houses in signs.items():
                for house_key, content in houses.items():
                    # Content is now dict {en:..., tr:...}
                    text_en = content.get('en', '')
                    text_tr = content.get('tr', '')
                    
                    # 'generic' -> house=0
                    house_num = 0 if house_key == 'generic' else int(house_key)
                    
                    PlanetInterpretation.objects.get_or_create(
                        planet=p_name,
                        sign=s_name,
                        house=house_num,
                        defaults={'text_en': text_en, 'text_tr': text_tr}
                    )
                    count_p += 1
        
        # 2. Aspects
        aspects = data.get('aspects', {})
        count_a = 0
        for p1, p2_list in aspects.items():
            for p2, aspects_list in p2_list.items():
                for a_type, content in aspects_list.items():
                    text_en = content.get('en', '')
                    text_tr = content.get('tr', '')
                    
                    AspectInterpretation.objects.get_or_create(
                        planet_1=p1,
                        planet_2=p2,
                        aspect_type=a_type,
                        defaults={'text_en': text_en, 'text_tr': text_tr}
                    )
                    count_a += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully imported {count_p} planets and {count_a} aspects'))
