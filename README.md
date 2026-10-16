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

## Running

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

Both platforms build on every push — see `.github/workflows/ci.yml`. Push a tag
like `v1.0.1` and the signed artifacts are attached to a new release.

## License

MIT
