import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/api_transport.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';

const defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api/v1',
);

class AppState extends ChangeNotifier {
  AppState(this.store, {ApiClient? client})
    : api =
          client ??
          ApiClient(baseUrl: defaultApiBaseUrl, transport: createTransport()) {
    auth = AuthService(store, api);
    api.onUnauthorized = _handleUnauthorized;
  }

  final LocalStore store;
  final ApiClient api;
  late final AuthService auth;

  static const _sessionKey = 'pinspire.session.v2';
  static const _prefsKey = 'pinspire.prefs.v1';

  bool ready = false, signedIn = false, introSeen = false;
  bool oled = false, notificationsEnabled = true;
  bool loading = false;
  String? error, storageError;
  UserProfile profile = const UserProfile();
  List<String> interests = ['Interior', 'Travel', 'Kreatif'];
  List<String> recentSearches = [];
  Set<String> hiddenIds = {};

  List<Board> boards = [];
  List<Pin> savedPins = [];
  List<Pin> likedPins = [];
  List<Creator> following = [];
  List<Creator> users = [];
  List<Conversation> conversations = [];
  List<AppNotice> notifications = [];
  Set<String> likedIds = {}, followedIds = {};

  final List<Pin> _feed = [];
  final List<Pin> _createdPins = [];
  final Map<String, Pin> _pinCache = {};
  final Map<String, Creator> _creators = {};
  final Map<String, List<Pin>> _creatorPins = {};
  final Map<String, List<PinComment>> _comments = {};
  final Map<String, List<ChatMessage>> _chats = {};
  final Set<String> _loadingPins = {}, _loadingComments = {};
  final Set<String> _missingPins = {};

  Future<void> _writeQueue = Future.value();

  int get unreadCount =>
      notificationsEnabled ? notifications.where((n) => !n.isRead).length : 0;

  List<Pin> get customPins => List.unmodifiable(_createdPins);

  List<Pin> get pins {
    final seen = <String>{};
    final result = <Pin>[];
    for (final source in [_createdPins, _feed, savedPins, likedPins]) {
      for (final pin in source) {
        if (seen.add(pin.id)) result.add(pin);
      }
    }
    for (final board in boards) {
      for (final id in board.pinIds) {
        final pin = _pinCache[id];
        if (pin != null && seen.add(pin.id)) result.add(pin);
      }
    }
    return result;
  }

  bool isLoadingPin(String id) => _loadingPins.contains(id);

  bool isMissingPin(String id) => _missingPins.contains(id);

  bool isLoadingComments(String id) => _loadingComments.contains(id);

  Pin? pinById(String id) => _pinCache[id];

  List<Pin> pinsForCreator(String id) {
    final loaded = _creatorPins[id];
    if (loaded != null) return loaded;
    return _pinCache.values.where((pin) => pin.authorId == id).toList();
  }

  Board? boardById(String id) {
    for (final board in boards) {
      if (board.id == id) return board;
    }
    return null;
  }

  List<Pin> pinsInBoard(Board board) =>
      board.pinIds.map(pinById).whereType<Pin>().toList();

  Creator creator(String id) {
    if (id.isEmpty) {
      return const Creator(id: '', name: 'Kreator', username: 'kreator');
    }
    if (id == profile.id) {
      return Creator(
        id: profile.id,
        name: profile.name,
        username: profile.username,
        bio: profile.bio,
        avatar: profile.avatar,
        color: 0xFFFF806B,
        pinsCount: profile.pinsCount,
        followersCount: profile.followersCount,
      );
    }
    final cached = _creators[id];
    if (cached != null) return cached;
    for (final user in users) {
      if (user.id == id) return user;
    }
    return Creator(
      id: id,
      name: 'Kreator',
      username: 'kreator',
      color: Creator.colorFor(id),
    );
  }

  bool isSaved(String id) => savedPins.any((pin) => pin.id == id);

  List<PinComment> commentsFor(String id) => _comments[id] ?? const [];

