import random
from ..tarot_data import TAROT_CARDS

class TarotEngine:
    def __init__(self):
        pass

    def draw_cards(self, count=3):
        """
        Draws {count} unique cards from the deck.
        Returns full card objects with 'is_reversed' status.
        """
        deck = list(TAROT_CARDS.keys())
        drawn_keys = random.sample(deck, count)
        
        result = []
        positions = ["Past", "Present", "Future"] # Default for 3
        tr_positions = ["Geçmiş", "Şimdi", "Gelecek"]

        for i, key in enumerate(drawn_keys):
            card_data = TAROT_CARDS[key]
            is_reversed = random.choice([True, False])
            
            # Map Position
            pos_label = positions[i] if i < len(positions) else f"Card {i+1}"
            
            result.append({
                "id": key,
                "name": card_data['name_tr'], # Defaulting to TR base name, can be localized later
                "name_en": card_data['name_en'],
                "name_tr": card_data['name_tr'],
                "is_reversed": is_reversed,
                "position": pos_label,
                "image": f"{key}.jpg", # Placeholder
                "element": card_data['element'],
                "meaning": card_data['reversed_tr'] if is_reversed else card_data['meaning_tr'], # Default TR
                "raw_data": card_data 
            })
            
        return result

    def interpret_spread(self, cards, lang='tr'):
        """
        Generates a synthesis based on the combination of cards.
        SIMPLE LOGIC:
        - Count Elements (Fire, Water, Air, Earth)
        - Check Majora/Minora balance
        - Basic predefined combos or LLM-simulated text
        """
        
        fire = sum(1 for c in cards if c['element'] == 'Fire')
        water = sum(1 for c in cards if c['element'] == 'Water')
        air = sum(1 for c in cards if c['element'] == 'Air')
        earth = sum(1 for c in cards if c['element'] == 'Earth')
        major = sum(1 for c in cards if c['raw_data']['type'] == 'Major')
        
        # Determine Dominant Energy
        dominant_element = "Mixed"
        max_count = 0
        if fire > max_count:
            dominant_element = "Fire"
            max_count = fire
        if water > max_count:
            dominant_element = "Water"
            max_count = water
        if air > max_count:
            dominant_element = "Air"
            max_count = air
        if earth > max_count:
            dominant_element = "Earth"
            max_count = earth
            
        # Synthesis Text
        synthesis = ""
        wish_outcome = {"score": 0, "title": "Neutral", "text": "Belirsiz"}

        if lang == 'tr':
            if major >= 2:
                synthesis += "Bu açılım hayatınızda **BÜYÜK** bir karmik dönüm noktasında olduğunuzu gösteriyor. Olaylar sizin kontrolünüz dışında gelişiyor olabilir. "
            else:
                synthesis += "Bu açılım daha çok günlük olaylara ve sizin kendi iradenizle değiştirebileceğiniz durumlara işaret ediyor. "
                
            if dominant_element == "Fire":
                synthesis += "Enerji çok yüksek! Harekete geçme zamanı. Beklemek size kaybettirir. Tutkularınızın peşinden gidin."
                wish_outcome = {"score": 85, "title": "EVET!", "text": "Ateşin gücüyle istediğiniz şey hızla size geliyor."}
            elif dominant_element == "Water":
                synthesis += "Duygusal yoğunluk ön planda. Mantığınızla değil, kalbinizle karar vermelisiniz. Sezgileriniz size doğru yolu gösterecek."
                wish_outcome = {"score": 60, "title": "Belki...", "text": "Duygusal dalgalanmalar sonucu değiştirebilir. Akışta kalın."}
            elif dominant_element == "Air":
                synthesis += "Zihinsel bir süreçtesiniz. Karar vermeden önce çok fazla düşünüyorsunuz. İletişim kurmak çözümün anahtarı."
                wish_outcome = {"score": 70, "title": "Mantıklıysa Evet", "text": "Eğer planınız mantıklıysa gerçekleşecek."}
            elif dominant_element == "Earth":
                synthesis += "Maddi konular ve güven arayışı belirgin. Sabırlı olmanız ve somut adımlar atmanız gerekiyor."
                wish_outcome = {"score": 40, "title": "Sabır Gerek", "text": "Hemen olmayacak, ama sağlam temellerle ilerliyor."}
            else:
                synthesis += "Dengeli bir enerji var. Hayatınızın farklı alanları birbirini etkiliyor."
                wish_outcome = {"score": 50, "title": "Denge", "text": "Ne çok iyi ne çok kötü, her şey sizin çabanıza bağlı."}
                
            # Past-Future Link
            synthesis += f" Geçmişten gelen {cards[0]['name_tr']} etkisi, gelecekteki {cards[2]['name_tr']} potansiyelini şekillendiriyor."
            
        else:
            # English Fallback
            if major >= 2:
                synthesis += "This spread indicates a **MAJOR** karmic turning point. Events might be unfolding beyond your control. "
            else:
                synthesis += "This spread relates more to daily events and situations you can influence with your will. "

            if dominant_element == "Fire":
                synthesis += "High energy! Time to act. Waiting gives no advantage. Follow your passions."
                wish_outcome = {"score": 85, "title": "YES!", "text": "With the power of fire, what you seek is coming fast."}
            elif dominant_element == "Water":
                synthesis += "Emotional intensity is high. Decide with your heart, not logic. Intuition is your guide."
                wish_outcome = {"score": 60, "title": "Maybe...", "text": "Emotional waves might shift the outcome. Stay in flow."}
            elif dominant_element == "Air":
                synthesis += "You are in a mental process. Overthinking before deciding. Communication is key."
                wish_outcome = {"score": 70, "title": "Logically Yes", "text": "If the plan is sound, it will manifest."}
            elif dominant_element == "Earth":
                synthesis += "Material matters and stability are in focus. Patience and tangible steps are needed."
                wish_outcome = {"score": 40, "title": "Requires Patience", "text": "Not immediate, but building on solid ground."}
            else:
                synthesis += "Balanced energy. Different areas of life are interacting."
                wish_outcome = {"score": 50, "title": "Balance", "text": "Depends on your effort."}
                
            synthesis += f" The influence of {cards[0]['name_en']} from the past shapes the potential of {cards[2]['name_en']} in the future."

        return {
            "synthesis": synthesis,
            "wish": wish_outcome,
            "element_counts": {"Fire": fire, "Water": water, "Air": air, "Earth": earth}
        }
