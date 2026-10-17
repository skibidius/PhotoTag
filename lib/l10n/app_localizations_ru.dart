// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PhotoTag';

  @override
  String get appTagline => 'GPS-камера с координатами на фото';

  @override
  String get tabCamera => 'Камера';

  @override
  String get tabProjects => 'Проекты';

  @override
  String get tabPhotos => 'Фото';

  @override
  String get cancel => 'Отмена';

  @override
  String get create => 'Создать';

  @override
  String get delete => 'Удалить';

  @override
  String get enable => 'Включить';

  @override
  String get view => 'Открыть';

  @override
  String get share => 'Поделиться';

  @override
  String get cameraNoCamera => 'На этом устройстве нет камеры.';

  @override
  String get cameraPermissionDenied => 'Для съёмки нужен доступ к камере.';

  @override
  String get cameraCannotStart => 'Не удалось запустить камеру.';

  @override
  String get cameraCannotInit => 'Не удалось инициализировать камеру.';

  @override
  String get cameraTryAgain => 'Повторить';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get cameraPhotoSaved => 'Фото сохранено';

  @override
  String get cameraCaptureFailed => 'Не удалось сделать снимок';

  @override
  String get projectRequired => 'Выберите проект, чтобы начать съёмку';

  @override
  String get chooseProject => 'Выбрать';

  @override
  String savingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сохраняем $count фото…',
      many: 'Сохраняем $count фото…',
      few: 'Сохраняем $count фото…',
      one: 'Сохраняем 1 фото…',
    );
    return '$_temp0';
  }

  @override
  String get cameraLocationUnavailable => 'Геолокация недоступна';

  @override
  String get cameraGrid => 'Сетка';

  @override
  String get cameraSettings => 'Настройки';

  @override
  String get cameraSwitch => 'Сменить камеру';

  @override
  String get cameraFlash => 'Вспышка';

  @override
  String get locationOff => 'Геолокация выключена';

  @override
  String get locationNoPermission => 'Нет доступа';

  @override
  String get locationLocating => 'Определяем…';

  @override
  String locationAccuracy(String meters) {
    return '±$meters м';
  }

  @override
  String get project => 'Проект';

  @override
  String get projectNone => 'Без проекта';

  @override
  String get projectNew => 'Новый проект';

  @override
  String get projectName => 'Название проекта';

  @override
  String get projectDeleteTitle => 'Удалить проект?';

  @override
  String projectDeleteBody(String name) {
    return '«$name» будет удалён. Фото сохранят координаты, но больше не будут сгруппированы.';
  }

  @override
  String get projectsEmpty => 'Пока нет проектов';

  @override
  String get projectsEmptyHint =>
      'Группируйте фото по объекту, задаче или заказчику.';

  @override
  String get projectsAllPhotos => 'Все фото';

  @override
  String get exportTitle => 'Экспорт проекта';

  @override
  String get exportOriginal => 'Оригиналы';

  @override
  String get exportWatermarked => 'С вотермарками';

  @override
  String get exportBoth => 'Вотермарки + оригиналы';

  @override
  String get exportEmpty => 'В этом проекте нет фото.';

  @override
  String get exportNoOriginals =>
      'Оригиналы недоступны — включите «Сохранять оригинал» в настройках.';

  @override
  String get exportPreparing => 'Готовим архив…';

  @override
  String get photosAll => 'Фото';

  @override
  String photosAllCount(int count) {
    return 'Фото · $count';
  }

  @override
  String get photosEmpty => 'Пока нет фото';

  @override
  String get photosEmptyHint => 'Здесь появятся ваши снимки.';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
      many: '$count фото',
      few: '$count фото',
      one: '1 фото',
    );
    return '$_temp0';
  }

  @override
  String get photoDeleteTitle => 'Удалить фото?';

  @override
  String get photoDeleteBody => 'Фото и данные о местоположении будут удалены.';

  @override
  String get photoShowOnMap => 'Показать на карте';

  @override
  String photoAccuracy(String meters) {
    return 'Точность ±$meters м';
  }

  @override
  String get mapTitle => 'Местоположение';

  @override
  String get mapStyle => 'Стиль карты';

  @override
  String get mapFitAll => 'Показать все фото';

  @override
  String get mapNoPhotos => 'Нет фото с геометками';

  @override
  String get mapNoPhotosHint =>
      'Снимайте с включённым GPS, чтобы увидеть фото на карте.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionCoordinates => 'Координаты';

  @override
  String get sectionAppearance => 'Вид вотермарки';

  @override
  String get sectionFields => 'Поля вотермарки';

  @override
  String get sectionDetails => 'Детали';

  @override
  String get sectionCamera => 'Камера';

  @override
  String get sectionAbout => 'О приложении';

  @override
  String get coordFormat => 'Формат';

  @override
  String get coordDecimal => 'Десятичные градусы';

  @override
  String get coordDms => 'Градусы · минуты · секунды';

  @override
  String get coordDdm => 'Градусы · десятичные минуты';

  @override
  String get coordUtm => 'UTM';

  @override
  String get coordMgrs => 'MGRS';

  @override
  String get stampStyle => 'Стиль';

  @override
  String get styleCard => 'Карточка';

  @override
  String get styleMinimal => 'Минимум';

  @override
  String get styleOutline => 'Контур';

  @override
  String get stampPosition => 'Положение';

  @override
  String get posTopLeft => 'Сверху слева';

  @override
  String get posTopCenter => 'Сверху по центру';

  @override
  String get posTopRight => 'Сверху справа';

  @override
  String get posBottomLeft => 'Снизу слева';

  @override
  String get posBottomCenter => 'Снизу по центру';

  @override
  String get posBottomRight => 'Снизу справа';

  @override
  String get stampSize => 'Размер';

  @override
  String get sizeSmall => 'S';

  @override
  String get sizeMedium => 'M';

  @override
  String get sizeLarge => 'L';

  @override
  String get stampTone => 'Цвет текста';

  @override
  String get toneLight => 'Светлый';

  @override
  String get toneDark => 'Тёмный';

  @override
  String stampOpacity(int percent) {
    return 'Непрозрачность фона · $percent%';
  }

  @override
  String get fieldDateTime => 'Дата и время';

  @override
  String get fieldCoordinates => 'Координаты';

  @override
  String get fieldBearing => 'Азимут';

  @override
  String get fieldAltitude => 'Высота';

  @override
  String get fieldAccuracy => 'Точность';

  @override
  String get fieldAddress => 'Адрес';

  @override
  String get fieldPhotoNumber => 'Номер фото';

  @override
  String get detailsNote => 'Заметка';

  @override
  String get detailsNoteHint => 'например, осмотр фундамента';

  @override
  String get detailsAuthor => 'Автор';

  @override
  String get detailsAuthorHint => 'Ваше имя или компания';

  @override
  String get detailsCounter => 'Счётчик фото';

  @override
  String detailsNextNumber(String value) {
    return 'Следующее фото — № $value';
  }

  @override
  String get detailsResetCounter => 'Сбросить счётчик';

  @override
  String get cameraGridSetting => 'Сетка третей';

  @override
  String get cameraHud => 'Показ вотермарки';

  @override
  String get cameraMaxResolution => 'Максимальное разрешение';

  @override
  String get cameraMaxResolutionHint => 'Съёмка в полном разрешении сенсора';

  @override
  String get cameraKeepOriginal => 'Сохранять оригинал';

  @override
  String get cameraKeepOriginalHint => 'Также сохранять фото без вотермарки';

  @override
  String get photoQuality => 'Качество фото';

  @override
  String get qualityMaximum => 'Максимальное';

  @override
  String get qualityHigh => 'Высокое';

  @override
  String get qualityBalanced => 'Сбалансированное';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get info => 'Информация';

  @override
  String get about => 'О приложении';

  @override
  String get aboutVersion => 'Версия';

  @override
  String get aboutLicense => 'Лицензия';

  @override
  String get aboutLicenseValue => 'Лицензия MIT';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checkingUpdates => 'Проверяем…';

  @override
  String get upToDate => 'У вас последняя версия';

  @override
  String updateAvailable(String version) {
    return 'Доступна версия $version';
  }

  @override
  String get update => 'Обновить';

  @override
  String stampByAuthor(String author) {
    return 'автор: $author';
  }

  @override
  String stampCounter(String value) {
    return '№ $value';
  }
}
