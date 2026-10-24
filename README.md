# PhotoTag

A small GPS camera for Android and iOS. Point, shoot, and the photo comes back
with coordinates, compass direction, altitude and time burned into the corner —
ready to drop into a report or send straight from the field.

*Русская версия — [README.ru.md](README.ru.md).*

## Features

- **In-app camera** with selectable quality, pinch-to-zoom and hardware lens
  switching where the platform exposes the lenses
- **Watermark** with coordinates (decimal, DMS, DDM, UTM, MGRS), bearing,
  altitude, accuracy, date/time, reverse-geocoded address, note, author and a
  separate photo counter for every project
- **Projects** to keep jobs, sites or clients apart
- **Export** a project to a ZIP archive — originals, watermarked, or both
- **English and Russian** interface
- **Background queue** — keep shooting while photos are watermarked
- **Offline first** — GPS and geocoding work without a connection
- Coordinates, altitude, direction, timestamp, project, note, author and the
  photo counter are also written into the EXIF metadata (including Unicode
  fields), not just burned into the pixels
- Saves to the system gallery and shares from the app
- In-app update check
- Tap to focus, pinch to zoom, lens and zoom presets, flash, grid and a live
  stamp preview
- **Google Photos-style gallery** — swipe sideways to browse, down to close,
  swipe up or tap for info
- **Project map** — every geotagged photo of a project on one map, with a camera
  direction cone, a photo preview card and switchable Yandex, Google and OSM
  basemaps (the choice is remembered)

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

**iOS** — install [AltStore](https://altstore.io/) and either tap
**[Add PhotoTag to AltStore](https://altstore.io/source/skibidius.github.io/PhotoTag/altstore.json?app=com.phototag)**,
or add the source manually in AltStore → *Sources* → **+**:

<https://skibidius.github.io/PhotoTag/altstore.json>

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

## RuStore

Every `v*` tag builds two Android APKs. The regular one checks GitHub Releases;
the `phototag-rustore.apk` build uses `--dart-define=PHOTOTAG_STORE=rustore` and
checks the published version in the RuStore catalog, opening RuStore to update.
Both files are attached to the GitHub release — publishing to RuStore itself is
manual: upload `phototag-rustore.apk` in the RuStore Console.

The two builds never cross-prompt: RuStore users update through RuStore,
GitHub/AltStore users through GitHub Releases.

## Support

If PhotoTag helps you, you can [support the project](https://pay.cloudtips.ru/p/3dc66105).

## License

MIT
