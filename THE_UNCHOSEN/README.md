# THE UNCHOSEN — Prototip 0.1

*Her kapı bir hayat. Her hayat bir ihtimal. Her seçim bir vazgeçiş.*

Godot 4.7 · GDScript · 2D · dikey mobil (720×1280, `canvas_items` + `expand`) · GL Compatibility

## Bu sürümde olanlar

Yalnızca koridor ve kapı etkileşimi var. Hikâye/karar sistemi henüz yok.

1. **Oyunu aç.** Karanlıkta başlık ve üç satır görünür, kapıların ışıkları tek tek yanar. Dokunursan giriş atlanır.
2. **Beş kapı aynı koridorda görünür.** Kapılar sol duvarda, sağ duvarda ve koridorun sonunda. Her kapının altından farklı renkte ve ritimde ışık sızar.
3. **Bir kapıya dokun, ona yaklaş.** Kamera kapının önüne yürür. Kapının ardından gelen sesler yazıyla verilir (ses dosyaları sonra eklenecek).
4. **Arala.** Kapı içeri doğru aralanır, kamera aralığa eğilir. Aralıktan o hayatın *yalnızca o anı* görünür. Gelecek gösterilmez.
5. **İçeri gir veya vazgeç.**
   - **Vazgeç:** kapı kapanır, koridora dönersin. *"Bu ihtimal olduğu yerde kalıyor."* Her vazgeçişte o kapının ışığı biraz söner.
   - **İçeri gir:** yalnızca *200 TL* kapısında var ve **basılı tutmak** gerekiyor. Aralamak bir dokunuştur, içeri girmek bir taahhüt. Kapı tamamen açılır, ışığa geçilir ve hayatın eşiğindeki ekran gelir.
   - Diğer dört kapı için: *"Kapı bundan fazla açılmıyor."*

Geri tuşu (Android) ve `Esc` bir adım geri götürür: kapının önündeysen koridora, aralıktaysan vazgeçmeye.

## Çalıştırma

Godot 4.7 ile `THE_UNCHOSEN/project.godot` dosyasını açıp **F5** ile çalıştır. Masaüstünde pencere 432×768 açılır, fare dokunmanın yerine geçer.

## Yapı

```text
THE_UNCHOSEN/
├── scenes/
│   ├── corridor.tscn      ana sahne: koridor, kapılar, HUD, aralık görünümü
│   ├── door.tscn          tek kapı (+ ışık sızıntısı için toplamalı katman)
│   ├── peek_scene.tscn    aralıktan görünen an
│   └── story_scene.tscn   hayatın eşiği (karar kartları burada başlayacak)
├── scripts/
│   ├── corridor.gd        durum makinesi + küçük perspektif çizici
│   ├── door.gd            kapı geometrisi, ışık ritmi, kamera bakış noktaları
│   ├── peek_scene.gd      beş anın prosedürel çizimleri
│   ├── game_manager.gd    autoload: bakılan/vazgeçilen/girilen kapılar
│   ├── door_manager.gd    autoload: data/doors.json okuyucu
│   ├── hold_button.gd     basılı tutma gerektiren buton
│   ├── story_scene.gd, door_glow.gd, ui_style.gd, world.gd
├── data/doors.json        kapıların tüm içeriği (metin, renk, ışık ritmi, sahne)
├── shaders/vignette.gdshader
└── tools/screenshot_tour.gd   geliştirici aracı: tüm akışı oynatıp ekran görüntüsü alır
```

**Kapılar koda gömülü değil.** Kapı eklemek, metin değiştirmek ya da bir kapıyı girilebilir yapmak için `data/doors.json` dosyasını düzenlemek yeterli:

| Alan | Anlamı |
| --- | --- |
| `wall` / `z` | `left`, `right`, `end`; koridordaki derinlik (metre) |
| `light_color` / `light_pattern` | `traffic`, `candle`, `tv`, `fluorescent`, `passing` |
| `sound` | Kapının önünde duyulan sesler (şimdilik altyazı olarak) |
| `peek_style` / `moment` | Aralıktan görünen an ve onu anlatan cümle |
| `enterable` / `entry_text` | İçeri girilebilir mi; girince ilk cümle |

**Neden 3D değil?** Koridor gerçek bir 3D sahne değil, 2D çokgenlerle çizilen bir kutu. `corridor.gd` içindeki küçük izdüşüm sayesinde kamera kapıya gerçekten yürüyebiliyor, dönebiliyor ve aralıktan eğilebiliyor. Üstelik hiç 3D varlık ya da çizim gerekmiyor. Aralıktan görünen an bir `SubViewport` içinde çiziliyor ve kapı boşluğuna doku olarak uygulanıyor. Sonradan `assets/backgrounds/` altına çizilmiş görseller konduğunda yalnızca `peek_scene.gd` değişecek.

**Bilinçli olarak yok:** ahlak puanı, gösterge, envanter. `GameManager` yalnızca ne olduğunu kaydediyor: kaç kez bakıldı, kaç kez vazgeçildi, içeri girildi mi.

## Sıradaki adım (Aşama 2–3)

- `story_manager.gd` + `data/stories/200_tl.json`: Reigns tarzı iki seçenekli kartlar, sağa/sola kaydırma.
- Gecikmeli sonuçlar: kararlar bayrak olarak saklanacak ve birkaç kart sonra ya da başka bir karakterin gözünden geri dönecek.
- Adam / çocuk / baba bakış açıları.
- `save_manager.gd`: `GameManager.door_states` ve hikâye bayraklarının `user://` altına yazılması.
