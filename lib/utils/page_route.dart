import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// A page route that uses a Material 3 shared-axis transition (horizontal by
/// default), so navigation feels native and consistent across the app.
Route<T> sharedAxisRoute<T>(
  Widget page, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) =>
        page,
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}

/// A vertical shared-axis route, used for bottom sheets and modals.
Route<T> sharedAxisRouteVertical<T>(Widget page) =>
    sharedAxisRoute<T>(page, type: SharedAxisTransitionType.vertical);
