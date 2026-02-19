
import os
import django
import sys

# Django Setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'astro_backend.settings') 
django.setup()

from library.models import LibraryCategory, LibraryItem

# Static Data from Mobile App
STATIC_DATA = {
    # Burçlar
    "Burçlar": {
        "Koç": "Zodyak'ın ilk burcu olan Koç, ateş elementinin öncü niteliğindedir. Mars tarafından yönetilen Koçlar, cesur, girişimci ve enerjik yapılarıyla tanınırlar. Hayata karşı tutkulu bir yaklaşımları vardır ve liderlik vasıfları yüksektir. Gölge yönlerinde sabırsızlık ve dürtüsellik görülebilir.",
        "Boğa": "Venüs yönetimindeki Boğa burcu, toprak elementinin sabit niteliğini taşır. Güven, istikrar ve huzur arayışı ön plandadır. Sanata, estetiğe ve dünyevi zevklere düşkündürler. Sabırlı ve kararlı yapıları, onları hedeflerine ulaşma konusunda inatçı kılabilir.",
        "İkizler": "Merkür yönetimindeki İkizler, hava elementinin değişken niteliğindedir. İletişim, merak ve zeka onların anahtar kelimeleridir. Hızlı düşünen, uyumlu ve sosyal yapılarıyla bilinirler. Ancak odaklanma sorunu ve yüzeysellik gölge yönleri olabilir.",
        "Yengeç": "Ay yönetimindeki Yengeç, su elementinin öncü niteliğindedir. Duygusal derinlik, sezgiler ve koruyuculuk ön plandadır. Aileye ve köklerine bağlıdırlar. Empati yetenekleri yüksektir ancak alınganlık ve aşırı korumacılık gösterebilirler.",
        "Aslan": "Güneş tarafından yönetilen Aslan, ateş elementinin sabit niteliğindedir. Yaratıcılık, özgüven ve liderlik onların doğal halidir. Sahne ışıklarını severler ve cömerttirler. Gölge yönlerinde kibir ve onaylanma ihtiyacı baskın olabilir.",
        "Başak": "Merkür yönetimindeki Başak, toprak elementinin değişken niteliğindedir. Analitik zeka, detaycılık ve hizmet bilinci ön plandadır. Mükemmeliyetçi yapıları onları eleştirel yapabilir. Düzen ve sağlık konularına önem verirler.",
        "Terazi": "Venüs yönetimindeki Terazi, hava elementinin öncü niteliğindedir. Denge, uyum ve adalet arayışı hayatlarının merkezindedir. İlişkiler ve ortaklıklar onlar için çok önemlidir. Kararsızlık ve çatışmadan kaçınma gölge yönleridir.",
        "Akrep": "Mars ve Plüton yönetimindeki Akrep, su elementinin sabit niteliğindedir. Gizem, dönüşüm ve tutku onların ana temalarıdır. Derin sezgileri ve araştırmacı yapıları vardır. Kıskançlık ve güç savaşları gölge yönleri olabilir.",
        "Yay": "Jüpiter yönetimindeki Yay, ateş elementinin değişken niteliğindedir. Özgürlük, inanç ve keşif arayışı ön plandadır. İyimser ve felsefi bir bakış açıları vardır. Abartıya kaçma ve fanatizm gölge yönleri olabilir.",
        "Oğlak": "Satürn yönetimindeki Oğlak, toprak elementinin öncü niteliğindedir. Disiplin, sorumluluk ve başarı odaklılık onların özellikleridir. Sabırlı ve çalışkandırlar. Melankoli ve katılık gölge yönleri olabilir.",
        "Kova": "Satürn ve Uranüs yönetimindeki Kova, hava elementinin sabit niteliğindedir. Özgürlükçü, yenilikçi ve hümanist yapılarıyla bilinirler. Toplumsal konulara duyarlıdırlar. Duygusal mesafeli duruş ve isyankarlık gölge yönleri olabilir.",
        "Balık": "Jüpiter ve Neptün yönetimindeki Balık, su elementinin değişken niteliğindedir. Sınırsız hayal gücü, şefkat ve ruhsallık ön plandadır. Evrensel birleşim arzusundadırlar. Kurban psikolojisi ve gerçeklerden kaçış gölge yönleri olabilir.",
    },
    
    # Tarot Büyük Arkana
    "Tarot - Büyük Arkana": {
        "Joker": "Joker, yeni başlangıçları, saflığı ve potansiyeli temsil eder. Henüz şekillenmemiş olanın özgürlüğünü taşır. Bir uçurumun kenarında, korkusuzca durur; çünkü evrenin onu tutacağını bilir. Risk alma ve bilinmeyene atılma zamanıdır.",
        "Büyücü": "Büyücü, irade gücünü, ustalığı ve tezahürü simgeler. Dört elementin (değnek, kupa, kılıç, tılsım) sahibidir ve bunları kullanarak arzularını gerçeğe dönüştürür. 'Yukarıda ne varsa, aşağıda da o vardır' ilkesinin vücut bulmuş halidir.",
        "Azize": "Azize, sezgiyi, bilinçaltını ve gizli bilgeliği temsil eder. Perdenin arkasındaki sırları korur. Size iç sesinizi dinlemenizi ve rüyalarınıza dikkat etmenizi söyler. Pasiflik ve bekleme zamanıdır, çünkü cevaplar dışarıda değil, içeridedir.",
        "İmparatoriçe": "İmparatoriçe, bereketi, doğurganlığı ve dişil gücü simgeler. Doğanın, sanatın ve güzelliğin koruyucusudur. Yaratıcılığın aktığı, duyuların uyandığı bir dönemi işaret eder. Bolluk ve sevgi enerjisi hakimdir.",
        "İmparator": "İmparator, otoriteyi, yapıyı ve eril gücü temsil eder. Düzen kurma, liderlik etme ve sınırları belirleme zamanıdır. Mantık ve strateji ile hareket etmeyi öğütler. İstikrarın ve güvenliğin sembolüdür.",
        "Aziz": "Aziz, gelenekleri, inanç sistemlerini ve ruhsal rehberliği simgeler. Toplumsal kurallara uyumu ve öğrenme sürecini işaret eder. Bir mentordan yardım alma veya bir gruba dahil olma zamanı olabilir.",
        "Aşıklar": "Aşıklar, sevgiyi, uyumu ve önemli seçimleri temsil eder. Sadece romantik aşkı değil, aynı zamanda değerler sisteminizle uyumlu kararlar almayı da simgeler. Kalbinizin sesini dinleyerek bir yol ayrımında olduğunuzu gösterir.",
        "Savaş Arabası": "Savaş Arabası, irade gücüyle elde edilen zaferi ve kontrolü simgeler. Zıt güçleri (siyah ve beyaz sfenksler) dengede tutarak hedefe ilerlemeyi anlatır. Kararlılık ve odaklanma başarıyı getirecektir.",
        "Güç": "Güç kartı, kaba kuvveti değil, içsel dayanıklılığı ve şefkati temsil eder. Aslanı (içgüdüleri) nazikçe ehlileştiren kadını gösterir. Sabır ve cesaretle zorlukların üstesinden gelinebileceğini müjdeler.",
        "Ermiş": "Ermiş, içe dönmeyi, yalnızlığı ve ruhsal arayışı simgeler. Dış dünyadan uzaklaşarak kendi iç ışığınızı bulma zamanıdır. Cevaplar sessizlikte ve tefekkürde gizlidir.",
        "Kader Çarkı": "Kader Çarkı, döngüleri, değişimi ve karmayı temsil eder. Hayatın inişli çıkışlı doğasını hatırlatır. Şansın sizden yana döndüğü bir dönemi işaret edebilir. Değişime direnmek yerine akışa uyum sağlamalısınız.",
        "Adalet": "Adalet, dengeyi, gerçeği ve sebep-sonuç ilişkisini simgeler. Ne ektiyseniz onu biçeceğiniz bir zamandır. Dürüstlük ve objektiflik gerektirir. Hukuki konular veya önemli kararlar gündeme gelebilir.",
        "Asılan Adam": "Asılan Adam, fedakarlığı, beklemeyi ve farklı bir bakış açısını temsil eder. Olaylara tersinden bakarak yeni bir anlayış kazanmayı öğütler. Bazen ilerlemek için durmak ve teslim olmak gerekir.",
        "Ölüm": "Ölüm kartı, bitişleri ve kaçınılmaz dönüşümü simgeler. Bu fiziksel bir ölüm değil, eski bir benliğin veya durumun sona ermesidir. Yeni bir başlangıç için yer açmaktır. Değişimden korkmayın.",
        "Denge": "Denge kartı, uyumu, ölçülülüğü ve sabrı temsil eder. Zıtlıkları bir araya getirerek yeni bir alaşım (simya) oluşturmayı anlatır. Ruhsal ve fiziksel sağlık için dengeyi bulma zamanıdır.",
        "Şeytan": "Şeytan, bağımlılıkları, maddi tutkuları ve kendi yarattığımız zincirleri temsil eder. Korkularınızın veya arzularınızın sizi esir almasına izin vermeyin. Özgürleşmek için önce sizi neyin bağladığını fark etmelisiniz.",
        "Yıkılan Kule": "Yıkılan Kule, ani değişimleri, şok edici olayları ve aydınlanmayı simgeler. Temeli sağlam olmayan yapıların çöküşüdür. Zorlayıcı olsa da, bu yıkım gerçeği görmenizi sağlar ve özgürleştiricidir.",
        "Yıldız": "Yıldız, umudu, şifayı ve ilhamı temsil eder. Fırtınadan (Kule) sonra gelen sakinliktir. Kozmik rehberliğe güvenmeyi ve hayallerinize inanmayı öğütler. Ruhsal yenilenme zamanıdır.",
        "Ay": "Ay, yanılsamaları, bilinçaltı korkularını ve belirsizliği temsil eder. Her şey göründüğü gibi olmayabilir. Rüyalarınıza ve sezgilerinize kulak verin ancak hayal dünyasında kaybolmamaya dikkat edin.",
        "Güneş": "Güneş, başarıyı, canlılığı ve neşeyi simgeler. Zodyak'ın en parlak kartıdır. Her şeyin netleştiği, enerjinizin yüksek olduğu ve mutluluğun hak edildiği bir dönemdir.",
        "Mahkeme": "Mahkeme, uyanışı, yargılamayı ve çağrıyı temsil eder. Geçmişi değerlendirip geleceğe yön verme zamanıdır. İçsel bir çağrıya kulak vererek hayatınızda köklü bir değişiklik yapabilirsiniz.",
        "Dünya": "Dünya, tamamlanmayı, bütünlüğü ve başarıyı simgeler. Bir döngünün sonuna gelinmiş ve hedefe ulaşılmıştır. Evrenle uyum içinde dans etme zamanıdır.",
    },

    # Tarot Küçük Arkana (Örnekler)
    "Tarot - Küçük Arkana": {
        "Kupa As": "Yeni bir aşk, duygusal başlangıç ve ruhsal uyanış. Kalbin kapılarını açma zamanı.",
        "Değnek As": "Yeni bir ilham, yaratıcı bir kıvılcım ve potansiyel enerji. Bir fikir veya proje için harekete geçme zamanı.",
        "Kılıç As": "Zihinsel berraklık, yeni bir fikir ve keskin bir zeka. Bir gerçeğin ortaya çıkması.",
        "Tılsım As": "Maddi fırsat, bolluk ve yeni bir iş kapısı. Somut bir başarının tohumlarının atılması.",
    }
}

def run():
    print("Populating Library with Initial Data...")
    
    order_counter = 0
    for cat_name, items in STATIC_DATA.items():
        order_counter += 1
        cat, created = LibraryCategory.objects.get_or_create(
            name=cat_name, 
            defaults={'icon': 'fas fa-book', 'order': order_counter}
        )
        if created:
            print(f"[CAT] Created Category: {cat_name}")
        else:
            print(f"[CAT] Found Category: {cat_name}")
            
        for title, content in items.items():
            # Create or Update item
            item, created = LibraryItem.objects.get_or_create(
                category=cat,
                title=title,
                defaults={'content': content, 'short_desc': content[:100] + '...'}
            )
            
            if created:
                print(f"  [ITEM] Created: {title}")
            else:
                # Update content just in case
                if item.content != content:
                    item.content = content
                    item.save()
                    print(f"  [ITEM] Updated: {title}")
                else:
                    print(f"  [ITEM] Exists: {title}")

    print("\nLibrary Population Complete!")

if __name__ == '__main__':
    run()
