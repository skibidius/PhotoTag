# PhotoTag

Небольшая GPS-камера для Android и iOS. Наводите, снимаете — и на фото сразу
отпечатываются координаты, азимут, высота и время. Готовый снимок можно
приложить к отчёту или сразу отправить с объекта.

*English version — [README.md](README.md).*

## Возможности

- **Встроенная камера** со съёмкой в полном разрешении сенсора
- **Оттиск** с координатами (десятичные, DMS, DDM, UTM, MGRS), азимутом,
  высотой, точностью, датой и временем, адресом, заметкой, автором и
  автоматическим счётчиком снимков
- **Проекты**, чтобы разделять объекты, задачи и заказчиков
- **Русский и английский** интерфейс
- **Работает офлайн** — GPS и определение адреса не требуют сети
- Сохранение в системную галерею и отправка прямо из приложения
- Фокус по тапу, щипок для зума, пресеты объективов, вспышка, сетка и живой
  предпросмотр оттиска

## Скриншоты

<table>
  <tr>
    <td><img src="docs/screenshots/ru/camera.png" width="220" alt="Камера"></td>
    <td><img src="docs/screenshots/ru/watermark.png" width="220" alt="Оттиск"></td>
    <td><img src="docs/screenshots/ru/projects.png" width="220" alt="Проекты"></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/ru/settings.png" width="220" alt="Настройки"></td>
    <td><img src="docs/screenshots/ru/gallery.png" width="220" alt="Галерея"></td>
    <td></td>
  </tr>
</table>

## Запуск

Нужен Flutter 3.24 или новее.

```sh
flutter pub get
flutter run
```

## Сборка

Android:

```sh
flutter build apk --release
```

iOS:

```sh
flutter build ios --no-codesign
```

Обе платформы собираются на каждый push — см. `.github/workflows/ci.yml`.
Отправьте тег вида `v1.0.1`, и артефакты появятся в новом релизе.

## Лицензия

MIT
