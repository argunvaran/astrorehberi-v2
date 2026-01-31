
import os
import django
import sys
import random

# Setup Django Environment
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "astro_backend.settings")
django.setup()

from astrology.models import BlogPost

# Base Data for Generation (50+ variations)
TOPICS = [
    "Aşk Astrolojisi", "Kariyer Yolu", "Karmik Düğümler", "Gezegen Gerilemeleri", 
    "Burç Uyumları", "Numeroloji ve Astroloji", "Doğal Taşların Gücü", 
    "Renklerin Enerjisi", "Dolunay Ritüelleri", "Yeniay Niyetleri",
    "Güneş Tutulması", "Ay Tutulması", "Venüs'ün Etkileri", "Mars Savaşçısı",
    "Jüpiter Şansı", "Satürn Dersleri", "Uranüs Sürprizleri", "Neptün Hayalleri",
    "Plüton Dönüşümü", "Chiron Yarası", "Lilith'in Gölgesi", "Juno Evlilik Bağı",
    "1. Ev Kimlik", "2. Ev Para", "3. Ev İletişim", "4. Ev Aile",
    "5. Ev Yaratıcılık", "6. Ev Sağlık", "7. Ev İlişkiler", "8. Ev Dönüşüm",
    "9. Ev Felsefe", "10. Ev Kariyer", "11. Ev Sosyal Çevre", "12. Ev Bilinçaltı",
    "Ateş Elementi", "Hava Elementi", "Toprak Elementi", "Su Elementi",
    "Öncü Burçlar", "Sabit Burçlar", "Değişken Burçlar",
    "Merkür İletişimi", "Venüs Cazibesi", "Ay Duygusallığı",
    "Yükselen Burç Maskesi", "Alçalan Burç Aynası", "Ay Düğümleri Rotası"
]

TITLES_TEMPLATES = [
    "{} Hakkında Bilmeniz Gereken 5 Şey",
    "{}: Hayatınızı Nasıl Etkiliyor?",
    "Astrolojide {} ve Önemi",
    "{}: Gizli Gücünüzü Keşfedin",
    "Neden {} Konusunda Dikkatli Olmalısınız?",
    "{} ile Potansiyelinizi Açığa Çıkarın",
    "Derinlemesine Analiz: {}",
    "{} Sırlarını Çözüyoruz",
    "Yeni Başlayanlar İçin: {}",
    "İleri Seviye Astroloji: {}"
]

IMAGES = [
    "https://images.unsplash.com/photo-1532968961962-8a0cb3a2d4f5?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1614730341194-75c60740a270?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1614732414444-096e5f1122d5?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1502657877623-f66bf489d236?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1506318137071-a8bcbf67cc77?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1505506874110-6a7a69069a08?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1464802686167-b939a6910659?auto=format&fit=crop&w=800&q=80"
]

CONTENT_TEMPLATES = [
    """
    <h3>Giriş: {topic} Evreni</h3>
    <p>Astroloji, binlerce yıldır insanlığın yolunu aydınlatan kadim bir rehberdir. Bugün {topic} konusunu ele alıyoruz. Haritanızdaki bu nokta, yaşam amacınızı ve günlük dinamiklerinizi derinden etkiler.</p>
    
    <h3>Enerjiyi Anlamak</h3>
    <p>{topic}, sadece bir sembol değil, yaşayan bir enerjidir. Bu enerjiyi doğru kanalize ettiğinizde, hayatınızdaki kilitli kapıların açıldığını göreceksiniz. Özellikle farkındalık çalışmalarıyla bu etkiyi olumluya çevirmek mümkündür.</p>

    <h3>Pratik Öneriler</h3>
    <ul>
        <li>Haritanızdaki konumunu inceleyin.</li>
        <li>Günlük meditasyonlarınızda bu temaya odaklanın.</li>
        <li>Bu enerjinin gölge yönlerine (aşırılıklarına) dikkat edin.</li>
    </ul>

    <h3>Sonuç</h3>
    <p>{topic} ile çalışmak sabır gerektirir, ancak ödülü büyüktür. Kendinizi tanıma yolculuğunda bu bilgi size ışık tutacaktır.</p>
    """,
    """
    <h3>{topic}: Gizli Bir Hazine</h3>
    <p>Pek çok insan {topic} konusunu yüzeysel bilir, ancak derinlere inildiğinde burada muazzam bir bilgelik yatar. Bu yazıda, bu kozmik faktörün hayatınızdaki rolünü keşfedeceğiz.</p>

    <h3>Neden Önemli?</h3>
    <p>Çünkü evren rastgele çalışmaz. {topic}, doğum anınızdaki göksel imzanın kritik bir parçasıdır. İlişkilerinizden kariyerinize kadar geniş bir yelpazede etkisi hissedilir.</p>
    
    <p>Özellikle zorlayıcı açılarda, {topic} bir öğretmen gibi davranır. Size sabrı, dayanıklılığı veya sevgiyi öğretmeye çalışıyor olabilir.</p>

    <h3>Ne Yapmalı?</h3>
    <p>Direnmek yerine akışta kalın. Bu enerjiyi kucaklayın ve size ne anlatmak istediğini dinleyin.</p>
    """
]

def generate_bulk():
    print("Generating 50+ SEO Optimized Articles...")
    
    count = 0
    slugs_seen = set()
    
    # 1. Existing High Quality Content (Keep them)
    # (Leaving logic inpopulate_blog_content.py or merging here? 
    #  Let's keep this as a separate generator that APPENDS, 
    #  or creates new random ones. Best to re-use the lists.)
    
    # Let's generate 45 random articles to reach ~50 total
    for topic in TOPICS:
        chosen_template = random.choice(TITLES_TEMPLATES)
        title = chosen_template.format(topic)
        
        # Create Slug
        from django.utils.text import slugify
        slug = slugify(title)
        
        # Unique Slug guarantee
        original_slug = slug
        counter = 1
        while slug in slugs_seen:
            slug = f"{original_slug}-{counter}"
            counter += 1
        slugs_seen.add(slug)

        image = random.choice(IMAGES)
        content_template = random.choice(CONTENT_TEMPLATES)
        content = content_template.format(topic=topic)
        
        # Create
        BlogPost.objects.get_or_create(
            slug=slug,
            defaults={
                'title': title,
                'content': content,
                'image_url': image,
                'is_published': True
            }
        )
        count += 1
        print(f"Generated: {title}")

    print(f"Total {count} articles generated.")

if __name__ == "__main__":
    generate_bulk()
