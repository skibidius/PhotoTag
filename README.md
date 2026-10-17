# PhotoTag

A small GPS camera for Android and iOS. Point, shoot, and the photo comes back
with coordinates, compass direction, altitude and time burned into the corner —
ready to drop into a report or send straight from the field.

*Русская версия — [README.ru.md](README.ru.md).*

## Features

- **In-app camera** that captures at the sensor's full resolution
- **Watermark** with coordinates (decimal, DMS, DDM, UTM, MGRS), bearing,
  altitude, accuracy, date/time, reverse-geocoded address, note, author and an
  automatic photo counter
- **Projects** to keep jobs, sites or clients apart
- **Export** a project to a ZIP archive — originals, watermarked, or both
- **English and Russian** interface
- **Offline first** — GPS and geocoding work without a connection
- Coordinates, altitude and direction are also written into the photo's EXIF
  metadata
- Saves to the system gallery and shares from the app
- Tap to focus, pinch to zoom, lens presets, flash, grid and a live stamp preview

## Screenshots

<table>
  <tr>
    <td><img src="docs/screenshots/en/camera.png" width="220" alt="Camera"></td>
    <td><img src="docs/screenshots/en/watermark.png" width="220" alt="Watermark"></td>
    <td><img src="docs/screenshots/en/projects.png" width="220" alt="Projects"></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/en/settings.png" width="220" alt="Settings"></td>
    <td><img src="docs/screenshots/en/gallery.png" width="220" alt="Gallery"></td>
    <td></td>
  </tr>
</table>

## Install

**Android** — [download the latest APK](https://github.com/skibidius/PhotoTag/releases/latest/download/phototag.apk)
and open it. Allow installation from unknown sources when prompted.

**iOS** — install [AltStore](https://altstore.io/) and add the source in
AltStore → *Sources* → **+**:

```
https://raw.githubusercontent.com/skibidius/PhotoTag/altstore/altstore.json
```

PhotoTag then shows up in AltStore and installs/updates in one tap. If you
prefer, [download the latest IPA](https://github.com/skibidius/PhotoTag/releases/latest/download/phototag.ipa)
and open it with AltStore.

AltStore signs the app with your Apple ID. A free account needs re-signing every
7 days; a paid developer account lasts a year.

## Running from source

You need Flutter 3.24 or newer.

```sh
flutter pub get
flutter run
```

## Building

Android:

```sh
flutter build apk --release
```

iOS:

```sh
flutter build ios --no-codesign
```

## License

MIT
