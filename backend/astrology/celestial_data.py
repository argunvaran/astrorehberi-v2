
# CELESTIAL EVENTS DATA
# Bu dosya Göksel Olaylar modülü için detaylı metinleri içerir.

HOUSE_THEMES = {
    "en": {
        1: "Self, Identity, Physical Body, New Beginnings",
        2: "Money, Values, Possessions, Self-Worth",
        3: "Communication, Siblings, Short Trips, Mental Activity",
        4: "Home, Family, Roots, Inner Security",
        5: "Creativity, Romance, Children, Pleasure, Speculation",
        6: "Health, Daily Routine, Service, Work Environment",
        7: "Relationships, Marriage, Partnerships, Open Enemies",
        8: "Transformation, Shared Resources, Intimacy, Death/Rebirth",
        9: "Philosophy, Higher Education, Travel, Belief Systems",
        10: "Career, Public Reputation, Authority, Life Goal",
        11: "Friends, Social Circles, Hopes, Future Goals",
        12: "Subconscious, Hidden Things, Spirituality, Isolation"
    },
    "tr": {
        1: "Benlik, Kimlik, Dış Görünüş ve Yeni Başlangıçlar",
        2: "Para, Maddi Değerler, Özdeğer ve Kaynaklar",
        3: "İletişim, Yakın Çevre, Kardeşler ve Zihinsel Faaliyetler",
        4: "Ev, Aile, Kökler ve İçsel Güvenlik",
        5: "Aşk, Yaratıcılık, Çocuklar ve Hayattan Keyif Alma",
        6: "Sağlık, Günlük Rutinler, Hizmet ve Çalışma Ortamı",
        7: "İkili İlişkiler, Evlilik, Ortaklıklar ve Açık Düşmanlar",
        8: "Dönüşüm, Ortak Paralar, Krizler ve Yeniden Doğuş",
        9: "Hayat Felsefesi, Yurt Dışı, Akademik Kariyer ve İnançlar",
        10: "Kariyer, Toplumsal Statü, Hedefler ve Otorite Figürleri",
        11: "Sosyal Çevre, Arkadaşlar, Gelecek Planları ve Umutlar",
        12: "Bilinçaltı, Gizli Konular, Ruhsallık ve İnziva"
    }
}

EVENT_DESCRIPTIONS = {
    "tr": {
        "New Moon": {
            "title": "Yeni Ay Enerjisi",
            "general": "Yeni Aylar, tohum ekme zamanıdır. Gökyüzü karanlıktır ve bu, bilinçaltımızdaki niyetleri evrene fısıldamak için en uygun zamandır. Eski bir döngü kapandı, şimdi yeni bir sayfa açılıyor.",
            "impact_template": "Bu Yeni Ay, senin haritanın **{house}. Ev** alanında gerçekleşiyor. Bu, **{theme}** konularında taze bir başlangıç yapman gerektiğine işaret ediyor. Bu alanda uzun süredir beklettiğin adımları atmak, niyetlerde bulunmak ve yeni projelere başlamak için kozmik bir destek alıyorsun."
        },
        "Full Moon": {
            "title": "Dolunay Enerjisi",
            "general": "Dolunaylar, hasat ve tamamlanma zamanıdır. Güneş ve Ay karşı karşıyadır, bu da hayatımızdaki dengesizlikleri görünür kılar. Gizli kalan her şey aydınlanır. Artık sana hizmet etmeyen şeyleri bırakma vaktidir.",
            "impact_template": "Bu Dolunay, senin haritanın **{house}. Ev** alanını aydınlatıyor. **{theme}** konularında bir farkındalık, bir sonuçlanma veya bir kriz yaşayabilirsin. Bu alanda tamamlanması gereken bir süreç sona eriyor olabilir. Eğer bir şeyler bitiyorsa, onun gitmesine izin ver."
        },
        "Eclipse": {
            "title": "Tutulma (Kadersel Dönemeç)",
            "general": "Tutulmalar, Astroloji'nin 'Joker' kartlarıdır. Olayları hızlandırır ve kadersel değişimleri tetikler. Normalde aylar sürecek değişimler tutulma zamanlarında birkaç güne sığabilir. Kontrol bizde değildir, sistem devreye girer.",
            "impact_template": "Bu Tutulma, haritanın **{house}. Ev** aksında gerçekleşiyor. Bu son derece kadersel bir etki. **{theme}** konularında önümüzdeki 6 ay boyunca büyük değişimlere hazırlıklı ol. Bu alanda kontrolü bırakmalı ve hayatın seni götürdüğü yöne güvenmelisin. Beklenmedik kapılar açılabilir veya kapanabilir."
        },
        "Retrograde": {
            "title": "Retro (Geri Hareket)",
            "general": "Gezegenler geri giderken enerji içe döner. Dış dünyada ilerlemek yerine, geçmişi gözden geçirmek, tamir etmek ve yeniden değerlendirmek gerekir.",
            "impact_template": "Şu anda haritanın **{house}. Ev** alanında bir Retro süreci yaşanıyor. **{theme}** konularında işler yavaşlayabilir veya geçmiş konular tekrar önüne gelebilir. Bu bir hata değil, bir düzeltme fırsatıdır. Eski defterleri kapatmadan yenisini açma."
        }
    },
    "en": {
        "New Moon": {
            "title": "New Moon Energy",
            "general": "New Moons are a time for planting seeds. The sky is dark, making it the perfect time to whisper your intentions to the universe.",
            "impact_template": "This New Moon falls in your **{house} House**. It signals a fresh start regarding **{theme}**. You have cosmic support to take new steps in this area."
        },
        "Full Moon": {
            "title": "Full Moon Energy",
            "general": "Full Moons are times of harvest and completion. The Sun and Moon are opposite, highlighting imbalances.",
            "impact_template": "This Full Moon illuminates your **{house} House**. You may experience a culmination or realization regarding **{theme}**. It is time to release what no longer serves you."
        },
        "Eclipse": {
            "title": "The Eclipse (Fated Turn)",
            "general": "Eclipses are the 'Wild Cards' of astrology. They accelerate events and trigger fated changes.",
            "impact_template": "This Eclipse happens in your **{house} House**. Expect major shifts regarding **{theme}** over the next 6 months. Control is minimal here; trust the flow."
        },
        "Retrograde": {
            "title": "Retrograde Motion",
            "general": "When planets retrograde, energy turns inward. It's time to review, repair, and reconsider.",
            "impact_template": "A Retrograde is happening in your **{house} House**. Matters related to **{theme}** might slow down. It's an opportunity to fix the past."
        }
    }
}
