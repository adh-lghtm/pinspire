import 'dart:convert';

import 'package:pinspire/services/api_models.dart';

/// Small in-memory implementation of the Pinspire API used by widget and
/// state tests. It intentionally mirrors the response envelope of the real
/// backend without touching the network.
class FakeApi implements ApiTransport {
  FakeApi() {
    users.addAll([
      {
        'id': 1,
        'name': 'Iza Demo',
        'username': 'iza.creates',
        'email': 'demo@pinspire.test',
        'bio': 'Mengumpulkan ide kecil.',
        'avatar_url': null,
        'website': 'https://pinspire.test',
        'followers_count': 4,
        'following_count': 1,
      },
      {
        'id': 2,
        'name': 'Nara Studio',
        'username': 'nara.studio',
        'email': 'nara@pinspire.test',
        'bio': 'Ruang yang tenang.',
        'avatar_url': null,
        'website': null,
        'followers_count': 8,
        'following_count': 2,
      },
      {
        'id': 3,
        'name': 'Raka Pradana',
        'username': 'raka.jalan',
        'email': 'raka@pinspire.test',
        'bio': 'Cerita di setiap perjalanan.',
        'avatar_url': null,
        'website': null,
        'followers_count': 6,
        'following_count': 1,
      },
    ]);

    pins.addAll([
      {
        'id': 1,
        'title': 'Sudut tenang, ide baru',
        'description': 'Ruang kecil untuk berhenti sejenak.',
        'image_url': 'assets/images/quiet_corner.jpg',
        'category': 'Interior',
        'vibe': 'Calm',
        'tags': ['minimalis', 'rumah'],
        'palette': [0xFFDAC9B7, 0xFF8D806F, 0xFF42463C],
        'author_id': 2,
        'likes_count': 12,
        'saves_count': 1,
        'created_at': '2026-10-19T09:00:00Z',
      },
      {
        'id': 2,
        'title': 'Ke mana akhir pekan ini?',
        'description': 'Tepi laut dan angin pelan.',
        'image_url': 'assets/images/coast.jpg',
        'category': 'Travel',
        'vibe': 'Fresh',
        'tags': ['pantai', 'laut'],
        'palette': [0xFFC4DCD7, 0xFF73AAA4, 0xFF2D5B66],
        'author_id': 3,
        'likes_count': 25,
        'saves_count': 0,
        'created_at': '2026-10-18T09:00:00Z',
      },
      {
        'id': 3,
        'title': 'Pelan-pelan, secangkir dulu',
        'description': 'Ritual pagi sederhana.',
        'image_url': 'assets/images/coffee.jpg',
        'category': 'Kuliner',
        'vibe': 'Warm',
        'tags': ['kopi', 'pagi'],
        'palette': [0xFFE3C8A8, 0xFFA97D54, 0xFF47372C],
        'author_id': 2,
        'likes_count': 7,
        'saves_count': 0,
        'created_at': '2026-10-17T09:00:00Z',
      },
    ]);

    boards.add({
      'id': 1,
      'name': 'Ruang untuk pulang',
      'description': 'Rumah hangat dan sudut tenang.',
      'is_private': false,
      'pin_ids': [1],
      'created_at': '2026-10-15T09:00:00Z',
    });

    comments.add({
      'id': 1,
      'pin_id': 1,
      'text': 'Cocok untuk ruang kerja.',
      'author_id': 3,
      'created_at': '2026-10-19T12:00:00Z',
    });

    following.add(2);

    notifications.add({
      'id': 1,
      'type': 'follow',
      'title': 'Nara mulai mengikuti kamu',
      'body': 'Kunjungi profil Nara untuk melihat inspirasinya.',
      'target_type': 'user',
      'target_id': 2,
      'image_url': null,
      'is_read': false,
      'created_at': '2026-10-19T13:00:00Z',
    });
    notifications.add({
      'id': 2,
      'type': 'like',
      'title': 'Raka menyukai pinmu',
      'body': 'Pin “Sudut tenang” mendapat suka baru.',
      'target_type': 'pin',
      'target_id': 1,
      'image_url': 'assets/images/quiet_corner.jpg',
      'is_read': true,
      'created_at': '2026-10-19T14:00:00Z',
    });

    chats[2] = [
      {
        'id': 1,
        'sender_id': 2,
        'body': 'Halo! Suka pinmu yang tadi.',
        'created_at': '2026-10-19T15:00:00Z',
      },
    ];
    unread[2] = 1;
  }

