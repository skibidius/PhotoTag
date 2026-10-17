import 'package:flutter/material.dart';

/// A page route that uses the platform's native transition (configured in the
/// theme via [PageTransitionsTheme]). Native transitions avoid the white flash
/// a custom fade-in route can cause and support predictive back on Android.
Route<T> sharedAxisRoute<T>(Widget page) {
  return MaterialPageRoute<T>(builder: (BuildContext context) => page);
}

/// A transparent, fading route used for the full-screen photo viewer so the
/// grid stays visible behind it while the photo is dragged down to dismiss.
Route<T> photoViewerRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) =>
        page,
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
