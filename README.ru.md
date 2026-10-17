# PhotoTag

Небольшая GPS-камера для Android и iOS. Наводите, снимаете — и на фото сразу
отпечатываются координаты, азимут, высота и время. Готовый снимок можно
приложить к отчёту или сразу отправить с объекта.

*English version — [README.md](README.md).*

## Возможности

- **Встроенная камера** со съёмкой в полном разрешении сенсора
- **Вотермарка** с координатами (десятичные, DMS, DDM, UTM, MGRS), азимутом,
  высотой, точностью, датой и временем, адресом, заметкой, автором и
  автоматическим счётчиком снимков
- **Проекты**, чтобы разделять объекты, задачи и заказчиков
- **Экспорт** проекта в ZIP — оригиналы, вотермарки или всё вместе
- **Русский и английский** интерфейс
- **Работает офлайн** — GPS и определение адреса не требуют сети
- Координаты, высота и направление также записываются в EXIF-метаданные
  снимка
- Сохранение в системную галерею и отправка прямо из приложения
- Фокус по тапу, щипок для зума, пресеты объективов, вспышка, сетка и живой
  предпросмотр вотермарки

## Скриншоты

<table>
  <tr>
    <td><img src="docs/screenshots/ru/camera.png" width="220" alt="Камера"></td>
    <td><img src="docs/screenshots/ru/watermark.png" width="220" alt="Вотермарка"></td>
    <td><img src="docs/screenshots/ru/projects.png" width="220" alt="Проекты"></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/ru/settings.png" width="220" alt="Настройки"></td>
    <td><img src="docs/screenshots/ru/gallery.png" width="220" alt="Галерея"></td>
    <td></td>
  </tr>
</table>

## Установка

**Android** — [скачайте последний APK](https://github.com/skibidius/PhotoTag/releases/latest/download/phototag.apk)
и откройте его. При необходимости разрешите установку из неизвестных источников.

**iOS** — [скачайте последний IPA](https://github.com/skibidius/PhotoTag/releases/latest/download/phototag.ipa)
и установите через [AltStore](https://altstore.io/):

1. Установите AltStore на iPhone или iPad и войдите под своим Apple ID.
2. Сохраните `phototag.ipa` в приложении «Файлы».
3. Откройте AltStore → *My Apps* → **+** и выберите IPA (или поделитесь файлом
   в AltStore).
4. AltStore подпишет приложение вашим аккаунтом. С бесплатным Apple ID подпись
   нужно обновлять раз в 7 дней; с платным — раз в год.

## Запуск из исходников

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

## Лицензия

MIT
