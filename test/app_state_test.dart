import 'package:flutter_test/flutter_test.dart';
import 'package:pinspire/models/models.dart';
import 'package:pinspire/services/api_client.dart';
import 'package:pinspire/services/local_store.dart';
import 'package:pinspire/state/app_state.dart';

import 'fake_api.dart';

void main() {
  late FakeApi api;
  late MemoryStore store;
  late AppState state;

  setUp(() async {
    api = FakeApi();
    store = MemoryStore();
    state = AppState(
      store,
      client: ApiClient(baseUrl: 'http://fake/api/v1', transport: api),
    );
    await state.initialize();
    final profile = await state.auth.login('demo@pinspire.test', 'password');
    await state.signIn(profile);
  });

  tearDown(() async {
    await state.flush();
    state.dispose();
  });

  test('login loads feed, boards, saves, following and conversations', () {
    expect(state.signedIn, true);
    expect(state.profile.username, 'iza.creates');
    expect(state.pins, isNotEmpty);
    expect(state.boards, hasLength(1));
    expect(state.savedPins, hasLength(1));
    expect(state.following, hasLength(1));
    expect(state.notifications, hasLength(2));
    expect(state.conversations, hasLength(1));
    expect(state.unreadCount, 1);
  });

  test('likes update optimistically and reconcile with the server', () async {
    expect(state.pinById('2')!.likes, 25);
    await state.toggleLike('2');
    expect(state.likedIds, contains('2'));
    expect(state.pinById('2')!.likes, 26);
    expect(state.likedPins.any((pin) => pin.id == '2'), true);

    await state.toggleLike('2');
    expect(state.likedIds, isNot(contains('2')));
    expect(state.pinById('2')!.likes, 25);
  });

  test('comments load, add, flag ownership, and delete', () async {
    await state.loadComments('1');
    expect(state.commentsFor('1'), hasLength(1));
    expect(state.commentsFor('1').single.mine, false);

    final added = await state.addComment('1', '  Ide menarik  ');
    expect(added, isNotNull);
    expect(added!.text, 'Ide menarik');
    expect(state.commentsFor('1'), hasLength(2));
    expect(state.commentsFor('1').last.mine, true);

    await state.deleteComment(added.id);
    expect(state.commentsFor('1'), hasLength(1));
  });

  test('board creation, save toggles, and deletion follow the API', () async {
    final id = await state.createBoard('Board baru', 'Deskripsi', true);
    expect(id, isNotNull);
    expect(state.boards.any((board) => board.title == 'Board baru'), true);

    await state.toggleBoardPin(id!, '2');
    expect(state.boardById(id)!.pinIds, contains('2'));
    expect(state.isSaved('2'), true);

    await state.toggleBoardPin(id, '2');
    expect(state.boardById(id)!.pinIds, isNot(contains('2')));
    expect(state.isSaved('2'), false);

    await state.deleteBoard(id);
    expect(state.boardById(id), isNull);
  });

  test('publishing, editing, and deleting a pin updates caches', () async {
    final pin = await state.publishPin(
      title: 'Uji',
      description: 'Deskripsi',
      category: 'Travel',
      vibe: 'Fresh',
      palette: const [0xFF112233],
      aspectRatio: .75,
      tags: const ['pantai'],
      imageUrl: 'https://example.com/pin.jpg',
    );
    expect(pin, isNotNull);
    expect(state.customPins.first.id, pin!.id);
    expect(state.boardById('1')!.pinIds, isNot(contains(pin.id)));

    final ok = await state.updatePin(
      pin.id,
      title: 'Sesudah',
      description: 'Deskripsi baru',
      category: 'Travel',
      vibe: 'Bold',
      tags: const ['pantai', 'baru'],
      palette: const [0xFF445566],
    );
    expect(ok, true);
    expect(state.pinById(pin.id)!.title, 'Sesudah');
    expect(state.pinById(pin.id)!.vibe, 'Bold');

    await state.deletePin(pin.id);
    expect(state.pinById(pin.id), isNull);
  });

  test('search and creator pins use the API endpoints', () async {
    final pins = await state.searchPins('pantai');
    expect(pins, isNotEmpty);
    expect(pins.every((pin) => pin.title.contains('akhir pekan')), true);

    final people = await state.searchUsers('nara');
    expect(people, hasLength(1));
    expect(people.single.username, 'nara.studio');

    await state.loadCreatorPins('2');
    expect(state.pinsForCreator('2'), hasLength(2));
  });

  test('messages load, send, and mark the thread as read', () async {
    await state.ensureConversation('2');
    expect(state.messagesFor('2'), hasLength(1));
    expect(state.messagesFor('2').single.mine, false);

    final ok = await state.sendMessage('2', 'Halo dari pengujian');
    expect(ok, true);
    expect(state.messagesFor('2').last.text, 'Halo dari pengujian');
    expect(state.messagesFor('2').last.mine, true);
    expect(state.conversations.first.lastMessage!.text, 'Halo dari pengujian');

    await state.markThreadRead('2');
    expect(state.conversations.first.unreadCount, 0);
  });

  test('profile, password, and account deletion call the API', () async {
    await state.updateProfile(
      state.profile.copyWith(name: 'Penguji', bio: 'Bio baru'),
    );
    expect(state.profile.name, 'Penguji');
    expect(state.profile.bio, 'Bio baru');

    expect(await state.changePassword('password', 'passwordbaru'), true);
    expect(await state.changePassword('salah', 'passwordbaru'), false);

    await state.deleteAccount();
    expect(state.signedIn, false);
    expect(api.accountDeleted, true);
    expect(state.boards, isEmpty);
  });

  test('preferences and recent searches survive a restart', () async {
    state.setOled(true);
    state.setNotifications(false);
    state.updateInterests(['Travel', 'Alam']);
    state.rememberSearch('Interior');
    state.rememberSearch('interior');
    await state.flush();
    await state.signOut();

    final restored = AppState(
      store,
      client: ApiClient(baseUrl: 'http://fake/api/v1', transport: FakeApi()),
    );
    await restored.initialize();
    expect(restored.signedIn, false);
    expect(restored.oled, true);
    expect(restored.notificationsEnabled, false);
    expect(restored.interests, ['Travel', 'Alam']);
    expect(restored.recentSearches, ['interior']);
    restored.dispose();
  });

  test('signing out clears API-backed data', () async {
    await state.signOut();
    expect(state.signedIn, false);
    expect(state.pins, isEmpty);
    expect(state.boards, isEmpty);
    expect(state.conversations, isEmpty);
    expect(state.profile.id, '');
  });

  test('models map API envelopes without demo fallbacks', () {
    final pin = Pin.fromApi({
      'id': 7,
      'title': 'API pin',
      'description': 'Dari server',
      'image_url': 'https://cdn.test/7.jpg',
      'category': 'Travel',
      'vibe': 'Fresh',
      'tags': ['laut'],
      'palette': [0xFF112233],
      'likes_count': 9,
      'source_url': 'https://source.test',
      'created_at': '2026-10-20T10:00:00Z',
      'image_width': 800,
      'image_height': 1000,
      'user': {'id': 2, 'name': 'Nara', 'username': 'nara.studio'},
    });
    expect(pin.id, '7');
    expect(pin.image, 'https://cdn.test/7.jpg');
    expect(pin.authorId, '2');
    expect(pin.likes, 9);
    expect(pin.aspectRatio, .8);

    final notice = AppNotice.fromApi({
      'id': 3,
      'type': 'like',
      'title': 'Suka',
      'body': 'Pin disukai',
      'target_type': 'pin',
      'target_id': 7,
      'image_url': 'https://cdn.test/7.jpg',
      'is_read': true,
      'created_at': '2026-10-20T10:00:00Z',
    });
    expect(notice.targetId, '7');
    expect(notice.isRead, true);
  });
}
