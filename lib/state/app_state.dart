import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store) : auth = AuthService(store);
  final LocalStore store;
  final AuthService auth;
  static const _sessionKey = 'pinspire.session.v1';
  bool ready = false, signedIn = false, introSeen = false;
  bool oled = false, notificationsEnabled = true;
  String? storageError;
  UserProfile profile = const UserProfile();
  List<String> interests = ['Interior', 'Travel', 'Kreatif'];
  List<Pin> customPins = [];
  List<Board> boards = initialBoards();
  Set<String> likedIds = {},
      followedIds = {'nara'},
      hiddenIds = {},
      readNotifications = {},
      readThreads = {};
  List<String> recentSearches = [];
  List<PinComment> comments = [];
  Map<String, List<ChatMessage>> chats = {};
  Future<void> _writeQueue = Future.value();
  int _idCounter = 0;
  String get _dataKey =>
      'pinspire.data.v1.${base64UrlEncode(utf8.encode(profile.email.toLowerCase()))}';
  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
  List<Pin> get pins => [...customPins, ...demoPins];
  List<Pin> get savedPins => pins.where((p) => isSaved(p.id)).toList();
  List<Pin> get likedPins =>
      pins.where((p) => likedIds.contains(p.id)).toList();
  int get unreadCount => notificationsEnabled
      ? notificationItems
            .where((n) => !readNotifications.contains(n['id']))
            .length
      : 0;
  Pin? pinById(String id) {
    for (final p in pins) {
      if (p.id == id) return p;
    }
    return null;
  }

  Board? boardById(String id) {
    for (final b in boards) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Pin> pinsInBoard(Board board) =>
      board.pinIds.map(pinById).whereType<Pin>().toList();
  Creator creator(String id) => id == 'me'
      ? Creator(
          id: 'me',
          name: profile.name,
          username: profile.username,
          bio: profile.bio,
          avatar: profile.avatar,
          color: 0xFFFF806B,
        )
      : demoCreators.firstWhere(
          (c) => c.id == id,
          orElse: () => demoCreators.first,
        );
  bool isSaved(String id) => boards.any((b) => b.pinIds.contains(id));
  List<PinComment> commentsFor(String id) =>
      comments.where((c) => c.pinId == id).toList();
  List<ChatMessage> messagesFor(String id) => chats[id] ?? [];
  String _now() => DateTime.now().toIso8601String();

  List<Map<String, String>> get notificationItems => [
    {
      'id': 'welcome',
      'title': 'Selamat datang di Pinspire',
      'body': 'Mulai dari satu ide. Simpan pin pertamamu hari ini.',
      'type': 'welcome',
      'target': 'p01',
      'image': 'assets/images/quiet_corner.jpg',
    },
    {
      'id': 'curated',
      'title': 'Pilihan untuk ruang yang lebih tenang',
      'body': 'Koleksi interior pilihan sudah siap kamu jelajahi.',
      'type': 'pin',
      'target': 'p05',
      'image': 'assets/images/workspace.jpg',
    },
    {
      'id': 'challenge',
      'title': 'Satu vibe, banyak kemungkinan',
      'body': 'Coba filter Fresh untuk menemukan palet baru.',
      'type': 'pin',
      'target': 'p14',
      'image': 'assets/images/flowers.jpg',
    },
  ];

  Future<void> initialize() async {
    try {
      final raw = await store.read(_sessionKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        introSeen = j['introSeen'] as bool? ?? false;
        signedIn = j['signedIn'] as bool? ?? false;
        interests = List<String>.from(j['interests'] as List? ?? interests);
        if (j['profile'] != null) {
          profile = UserProfile.fromJson(j['profile'] as Map<String, dynamic>);
        }
      }
      if (signedIn) await _loadUser();
    } catch (_) {
      signedIn = false;
      storageError = 'Data lokal tidak dapat dibaca. Silakan masuk kembali.';
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    customPins = [];
    boards = initialBoards();
    likedIds = {};
    followedIds = {'nara'};
    hiddenIds = {};
    readNotifications = {};
    recentSearches = [];
    comments = [];
    oled = false;
    notificationsEnabled = true;
    readThreads = {};
    chats = {
      'alya': [
        ChatMessage(
          id: 'seed1',
          text: 'Halo! Aku mengumpulkan referensi warna hangat. Kamu sedang bikin board apa?',
          mine: false,
          createdAt: _now(),
        ),
      ],
      'nara': [
        ChatMessage(
          id: 'seed2',
          text: 'Selamat datang! Coba lihat koleksi sudut kerja yang baru.',
          mine: false,
          createdAt: _now(),
        ),
      ],
    };
    final raw = await store.read(_dataKey);
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    profile = UserProfile.fromJson(j['profile'] as Map<String, dynamic>);
    boards = (j['boards'] as List)
        .map((e) => Board.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    customPins = (j['customPins'] as List? ?? [])
        .map((e) => Pin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    likedIds = Set<String>.from(j['likedIds'] as List? ?? []);
    followedIds = Set<String>.from(j['followedIds'] as List? ?? []);
    hiddenIds = Set<String>.from(j['hiddenIds'] as List? ?? []);
    readNotifications = Set<String>.from(j['readNotifications'] as List? ?? []);
    readThreads = Set<String>.from(j['readThreads'] as List? ?? []);
    recentSearches = List<String>.from(j['recentSearches'] as List? ?? []);
    interests = List<String>.from(j['interests'] as List? ?? interests);
    comments = (j['comments'] as List? ?? [])
        .map((e) => PinComment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    oled = j['oled'] as bool? ?? false;
    notificationsEnabled = j['notificationsEnabled'] as bool? ?? true;
    chats = (j['chats'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(
        key,
        (value as List)
            .map(
              (e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      ),
    );
  }

  Map<String, dynamic> _userJson() => {
    'schema': 1,
    'profile': profile.toJson(),
    'customPins': customPins.map((e) => e.toJson()).toList(),
    'boards': boards.map((e) => e.toJson()).toList(),
    'likedIds': likedIds.toList(),
    'followedIds': followedIds.toList(),
    'hiddenIds': hiddenIds.toList(),
    'readNotifications': readNotifications.toList(),
    'readThreads': readThreads.toList(),
    'recentSearches': recentSearches,
    'comments': comments.map((e) => e.toJson()).toList(),
    'chats': chats.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    ),
    'oled': oled,
    'notificationsEnabled': notificationsEnabled,
    'interests': interests,
  };
  Map<String, dynamic> _sessionJson() => {
    'introSeen': introSeen,
    'signedIn': signedIn,
    'profile': profile.toJson(),
    'interests': interests,
  };

  Future<void> flush() => _writeQueue;
  void _commit() {
    notifyListeners();
    final key = _dataKey;
    final data = jsonEncode(_userJson());
    final session = jsonEncode(_sessionJson());
    _writeQueue = _writeQueue
        .then((_) async {
          await store.write(key, data);
          await store.write(_sessionKey, session);
          storageError = null;
        })
        .catchError((Object error) {
          storageError =
              'Perubahan belum tersimpan. Ruang penyimpanan mungkin penuh.';
          notifyListeners();
        });
  }

  Future<void> finishIntro(List<String> selected) async {
    interests = selected.isEmpty
        ? ['Interior', 'Travel', 'Kreatif']
        : List.of(selected);
    introSeen = true;
    await store.write(_sessionKey, jsonEncode(_sessionJson()));
    notifyListeners();
  }

  Future<void> signIn(UserProfile user) async {
    await flush();
    profile = user;
    await _loadUser();
    signedIn = true;
    introSeen = true;
    _commit();
    await flush();
  }

  Future<void> signOut() async {
    await flush();
    signedIn = false;
    await store.write(_sessionKey, jsonEncode(_sessionJson()));
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    profile = updated;
    await auth.updateProfile(updated);
    _commit();
    await flush();
  }

  List<Pin> discover({
    String category = 'Semua',
    String vibe = 'Semua',
    bool following = false,
    String query = '',
    String sort = 'Relevan',
  }) {
    final q = query.trim().toLowerCase();
    final result = pins.where((p) {
      final haystack =
          '${p.title} ${p.description} ${p.tags.join(' ')} ${p.category} ${creator(p.authorId).name}'
              .toLowerCase();
      return !hiddenIds.contains(p.id) &&
          (category == 'Semua' || p.category == category) &&
          (vibe == 'Semua' || p.vibe == vibe) &&
          (!following || followedIds.contains(p.authorId)) &&
          (q.isEmpty || q.split(RegExp(r'\s+')).every(haystack.contains));
    }).toList();
    if (sort == 'Populer') {
      result.sort(
        (a, b) => (b.likes + (likedIds.contains(b.id) ? 1 : 0)).compareTo(
          a.likes + (likedIds.contains(a.id) ? 1 : 0),
        ),
      );
    } else if (sort == 'Terbaru') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Stabil: kategori minat lebih dulu, kemudian urutan kurasi tetap.
      result.sort((a, b) {
        final ai = interests.contains(a.category) ? 0 : 1;
        final bi = interests.contains(b.category) ? 0 : 1;
        final priority = ai.compareTo(bi);
        return priority != 0
            ? priority
            : pins.indexOf(a).compareTo(pins.indexOf(b));
      });
    }
    return result;
  }

  void toggleLike(String id) {
    if (!likedIds.add(id)) likedIds.remove(id);
    _commit();
  }

  void toggleFollow(String id) {
    if (id == 'me') return;
    if (!followedIds.add(id)) followedIds.remove(id);
    _commit();
  }

  void hidePin(String id) {
    hiddenIds.add(id);
    _commit();
  }

  void showHiddenPins() {
    hiddenIds.clear();
    _commit();
  }

  String createBoard(String title, String description, bool secret) {
    final id = newId('board');
    boards.insert(
      0,
      Board(
        id: id,
        title: title.trim(),
        description: description.trim(),
        secret: secret,
        createdAt: _now(),
      ),
    );
    _commit();
    return id;
  }

  void editBoard(Board board) {
    final i = boards.indexWhere((b) => b.id == board.id);
    if (i < 0) return;
    boards[i] = board;
    _commit();
  }

  void deleteBoard(String id) {
    boards.removeWhere((b) => b.id == id);
    _commit();
  }

  void toggleBoardPin(String boardId, String pinId) {
    final index = boards.indexWhere((b) => b.id == boardId);
    if (index < 0 || pinById(pinId) == null) return;
    final ids = [...boards[index].pinIds];
    if (ids.contains(pinId)) {
      ids.remove(pinId);
    } else {
      ids.add(pinId);
    }
    boards[index] = boards[index].copyWith(pinIds: ids);
    _commit();
  }

  void removeFromBoard(String boardId, String pinId) {
    final board = boardById(boardId);
    if (board == null) return;
    editBoard(
      board.copyWith(pinIds: board.pinIds.where((id) => id != pinId).toList()),
    );
  }

  String publishPin({
    required String title,
    required String description,
    required String image,
    required String category,
    required String vibe,
    required double aspectRatio,
    required List<int> palette,
    String sourceUrl = '',
    String? boardId,
    List<String> tags = const [],
  }) {
    final id = newId('pin');
    customPins.insert(
      0,
      Pin(
        id: id,
        title: title.trim(),
        description: description.trim(),
        image: image,
        authorId: 'me',
        category: category,
        vibe: vibe,
        aspectRatio: aspectRatio.clamp(.4, 1.8),
        palette: palette,
        sourceUrl: sourceUrl.trim(),
        createdAt: _now(),
        tags: tags.isEmpty
            ? [category.toLowerCase(), vibe.toLowerCase()]
            : tags,
      ),
    );
    if (boardId != null && boardById(boardId) != null) {
      final board = boardById(boardId)!;
      final i = boards.indexWhere((b) => b.id == boardId);
      boards[i] = board.copyWith(pinIds: [...board.pinIds, id]);
    }
    _commit();
    return id;
  }

  void updatePin(String id, Map<String, dynamic> changes, {String? boardId}) {
    final i = customPins.indexWhere((p) => p.id == id);
    if (i < 0) return;
    customPins[i] = Pin.fromJson({
      ...customPins[i].toJson(),
      ...changes,
      'id': id,
      'authorId': 'me',
    });
    if (boardId != null) {
      final b = boardById(boardId);
      if (b != null && !b.pinIds.contains(id)) {
        final bi = boards.indexWhere((e) => e.id == boardId);
        boards[bi] = b.copyWith(pinIds: [...b.pinIds, id]);
      }
    }
    _commit();
  }

  void deletePin(String id) {
    if (!customPins.any((p) => p.id == id)) return;
    customPins.removeWhere((p) => p.id == id);
    boards = boards
        .map((b) => b.copyWith(pinIds: b.pinIds.where((p) => p != id).toList()))
        .toList();
    likedIds.remove(id);
    hiddenIds.remove(id);
    comments.removeWhere((c) => c.pinId == id);
    _commit();
  }

  void addComment(String pinId, String text) {
    if (text.trim().isEmpty || pinById(pinId) == null) return;
    comments.add(
      PinComment(
        id: newId('comment'),
        pinId: pinId,
        author: 'me',
        text: text.trim(),
        createdAt: _now(),
      ),
    );
    _commit();
  }

  void deleteComment(String id) {
    comments.removeWhere((c) => c.id == id && c.author == 'me');
    _commit();
  }

  void rememberSearch(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    recentSearches.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    recentSearches.insert(0, q);
    recentSearches = recentSearches.take(8).toList();
    _commit();
  }

  void removeSearch(String value) {
    recentSearches.remove(value);
    _commit();
  }

  void clearSearches() {
    recentSearches.clear();
    _commit();
  }

  void updateInterests(List<String> value) {
    interests = List.of(value);
    _commit();
  }

  void setOled(bool value) {
    oled = value;
    _commit();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    _commit();
  }

  void markAllRead() {
    readNotifications.addAll(notificationItems.map((n) => n['id']!));
    _commit();
  }

  void markRead(String id) {
    readNotifications.add(id);
    _commit();
  }

  void markThreadRead(String id) {
    if (readThreads.add(id)) _commit();
  }

  void sendMessage(String creatorId, String value) {
    if (value.trim().isEmpty) return;
    chats.putIfAbsent(creatorId, () => []);
    chats[creatorId]!.add(
      ChatMessage(
        id: newId('msg'),
        text: value.trim(),
        mine: true,
        createdAt: _now(),
      ),
    );
    readThreads.add(creatorId);
    _commit();
  }

  Future<void> resetData() async {
    await flush();
    await store.remove(_dataKey);
    await _loadUser();
    _commit();
    await flush();
  }

  Future<void> deleteLocalAccount() async {
    await flush();
    await store.remove(_dataKey);
    if (profile.email != AuthService.demoEmail) await auth.reset();
    signedIn = false;
    profile = const UserProfile();
    await store.write(_sessionKey, jsonEncode(_sessionJson()));
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
