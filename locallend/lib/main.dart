import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.init();
    // Best-effort demo seed. Won't crash the app if Firebase isn't set up yet.
    // Remove this call once you have real data in production.
    unawaited(SeedService(FirebaseFirestore.instance).seedIfEmpty());
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const ProviderScope(child: LocalLendApp()),
    ),
  );
}
