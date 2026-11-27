# THE UNCHOSEN

*Her kapı bir hayat. Her hayat bir ihtimal. Her seçim bir vazgeçiş.*

Seçimler, ihtimaller ve hiç yaşanmamış hayatlar üzerine bir oyun.
Godot 4.7 · GDScript · 2D piksel-art · dikey mobil (720×1280) · Android / Windows / Linux / Web

## Oyun

Karanlık bir koridorda beş kapı var. Her kapının ardında başka bir hayat sürüyor.

1. **Kapıya yaklaş.** Altından sızan ışığı görürsün, ardındaki sesleri duyarsın.
2. **Arala.** O hayatın yalnızca o anını görürsün. Geleceğini göremezsin.
3. **İçeri gir** (basılı tut) **ya da vazgeç.** Aralamak seçmek değildir; içeri girmek bir taahhüttür. Vazgeçtiğin kapının ışığı biraz söner. *Bu ihtimal olduğu yerde kalır.*

İçeri girdiğinde Reigns tarzı kartlarla bir hayatı yaşarsın: kartı sola ya da sağa kaydırırsın. Gösterge yok, puan yok, iyi/kötü yok. Kararlar yalnızca sonradan ne olacağını değiştirir. Çoğu zaman sonuç hemen gelmez, bazen başka birinin gözünden gelir.

### 200 TL — ilk hayat

Bir adam kırmızı ışıkta bekliyor. Camın önünde mendil satan bir çocuk var. Adamın cüzdanında tek bir kâğıt para duruyor: 200 TL.

Aynı öğleden sonrayı üç kişinin gözünden yaşarsın: **Adam**, **Çocuk**, **Baba**.

- **Yeniden görülen anlar:** Adamın camı tıklatılır. Aynı an daha sonra çocuğun gözünden, camdaki yansıma olarak geri gelir.
- **Uzaktan duyulan korna:** Arkadaki beyaz kamyonetin kornası marketteki çocuğa da ulaşır. Babanın bölümünde o kamyonetin direksiyonunda kimin olduğunu öğrenirsin.
- **Çizime yansıyan kararlar:** "Üstü senin" demek, çocuğun markette kardeşine çikolata alıp almamasını değiştirir. O çikolata gece çocuk odasında yeniden görünür.
- **Son sahne:** Babanın son kararı oyunun kendisini tekrar eder: oğlunun kapısının altından ışık sızıyor. Aralayacak mısın?

Sayılar:
- **Düğüm:** 43
- **Karar kartı:** 15
- **Farklı oynanış:** 496
- **Farklı son:** 26 kombinasyon
- **Oynanış başına karar:** 6–12

Final **açıktır**: üç kişinin o akşam ne düşündüğünü söyler ama hiçbirini yargılamaz.

> Üçü de aynı 200 lirayı düşündü.
> Hiçbiri aynı şeyi görmedi.

Bir hayatı yaşadıktan sonra o kapı bir daha açılmaz. Diğer kapıların ardındaki anlarda ise o hayatın izleri belirmeye başlar: peronda kurumaya bırakılmış mendil paketleri, bekleme salonunda telefonla konuşan bir adam… (A — *Paralel* katmanı.)

## Çalıştırma

- **Editörde:** Godot 4.7 ile `project.godot` dosyasını açıp **F5**'e bas. Masaüstünde fare dokunmanın yerine geçer; kartlar ← → tuşlarıyla da seçilebilir.
- **Hazır sürümler:** Aşağıdaki "Dışa aktarma" bölümüne bak.

Android geri tuşu bir adım geri götürür; koridorda ya da menüdeyken oyunu kaydedip kapatır. Bir hayatın ortasında geri tuşu oyunu kaydedip kapatır, çünkü bir hayattan yarıda çıkılmaz. Her karardan sonra ve uygulama arka plana alındığında oyun kaydedilir. Menüde **Devam et** kaldığın karttan sürdürür.

## Yapı

