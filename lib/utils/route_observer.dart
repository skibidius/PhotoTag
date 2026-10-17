import 'package:flutter/material.dart';

/// Global observer used to pause the camera when another route covers it.
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();
