import 'package:flutter_test/flutter_test.dart';

import 'package:phototag/models/app_settings.dart';

void main() {
  test('photo counters are independent per project', () {
    const AppSettings base = AppSettings();

    AppSettings settings = base.advanceCounter('North wing');
    settings = settings.advanceCounter('Site survey');
    settings = settings.advanceCounter('North wing');

    expect(base.counterFor('North wing'), 1);
    expect(settings.counterFor('North wing'), 3);
    expect(settings.counterFor('Site survey'), 2);
    expect(settings.counterFor(null), 1);
  });

  test('reset only touches the selected project', () {
    final AppSettings settings = const AppSettings()
        .advanceCounter('A')
        .advanceCounter('A')
        .advanceCounter('B')
        .withCounter('A', 1);

    expect(settings.counterFor('A'), 1);
    expect(settings.counterFor('B'), 2);
  });

  test('project counters survive a JSON round-trip', () {
    final AppSettings settings = const AppSettings()
        .advanceCounter('North wing')
        .advanceCounter('North wing');
    final AppSettings restored = AppSettings.fromJson(settings.toJson());

    expect(restored.counterFor('North wing'), 3);
    expect(restored.basemap, settings.basemap);
  });

  test('the legacy global counter migrates to the no-project bucket', () {
    final AppSettings restored = AppSettings.fromJson(<String, dynamic>{
      'counter': 42,
    });

    expect(restored.counterFor(null), 42);
    expect(restored.counterFor('New project'), 1);
  });
}
