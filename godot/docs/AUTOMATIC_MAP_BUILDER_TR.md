# Otomatik Harita Kurucu

Yeni bir harita denemek için `data/maps/map_template.json` dosyasını çoğaltıp değerleri değiştir.

## Temel alanlar

- `id`: Haritanın benzersiz adı.
- `base_level`: Başlangıç yoğunluğu ve bitki paleti için temel bölüm.
- `seed`: Aynı değer her zaman aynı dekor dağılımını üretir.
- `terrain_style`: `gentle`, `terraced`, `rolling` veya `hummocks`.
- `terrain_amplitude`: Merkez arazinin tepe ve çukur yüksekliği.
- `paths`: Yol genişliği ve `[x, z]` kontrol noktaları.
- `clearings`: Bina, görev veya dinlenme alanları için bitkisiz daireler.
- `decor_clusters`: Çiçek, kaya, mantar veya odun kümeleri.

Tarif şu şekilde yüklenir:

```gdscript
var recipe := ProceduralMapRecipes.load_json_recipe("res://data/maps/map_template.json")
map_builder.build(recipe, terrain_provider, path_material)
```

Kurucu yolları Terrain3D yüzeyine oturtur, çim/ağaç yasak bölgelerini çıkarır ve dekorlara otomatik LOD uygular.
