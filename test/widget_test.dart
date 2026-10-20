import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinspire/main.dart';
import 'package:pinspire/services/api_client.dart';
import 'package:pinspire/services/local_store.dart';
import 'package:pinspire/state/app_state.dart';

import 'fake_api.dart';

Future<AppState> demoApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final state = AppState(
    MemoryStore(),
    client: ApiClient(baseUrl: 'http://fake/api/v1', transport: FakeApi()),
  );
  await state.initialize();
  final profile = await state.auth.login('demo@pinspire.test', 'password');
  await state.signIn(profile);
  await tester.pumpWidget(PinspireApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
  });

  testWidgets('main navigation, search, and pin detail work at phone width', (
    tester,
  ) async {
    final state = await demoApp(tester);
    expect(find.text('Sedikit ide,\nbanyak kemungkinan.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Jelajah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'pantai');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('hasil untuk'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('@iza.creates'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('pinspire').first);
    Navigator.pushNamed(context, '/pin', arguments: '1');
    await tester.pumpAndSettle();
    expect(find.text('Inspirasi, lebih dekat'), findsOneWidget);

    final like = find.byTooltip('Suka pin');
    await tester.ensureVisible(like);
    await tester.tap(like);
    await tester.pumpAndSettle();
    expect(state.likedIds, contains('1'));
    expect(tester.takeException(), isNull);

    await state.flush();
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  for (final size in [const Size(320, 740), const Size(1440, 1000)]) {
    testWidgets(
      'home and create form have no layout exceptions at ${size.width}',
      (tester) async {
        final state = await demoApp(tester, size: size);
        expect(tester.takeException(), isNull);
        final context = tester.element(find.text('pinspire').first);
        Navigator.pushNamed(context, '/create');
        await tester.pumpAndSettle();
        expect(find.text('Awali dengan sebuah gambar'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await state.flush();
        await tester.pumpWidget(const SizedBox());
        state.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  }

  testWidgets('a refreshed detail route starts home with API data', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/pin';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final state = await demoApp(tester);
    expect(find.text('Sedikit ide,\nbanyak kemungkinan.'), findsOneWidget);
    expect(find.text('Pin tidak ditemukan'), findsNothing);
    expect(state.savedPins.length, 1);
    expect(tester.takeException(), isNull);
    await state.flush();
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('onboarding can advance to API login', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final state = AppState(
      MemoryStore(),
      client: ApiClient(baseUrl: 'http://fake/api/v1', transport: FakeApi()),
    );
    await state.initialize();
    await tester.pumpWidget(PinspireApp(state: state));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mulai temukan inspirasi'));
    await tester.tap(find.text('Mulai temukan inspirasi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lanjut dengan 3 minat'));
    await tester.tap(find.text('Lanjut dengan 3 minat'));
    await tester.pumpAndSettle();
    expect(find.text('Jelajahi dengan akun demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await state.flush();
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
