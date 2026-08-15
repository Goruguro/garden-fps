# Otomatik Harita Ayarlayıcı

Haritanın arazi, çim ve bitki ayarları artık tek bir profil dosyasında tutulur. Godot içinde `data/maps/profiles` klasörünü açıp istediğin `.tres` dosyasına çift tıkla. Sağdaki **Inspector** panelinde bütün ayarlar başlıklar altında görünür.

## Hazır profiller

- `home_garden.tres`: Ev Bahçesi
- `shaping_estate.tres`: Şekillendirme Malikânesi
- `forest_path.tres`: Orman Yolu
- `giant_garden.tres`: Devasa Bahçe
- `map_profile_template.tres`: Yeni haritalar için başlangıç kopyası

## Neleri değiştirebilirsin?

- **Arazi:** Engebe miktarı, büyük/küçük yüzey dalgaları, sırt kuvveti ve arazi biçimi.
- **Çim Dağılımı:** Toplam yoğunluk, en kısa/en uzun çim, öbek büyüklüğü ve öbek içi detay.
- **Çim Biçimi:** Aynalanma oranı, yatma oranı, maksimum yatış açısı ve sap kıvrımı çeşitliliği.
- **Ağaçlar ve Bitkiler:** Toplam adet, ölçek aralığı ve ağaçlar arasındaki minimum mesafe.
- **Model Kullanım Oranları:** Her `.glb` modelinin biyomda ne sıklıkta seçileceği. `0` modeli kapatır; `2`, `1` değerine göre yaklaşık iki kat seçim ağırlığı verir.

Bir profil değiştiğinde ilgili bölüm yeniden açılınca arazi, LOD çimleri ve LOD bitkileri aynı ayarlardan tekrar üretilir. Yeni bir bitki modeli dağıtım listesine eklendiğinde profil sözlüğüne adı eklenerek oranı ayarlanabilir; profil dışında biyoma özel sayı yazmaya gerek kalmaz.