```text
THE_UNCHOSEN/
├── scenes/
│   ├── corridor.tscn        menü + koridor (piksel SubViewport) + HUD
│   ├── door.tscn            tek kapı (+ ışık sızıntısı için toplamalı katman)
│   ├── peek_scene.tscn      bir anın çizimi (aralık ve kartlar için ortak)
│   ├── decision_card.tscn   sürüklenen, eğilen karar kartı
│   └── story_scene.tscn     hayatın içi: bölüm, anlatı, karar, son
├── scripts/
│   ├── corridor.gd          durum makinesi: MENU → IDLE → AT_DOOR → PEEKING → ENTERING
│   ├── corridor_world.gd    küçük perspektif çizici (2D çokgenlerle 3D koridor)
│   ├── door.gd              kapı geometrisi, ışık ritmi, kamera bakış noktaları
│   ├── peek_scene.gd        17 prosedürel sahne (bayraklara göre ayrıntı değişir)
│   ├── decision_card.gd     Reigns tarzı sürükle-bırak
│   ├── story_scene.gd       kart akışı, yankı vurgusu, final
│   ├── story_manager.gd     autoload: hikâye JSON yorumlayıcı (bayraklar, varyantlar)
│   ├── game_manager.gd      autoload: bakılan / vazgeçilen / girilen / yaşanan
│   ├── save_manager.gd      autoload: user://save.json, user://settings.json
│   ├── audio_manager.gd     autoload: müzik, ambiyans, efekt, kapı ardı döngüleri
│   ├── door_manager.gd      autoload: data/doors.json
│   └── hold_button.gd, ui_style.gd, world.gd, door_glow.gd
├── data/
│   ├── doors.json           beş kapı: ışık, ses, an, yaşandıktan sonraki izler
│   └── stories/200_tl.json  ilk hayat
├── shaders/                 pixel_dither (Bayer 4×4), vignette
├── assets/audio/            20 ses (tools/synth_audio.py ile üretildi)
├── assets/fonts/            Pixelify Sans, Lora (SIL OFL 1.1, lisansları yanında)
└── tools/
    ├── validate_story.py    bütün oynanışları dolaşır, kopuk/erişilemez düğümü bulur
    ├── synth_audio.py       bütün sesleri sıfırdan sentezler (numpy + scipy + ffmpeg)
    ├── test_logic.gd        başsız mantık testleri (300 rastgele oynanış, kayıt/devam…)
    └── screenshot_tour.gd   oyunu baştan sona oynayıp ekran görüntüsü alır
```

### Yeni bir hayat eklemek

1. `data/stories/<id>.json` yaz. Düğüm tipleri: `chapter`, `text`, `card` (sol/sağ seçenekli), `branch`, `ending`. Koşullar `{"bayrak": değer}` biçiminde yazılır ve hepsinin tutması gerekir; tanımsız bayrak `false` sayılır. `variants` içinde koşulu tutan ilk metin seçilir; geç gelen sonuçlar bu yolla yazılır.
2. `python3 tools/validate_story.py data/stories/<id>.json -v` ile bütün yolları kontrol et.
3. `data/doors.json` içinde ilgili kapıya `"enterable": true` ve `"story": "res://data/stories/<id>.json"` ekle.
4. Kartlardaki `art` anahtarları `scripts/peek_scene.gd` içindeki sahnelere karşılık gelir.

### Görsel dil

- **Dünya:** Koridor 1/3, kart çizimleri 1/4 çözünürlükte çizilir. Ardından `pixel_dither.gdshader` ile Bayer dither uygulanır ve renk sayısı sınırlanır. Sonuç tutarlı bir piksel-art görünümü.
- **Metinler:** Anlatı keskin kalır. Arayüzde Pixelify Sans, okunan metinlerde Lora ve Lora Italic kullanılır.
- **Hazır görsel yok:** Hiçbir hazır görsel kullanılmadı, her şey kodla çiziliyor. Sonradan çizim eklemek için yalnızca `peek_scene.gd` içindeki ilgili fonksiyonu değiştirmek yeterli.

### Ses

Bütün sesler `tools/synth_audio.py` ile sentezlendi; kayıt ya da lisanslı örnek kullanılmadı.

- **Müzik:** Üç parça var: koridor, hayatın içi ve final. Keçe piyano + pad + yankıdan oluşuyor.
- **Ambiyans:** İki döngü var: koridor uğultusu ve yağmur.
- **Kapı ardı sesleri:** Her kapının kendi döngüsü var: trafik, kalem, televizyon, floresan, tren. Kapı kapalıyken boğuk duyulur, aralayınca filtre açılır.
- **Efektler:** On efekt var: adım, kapı, kart, kaydırma, yankı, bölüm geçişi ve diğerleri.

## Test

```bash
python3 tools/validate_story.py data/stories/200_tl.json
godot --headless --path . --script res://tools/test_logic.gd
TOUR_OUT=/tmp/shots xvfb-run godot --path . --rendering-driver opengl3 --resolution 720x1280 --script res://tools/screenshot_tour.gd
```

## Dışa aktarma

`export_presets.cfg` içinde dört ön ayar var: **Android** (arm64 + armv7, minSdk 24, dikey), **Linux**, **Windows**, **Web** (tek iş parçacıklı; özel sunucu başlığı gerektirmez).

```bash
godot --headless --path . --export-release "Linux"   ../export/linux/the_unchosen.x86_64
godot --headless --path . --export-release "Windows" ../export/windows/the_unchosen.exe
godot --headless --path . --export-release "Web"     ../export/web/index.html
# Android: Editör Ayarları > Export > Android > SDK yolu, ve imza anahtarı:
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=... GODOT_ANDROID_KEYSTORE_RELEASE_USER=... \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=... \
godot --headless --path . --export-release "Android" ../export/android/the_unchosen.apk
```

Mağazaya yüklemek için kendi upload anahtarını oluştur (`keytool -genkeypair …`) ve bu anahtarı depoya koyma.

## Lisanslar

- **Fontlar:** Pixelify Sans (© The Pixelify Sans Project Authors) ve Lora (© The Lora Project Authors), ikisi de SIL Open Font License 1.1. Lisans metinleri `assets/fonts/` altında.
- **Diğer her şey:** Kod, ses ve çizimler bu proje için üretildi.
