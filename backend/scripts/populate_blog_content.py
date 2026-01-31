
import os
import django
import sys

# Setup Django Environment
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "astro_backend.settings")
django.setup()

from astrology.models import BlogPost

ARTICLES = [
    {
        "title": "Merkür Retrosu: Felaket mi, Fırsat mı?",
        "slug": "merkur-retrosu-nedir-etkileri",
        "image_url": "https://images.unsplash.com/photo-1614730341194-75c60740a270?auto=format&fit=crop&w=800&q=80",
        "content": """
        <h3>Merkür Retrosu Nedir?</h3>
        <p>Astrolojide en çok korkulan dönemlerden biri olan Merkür Retrosu (Gerilemesi), aslında gezegenin fiziksel olarak geri gitmesi değil, Dünya'dan bakıldığında hızının yavaşlaması sonucu oluşan bir optik illüzyondur. Ancak bu illüzyonun enerjisel etkileri oldukça gerçektir.</p>
        
        <h3>Neleri Etkiler?</h3>
        <p>Merkür; iletişim, teknoloji, seyahat ve düşünce süreçlerini yönetir. Retro dönemlerinde bu alanlarda aksamalar sıkça görülür:</p>
        <ul>
            <li>Elektronik aletlerin bozulması</li>
            <li>Yanlış anlaşılan mesajlar</li>
            <li>Eski sevgililerin dönüşü</li>
            <li>İmzalanan sözleşmelerde gözden kaçan detaylar</li>
        </ul>

        <h3>Nasıl Fırsata Çevrilir?</h3>
        <p>"Retro" kelimesi "RE" önekiyle başlar: Yeniden (Re-do), Gözden Geçir (Re-view), Onar (Re-pair). Bu dönem yeni başlangıç yapmak yerine, yarım kalan işleri tamamlamak için mükemmeldir. Eski projelerinizi raftan indirin, odanızı toplayın ve içsel muhasebenizi yapın.</p>
        """
    },
    {
        "title": "Ay Fazlarının Psikolojik Etkileri: Yeniay ve Dolunay",
        "slug": "ay-fazlari-ve-etkileri",
        "image_url": "https://images.unsplash.com/photo-1532968961962-8a0cb3a2d4f5?auto=format&fit=crop&w=800&q=80",
        "content": """
        <h3>Ay'ın Döngüsü ve Biz</h3>
        <p>Ay, duygularımızı ve bilinçaltımızı yönetir. Her 29.5 günde bir tamamlanan Ay döngüsü, ruh halimizde belirgin dalgalanmalar yaratır. Bu döngüyle uyumlanmak, enerjimizi daha verimli kullanmamızı sağlar.</p>

        <h3>Yeniay: Tohum Ekme Zamanı</h3>
        <p>Gökyüzünün karanlık olduğu bu evre, başlangıçlar içindir. Enerji düşüktür ancak niyetler güçlüdür. Bu dönemde:</p>
        <ul>
            <li>Dileklerinizi yazın.</li>
            <li>Yeni projelere başlamak için plan yapın (harekete geçmeyin, sadece planlayın).</li>
            <li>İçinize dönün.</li>
        </ul>

        <h3>Dolunay: Hasat ve Bırakma</h3>
        <p>Ay'ın en parlak olduğu bu dönemde duygular tavan yapar. Uykusuzluk ve gerginlik görülebilir. Bu, bir şeylerin tamamlanma ve görünür olma zamanıdır. Artık size hizmet etmeyen alışkanlıkları ve insanları hayatınızdan çıkarmak için en iyi zamandır.</p>
        """
    },
    {
        "title": "Satürn Döngüsü: 29 Yaş Krizi mi, Olgunluk mu?",
        "slug": "saturn-dongusu-nedir",
        "image_url": "https://images.unsplash.com/photo-1614732414444-096e5f1122d5?auto=format&fit=crop&w=800&q=80",
        "content": """
        <h3>Büyümenin Sancılı Eşiği</h3>
        <p>Astrolojide Satürn, zamanın, disiplinin ve karmanın efendisidir. Satürn'ün doğum haritanızdaki konumuna tekrar dönmesi yaklaşık 29.5 yıl sürer. Bu süreç genellikle 28-30 yaşları arasında yaşanır ve "Satürn Döngüsü" olarak adlandırılır.</p>

        <h3>Neden Zorludur?</h3>
        <p>Bu dönemde hayat, sizi yetişkin olmaya zorlar. Çürük yapıları yıkar. Eğer yanlış bir kariyerdeyseniz işten çıkabilirsiniz, yanlış bir ilişkideyseniz evliliğiniz bitebilir. Satürn, temeli sağlam olmayan hiçbir şeyi barındırmaz.</p>

        <h3>Ödülü Nedir?</h3>
        <p>Eğer sorumluluklarınızı alır ve disiplinli olursanız, Satürn döngüsü size kalıcı başarılar getirir. Bu dönemde atılan temeller, hayatınızın geri kalanını şekillendirir. Korkmayın, sadece sorumluluk alın.</p>
        """
    },
    {
        "title": "Elementlerin Dansı: Ateş, Toprak, Hava, Su",
        "slug": "astrolojide-elementler",
        "image_url": "https://images.unsplash.com/photo-1502657877623-f66bf489d236?auto=format&fit=crop&w=800&q=80",
        "content": """
        <h3>Dört Temel Yapı Taşı</h3>
        <p>Astrolojik haritanızı anlamanın en basit yolu, element dengesine bakmaktır. Burçlar dört elemente ayrılır ve her biri farklı bir mizaç yaratır.</p>

        <ul>
            <li><strong>Ateş (Koç, Aslan, Yay):</strong> Tutkulu, inisiyatif alan, enerjik. Ateş fazlalığı öfke problemleri yaratabilir, eksikliği ise motivasyon düşüklüğü.</li>
            <li><strong>Toprak (Boğa, Başak, Oğlak):</strong> Pratik, sağlamcı, maddi dünyaya odaklı. Toprak fazlalığı materyalizm, eksikliği ise köklenememe sorunu yaratır.</li>
            <li><strong>Hava (İkizler, Terazi, Kova):</strong> İletişim, mantık, sosyal bağlar. Hava eksikliği objektif bakmayı zorlaştırır.</li>
            <li><strong>Su (Yengeç, Akrep, Balık):</strong> Duygusal, sezgisel, empatik. Su fazlalığı aşırı hassasiyet demektir.</li>
        </ul>
        <p>Haritanızdaki eksik elementi dengelemek için o elementin doğasına uygun aktiviteler yapabilirsiniz. Örneğin su eksikse, daha fazla yüzmek veya meditasyon yapmak iyi gelebilir.</p>
        """
    },
    {
        "title": "Yükselen Burç Neden Önemlidir?",
        "slug": "yukselen-burc-onemi",
        "image_url": "https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=800&q=80",
        "content": """
        <h3>Maskeniz ve İlk İzleniminiz</h3>
        <p>Güneş burcunuz "kim olduğunuzu" (özünüzü) anlatırken, Yükselen burcunuz "başkalarının sizi nasıl gördüğünü" (maskenizi) anlatır. Haritanın 1. evini yönetir ve fiziksel görüntünüzden, hayatı karşılama şeklinize kadar birçok şeyi belirler.</p>

        <h3>Hayatın Dümeni</h3>
        <p>Astrolojik harita yorumlanırken Yükselen burç referans alınır. Gezegenlerin hangi evlere düştüğü Yükselen burca göre hesaplanır. Bu yüzden günlük burç yorumlarını okurken mutlaka Yükselen burcunuzu da okumalısınız.</p>
        
        <p>Örneğin, Güneş'i Yengeç ama Yükselen'i Koç olan biri, iç dünyasında hassas olsa da dışarıya son derece atılgan ve cesur bir imaj çizer.</p>
        """
    }
]

def populate():
    print("Populating Cosmic Articles...")
    for art in ARTICLES:
        obj, created = BlogPost.objects.update_or_create(
            slug=art['slug'],
            defaults={
                'title': art['title'],
                'content': art['content'],
                'image_url': art['image_url'],
                'is_published': True
            }
        )
        status = "Created" if created else "Updated"
        print(f" - {status}: {art['title']}")
    print("Done! Ensure database is committed if running locally.")

if __name__ == "__main__":
    populate()