  final List<ApiRequest> requests = [];
  final List<Map<String, dynamic>> users = [];
  final List<Map<String, dynamic>> pins = [];
  final List<Map<String, dynamic>> boards = [];
  final List<Map<String, dynamic>> comments = [];
  final List<Map<String, dynamic>> notifications = [];
  final Map<int, List<Map<String, dynamic>>> chats = {};
  final Map<int, int> unread = {};
  final Set<int> liked = {};
  final Set<int> following = {};
  int _sequence = 100;
  bool accountDeleted = false;
  String? token;
  String password = 'password';

  Map<String, dynamic> get self => users.first;

  Map<String, dynamic> _user(int id) =>
      users.firstWhere((user) => user['id'] == id, orElse: () => self);

  Map<String, dynamic> _userByUsername(String username) => users.firstWhere(
    (user) => user['username'] == username,
    orElse: () => self,
  );

  Map<String, dynamic> userPayload(Map<String, dynamic> user) {
    final id = user['id'] as int;
    return {
      ...user,
      'pins_count': pins.where((pin) => pin['author_id'] == id).length,
      'boards_count': boards.length,
      'following_count': following.length,
      'is_following': following.contains(id),
    };
  }

  Map<String, dynamic> pinPayload(Map<String, dynamic> pin) {
    final id = pin['id'] as int;
    return {
      ...pin,
      'user': userPayload(_user(pin['author_id'] as int)),
      'is_liked': liked.contains(id),
      'is_saved': boards.any(
        (board) => (board['pin_ids'] as List).contains(id),
      ),
      'comments_count': comments.where((c) => c['pin_id'] == id).length,
    };
  }

  Map<String, dynamic> boardPayload(Map<String, dynamic> board) => {
    ...board,
    'user': userPayload(self),
    'pin_ids': (board['pin_ids'] as List).map((id) => '$id').toList(),
  };

  Map<String, dynamic> messagePayload(Map<String, dynamic> message) => {
    ...message,
    'mine': message['sender_id'] == self['id'],
    'sender': userPayload(_user(message['sender_id'] as int)),
  };

  List<Map<String, dynamic>> _pinsForBoard(int boardId) {
    final board = boards.firstWhere((b) => b['id'] == boardId);
    return (board['pin_ids'] as List)
        .map((id) => pins.firstWhere((pin) => pin['id'] == id))
        .map(pinPayload)
        .toList();
  }

  ApiResponse _ok(dynamic data, {Map<String, dynamic>? meta}) => ApiResponse(
    200,
    jsonEncode({
      'success': true,
      'message': 'OK',
      'data': data,
      if (meta != null) 'meta': meta,
    }),
  );

  ApiResponse _created(dynamic data) => ApiResponse(
    201,
    jsonEncode({'success': true, 'message': 'Created', 'data': data}),
  );

  ApiResponse _error(
    int status,
    String message, [
    Map<String, dynamic>? errors,
  ]) => ApiResponse(
    status,
    jsonEncode({
      'success': false,
      'message': message,
      if (errors != null) 'errors': errors,
    }),
  );