  List<ChatMessage> messagesFor(String creatorId) =>
      _chats[creatorId] ?? const [];

  bool isFollowing(String id) => followedIds.contains(id);

  List<AppNotice> get notificationItems => notifications;

  String? _message(Object error) =>
      error is ApiException ? (error.firstError ?? error.message) : '$error';

  Future<void> initialize() async {
    try {
      final raw = await store.read(_sessionKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        introSeen = json['introSeen'] as bool? ?? false;
        interests = List<String>.from(json['interests'] as List? ?? interests);
      }
    } catch (_) {
      storageError = 'Sesi lokal tidak dapat dibaca. Silakan masuk kembali.';
    }

    // Preferences are the source of truth for interests, so they are loaded
    // after the legacy session payload instead of being overwritten by it.
    await _loadPrefs();

    try {
      final token = await auth.restoreToken();
      if (token != null && token.isNotEmpty) {
        signedIn = true;
        try {
          profile = await auth.me();
          await refreshAll();
        } on ApiException catch (e) {
          if (e.isUnauthorized) {
            await auth.clearToken();
            signedIn = false;
          } else {
            signedIn = false;
            error = e.toString();
          }
        }
      }
    } catch (_) {
      signedIn = false;
      storageError = 'Sesi lokal tidak dapat dibaca. Silakan masuk kembali.';
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    try {
      final raw = await store.read(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      oled = json['oled'] as bool? ?? false;
      notificationsEnabled = json['notificationsEnabled'] as bool? ?? true;
      interests = List<String>.from(json['interests'] as List? ?? interests);
      recentSearches = List<String>.from(json['recentSearches'] as List? ?? []);
      hiddenIds = Set<String>.from(json['hiddenIds'] as List? ?? []);
    } catch (_) {
      storageError = 'Preferensi lokal tidak dapat dibaca.';
    }
  }

  Future<void> _savePrefs() {
    final payload = jsonEncode({
      'oled': oled,
      'notificationsEnabled': notificationsEnabled,
      'interests': interests,
      'recentSearches': recentSearches,
      'hiddenIds': hiddenIds.toList(),
    });
    _writeQueue = _writeQueue.then((_) async {
      try {
        await store.write(_prefsKey, payload);
      } catch (_) {
        storageError =
            'Preferensi belum tersimpan. Ruang penyimpanan mungkin penuh.';
        notifyListeners();
      }
    });
    return _writeQueue;
  }

  Future<void> _saveSession() async {
    await store.write(
      _sessionKey,
      jsonEncode({'introSeen': introSeen, 'interests': interests}),
    );
  }

  Future<void> flush() => _writeQueue;

  Future<void> refreshAll() async {
    if (!signedIn) return;
    loading = true;
    error = null;
    notifyListeners();
    await Future.wait<void>([
      _guard(_loadFeed),
      _guard(_loadBoards),
      _guard(_loadSaved),
      _guard(_loadLiked),
      _guard(_loadCreated),
      _guard(_loadFollowing),
      _guard(_loadUsers),
      _guard(_loadNotifications),
      _guard(_loadConversations),
    ]);
    loading = false;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      error ??= _message(e);
    }
  }

  Future<void> _loadFeed() async {
    final result = await api.get('/pins', query: {'per_page': '50'});
    final items = result.items;
    final pins = items.map(Pin.fromApi).toList();
    _feed
      ..clear()
      ..addAll(pins);
    _rememberPins(items);
  }

  Future<void> _loadBoards() async {
    final result = await api.get('/boards', query: {'per_page': '50'});
    boards = result.items.map(Board.fromApi).toList();
  }

  Future<void> _loadSaved() async {
    final result = await api.get('/saves', query: {'per_page': '50'});
    final pins = <Pin>[];
    for (final item in result.items) {
      final json = item['pin'];
      if (json is Map) {
        final pin = Pin.fromApi(Map<String, dynamic>.from(json));
        pins.add(pin);
        _pinCache[pin.id] = pin;
        _rememberUser(json['user']);
      }
    }
    savedPins = pins;
  }

  Future<void> _loadLiked() async {
    final result = await api.get('/likes', query: {'per_page': '50'});
    final items = result.items;
    likedPins = items.map(Pin.fromApi).toList();
    likedIds = likedPins.map((pin) => pin.id).toSet();
    _rememberPins(items);
  }

  Future<void> _loadCreated() async {
    if (profile.username.isEmpty) return;
    final result = await api.get(
      '/users/${Uri.encodeComponent(profile.username)}/pins',
      query: {'per_page': '50'},
    );
    final items = result.items;
    _createdPins
      ..clear()
      ..addAll(items.map(Pin.fromApi));
    _rememberPins(items);
  }

  Future<void> _loadFollowing() async {
    final result = await api.get('/following', query: {'per_page': '50'});
    following = result.items.map(Creator.fromApi).toList();
    followedIds = following.map((creator) => creator.id).toSet();
    for (final creator in following) {
      _creators[creator.id] = creator;
    }
  }

  Future<void> _loadUsers() async {
    final result = await api.get('/users', query: {'per_page': '50'});
    users = result.items.map(Creator.fromApi).toList();
    for (final creator in users) {
      if (creator.id == profile.id) continue;
      _creators[creator.id] = creator;
      if (creator.isFollowing) followedIds.add(creator.id);
    }
  }

  Future<void> _loadNotifications() async {
    final result = await api.get('/notifications', query: {'per_page': '50'});
    notifications = result.items.map(AppNotice.fromApi).toList();
  }

  Future<void> _loadConversations() async {
    final result = await api.get('/conversations');
    conversations = result.items.map(Conversation.fromApi).toList();
    for (final conversation in conversations) {
      _creators[conversation.user.id] = conversation.user;
    }
  }

  void _rememberPins(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final pin = Pin.fromApi(item);
      _pinCache[pin.id] = pin;
      _rememberUser(item['user']);
    }
  }

