import 'package:flutter/material.dart';

/// A page route that uses the platform's native transition (configured in the
/// theme via [PageTransitionsTheme]). Native transitions avoid the white flash
/// a custom fade-in route can cause and support predictive back on Android.
Route<T> sharedAxisRoute<T>(Widget page) {
  return MaterialPageRoute<T>(builder: (BuildContext context) => page);
}
