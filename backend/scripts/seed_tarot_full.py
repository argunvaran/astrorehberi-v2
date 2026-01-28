import os
import sys
import django

# Setup Django Environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings')
django.setup()

from library.models import LibraryCategory, LibraryItem

def seed():
    print("Seeding Full Tarot Deck...")
    cat_tarot, _ = LibraryCategory.objects.get_or_create(name='Tarot Odası', defaults={'icon': 'fas fa-hat-wizard'})

    # 1. MAJOR ARCANA (22 Cards)
    majors = [
        ("0 - Joker (The Fool)", "Başlangıç, risk, saflık", "Yeni bir yolculuğun habercisidir. Bilinmeze atılan cesur bir adımı simgeler."),
        ("I - Büyücü (The Magician)", "Yetenek, eylem, odaklanma", "İstediğini başaracak güce ve yeteneğe sahipsin. Harekete geçme zamanı."),
        ("II - Azize (High Priestess)", "Sezgi, gizem, bilinçaltı", "İç sesini dinle. Cevaplar dış dünyada değil, senin içinde."),
        ("III - İmparatoriçe (Empress)", "Bereket, doğa, annelik", "Yaratıcılık ve bolluk dönemindesin. Projelerini büyütmek için harika bir zaman."),
        ("IV - İmparator (Emperor)", "Otorite, yapı, düzen", "Hayatına disiplin ve düzen getirmelisin. Mantıklı kararlar al."),
        ("V - Aziz (Hierophant)", "Gelenek, inanç, rehberlik", "Yerleşik kurallara uyma veya bir ustadan öğrenme zamanı."),
        ("VI - Aşıklar (Lovers)", "Aşk, uyum, seçim", "Kalbini dinleyerek önemli bir seçim yapman gerekiyor. İkilemde kalabilirsin."),
        ("VII - Savaş Arabası (Chariot)", "Zafer, irade, ilerleme", "Kontrolü eline al ve hedefine odaklan. Engelleri aşacak gücün var."),
        ("VIII - Güç (Strength)", "Cesaret, sabır, şefkat", "Kaba kuvvetle değil, içsel gücünle zorlukların üstesinden geleceksin."),
        ("IX - Ermiş (Hermit)", "İçe dönüş, yalnızlık, bilgelik", "Bir süre yalnız kalıp kendi yolunu bulmalısın. Dış sesleri sustur."),
        ("X - Kader Çarkı (Wheel of Fortune)", "Şans, değişim, döngü", "Talih senden yana dönüyor. Değişime direnme, akışta kal."),
        ("XI - Adalet (Justice)", "Denge, hakikat, karar", "Ne ektiysen onu biçeceksin. Adil ol ve gerçekle yüzleş."),
        ("XII - Asılan Adam (Hanged Man)", "Fedakarlık, bekleme, bakış açısı", "Olaylara farklı bir açıdan bakman gerekiyor. Bir şey kazanmak için bir şeyden vazgeç."),
        ("XIII - Ölüm (Death)", "Bitiş, dönüşüm, yenilenme", "Eski bir dönem kapanıyor, yeni bir sayfa açılıyor. Değişim kaçınılmaz."),
        ("XIV - Denge (Temperance)", "Uyum, sabır, ölçülülük", "Aşırılıklardan kaçın. Zıtlıkları birleştirerek orta yolu bul."),
        ("XV - Şeytan (Devil)", "Bağımlılık, madde, tutku", "Seni kısıtlayan zincirlerden kurtul. Kendi korkularının esiri olma."),
        ("XVI - Yıkılan Kule (Tower)", "Ani değişim, kaos, uyanış", "Temeli sağlam olmayan her şey yıkılacak. Bu bir felaket değil, özgürleşmedir."),
        ("XVII - Yıldız (Star)", "Umut, ilham, şifa", "Fırtınadan sonra güneş doğuyor. Dileklerin gerçekleşebilir."),
        ("XVIII - Ay (Moon)", "Yanılsama, korku, belirsizlik", "Her şey göründüğü gibi olmayabilir. Rüyalarına ve sezgilerine dikkat et."),
        ("XIX - Güneş (Sun)", "Neşe, başarı, canlılık", "Mutluluk ve başarı dolu bir dönem. Kendini göster ve parla."),
        ("XX - Mahkeme (Judgement)", "Uyanış, çağrı, arınma", "Geçmiş değerlendiriliyor. İkinci bir şans veya yeni bir başlangıç kapıda."),
        ("XXI - Dünya (World)", "Tamamlanma, bütünlük, yolculuk", "Bir döngü başarıyla tamamlandı. Hedefine ulaştın, kutlama zamanı.")
    ]

    # 2. MINOR ARCANA (56 Cards)
    suits = {
        "Değnek (Wands)": {"kw": "Tutku, Ateş, Eylem", "desc": "Enerji, yaratıcılık ve girişimcilikle ilgilidir."},
        "Kupa (Cups)": {"kw": "Duygu, Su, İlişkiler", "desc": "Aşk, duygular ve rüyalarla ilgilidir."},
        "Kılıç (Swords)": {"kw": "Zihin, Hava, Mücadele", "desc": "Düşünceler, çatışmalar ve iletişimle ilgilidir."},
        "Tılsım (Pentacles)": {"kw": "Madde, Toprak, Para", "desc": "Kariyer, para ve somut dünyayla ilgilidir."}
    }
    
    ranks = [
        ("As (Ace)", "Yeni başlangıç, potansiyel"),
        ("İkili (Two)", "Denge, planlama, karar"),
        ("Üçlü (Three)", "İşbirliği, büyüme, ilk sonuçlar"),
        ("Dörtlü (Four)", "İstikrar, kutlama, mola"),
        ("Beşli (Five)", "Çatışma, kayıp, zorluk"),
        ("Altılı (Six)", "Zafer, paylaşım, nostalji"),
        ("Yedili (Seven)", "Savunma, değerlendirme, strateji"),
        ("Sekizli (Eight)", "Haraket, ustalık, hız"),
        ("Dokuzlu (Nine)", "Tatmin, endişe (Kılıç), bolluk"),
        ("Onlu (Ten)", "Tamamlanma, miras, son"),
        ("Prens (Page)", "Haberci, öğrenci, yeni fikir"),
        ("Şövalye (Knight)", "Eylem, macera, hız"),
        ("Kraliçe (Queen)", "Olgunluk, bakım, sezgi"),
        ("Kral (King)", "Otorite, hakimiyet, sonuç")
    ]

    minors = []
    for suit_name, suit_data in suits.items():
        base_suit = suit_name.split(' ')[0] # 'Değnek'
        
        for rank_name, rank_desc in ranks:
            full_title = f"{base_suit} {rank_name}"
            # Specific meanings override generic generation for better quality
            content = f"""
            <p><strong>Genel Bakış:</strong> {suit_name} serisi, {suit_data['kw']} temalarını işler. {full_title}, bu alanda {rank_desc.lower()} temasını vurgular.</p>
            <p><strong>Anlamı:</strong> {suit_data['desc']} kart çekildiğinde, hayatınızda {rank_desc.lower()} ile ilgili bir durumun ön plana çıkacağını gösterir.</p>
            <p><strong>Tavsiye:</strong> Durumu analiz edin ve elementinizin ({suit_data['kw'].split(', ')[1]}) gücünü kullanın.</p>
            """
            
            # Special Overrides for famous cards
            if "Kılıç Üçlü" in full_title: content += "<p><em>Kalp kırıklığı ve ayrılığı simgeler. Ancak bu acı geçicidir.</em></p>"
            if "Değnek Sekizli" in full_title: content += "<p><em>Olaylar çok hızlı gelişecek. Haberler yolda.</em></p>"
            if "Tılsım Onlu" in full_title: content += "<p><em>Kalıcı zenginlik ve aile mirası. Maddi güvence.</em></p>"
            if "Kupa İkili" in full_title: content += "<p><em>Ruh eşi bağlantısı, karşılıklı sevgi ve ortaklık.</em></p>"

            minors.append((full_title, f"{suit_data['kw']} - {rank_desc}", content))

    # SAVE ALL
    all_cards = majors + minors
    print(f"Total Cards to Seed: {len(all_cards)}")

    for title, short, content in all_cards:
        # Create Slug manually or let save() handle it? Model handles it.
        # Check if exists
        LibraryItem.objects.update_or_create(
            title=title,
            category=cat_tarot,
            defaults={
                'short_desc': short,
                'content': content,
                'lookup_key': title.lower().replace(' ', '_').replace('-', '').replace('(', '').replace(')', '')[:50]
            }
        )

    print("Seeding Complete!")

if __name__ == '__main__':
    seed()
