# Değişiklikler

## 0.3.0 — Duygusal derinlik

Yeni hikâye yok. Mevcut üç hayatın metinlerinden hiçbiri değişmedi ya da kısalmadı. Yeni içerik yalnızca `next` işaretçileri ve koşullu varyantlarla eklendi (`tools/add_depth_03.py`).

- **Ara sahneler** (`"type": "interlude"`): Dokundukça ilerleyen kısa anlar. Yeni bir kontrol yok.
  - 200 TL: markete yürüyüş, arabanın uzaklaşması, eve dönüş.
  - Son Mektup: mektubun yazıldığı gece.
  - Yanlış Kapı: ışığın söndüğü merdiven.
- **Yankılar:** Yaşanmış hayatlar ara sahnelere koşullu anlar ve yeni varyantlar ekliyor. Örnekler: babanın gecesine bir apartman merdiveni, Kurye'nin eline az önce çalınan korna.
- **Sessizlik:**
  - Müzik yalnızca menüde, bölüm açılışlarında ve finalde çalıyor.
  - 12 ağır kararın ardından `pause` süresince sesler kısılıyor ve ekran kararıyor.
- **Kapılar:**
  - Beklemeye kapının ardından ikinci bir ses ipucu ve geçen bir gölge cevap veriyor.
  - Kol, kilit sarsıntısı ve aralığın açılışı ayrı ayrı canlandırılıyor.
- **Yaşayan koridor:**
  - Yaşanmış kapıların önünde iz nesneleri var.
  - Karanlık her hayatla biraz ısınıyor ve sondaki kapı daha belirgin nefes alıyor.
  - "Hafıza" ses katmanları duyuluyor: yağmur, oda, merdiven. Arada uzaktan tek tük sesler geliyor.
- **Görsel:**
  - Yürüyen figürler.
  - Quintic kamera geçişleri ve yürürken baş sallantısı.
  - Kartlar arasında arka planın yumuşak geçişi.
- **Teknik:**
  - Metin, varyant, ara sahne ve final satırı için ortak çözücü (`StoryManager.resolve`).
  - Ortak solma yardımcısı (`scripts/fx.gd`).
  - Denetleyici ara sahneleri ve sessizlik süresini kontrol ediyor.
  - Testler: eski (0.2) kaydın 0.3'te açılması, yankıların yalnızca yaşanmış hayatlarda görünmesi, her hayatta ara sahnelere ulaşılması.

## 0.2.0

- Üç hayat: 200 TL, Son Mektup, Yanlış Kapı.
- Gizli final.
- Meta Open Sound (CC0) ile gerçek piyano ve saha kayıtları; OpenGameArt (CC0) kalem ve parazit sesleri.
- Metin ve görsel cila.

## 0.1.0

- Koridor, beş kapı, aralama ve içeri girme.
- Reigns tarzı kart motoru.
- 200 TL hikâyesi.
