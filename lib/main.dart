import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'services/local_store.dart';
import 'services/media_service.dart';
import 'state/app_state.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/pins/create_pin_screen.dart';
import 'screens/pins/pin_detail_screen.dart';
import 'screens/boards/boards_screen.dart';
import 'screens/boards/board_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/inbox/inbox_screen.dart';
import 'screens/inbox/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: PColors.surface,
    ),
  );
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], text);
  });
  await MediaService.recoverLostPhoto();
  final state = AppState(PreferencesStore());
  await state.initialize();
  runApp(PinspireApp(state: state));
}

class PinspireApp extends StatelessWidget {
  const PinspireApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pinspire',
        initialRoute: '/',
        // Argumen route hanya berada di memori. Refresh web memulai gate
        // sesi kembali agar URL detail tanpa ID tidak membuka halaman kosong.
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/'),
            builder: (_) => const _Gate(),
          ),
        ],
        theme: PinspireTheme.dark(oled: state.oled),
        scrollBehavior: const _PinspireScrollBehavior(),
        onGenerateRoute: _route,
      ),
    ),
  );
  Route<dynamic> _route(RouteSettings settings) {
    final arg = settings.arguments is String
        ? settings.arguments as String
        : '';
    final Widget page = switch (settings.name) {
      '/' => const _Gate(),
      '/pin' => PinDetailScreen(pinId: arg),
      '/image' => ImageViewerScreen(image: arg),
      '/create' => CreatePinScreen(initialBoardId: arg.isEmpty ? null : arg),
      '/edit-pin' => CreatePinScreen(editPinId: arg),
      '/search' => SearchScreen(initialQuery: arg, standalone: true),
      '/boards' => const BoardsScreen(),
      '/board' => BoardDetailScreen(boardId: arg),
      '/profile' => const ProfileScreen(standalone: true),
      '/creator' => CreatorProfileScreen(creatorId: arg),
      '/edit-profile' => const EditProfileScreen(),
      '/notifications' => const NotificationsScreen(),
      '/chat' => ChatScreen(creatorId: arg),
      '/settings' => const SettingsScreen(),
      '/about' => const AboutScreen(),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Pinspire')),
        body: const EmptyState(
          title: 'Halaman belum ditemukan',
          message: 'Kembali untuk melanjutkan penjelajahan.',
        ),
      ),
    };
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}

class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!state.introSeen) return const OnboardingScreen();
    if (!state.signedIn) return const AuthScreen();
    return ShellScreen(key: ValueKey('shell-${state.profile.email}'));
  }
}

class _PinspireScrollBehavior extends MaterialScrollBehavior {
  const _PinspireScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
