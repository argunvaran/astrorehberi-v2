import os
import sys
import django

# Setup Django Environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings')
django.setup()

from library.models import LibraryCategory, LibraryItem

def seed():
    print("Seeding Full Library (Zodiac + Full Tarot)...")
    
    # 1. Ensure Categories
    cat_zodiac, _ = LibraryCategory.objects.get_or_create(name='Burç Yorumları', defaults={'icon': 'fas fa-star'})
    cat_tarot, _ = LibraryCategory.objects.get_or_create(name='Tarot Odası', defaults={'icon': 'fas fa-hat-wizard'})
    # cat_astro, _ = LibraryCategory.objects.get_or_create(name='Astroloji 101', defaults={'icon': 'fas fa-book'})

    # ==========================================
    # 2. ZODIAC CONTENT (From seed_lib.py)
    # ==========================================
    zodiacs = [
        ("Koç (Aries)", "♈", "Öncü, Ateş, Mars", 
         """<p><strong>Genel Bakış:</strong> Zodyak'ın ilk burcu olan Koç, başlangıçların, enerjinin ve cesaretin sembolüdür. Mars tarafından yönetilen Koç burçları, doğuştan lider ruhludur. Hayata karşı tutkulu, doğrudan ve rekabetçidirler.</p>
            <p><strong>Aşk ve İlişkiler:</strong> Aşkta avcı rolünü seven Koçlar, heyecanı ve tutkuyu ararlar. İlişkilerde dürüst ve açıktırlar ancak sabırsızlıkları bazen sorun yaratabilir.</p>
            <p><strong>Doğum Haritasında:</strong> Koç burcunun bulunduğu ev, kişinin nerede en çok inisiyatif alacağını ve savaşçı ruhunu göstereceğini belirtir.</p>"""),
        
        ("Boğa (Taurus)", "♉", "Sabit, Toprak, Venüs",
         """<p><strong>Genel Bakış:</strong> Güven, istikrar ve huzurun burcudur. Venüs yönetimindeki Boğalar, hayattaki güzelliklere, sanata ve konfora düşkündürler. Sabırlı ve kararlı yapılarıyla girdikleri işi mutlaka bitirirler.</p>
            <p><strong>Aşk ve İlişkiler:</strong> Sadakat Boğa burcu için her şeydir. Dokunsal ve duygusaldırlar. Değişimi sevmezler ve ilişkilerde uzun vadeli güven ararlar.</p>"""),
            
        ("İkizler (Gemini)", "♊", "Değişken, Hava, Merkür",
         """<p><strong>Genel Bakış:</strong> Meraklı, zeki ve uyumlu İkizler, Zodyak'ın iletişimcileridir. Merkür tarafından yönetilirler. Hızlı düşünür, çabuk öğrenir ve sürekli yeni bilgiler peşinde koşarlar.</p>
            <p><strong>Kariyer:</strong> İletişim, yazarlık, medya ve ticaret alanlarında çok başarılıdırlar. Tekdüze işler onlara göre değildir.</p>"""),
            
        ("Yengeç (Cancer)", "♋", "Öncü, Su, Ay",
         """<p><strong>Genel Bakış:</strong> Duygusal, koruyucu ve sezgiseldir. Ay tarafından yönetilen Yengeçler için ev ve aile kutsaldır. Dışarıdan sert kabuklu görünseler de içlerinde çok hassas bir kalp taşırlar.</p>
            <p><strong>Aşk:</strong> Derin bağlar kurmak isterler. Partnerlerine anne/baba şefkatiyle yaklaşırlar ancak kırıldıklarında içlerine kapanabilirler.</p>"""),
            
        ("Aslan (Leo)", "♌", "Sabit, Ateş, Güneş",
         """<p><strong>Genel Bakış:</strong> Zodyak'ın kralları ve kraliçeleridir. Güneş tarafından yönetilen Aslanlar, sahnede olmayı, takdir edilmeyi ve yönetmeyi severler. Cömert, sıcakkanlı ve yaratıcıdırlar.</p>
            <p><strong>Kariyer:</strong> Sanat, yöneticilik ve eğlence sektörü onlar için biçilmiş kaftandır. Liderlik vasıfları yüksektir.</p>"""),
            
        ("Başak (Virgo)", "♍", "Değişken, Toprak, Merkür",
         """<p><strong>Genel Bakış:</strong> Analitik, detaycı ve hizmet odaklıdır. Mükemmeliyetçi yapıları sayesinde başkalarının kaçırdığı detayları görürler. Çalışkan ve pratiktirler.</p>
            <p><strong>Sağlık:</strong> Başak burcu sağlık ve hijyenle de ilişkilidir. Doğal tedavi yöntemlerine ve sağlıklı beslenmeye ilgi duyarlar.</p>"""),
            
        ("Terazi (Libra)", "♎", "Öncü, Hava, Venüs", 
         """<p><strong>Genel Bakış:</strong> Denge, adalet ve uyum arayışındadırlar. Venüs yönetiminde oldukları için estetik algıları çok yüksektir. Diplomatik yetenekleri sayesinde her ortamda barışı sağlarlar.</p>
            <p><strong>İlişkiler:</strong> Terazi "Biz" burcudur. Yalnız kalmaktan hoşlanmazlar ve kendilerini bir partnerle tamamlama ihtiyacı hissederler.</p>"""),
            
        ("Akrep (Scorpio)", "♏", "Sabit, Su, Mars/Plüton",
         """<p><strong>Genel Bakış:</strong> Gizemli, tutkulu ve derin. Akrepler yüzeysel hiçbir şeyi sevmezler. Ya hep ya hiç felsefesine sahiptirler. Sezgileri korkutucu derecede güçlüdür.</p>
            <p><strong>Dönüşüm:</strong> Zodyak'ın en büyük dönüşüm ve yeniden doğuş enerjisini taşırlar. Krizleri fırsata çevirme ustasıdırlar.</p>"""),
            
        ("Yay (Sagittarius)", "♐", "Değişken, Ateş, Jüpiter",
         """<p><strong>Genel Bakış:</strong> Özgürlük, felsefe ve macera. Jüpiter tarafından yönetilen Yaylar, hayata iyimser bir pencereden bakarlar. Keşfetmek, gezmek ve öğrenmek onların yaşam amacıdır.</p>
            <p><strong>Kariyer:</strong> Akademisyenlik, rehberlik, yurt dışı bağlantılı işler ve hukuk alanlarında başarılı olurlar.</p>"""),
            
        ("Oğlak (Capricorn)", "♑", "Öncü, Toprak, Satürn",
         """<p><strong>Genel Bakış:</strong> Disiplin, sorumluluk ve hırs. Oğlaklar zamanın ve sabrın ustasıdır. Zirveye tırmanmak için her türlü zorluğa göğüs gererler. Geleneksel ve kuralcıdırlar.</p>
            <p><strong>Hedefler:</strong> Başarı odaklıdırlar. Duygularını işlerine karıştırmadan, profesyonelce ilerlerler.</p>"""),
            
        ("Kova (Aquarius)", "♒", "Sabit, Hava, Satürn/Uranüs",
         """<p><strong>Genel Bakış:</strong> Yenilikçi, insancıl ve sıra dışı. Kovalar geleceğin burcudur. Toplumsal kuralları sorgular ve özgürlüğü savunurlar. Zekaları keskin ve orijinaldir.</p>
            <p><strong>Arkadaşlık:</strong> Romantik ilişkilerden çok entelektüel dostluklara önem verirler. Herkesle eşit ilişki kurarlar.</p>"""),
            
        ("Balık (Pisces)", "♓", "Değişken, Su, Jüpiter/Neptün",
         """<p><strong>Genel Bakış:</strong> Hayalperest, merhametli ve sanatsal. Balıklar maddi dünyadan çok manevi dünya ile ilgilidir. Sınrsız bir hayal güçleri ve empati yetenekleri vardır.</p>
            <p><strong>Ruhsallık:</strong> Evrensel sevgi ve fedakarlık temalarını taşırlar. Sanat ve müzik yoluyla kendilerini ifade ederler.</p>""")
    ]

    print(f"Updates/Creating {len(zodiacs)} Zodiac Items...")
    for title, symbol, short, content in zodiacs:
        LibraryItem.objects.update_or_create(
            title=title,
            category=cat_zodiac,
            defaults={
                'short_desc': f"{symbol} {short}",
                'content': content,
                'lookup_key': title.split('(')[1].replace(')', '').lower() if '(' in title else ''
            }
        )
    
    # ==========================================
    # 3. FULL TAROT CONTENT (Major + Minor)
    # ==========================================
    
    # Major Arcana
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

    # Minor Arcana
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
            
            # Special Overrides for famous cards (Simple examples)
            if "Kılıç Üçlü" in full_title: content += "<p><em>Kalp kırıklığı ve ayrılığı simgeler. Ancak bu acı geçicidir.</em></p>"
            if "Değnek Sekizli" in full_title: content += "<p><em>Olaylar çok hızlı gelişecek. Haberler yolda.</em></p>"
            if "Tılsım Onlu" in full_title: content += "<p><em>Kalıcı zenginlik ve aile mirası. Maddi güvence.</em></p>"
            if "Kupa İkili" in full_title: content += "<p><em>Ruh eşi bağlantısı, karşılıklı sevgi ve ortaklık.</em></p>"

            minors.append((full_title, f"{suit_data['kw']} - {rank_desc}", content))

    all_cards = majors + minors
    print(f"Updates/Creating {len(all_cards)} Tarot Items...")

    for title, short, content in all_cards:
        # Construct lookup key safely
        lookup = title.lower().replace(' ', '_').replace('-', '').replace('(', '').replace(')', '')
        # Truncate if too long (rare but safe)
        lookup = lookup[:50]

        LibraryItem.objects.update_or_create(
            title=title,
            category=cat_tarot,
            defaults={
                'short_desc': short,
                'content': content,
                'lookup_key': lookup
            }
        )

    print("Seeding Complete! All items are active/updated.")

if __name__ == '__main__':
    seed()