  Creator? _rememberUser(dynamic json) {
    if (json is! Map) return null;
    final creator = Creator.fromApi(Map<String, dynamic>.from(json));
    if (creator.id.isEmpty) return null;
    _creators[creator.id] = creator;
    return creator;
  }

  void _replacePin(Pin pin) {
    _pinCache[pin.id] = pin;
    void replaceIn(List<Pin> list) {
      final index = list.indexWhere((item) => item.id == pin.id);
      if (index >= 0) list[index] = pin;
    }

    replaceIn(_feed);
    replaceIn(_createdPins);
    replaceIn(savedPins);
    replaceIn(likedPins);
    for (final list in _creatorPins.values) {
      replaceIn(list);
    }
  }

  List<Pin> get _discoverPins {
    final seen = <String>{};
    final result = <Pin>[];
    for (final pin in [..._createdPins, ..._feed]) {
      if (seen.add(pin.id)) result.add(pin);
    }
    return result;
  }

  List<Pin> discover({
    String category = 'Semua',
    String vibe = 'Semua',
    bool following = false,
    String query = '',
    String sort = 'Relevan',
  }) {
    final q = query.trim().toLowerCase();
    final source = _discoverPins;
    final result = source.where((pin) {
      final haystack =
          '${pin.title} ${pin.description} ${pin.tags.join(' ')} '
                  '${pin.category} ${pin.vibe} ${creator(pin.authorId).name} '
                  '${creator(pin.authorId).username}'
              .toLowerCase();
      return !hiddenIds.contains(pin.id) &&
          (category == 'Semua' || pin.category == category) &&
          (vibe == 'Semua' || pin.vibe == vibe) &&
          (!following || followedIds.contains(pin.authorId)) &&
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
      result.sort((a, b) {
        final ai = interests.contains(a.category) ? 0 : 1;
        final bi = interests.contains(b.category) ? 0 : 1;
        final priority = ai.compareTo(bi);
        return priority != 0
            ? priority
            : source.indexOf(a).compareTo(source.indexOf(b));
      });
    }
    return result;
  }

  Future<void> toggleLike(String id) async {
    final pin = _pinCache[id];
    if (pin == null) return;
    final wasLiked = likedIds.contains(id);
    final previousLikes = pin.likes;

    if (wasLiked) {
      likedIds.remove(id);
      likedPins.removeWhere((item) => item.id == id);
      _replacePin(
        pin.copyWith(likes: previousLikes > 0 ? previousLikes - 1 : 0),
      );
    } else {
      likedIds.add(id);
      if (!likedPins.any((item) => item.id == id)) likedPins.insert(0, pin);
      _replacePin(pin.copyWith(likes: previousLikes + 1));
    }
    notifyListeners();

    try {
      final result = wasLiked
          ? await api.delete('/pins/$id/like')
          : await api.post('/pins/$id/like');
      final count = (result.object['likes_count'] as num?)?.toInt();
      final current = _pinCache[id];
      if (count != null && current != null) {
        _replacePin(current.copyWith(likes: count));
      }
    } catch (e) {
      if (wasLiked) {
        likedIds.add(id);
        if (!likedPins.any((item) => item.id == id)) likedPins.insert(0, pin);
      } else {
        likedIds.remove(id);
        likedPins.removeWhere((item) => item.id == id);
      }
      _replacePin(pin);
      error = _message(e);
    }
    notifyListeners();
  }

  Future<void> toggleFollow(String id) async {
    if (id.isEmpty || id == profile.id) return;
    final creator = _creators[id];
    if (creator == null || creator.username.isEmpty) return;
    final wasFollowing = followedIds.contains(id);

    if (wasFollowing) {
      followedIds.remove(id);
      following.removeWhere((item) => item.id == id);
      _creators[id] = creator.copyWith(
        isFollowing: false,
        followersCount: creator.followersCount > 0
            ? creator.followersCount - 1
            : 0,
      );
    } else {
      followedIds.add(id);
      if (!following.any((item) => item.id == id)) following.insert(0, creator);
      _creators[id] = creator.copyWith(
        isFollowing: true,
        followersCount: creator.followersCount + 1,
      );
    }
    notifyListeners();

    try {
      final result = wasFollowing
          ? await api.delete('/users/${creator.username}/follow')
          : await api.post('/users/${creator.username}/follow');
      final updated = Creator.fromApi(result.object);
      _creators[updated.id] = updated;
      final index = following.indexWhere((item) => item.id == id);
      if (updated.isFollowing) {
        followedIds.add(id);
        if (index >= 0) {
          following[index] = updated;
        } else {
          following.insert(0, updated);
        }
      } else {
        followedIds.remove(id);
        following.removeWhere((item) => item.id == id);
      }
    } catch (e) {
      if (wasFollowing) {
        followedIds.add(id);
        if (!following.any((item) => item.id == id)) {
          following.insert(0, creator);
        }
        _creators[id] = creator;
      } else {
        followedIds.remove(id);
        following.removeWhere((item) => item.id == id);
        _creators[id] = creator;
      }
      error = _message(e);
    }
    notifyListeners();
  }

  void hidePin(String id) {
    hiddenIds.add(id);
    _savePrefs();
    notifyListeners();
  }

  void showHiddenPins() {
    hiddenIds.clear();
    _savePrefs();
    notifyListeners();
  }

  Future<String?> createBoard(
    String title,
    String description,
    bool secret,
  ) async {
    try {
      final result = await api.post(
        '/boards',
        body: {
          'name': title.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'is_private': secret,
        },
      );
      final board = Board.fromApi(result.object);
      boards.insert(0, board);
      notifyListeners();
      return board.id;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> editBoard(Board board) async {
    try {
      final result = await api.patch(
        '/boards/${board.id}',
        body: {
          'name': board.title.trim(),
          'description': board.description.trim().isEmpty
              ? null
              : board.description.trim(),
          'is_private': board.secret,
        },
      );
      final updated = Board.fromApi(result.object);
      final index = boards.indexWhere((item) => item.id == board.id);
      if (index >= 0) boards[index] = updated;
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> deleteBoard(String id) async {
    try {
      await api.delete('/boards/$id');
      boards.removeWhere((board) => board.id == id);
      savedPins.removeWhere(
        (pin) => !boards.any((board) => board.pinIds.contains(pin.id)),
      );
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> toggleBoardPin(String boardId, String pinId) async {
    final board = boardById(boardId);
    if (board == null) return;
    if (board.pinIds.contains(pinId)) {
      await _unsavePin(board, pinId);
    } else {
      await _savePin(board, pinId);
    }
  }

  Future<void> removeFromBoard(String boardId, String pinId) async {
    final board = boardById(boardId);
    if (board == null) return;
    await _unsavePin(board, pinId);
  }

  int? get _ownerBoardId {
    final id = boards.isEmpty ? null : int.tryParse(boards.first.id);
    return id;
  }

  Future<void> _savePin(Board board, String pinId) async {
    final boardId = int.tryParse(board.id) ?? _ownerBoardId;
    if (boardId == null) return;
    try {
      final result = await api.post(
        '/pins/$pinId/save',
        body: {'board_id': boardId},
      );
      final savedBoardJson = result.object['board'];
      final pinJson = result.object['pin'];
      final updatedBoard = savedBoardJson is Map
          ? Board.fromApi(Map<String, dynamic>.from(savedBoardJson))
          : board;
      final mergedBoard = updatedBoard.pinIds.contains(pinId)
          ? updatedBoard
          : updatedBoard.copyWith(pinIds: [...updatedBoard.pinIds, pinId]);
      final index = boards.indexWhere((item) => item.id == board.id);
      if (index >= 0) boards[index] = mergedBoard;
      if (pinJson is Map) {
        final pin = Pin.fromApi(Map<String, dynamic>.from(pinJson));
        _pinCache[pin.id] = pin;
      }
      final pin = _pinCache[pinId];
      if (pin != null && !savedPins.any((item) => item.id == pinId)) {
        savedPins.insert(0, pin);
      }
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> _unsavePin(Board board, String pinId) async {
    final boardId = int.tryParse(board.id) ?? _ownerBoardId;
    if (boardId == null) return;
    try {
      await api.delete('/pins/$pinId/save', body: {'board_id': boardId});
      final index = boards.indexWhere((item) => item.id == board.id);
      if (index >= 0) {
        boards[index] = board.copyWith(
          pinIds: board.pinIds.where((id) => id != pinId).toList(),
        );
      }
      if (!boards.any((item) => item.pinIds.contains(pinId))) {
        savedPins.removeWhere((pin) => pin.id == pinId);
      }
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<Pin?> publishPin({
    required String title,
    required String description,
    required String category,
    required String vibe,
    required List<int> palette,
    required double aspectRatio,
    String sourceUrl = '',
    String? boardId,
    List<String> tags = const [],
    String imageUrl = '',
    Uint8List? imageBytes,
    String imageMime = 'image/jpeg',
    String imageName = 'pin.jpg',
  }) async {
    final fields = <String, String>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'vibe': vibe,
      if (sourceUrl.trim().isNotEmpty) 'source_url': sourceUrl.trim(),
      if (imageBytes == null && imageUrl.trim().isNotEmpty)
        'image_url': imageUrl.trim(),
    };
    for (var i = 0; i < tags.length; i++) {
      fields['tags[$i]'] = tags[i];
    }
    for (var i = 0; i < palette.length; i++) {
      fields['palette[$i]'] = '${palette[i]}';
    }

    final files = imageBytes == null
        ? const <ApiFile>[]
        : [
            ApiFile(
              field: 'image',
              filename: imageName,
              bytes: imageBytes,
              mimeType: imageMime,
            ),
          ];

    try {
      final result = await api.post('/pins', fields: fields, files: files);
      final pin = Pin.fromApi(result.object);
      _pinCache[pin.id] = pin;
      if (pin.authorId == profile.id) {
        _createdPins.insert(0, pin);
      }
      _rememberUser(result.object['user']);
      if (boardId != null) {
        final board = boardById(boardId);
        if (board != null) await _savePin(board, pin.id);
      }
      notifyListeners();
      return pin;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePin(
    String id, {
    required String title,
    required String description,
    required String category,
    required String vibe,
    required List<String> tags,
    required List<int> palette,
    String sourceUrl = '',
    String imageUrl = '',
    Uint8List? imageBytes,
    String imageMime = 'image/jpeg',
    String imageName = 'pin.jpg',
    bool imageChanged = false,
    String? boardId,
  }) async {
    final fields = <String, String>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'vibe': vibe,
      'source_url': sourceUrl.trim(),
      if (imageChanged && imageBytes == null && imageUrl.trim().isNotEmpty)
        'image_url': imageUrl.trim(),
    };
    for (var i = 0; i < tags.length; i++) {
      fields['tags[$i]'] = tags[i];
    }
    for (var i = 0; i < palette.length; i++) {
      fields['palette[$i]'] = '${palette[i]}';
    }

    final files = imageChanged && imageBytes != null
        ? [
            ApiFile(
              field: 'image',
              filename: imageName,
              bytes: imageBytes,
              mimeType: imageMime,
            ),
          ]
        : const <ApiFile>[];

    try {
      final result = files.isEmpty
          ? await api.patch('/pins/$id', body: fields)
          : await api.multipartUpdate(
              '/pins/$id',
              fields: fields,
              files: files,
            );
      final pin = Pin.fromApi(result.object);
      _replacePin(pin);
      if (pin.authorId == profile.id &&
          !_createdPins.any((item) => item.id == pin.id)) {
        _createdPins.insert(0, pin);
      }
      if (boardId != null) {
        final board = boardById(boardId);
        if (board != null && !board.pinIds.contains(pin.id)) {
          await _savePin(board, pin.id);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePin(String id) async {
    try {
      await api.delete('/pins/$id');
      _pinCache.remove(id);
      _feed.removeWhere((pin) => pin.id == id);
      _createdPins.removeWhere((pin) => pin.id == id);
      savedPins.removeWhere((pin) => pin.id == id);
      likedPins.removeWhere((pin) => pin.id == id);
      for (final list in _creatorPins.values) {
        list.removeWhere((pin) => pin.id == id);
      }
      likedIds.remove(id);
      hiddenIds.remove(id);
      _comments.remove(id);
      boards = boards
          .map(
            (board) => board.copyWith(
              pinIds: board.pinIds.where((pinId) => pinId != id).toList(),
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> loadPin(String id) async {
    if (_loadingPins.contains(id)) return;
    _loadingPins.add(id);
    notifyListeners();
    try {
      final result = await api.get('/pins/$id');
      final pin = Pin.fromApi(result.object);
      _pinCache[pin.id] = pin;
      _missingPins.remove(id);
      _rememberUser(result.object['user']);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _missingPins.add(id);
      } else {
        error = _message(e);
      }
    } catch (e) {
      error = _message(e);
    } finally {
      _loadingPins.remove(id);
      notifyListeners();
    }
  }

  Future<void> loadComments(String pinId) async {
    if (_loadingComments.contains(pinId)) return;
    _loadingComments.add(pinId);
    notifyListeners();
    try {
      final result = await api.get('/pins/$pinId/comments');
      _comments[pinId] = result.items.map((json) {
        _rememberUser(json['user']);
        final comment = PinComment.fromApi(json);
        return comment.copyWith(mine: comment.author == profile.id);
      }).toList();
    } catch (e) {
      error = _message(e);
    } finally {
      _loadingComments.remove(pinId);
      notifyListeners();
    }
  }

  Future<void> loadCreatorPins(String creatorId) async {
    final creator = _creators[creatorId];
    if (creator == null || creator.username.isEmpty) return;
    try {
      final result = await api.get(
        '/users/${Uri.encodeComponent(creator.username)}/pins',
        query: {'per_page': '50'},
      );
      _rememberPins(result.items);
      _creatorPins[creatorId] = result.items.map(Pin.fromApi).toList();
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<PinComment?> addComment(String pinId, String text) async {
    if (text.trim().isEmpty) return null;
    try {
      final result = await api.post(
        '/pins/$pinId/comments',
        body: {'text': text.trim()},
      );
      _rememberUser(result.object['user']);
      final comment = PinComment.fromApi(result.object).copyWith(mine: true);
      _comments.putIfAbsent(pinId, () => []).add(comment);
      notifyListeners();
      return comment;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteComment(String id) async {
    try {
      await api.delete('/comments/$id');
      for (final list in _comments.values) {
        list.removeWhere((comment) => comment.id == id);
      }
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> loadBoard(String id) async {
    try {
      final boardResult = await api.get('/boards/$id');
      final board = Board.fromApi(boardResult.object);
      final index = boards.indexWhere((item) => item.id == id);
      if (index >= 0) {
        boards[index] = board;
      } else {
        boards.add(board);
      }
      final pinsResult = await api.get(
        '/boards/$id/pins',
        query: {'per_page': '50'},
      );
      _rememberPins(pinsResult.items);
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<List<Pin>> searchPins(String query) async {
    final term = query.trim();
    if (term.isEmpty) return const [];
    try {
      final result = await api.get(
        '/search',
        query: {'q': term, 'per_page': '50'},
      );
      _rememberPins(result.items);
      return result.items.map(Pin.fromApi).toList();
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return const [];
    }
  }

  Future<List<Creator>> searchUsers(String query) async {
    final term = query.trim();
    if (term.isEmpty) return const [];
    try {
      final result = await api.get(
        '/users',
        query: {'q': term, 'per_page': '50'},
      );
      final found = result.items.map(Creator.fromApi).toList();
      for (final creator in found) {
        if (creator.id == profile.id) continue;
        _creators[creator.id] = creator;
      }
      return found.where((creator) => creator.id != profile.id).toList();
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return const [];
    }
  }

  Future<void> ensureConversation(String creatorId) async {
    final creator = _creators[creatorId];
    if (creator == null || creator.username.isEmpty) return;
    try {
      final result = await api.get(
        '/conversations/${Uri.encodeComponent(creator.username)}',
      );
      _chats[creatorId] = result.items.map(ChatMessage.fromApi).toList();
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String creatorId, String value) async {
    final text = value.trim();
    if (text.isEmpty) return false;
    final creator = _creators[creatorId];
    if (creator == null || creator.username.isEmpty) return false;
    try {
      final result = await api.post(
        '/conversations/${Uri.encodeComponent(creator.username)}/messages',
        body: {'body': text},
      );
      final message = ChatMessage.fromApi(result.object);
      _chats.putIfAbsent(creatorId, () => []).add(message);
      final index = conversations.indexWhere(
        (conversation) => conversation.user.id == creatorId,
      );
      if (index >= 0) {
        conversations[index] = conversations[index].copyWith(
          lastMessage: message,
          unreadCount: 0,
        );
      } else {
        conversations.insert(
          0,
          Conversation(user: creator, lastMessage: message),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> markThreadRead(String creatorId) async {
    final creator = _creators[creatorId];
    if (creator == null || creator.username.isEmpty) return;
    try {
      await api.post(
        '/conversations/${Uri.encodeComponent(creator.username)}/read',
      );
      final index = conversations.indexWhere(
        (conversation) => conversation.user.id == creatorId,
      );
      if (index >= 0) {
        conversations[index] = conversations[index].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (_) {
      /* Menandai sudah dibaca bersifat opsional. */
    }
  }

  Future<void> markAllRead() async {
    try {
      await api.post('/notifications/read-all');
      notifications = notifications
          .map((notice) => notice.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      await api.post('/notifications/$id/read');
      notifications = notifications
          .map(
            (notice) =>
                notice.id == id ? notice.copyWith(isRead: true) : notice,
          )
          .toList();
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
    }
  }

  void rememberSearch(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    recentSearches.removeWhere(
      (entry) => entry.toLowerCase() == q.toLowerCase(),
    );
    recentSearches.insert(0, q);
    recentSearches = recentSearches.take(8).toList();
    _savePrefs();
    notifyListeners();
  }

  void removeSearch(String value) {
    recentSearches.remove(value);
    _savePrefs();
    notifyListeners();
  }

  void clearSearches() {
    recentSearches.clear();
    _savePrefs();
    notifyListeners();
  }

  void updateInterests(List<String> value) {
    interests = List.of(value);
    _savePrefs();
    notifyListeners();
  }

  void setOled(bool value) {
    oled = value;
    _savePrefs();
    notifyListeners();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    _savePrefs();
    notifyListeners();
  }

  Future<void> finishIntro(List<String> selected) async {
    interests = selected.isEmpty
        ? ['Interior', 'Travel', 'Kreatif']
        : List.of(selected);
    introSeen = true;
    await _saveSession();
    await _savePrefs();
    notifyListeners();
  }

  Future<void> signIn(UserProfile user) async {
    profile = user;
    signedIn = true;
    introSeen = true;
    _creators.remove(profile.id);
    await _saveSession();
    await refreshAll();
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.logout();
    signedIn = false;
    _clearData();
    notifyListeners();
  }

  Future<void> updateProfile(
    UserProfile updated, {
    Uint8List? avatarBytes,
    String avatarMime = 'image/jpeg',
    String avatarName = 'avatar.jpg',
    bool removeAvatar = false,
  }) async {
    try {
      if (removeAvatar) {
        await api.delete('/profile/avatar');
      }
      if (avatarBytes != null) {
        await api.post(
          '/profile/avatar',
          files: [
            ApiFile(
              field: 'avatar',
              filename: avatarName,
              bytes: avatarBytes,
              mimeType: avatarMime,
            ),
          ],
        );
      }
      final result = await api.patch(
        '/profile',
        body: {
          'name': updated.name.trim(),
          'username': updated.username.trim().toLowerCase(),
          'bio': updated.bio.trim(),
          'website': updated.website.trim(),
        },
      );
      profile = UserProfile.fromApi(result.object);
      _creators.remove(profile.id);
      notifyListeners();
    } catch (e) {
      error = _message(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetData() async {
    hiddenIds.clear();
    recentSearches.clear();
    await _savePrefs();
    await refreshAll();
  }

  Future<bool> changePassword(String current, String next) async {
    try {
      await api.patch(
        '/settings/password',
        body: {
          'current_password': current,
          'password': next,
          'password_confirmation': next,
        },
      );
      return true;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await api.delete('/profile');
    } finally {
      await auth.clearToken();
      signedIn = false;
      _clearData();
      notifyListeners();
    }
  }

  Future<void> deleteLocalAccount() => deleteAccount();

  void _handleUnauthorized() {
    if (!signedIn) return;
    signedIn = false;
    _clearData();
    error = 'Sesi berakhir. Silakan masuk kembali.';
    notifyListeners();
  }

  void _clearData() {
    profile = const UserProfile();
    boards = [];
    savedPins = [];
    likedPins = [];
    following = [];
    users = [];
    conversations = [];
    notifications = [];
    likedIds = {};
    followedIds = {};
    recentSearches = [];
    hiddenIds = {};
    _feed.clear();
    _createdPins.clear();
    _pinCache.clear();
    _creators.clear();
    _creatorPins.clear();
    _comments.clear();
    _chats.clear();
    _missingPins.clear();
    _loadingPins.clear();
    _loadingComments.clear();
    loading = false;
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
