import 'package:flutter_test/flutter_test.dart';
import 'package:pinspire/models/models.dart';
import 'package:pinspire/services/auth_service.dart';
import 'package:pinspire/services/local_store.dart';
import 'package:pinspire/state/app_state.dart';

void main() {
  late MemoryStore store;
  late AppState state;
  setUp(() async {
    store = MemoryStore();
    state = AppState(store);
    await state.initialize();
    await state.signIn(const UserProfile());
  });
  tearDown(() async {
    await state.flush();
    state.dispose();
  });

  test(
    'save to several boards, remove once, and retain unique profile count',
    () async {
      final a = state.createBoard('A', '', false),
          b = state.createBoard('B', '', true);
      final before = state.savedPins.length;
      state.toggleBoardPin(a, 'p02');
      state.toggleBoardPin(b, 'p02');
      expect(state.savedPins.length, before + 1);
      expect(state.isSaved('p02'), true);
      state.toggleBoardPin(a, 'p02');
      expect(state.isSaved('p02'), true);
      state.deleteBoard(b);
      expect(state.isSaved('p02'), false);
    },
  );
  test('pin deletion cleans board membership, likes and comments', () {
    final id = state.publishPin(
      title: 'Uji',
      description: '',
      image: 'assets/images/beach.jpg',
      category: 'Travel',
      vibe: 'Fresh',
      aspectRatio: .75,
      palette: [0xFF112233],
      boardId: 'b01',
    );
    state.toggleLike(id);
    state.addComment(id, 'Ide menarik');
    expect(state.pinById(id), isNotNull);
    expect(state.boardById('b01')!.pinIds, contains(id));
    state.deletePin(id);
    expect(state.pinById(id), isNull);
    expect(state.boardById('b01')!.pinIds, isNot(contains(id)));
    expect(state.likedIds, isNot(contains(id)));
    expect(state.commentsFor(id), isEmpty);
    // Pin kurasi tidak dapat dihapus melalui API untuk pin milik sendiri.
    state.deletePin('p01');
    expect(state.pinById('p01'), isNotNull);
  });
  test('edits keep the pin id and existing board memberships', () {
    final id = state.publishPin(
      title: 'Sebelum',
      description: '',
      image: 'assets/images/coffee.jpg',
      category: 'Kuliner',
      vibe: 'Warm',
      aspectRatio: .8,
      palette: [0xFF112233],
      boardId: 'b01',
    );
    state.updatePin(id, {'title': 'Sesudah', 'vibe': 'Bold'}, boardId: 'b02');
    expect(state.pinById(id)!.title, 'Sesudah');
    expect(state.pinById(id)!.vibe, 'Bold');
    expect(state.boardById('b01')!.pinIds, contains(id));
    expect(state.boardById('b02')!.pinIds, contains(id));
    expect(state.customPins.length, 1);
  });
  test('search combines terms, category, vibe, and creator following', () {
    final found = state.discover(
      query: 'RUMAH minimalis',
      category: 'Interior',
      vibe: 'Calm',
    );
    expect(found, isNotEmpty);
    expect(
      found.every((p) => p.category == 'Interior' && p.vibe == 'Calm'),
      true,
    );
    state.hidePin(found.first.id);
    expect(
      state
          .discover(query: 'rumah minimalis')
          .any((p) => p.id == found.first.id),
      false,
    );
    expect(
      state.discover(following: true).every((p) => p.authorId == 'nara'),
      true,
    );
    state.showHiddenPins();
    expect(
      state
          .discover(query: 'rumah minimalis')
          .any((p) => p.id == found.first.id),
      true,
    );
    final popular = state.discover(sort: 'Populer');
    expect(popular.first.likes, greaterThanOrEqualTo(popular.last.likes));
  });
  test(
    'board, profile, comments, chats and settings survive restart',
    () async {
      state.toggleLike('p01');
      state.addComment('p01', 'Cocok untuk ruang kerja');
      state.sendMessage('alya', 'Halo dari demo');
      state.setOled(true);
      state.setNotifications(false);
      state.rememberSearch('Interior');
      state.rememberSearch('interior');
      state.createBoard('Board baru', 'Deskripsi', true);
      await state.updateProfile(state.profile.copyWith(name: 'Penguji'));
      await state.flush();
      final restored = AppState(store);
      await restored.initialize();
      expect(restored.signedIn, true);
      expect(restored.profile.name, 'Penguji');
      expect(restored.boards.first.title, 'Board baru');
      expect(restored.likedIds, contains('p01'));
      expect(
        restored.commentsFor('p01').single.text,
        'Cocok untuk ruang kerja',
      );
      expect(restored.messagesFor('alya').last.text, 'Halo dari demo');
      expect(restored.oled, true);
      expect(restored.notificationsEnabled, false);
      expect(restored.recentSearches, ['interior']);
      restored.dispose();
    },
  );
  test(
    'activities are separated between local profiles and demo account',
    () async {
      state.createBoard('Hanya demo', '', false);
      await state.signOut();
      final registered = await state.auth.register(
        'Teman',
        'teman@example.com',
        'Percobaan123!',
      );
      await state.signIn(registered);
      expect(state.boards.any((b) => b.title == 'Hanya demo'), false);
      state.createBoard('Hanya teman', '', false);
      await state.signOut();
      await state.signIn(const UserProfile());
      expect(state.boards.any((b) => b.title == 'Hanya demo'), true);
      expect(state.boards.any((b) => b.title == 'Hanya teman'), false);
    },
  );
  test(
    'local registration validates credentials without storing plaintext',
    () async {
      final profile = await state.auth.register(
        'Akun Uji',
        'uji@example.com',
        'Rahasia123!',
      );
      expect(profile.email, 'uji@example.com');
      final raw = await store.read(AuthService.accountKey);
      expect(raw, isNot(contains('Rahasia123!')));
      expect(
        (await state.auth.login('UJI@example.com', 'Rahasia123!')).name,
        'Akun Uji',
      );
      await expectLater(
        state.auth.login('uji@example.com', 'salah'),
        throwsFormatException,
      );
      await expectLater(
        state.auth.register('Lain', 'lain@example.com', 'Rahasia456!'),
        throwsFormatException,
      );
    },
  );
  test(
    'reset preserves profile, deleting an account signs out and removes it',
    () async {
      final user = await state.auth.register(
        'Uji',
        'uji@example.com',
        'Rahasia123!',
      );
      await state.signIn(user);
      state.createBoard('Sementara', '', false);
      await state.resetData();
      expect(state.profile.name, 'Uji');
      expect(state.boards.length, 3);
      expect(state.boards.any((b) => b.title == 'Sementara'), false);
      await state.deleteLocalAccount();
      expect(state.signedIn, false);
      expect(await store.read(AuthService.accountKey), isNull);
    },
  );
}
