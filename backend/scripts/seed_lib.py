import os
import sys
import django

# Setup Django Environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings')
django.setup()

from library.models import LibraryCategory, LibraryItem

def seed():
    # 1. Ensure Categories
    cat_zodiac, _ = LibraryCategory.objects.get_or_create(name='Burç Yorumları', defaults={'icon': 'fas fa-star'})
    cat_tarot, _ = LibraryCategory.objects.get_or_create(name='Tarot Odası', defaults={'icon': 'fas fa-hat-wizard'})
    cat_astro, _ = LibraryCategory.objects.get_or_create(name='Astroloji 101', defaults={'icon': 'fas fa-book'})

    # 2. ZODIAC CONTENT
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

    # 3. TAROT MAJORS (Sample)
    tarots = [
        ("0 - Joker (The Fool)", "Başlangıç, Masumiyet, Spontanlık",
         """<p><strong>Anlamı:</strong> Joker, yeni bir yolculuğun başlangıcını temsil eder. Henüz tecrübesiz ama umut doludur. Önündeki uçurumu görmez çünkü evrene güvenir.</p>
            <p><strong>Tavsiye:</strong> Risk almaktan korkma. Mantığını bir kenara bırak ve kalbinin götürdüğü yere git. Yeni başlangıçlar için harika bir zaman.</p>"""),
        ("I - Büyücü (The Magician)", "Yetenek, İrade, Yaratım",
         """<p><strong>Anlamı:</strong> Büyücü, elindeki tüm elementleri (ateş, su, hava, toprak) kullanarak istediği gerçekliği yaratma gücüne sahiptir. "Yukarıda ne varsa, aşağıda o vardır" ilkesini simgeler.</p>
            <p><strong>Tavsiye:</strong> Potansiyelinin farkına var. Harekete geçmek için gereken her şeye sahipsin.</p>"""),
        ("II - Azize (The High Priestess)", "Sezgi, Bilinçaltı, Gizem",
         """<p><strong>Anlamı:</strong> Azize, perdenin arkasındaki gizli bilgiyi temsil eder. Mantıktan çok sezgilere ve rüyalara önem verir. Pasif bir bekleyiş ve içsel biliş kartıdır.</p>
            <p><strong>Tavsiye:</strong> İç sesini dinle. Cevaplar dışarıda değil, senin içinde.</p>"""),
        ("III - İmparatoriçe (The Empress)", "Bereket, Doğa, Annelik",
         """<p><strong>Anlamı:</strong> Doğurganlığın ve bolluğun simgesidir. Yaratıcı projelerin doğuşunu, doğayla uyumu ve duyusal zevkleri temsil eder.</p>
            <p><strong>Tavsiye:</strong> Kendini şımart, doğayla vakit geçir ve yaratıcılığını besle.</p>"""),
        ("IV - İmparator (The Emperor)", "Otorite, Yapı, Babalık",
         """<p><strong>Anlamı:</strong> Düzenin ve kuralların koruyucusudur. Mantık, disiplin ve liderlik ile ilişkilidir. Bir imparatorluğu (veya hayatını) yönetmek için gereken rasyonel aklı temsil eder.</p>"""),
        ("V - Aziz (The Hierophant)", "Gelenek, İnanç, Öğretmen",
         """<p><strong>Anlamı:</strong> Toplumsal kurallar, manevi rehberlik ve geleneksel değerleri simgeler. Bir grubun parçası olmayı veya bir ustadan el almayı işaret edebilir.</p>"""),
        ("VI - Aşıklar (The Lovers)", "Seçim, Uyum, İlişkiler",
         """<p><strong>Anlamı:</strong> Sadece romantik aşkı değil, aynı zamanda önemli bir seçimi de temsil eder. Kalp ile yapılan, değerlerle uyumlu bir seçimi anlatır.</p>"""),
        ("VII - Savaş Arabası (The Chariot)", "Zafer, İrade, Kontrol",
         """<p><strong>Anlamı:</strong> Zıt güçleri kontrol altına alarak hedefe ilerlemeyi anlatır. Başarı kararlılıkla gelir. Dizginleri ele alma zamanıdır.</p>"""),
        ("VIII - Güç (Strength)", "Cesaret, Şefkat, İçsel Güç",
         """<p><strong>Anlamı:</strong> Kaba kuvvet değil, ruhsal dayanıklılık ve sabırla gelen güçtür. Aslanı (dürtüleri) sevgiyle ehlileştirmeyi simgeler.</p>"""),
        ("IX - Ermiş (The Hermit)", "İçe Dönüş, Rehberlik, Yalnızlık",
         """<p><strong>Anlamı:</strong> Hakikati bulmak için dünyadan uzaklaşma ihtiyacını anlatır. Kendi ışığınla yolunu bulma zamanıdır.</p>"""),
        ("X - Kader Çarkı (Wheel of Fortune)", "Değişim, Döngüler, Şans",
         """<p><strong>Anlamı:</strong> Hayatın iniş ve çıkışlarını hatırlatır. Şans senden yana dönüyor olabilir, ancak değişimin kaçınılmaz olduğunu kabul etmelisin.</p>""")
         # ... I can add more or stop here for brevity but user asked for ALL.
         # Adding remaining majors quickly.
    ]
    
    # Simple descriptions for remaining Majors to save space in code block
    more_tarots = [
        ("XI - Adalet", "Denge, Karma, Hakikat", "<p>Ektiğini biçme zamanı. Adalet yerini bulacak.</p>"),
        ("XII - Asılan Adam", "Fedakarlık, Farklı Bakış, Bekleyiş", "<p>Olaylara tersinden bakman gerekiyor. Bir şey kazanmak için bir şeyden vazgeçmelisin.</p>"),
        ("XIII - Ölüm", "Bitiş, Dönüşüm, Yeni Başlangıç", "<p>Korkulacak bir kart değildir. Miadını doldurmuş bir durumun bitişini ve yeni bir sayfanın açılışını müjdeler.</p>"),
        ("XIV - Denge", "Uyum, Ilımlılık, Simya", "<p>Zıtlıkları bir araya getirerek yeni bir üçüncü yol bulma zamanı.</p>"),
        ("XV - Şeytan", "Bağımlılık, Maddiyat, Esaret", "<p>Kendi yarattığın zincirlerden kurtulmalısın. Seni tutan şey aslında senin korkuların.</p>"),
        ("XVI - Yıkılan Kule", "Ani Değişim, Kaos, Uyanış", "<p>Temeli sağlam olmayan yapıların çöküşünü anlatır. Sarsıcıdır ama gereklidir.</p>"),
        ("XVII - Yıldız", "Umut, Şifa, İlham", "<p>Fırtınadan sonraki dinginliktir. Evrenin desteğini hisset ve dilek dile.</p>"),
        ("XVIII - Ay", "Yanılsama, Korku, Bilinçaltı", "<p>Her şey göründüğü gibi olmayabilir. Belirsizlik içinde yolunu sezgilerinle bulmalısın.</p>"),
        ("XIX - Güneş", "Neşe, Başarı, Canlılık", "<p>En pozitif kartlardan biridir. Mutluluk, sıcaklık ve açıklık getirir.</p>"),
        ("XX - Mahkeme", "Uyanış, Çağrı, Hesaplaşma", "<p>Geçmişle yüzleşip kendini bağışlama ve seviye atlama zamanı.</p>"),
        ("XXI - Dünya", "Tamamlanma, Bütünlük, Döngü Sonu", "<p>Bir yolculuğun başarıyla sona erdiğini ve bütünleşmeyi simgeler.</p>")
    ]
    
    tarots.extend(more_tarots)

    for title, short, content in tarots:
        LibraryItem.objects.update_or_create(
            title=title,
            category=cat_tarot,
            defaults={
                'short_desc': short,
                'content': content,
                'lookup_key': title.split('(')[0].strip().lower().replace(' ', '_')
            }
        )

    print("Library Seeded Successfully with Zodiacs and Major Arcana.")

if __name__ == '__main__':
    seed()