  Map<String, dynamic> _body(ApiRequest request) {
    if (request.body == null || request.body!.trim().isEmpty) return {};
    final value = jsonDecode(request.body!);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  Map<String, dynamic> _input(ApiRequest request) => request.isMultipart
      ? Map<String, dynamic>.from(request.fields)
      : _body(request);

  String _text(
    Map<String, dynamic> input,
    String key, [
    String fallback = '',
  ]) => input[key] == null ? fallback : '${input[key]}';

  List<String> _list(Map<String, dynamic> input, String prefix) {
    final values = <String>[];
    for (var i = 0; i < 30; i++) {
      final key = '$prefix[$i]';
      if (!input.containsKey(key)) break;
      values.add('${input[key]}');
    }
    return values;
  }

  List<int> _palette(Map<String, dynamic> input) {
    final values = <int>[];
    for (var i = 0; i < 10; i++) {
      final key = 'palette[$i]';
      if (!input.containsKey(key)) break;
      values.add(int.tryParse('${input[key]}') ?? 0);
    }
    return values.isEmpty ? const [0xFFDAC9B7, 0xFF71685E, 0xFF303830] : values;
  }

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    requests.add(request);
    final uri = Uri.parse(request.url);
    var path = uri.path;
    if (path.startsWith('/api/v1')) {
      path = path.substring('/api/v1'.length);
    }
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final method = request.method.toUpperCase();
    final input = _input(request);

    if (method == 'POST' && path == '/auth/login') {
      final email = _text(input, 'email');
      final password = _text(input, 'password');
      if (email == 'demo@pinspire.test' && password == 'password') {
        token = 'fake-token';
        return _ok({'access_token': token, 'user': userPayload(self)});
      }
      return _error(422, 'Email atau kata sandi tidak cocok.', {
        'email': ['Email atau kata sandi tidak cocok.'],
      });
    }

    if (method == 'POST' && path == '/auth/register') {
      final username = _text(input, 'username');
      if (users.any((user) => user['username'] == username)) {
        return _error(422, 'Username sudah dipakai.', {
          'username': ['Username sudah dipakai.'],
        });
      }
      final user = {
        'id': users.length + 1,
        'name': _text(input, 'name'),
        'username': username,
        'email': _text(input, 'email'),
        'bio': '',
        'avatar_url': null,
        'website': null,
        'followers_count': 0,
        'following_count': 0,
      };
      users.add(user);
      token = 'fake-token';
      return _created({'access_token': token, 'user': userPayload(user)});
    }

    if (method == 'POST' && path == '/auth/logout') {
      token = null;
      return _ok(null);
    }

    if (path == '/auth/me') return _ok(userPayload(self));

    if (path == '/pins') {
      if (method == 'GET') {
        final term = (uri.queryParameters['q'] ?? '').toLowerCase();
        final result = pins
            .where(
              (pin) =>
                  term.isEmpty ||
                  '${pin['title']} ${pin['description']}'
                      .toLowerCase()
                      .contains(term),
            )
            .map(pinPayload)
            .toList();
        return _ok(result, meta: {'current_page': 1, 'last_page': 1});
      }
      if (method == 'POST') {
        final id = ++_sequence;
        final pin = {
          'id': id,
          'title': _text(input, 'title', 'Tanpa judul'),
          'description': _text(input, 'description'),
          'image_url': _text(
            input,
            'image_url',
            request.files.isNotEmpty ? 'https://cdn.test/pin.jpg' : '',
          ),
          'category': _text(input, 'category', 'Kreatif'),
          'vibe': _text(input, 'vibe', 'Calm'),
          'tags': _list(input, 'tags'),
          'palette': _palette(input),
          'author_id': self['id'],
          'likes_count': 0,
          'saves_count': 0,
          'created_at': '2026-10-20T09:00:00Z',
        };
        pins.insert(0, pin);
        return _created(pinPayload(pin));
      }
    }

    if (parts.length == 2 && parts.first == 'pins') {
      final id = int.tryParse(parts[1]) ?? 0;
      final index = pins.indexWhere((pin) => pin['id'] == id);
      if (method == 'GET') {
        if (index < 0) return _error(404, 'Pin tidak ditemukan.');
        return _ok(pinPayload(pins[index]));
      }
      if (method == 'PATCH' || method == 'PUT') {
        if (index < 0) return _error(404, 'Pin tidak ditemukan.');
        final pin = pins[index];
        final updated = Map<String, dynamic>.from(pin);
        for (final key in [
          'title',
          'description',
          'category',
          'vibe',
          'image_url',
        ]) {
          if (input.containsKey(key)) updated[key] = _text(input, key);
        }
        if (input.containsKey('tags[0]')) {
          updated['tags'] = _list(input, 'tags');
        }
        if (input.containsKey('palette[0]')) {
          updated['palette'] = _palette(input);
        }
        pins[index] = updated;
        return _ok(pinPayload(updated));
      }
      if (method == 'DELETE') {
        if (index >= 0) pins.removeAt(index);
        return _ok(null);
      }
    }

    if (parts.length == 3 && parts.first == 'pins' && parts[2] == 'comments') {
      final pinId = int.tryParse(parts[1]) ?? 0;
      if (method == 'GET') {
        return _ok(
          comments
              .where((comment) => comment['pin_id'] == pinId)
              .map(
                (comment) => {
                  ...comment,
                  'user': userPayload(_user(comment['author_id'] as int)),
                  'mine': comment['author_id'] == self['id'],
                },
              )
              .toList(),
        );
      }
      if (method == 'POST') {
        final comment = {
          'id': ++_sequence,
          'pin_id': pinId,
          'text': _text(input, 'text'),
          'author_id': self['id'],
          'created_at': '2026-10-20T10:00:00Z',
        };
        comments.add(comment);
        return _created({...comment, 'user': userPayload(self), 'mine': true});
      }
    }

    if (parts.length == 2 && parts.first == 'comments' && method == 'DELETE') {
      final id = int.tryParse(parts[1]) ?? 0;
      comments.removeWhere((comment) => comment['id'] == id);
      return _ok(null);
    }

    if (parts.length == 3 && parts.first == 'pins' && parts[2] == 'like') {
      final id = int.tryParse(parts[1]) ?? 0;
      final pin = pins.firstWhere((pin) => pin['id'] == id);
      if (method == 'POST' && liked.add(id)) {
        pin['likes_count'] = (pin['likes_count'] as int) + 1;
      }
      if (method == 'DELETE' && liked.remove(id)) {
        pin['likes_count'] = (pin['likes_count'] as int) - 1;
      }
      return _ok(pinPayload(pin));
    }

    if (parts.length == 3 && parts.first == 'pins' && parts[2] == 'save') {
      final pinId = int.tryParse(parts[1]) ?? 0;
      final boardId = int.tryParse(_text(input, 'board_id')) ?? 0;
      final board = boards.firstWhere(
        (board) => board['id'] == boardId,
        orElse: () => boards.first,
      );
      final pinIds = board['pin_ids'] as List;
      if (method == 'POST' && !pinIds.contains(pinId)) pinIds.add(pinId);
      if (method == 'DELETE') pinIds.remove(pinId);
      final pin = pins.firstWhere((pin) => pin['id'] == pinId);
      pin['saves_count'] = boards
          .where((item) => (item['pin_ids'] as List).contains(pinId))
          .length;
      return _ok({'board': boardPayload(board), 'pin': pinPayload(pin)});
    }

    if (path == '/search') {
      final term = (uri.queryParameters['q'] ?? '').toLowerCase();
      final result = pins
          .where((pin) {
            final haystack =
                '${pin['title']} ${pin['description']} ${pin['category']} ${pin['vibe']} ${(pin['tags'] as List).join(' ')}'
                    .toLowerCase();
            return term.isNotEmpty && haystack.contains(term);
          })
          .map(pinPayload)
          .toList();
      return _ok(result, meta: {'current_page': 1, 'last_page': 1});
    }

    if (path == '/likes' && method == 'GET') {
      return _ok(
        pins.where((pin) => liked.contains(pin['id'])).map(pinPayload).toList(),
      );
    }

    if (path == '/saves' && method == 'GET') {
      final result = <Map<String, dynamic>>[];
      for (final board in boards) {
        for (final id in board['pin_ids'] as List) {
          final pin = pins.firstWhere((pin) => pin['id'] == id);
          result.add({
            'id': ++_sequence,
            'board': boardPayload(board),
            'pin': pinPayload(pin),
          });
        }
      }
      return _ok(result);
    }

    if (path == '/boards') {
      if (method == 'GET') {
        return _ok(boards.map(boardPayload).toList());
      }
      if (method == 'POST') {
        final board = {
          'id': ++_sequence,
          'name': _text(input, 'name'),
          'description': _text(input, 'description'),
          'is_private':
              input['is_private'] == true || input['is_private'] == '1',
          'pin_ids': <int>[],
          'created_at': '2026-10-20T11:00:00Z',
        };
        boards.insert(0, board);
        return _created(boardPayload(board));
      }
    }

    if (parts.length == 2 && parts.first == 'boards') {
      final id = int.tryParse(parts[1]) ?? 0;
      final index = boards.indexWhere((board) => board['id'] == id);
      if (method == 'GET') {
        if (index < 0) return _error(404, 'Board tidak ditemukan.');
        return _ok(boardPayload(boards[index]));
      }
      if (method == 'PATCH' || method == 'PUT') {
        if (index < 0) return _error(404, 'Board tidak ditemukan.');
        final updated = Map<String, dynamic>.from(boards[index]);
        for (final key in ['name', 'description']) {
          if (input.containsKey(key)) updated[key] = _text(input, key);
        }
        if (input.containsKey('is_private')) {
          updated['is_private'] =
              input['is_private'] == true || input['is_private'] == '1';
        }
        boards[index] = updated;
        return _ok(boardPayload(updated));
      }
      if (method == 'DELETE') {
        if (index >= 0) boards.removeAt(index);
        return _ok(null);
      }
    }

    if (parts.length == 3 &&
        parts.first == 'boards' &&
        parts[2] == 'pins' &&
        method == 'GET') {
      return _ok(_pinsForBoard(int.tryParse(parts[1]) ?? 0));
    }

    if (path == '/users' && method == 'GET') {
      final term = (uri.queryParameters['q'] ?? '').toLowerCase();
      final result = users
          .where((user) {
            return term.isEmpty ||
                '${user['name']} ${user['username']} ${user['bio']}'
                    .toLowerCase()
                    .contains(term);
          })
          .map(userPayload)
          .toList();
      return _ok(result);
    }

    if (parts.length == 2 && parts.first == 'users') {
      final user = _userByUsername(parts[1]);
      if (method == 'GET') return _ok(userPayload(user));
      if (method == 'POST' && path.endsWith('/follow')) {
        following.add(user['id'] as int);
        return _ok(userPayload(user));
      }
      if (method == 'DELETE' && path.endsWith('/follow')) {
        following.remove(user['id'] as int);
        return _ok(userPayload(user));
      }
    }

    if (parts.length == 3 &&
        parts.first == 'users' &&
        parts[2] == 'follow' &&
        (method == 'POST' || method == 'DELETE')) {
      final user = _userByUsername(parts[1]);
      final id = user['id'] as int;
      if (method == 'POST') {
        following.add(id);
      } else {
        following.remove(id);
      }
      return _ok(userPayload(user));
    }

    if (parts.length == 3 && parts.first == 'users' && parts[2] == 'pins') {
      final user = _userByUsername(parts[1]);
      return _ok(
        pins
            .where((pin) => pin['author_id'] == user['id'])
            .map(pinPayload)
            .toList(),
      );
    }

    if (parts.length == 3 && parts.first == 'users' && parts[2] == 'boards') {
      return _ok(boards.map(boardPayload).toList());
    }

    if (path == '/following' && method == 'GET') {
      return _ok(
        users
            .where((user) => following.contains(user['id']))
            .map(userPayload)
            .toList(),
      );
    }

    if (path == '/profile') {
      if (method == 'GET') return _ok(userPayload(self));
      if (method == 'PATCH' || method == 'PUT') {
        for (final key in ['name', 'username', 'bio', 'website']) {
          if (input.containsKey(key)) self[key] = _text(input, key);
        }
        return _ok(userPayload(self));
      }
      if (method == 'DELETE') {
        accountDeleted = true;
        return _ok(null);
      }
    }

    if (path == '/profile/avatar') {
      if (method == 'POST') {
        self['avatar_url'] = 'https://cdn.test/avatar.jpg';
      } else if (method == 'DELETE') {
        self['avatar_url'] = null;
      }
      return _ok(userPayload(self));
    }

    if (path == '/settings/password' && method == 'PATCH') {
      if (_text(input, 'current_password') != password) {
        return _error(422, 'Kata sandi saat ini tidak cocok.', {
          'current_password': ['Kata sandi saat ini tidak cocok.'],
        });
      }
      password = _text(input, 'password');
      return _ok(null);
    }

    if (path == '/notifications') {
      if (method == 'GET') {
        return _ok(
          notifications
              .map(
                (notice) => {...notice, 'is_read': notice['is_read'] == true},
              )
              .toList(),
        );
      }
    }

    if (path == '/notifications/read-all' && method == 'POST') {
      for (final notice in notifications) {
        notice['is_read'] = true;
      }
      return _ok(null);
    }

    if (parts.length == 3 &&
        parts.first == 'notifications' &&
        parts[2] == 'read' &&
        method == 'POST') {
      final id = int.tryParse(parts[1]) ?? 0;
      for (final notice in notifications) {
        if (notice['id'] == id) notice['is_read'] = true;
      }
      return _ok(null);
    }

    if (path == '/conversations' && method == 'GET') {
      final result = <Map<String, dynamic>>[];
      for (final entry in chats.entries) {
        if (entry.value.isEmpty) continue;
        result.add({
          'user': userPayload(_user(entry.key)),
          'last_message': messagePayload(entry.value.last),
          'unread_count': unread[entry.key] ?? 0,
        });
      }
      return _ok(result);
    }

    if (parts.length >= 2 &&
        parts.first == 'conversations' &&
        parts.length <= 3) {
      final user = _userByUsername(parts[1]);
      final id = user['id'] as int;
      if (method == 'GET') {
        return _ok((chats[id] ?? const []).map(messagePayload).toList());
      }
      if (method == 'POST' && parts.length == 3 && parts[2] == 'read') {
        unread[id] = 0;
        return _ok(null);
      }
      if (method == 'POST' && parts.length == 3 && parts[2] == 'messages') {
        final message = {
          'id': ++_sequence,
          'sender_id': self['id'],
          'body': _text(input, 'body'),
          'created_at': '2026-10-20T12:00:00Z',
        };
        chats.putIfAbsent(id, () => []).add(message);
        return _created(messagePayload(message));
      }
    }

    return _error(404, 'Endpoint palsu tidak ditemukan: $method $path');
  }
}
