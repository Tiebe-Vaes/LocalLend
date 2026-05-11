import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

/// Root widget — wires the GoRouter, theme and DevicePreview together.
class LocalLendApp extends ConsumerWidget {
  const LocalLendApp({super.key});

  /// Builds the MaterialApp with the app-wide router and theme.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'LocalLend',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      routerConfig: router,
    );
  }
}
