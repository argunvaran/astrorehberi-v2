from django.core.management.base import BaseCommand
from library.models import LibraryCategory, LibraryItem
from astrology.tarot_data import tarot_deck
import json
import os
from django.conf import settings
from django.utils.text import slugify

class Command(BaseCommand):
    help = 'Populates the Library with Tarot Cards and Horoscope Interpretations'

    def handle(self, *args, **kwargs):
        self.populate_tarot()
        self.populate_horoscopes()

    def populate_tarot(self):
        cat_name = "Tarot Kartları"
        category, created = LibraryCategory.objects.get_or_create(
            name=cat_name,
            defaults={'slug': slugify(cat_name), 'icon': 'fas fa-clone', 'order': 1}
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f"Category '{cat_name}' created."))
        else:
            self.stdout.write(f"Category '{cat_name}' exists.")

        count = 0
        for card in tarot_deck:
            title = card['name_tr']
            # Create a rich HTML content
            content_html = f"""
            <div class="tarot-card-detail">
                <div class="card-header" style="background-color: {card.get('color', '#333')}; color: #fff; padding: 10px; border-radius: 5px;">
                    <h3>{card['name_tr']} ({card['name_en']})</h3>
                    <p><strong>Element:</strong> {card['element']} | <strong>Tip:</strong> {card.get('type', 'N/A')}</p>
                </div>
                <div class="card-body" style="margin-top: 15px;">
                    <h4>Anlamı (Düz)</h4>
                    <p>{card['meaning_upright_tr']}</p>
                    <p><em>({card['meaning_upright_en']})</em></p>
                    <hr>
                    <h4>Anlamı (Ters)</h4>
                    <p>{card['meaning_reversed_tr']}</p>
                    <p><em>({card['meaning_reversed_en']})</em></p>
                </div>
            </div>
            """
            
            LibraryItem.objects.update_or_create(
                category=category,
                lookup_key=card['id'], # Use ID as lookup key for stability
                defaults={
                    'title': title,
                    'slug': slugify(f"tarot-{title}"),
                    'short_desc': card['meaning_upright_tr'],
                    'content': content_html,
                    'is_active': True
                }
            )
            count += 1
        
        self.stdout.write(self.style.SUCCESS(f"Processed {count} Tarot cards."))

    def populate_horoscopes(self):
        cat_name = "Burç Yorumları"
        category, created = LibraryCategory.objects.get_or_create(
            name=cat_name,
            defaults={'slug': slugify(cat_name), 'icon': 'fas fa-star', 'order': 2}
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f"Category '{cat_name}' created."))
        
        # Load from interpretations.json
        path = os.path.join(settings.BASE_DIR, 'data', 'interpretations.json')
        if not os.path.exists(path):
            self.stdout.write(self.style.ERROR('interpretations.json not found! Skipping horoscopes.'))
            return

        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # We look for planets -> Sun -> [Sign] -> generic -> tr
        sun_data = data.get('planets', {}).get('Sun', {})
        
        # Sign mapping to Turkish names (hardcoded or derived)
        # Using a map to ensure clean titles
        en_to_tr_signs = {
            "Aries": "Koç",
            "Taurus": "Boğa",
            "Gemini": "İkizler",
            "Cancer": "Yengeç",
            "Leo": "Aslan",
            "Virgo": "Başak",
            "Libra": "Terazi",
            "Scorpio": "Akrep",
            "Sagittarius": "Yay",
            "Capricorn": "Oğlak",
            "Aquarius": "Kova",
            "Pisces": "Balık"
        }

        count = 0
        for sign_en, sign_data in sun_data.items():
            generic_data = sign_data.get('generic', {})
            text_tr = generic_data.get('tr', '')
            
            if not text_tr:
                continue

            sign_tr = en_to_tr_signs.get(sign_en, sign_en)
            title = f"{sign_tr} Burcu Özellikleri"
            
            content_html = f"""
            <div class="sign-detail">
                <h3>{sign_tr} ({sign_en})</h3>
                <p>{text_tr}</p>
            </div>
            """

            LibraryItem.objects.update_or_create(
                category=category,
                lookup_key=slugify(sign_en), # e.g. 'aries', 'taurus'
                defaults={
                    'title': title,
                    'slug': slugify(title),
                    'short_desc': text_tr[:150] + "...", # First 150 chars
                    'content': content_html,
                    'is_active': True
                }
            )
            count += 1

        self.stdout.write(self.style.SUCCESS(f"Processed {count} Horoscope interpretations."))
