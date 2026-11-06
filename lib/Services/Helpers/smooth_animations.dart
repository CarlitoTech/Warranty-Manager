import 'package:flutter/material.dart';

/// Einheitliche, sehr leichte Fade-Seitenübergänge (GPU-freundlich, ideal für
/// ältere Geräte). Kein Scale, kein Slide – nur Opacity.
Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
  );
}