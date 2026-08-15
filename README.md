# Bahçıvan

Godot 4.6 ile hazırlanmış birinci şahıs bahçıvanlık dikey dilimi.

## Oynanış

1. Mira ile konuş ve dere kenarı temizliği işini al.
2. Uzun otlara nişan alıp tırpanla 12 kümeyi biç.
3. Mira'dan 260 ₺ ödemeni al.
4. Atölyeden 250 ₺ karşılığında büyük bahçe makasını satın al.
5. Atölyeyi tekrar kullanarak kondisyon ve bakım değerlerini yenile.

## Kontroller

- `WASD`: Hareket
- `Shift`: Koş
- `Space`: Zıpla
- `C`: Eğil
- `E`: Etkileşim
- `Sol tık`: Aleti kullan
- `Q`: Alet değiştir
- `V`: Birinci/üçüncü şahıs kamera
- `ESC`: Bahçe defteri ve duraklatma

## Mimari

- `scripts/rebuild/game_session.gd`: Yalnız kalıcı kayıt, ekonomi ve ekipman verisi
- `scripts/systems/mission_system.gd`: Görev durum makinesi ve ödül akışı
- `scripts/systems/tool_system.gd`: Alet değiştirme, aşınma, bakım ve satın alma
- `scripts/systems/world_clock.gd`: Oyun saati ve gün ışığı hesabı
- `scripts/systems/weather_controller.gd`: Bulut, yağmur, ses ve ıslak zemin sinyali
- `scripts/components/interaction_target.gd`: NPC ve istasyonlar için ortak etkileşim bileşeni
- `scripts/presentation/garden_hud.gd`: HUD, mesajlar ve duraklatma rehberi
- `scripts/presentation/character_visual.gd`: Harici rigli karakter ve animasyon adaptörü
- `scripts/rebuild/garden_world.gd`: Sistemleri birleştiren dünya koordinatörü ve sahne üretimi
- `scripts/rebuild/player_controller.gd`: Jolt uyumlu hareket, kamera, viewmodel ve ses

Yeni görev, alet veya etkileşim eklemek için dünya koordinatörüne yeni oyun kuralı yazmak yerine ilgili sistem genişletilmelidir.

## Hazır Modüller ve Varlıklar

- Dialogue Manager `v3.10.5` (MIT): dallanan, seçimli NPC konuşmaları
- KayKit Adventurers `1.0` (CC0): Mira ve üçüncü şahıs bahçıvan modeli, 76 animasyon
- Kenney Nature Kit (CC0): ağaçlar, çalılar, çiçekler ve kayalar
- Godot 4.6 yerleşik Jolt Physics: proje ayarında açıkça sabitlenmiştir
- Terrain3D `1.0.2`: dört bölümlü çalışma zamanı arazisi ve ortak yükseklik sağlayıcısı
- GLoot `3.0.2`: sınırsız, prototip tabanlı oyuncu envanteri
- QuestSystem `2.0.2`: mevcut görev akışını yansıtan modüler görev havuzları
- LimboAI `1.8.0`: sonraki NPC davranış ağaçları için Godot 4.6 GDExtension altyapısı
- ProtonScatter `4.2.0`: optimize bitki dağıtımı için editör aracı
- Phantom Camera `0.10`: Godot 4.6 uyumlu kamera üretim aracı
- Simple Asset Placer `2.1.0`: KayKit çevre parçalarını hızlı yerleştirme aracı
- KayKit City Builder ve Medieval Hexagon (CC0): bank, kuyu, ışık, ağaç, çalı ve atölye dekorları

Ayrıntılı kaynak, sürüm ve lisans bilgileri `godot/THIRD_PARTY.md` dosyasındadır.

## Doğrulama

Proje Godot 4.6.2 ile test edilir:

```powershell
Godot_v4.6.2-stable_win64.exe --headless --path godot --script res://tests/smoke_test.gd
Godot_v4.6.2-stable_win64.exe --headless --path godot --script res://tests/terrain_physics_test.gd
Godot_v4.6.2-stable_win64.exe --headless --path godot --script res://tests/asset_validation.gd
```

`smoke_test.gd` Terrain3D, GLoot, QuestSystem, KayKit, görev, ödeme, yükseltme, kayıt ve HUD akışını; `terrain_physics_test.gd` oyuncunun Jolt üzerinde araziye oturmasını; `asset_validation.gd` ise rigli modeller ile animasyon kütüphanelerini doğrular.

## Varlık Lisansı

Üçüncü taraf lisanslarının kopyaları ilgili varlık klasörlerinde ve `godot/THIRD_PARTY.md` içinde tutulur.
