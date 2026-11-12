import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/app/bootstrap/app_widget.dart';
import 'package:flutterbase/app/di/provider_overrides.dart';
import 'package:flutterbase/app/di/service_locator.dart';
import 'package:flutterbase/presentation/licenses/app_license_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make the status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Lock to portrait (comment out if not needed)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialise dependency injection
  await setupServiceLocator();

  // Register our own licences with LicenseRegistry
  AppLicenseRegistrar.register();

  // ProviderScope is the Riverpod root. Through overrides, the composition root
  // injects the implementations into the Presentation providers
  // (lib/app/di/provider_overrides.dart).
  runApp(
    ProviderScope(
      overrides: buildProviderOverrides(),
      child: const AppWidget(),
    ),
  );
}
