// Model netral: halaman tidak bergantung pada format respons backend tertentu.
int _asInt(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String _asString(dynamic value, [String fallback = '']) =>
    value == null ? fallback : '$value';

List<int> _asPalette(dynamic value) {
  if (value is! List || value.isEmpty) {
    return const [0xFFDAC9B7, 0xFF71685E, 0xFF303830];
  }
  return value.map((entry) => _asInt(entry)).where((e) => e != 0).toList();
}

class Pin {
  final String id, title, description, image, authorId, category, vibe;
  final List<String> tags;
  final List<int> palette;
  final double aspectRatio;
  final int likes;
  final String sourceUrl, createdAt;

  const Pin({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.authorId,
    required this.category,
    required this.vibe,
    this.tags = const [],
    this.palette = const [0xFFDAC9B7, 0xFF71685E, 0xFF303830],
    this.aspectRatio = .72,
    this.likes = 0,
    this.sourceUrl = '',
    this.createdAt = '',
  });

  factory Pin.fromJson(Map<String, dynamic> j) => Pin(
    id: _asString(j['id']),
    title: _asString(j['title'], 'Tanpa judul'),
    description: _asString(j['description']),
    image: _asString(j['image']),
    authorId: _asString(j['authorId']),
    category: _asString(j['category'], 'Kreatif'),
    vibe: _asString(j['vibe'], 'Calm'),
    tags: List<String>.from(j['tags'] as List? ?? []),
    palette: List<int>.from(j['palette'] as List? ?? [0xFFDAC9B7]),
    aspectRatio: (j['aspectRatio'] as num? ?? .72).toDouble(),
    likes: _asInt(j['likes']),
    sourceUrl: _asString(j['sourceUrl']),
    createdAt: _asString(j['createdAt']),
  );

  /// Maps the JSON returned by `PinResource`.
  factory Pin.fromApi(Map<String, dynamic> j) {
    final user = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : const <String, dynamic>{};
    final width = (j['image_width'] as num?)?.toDouble();
    final height = (j['image_height'] as num?)?.toDouble();
    final ratio = width != null && height != null && height > 0
        ? width / height
        : .72;
    final tags = j['tags'] is List
        ? List<String>.from((j['tags'] as List).map((e) => '$e'))
        : <String>[];
    final palette = _asPalette(j['palette']);

    return Pin(
      id: _asString(j['id']),
      title: _asString(j['title']).trim().isEmpty
          ? 'Tanpa judul'
          : _asString(j['title']),
      description: _asString(j['description']),
      image: _asString(j['image_url']),
      authorId: _asString(user['id']),
      category: _asString(j['category'], 'Kreatif'),
      vibe: _asString(j['vibe'], 'Calm'),
      tags: tags,
      palette: palette.isEmpty
          ? const [0xFFDAC9B7, 0xFF71685E, 0xFF303830]
          : palette,
      aspectRatio: ratio.clamp(.4, 1.8),
      likes: _asInt(j['likes_count']),
      sourceUrl: _asString(j['source_url']),
      createdAt: _asString(j['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'authorId': authorId,
    'category': category,
    'vibe': vibe,
    'tags': tags,
    'palette': palette,
    'aspectRatio': aspectRatio,
    'likes': likes,
    'sourceUrl': sourceUrl,
    'createdAt': createdAt,
  };

  Pin copyWith({
    String? title,
    String? description,
    String? image,
    String? category,
    String? vibe,
    List<String>? tags,
    List<int>? palette,
    double? aspectRatio,
    int? likes,
    String? sourceUrl,
  }) => Pin(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    image: image ?? this.image,
    authorId: authorId,
    category: category ?? this.category,
    vibe: vibe ?? this.vibe,
    tags: tags ?? this.tags,
    palette: palette ?? this.palette,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    likes: likes ?? this.likes,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    createdAt: createdAt,
  );
}

class Creator {
  final String id, name, username, bio, avatar;
  final int color;
  final int pinsCount, followersCount;
  final bool isFollowing;

  const Creator({
    required this.id,
    required this.name,
    required this.username,
    this.bio = '',
    this.avatar = '',
    this.color = 0xFFC3B2E7,
    this.pinsCount = 0,
    this.followersCount = 0,
    this.isFollowing = false,
  });

  factory Creator.fromApi(Map<String, dynamic> j) {
    final username = _asString(j['username']);
    return Creator(
      id: _asString(j['id']),
      name: _asString(j['name'], username),
      username: username,
      bio: _asString(j['bio']),
      avatar: _asString(j['avatar_url']),
      color: colorFor(_asString(j['id'], username)),
      pinsCount: _asInt(j['pins_count']),
      followersCount: _asInt(j['followers_count']),
      isFollowing: j['is_following'] == true,
    );
  }

  static const _colors = [
    0xFFB6CDA0,
    0xFFC3B2E7,
    0xFFFF806B,
    0xFFE4BC81,
    0xFF8FB8C9,
    0xFFD3A6B8,
  ];

  static int colorFor(String seed) {
    if (seed.isEmpty) return _colors.first;
    final hash = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _colors[hash % _colors.length];
  }

  Creator copyWith({
    String? name,
    String? username,
    String? bio,
    String? avatar,
    int? pinsCount,
    int? followersCount,
    bool? isFollowing,
  }) => Creator(
    id: id,
    name: name ?? this.name,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    avatar: avatar ?? this.avatar,
    color: color,
    pinsCount: pinsCount ?? this.pinsCount,
    followersCount: followersCount ?? this.followersCount,
    isFollowing: isFollowing ?? this.isFollowing,
  );
}

class Board {
  final String id, title, description, createdAt;
  final bool secret;
  final List<String> pinIds;
  final String ownerId, ownerName, ownerAvatar;

  const Board({
    required this.id,
    required this.title,
    this.description = '',
    this.secret = false,
    this.pinIds = const [],
    this.createdAt = '',
    this.ownerId = '',
    this.ownerName = '',
    this.ownerAvatar = '',
  });

  factory Board.fromApi(Map<String, dynamic> j) {
    final pinIds = j['pin_ids'] is List
        ? List<String>.from((j['pin_ids'] as List).map((e) => '$e'))
        : <String>[];
    final user = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : const <String, dynamic>{};
    return Board(
      id: _asString(j['id']),
      title: _asString(j['name'], 'Board tanpa nama'),
      description: _asString(j['description']),
      secret: j['is_private'] == true,
      pinIds: pinIds,
      createdAt: _asString(j['created_at']),
      ownerId: _asString(user['id']),
      ownerName: _asString(user['name']),
      ownerAvatar: _asString(user['avatar_url']),
    );
  }

  Board copyWith({
    String? title,
    String? description,
    bool? secret,
    List<String>? pinIds,
  }) => Board(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    secret: secret ?? this.secret,
    pinIds: pinIds ?? this.pinIds,
    createdAt: createdAt,
    ownerId: ownerId,
    ownerName: ownerName,
    ownerAvatar: ownerAvatar,
  );

  factory Board.fromJson(Map<String, dynamic> j) => Board(
    id: _asString(j['id']),
    title: _asString(j['title'], 'Board tanpa nama'),
    description: _asString(j['description']),
    secret: j['secret'] as bool? ?? false,
    pinIds: List<String>.from(j['pinIds'] as List? ?? []),
    createdAt: _asString(j['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'secret': secret,
    'pinIds': pinIds,
    'createdAt': createdAt,
  };
}

class UserProfile {
  final String id, name, username, email, bio, avatar, website;
  final int pinsCount, boardsCount, followersCount, followingCount;

  const UserProfile({
    this.id = '',
    this.name = 'Iza',
    this.username = 'iza.creates',
    this.email = 'demo@pinspire.test',
    this.bio = 'Mengumpulkan ide kecil untuk hal-hal besar.',
    this.avatar = '',
    this.website = '',
    this.pinsCount = 0,
    this.boardsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserProfile.fromApi(Map<String, dynamic> j) => UserProfile(
    id: _asString(j['id']),
    name: _asString(j['name'], 'Pengguna Pinspire'),
    username: _asString(j['username']),
    email: _asString(j['email']),
    bio: _asString(j['bio']),
    avatar: _asString(j['avatar_url']),
    website: _asString(j['website']),
    pinsCount: _asInt(j['pins_count']),
    boardsCount: _asInt(j['boards_count']),
    followersCount: _asInt(j['followers_count']),
    followingCount: _asInt(j['following_count']),
  );

  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? bio,
    String? avatar,
    String? website,
    int? pinsCount,
    int? boardsCount,
    int? followersCount,
    int? followingCount,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    bio: bio ?? this.bio,
    avatar: avatar ?? this.avatar,
    website: website ?? this.website,
    pinsCount: pinsCount ?? this.pinsCount,
    boardsCount: boardsCount ?? this.boardsCount,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
  );

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: _asString(j['name'], 'Pengguna Pinspire'),
    username: _asString(j['username']),
    email: _asString(j['email']),
    bio: _asString(j['bio']),
    avatar: _asString(j['avatar']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'email': email,
    'bio': bio,
    'avatar': avatar,
  };
}

class PinComment {
  final String id, pinId, author, text, createdAt;
  final String authorName, authorAvatar;
  final bool mine;

  const PinComment({
    required this.id,
    required this.pinId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.authorName = '',
    this.authorAvatar = '',
    this.mine = false,
  });

  factory PinComment.fromJson(Map<String, dynamic> j) => PinComment(
    id: _asString(j['id']),
    pinId: _asString(j['pinId']),
    author: _asString(j['author']),
    text: _asString(j['text']),
    createdAt: _asString(j['createdAt']),
  );

  factory PinComment.fromApi(Map<String, dynamic> j) {
    final user = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : const <String, dynamic>{};
    return PinComment(
      id: _asString(j['id']),
      pinId: _asString(j['pin_id']),
      author: _asString(user['id']),
      text: _asString(j['text']),
      createdAt: _asString(j['created_at']),
      authorName: _asString(user['name']),
      authorAvatar: _asString(user['avatar_url']),
      mine: j['mine'] == true,
    );
  }

  PinComment copyWith({String? authorName, String? authorAvatar, bool? mine}) =>
      PinComment(
        id: id,
        pinId: pinId,
        author: author,
        text: text,
        createdAt: createdAt,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        mine: mine ?? this.mine,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'pinId': pinId,
    'author': author,
    'text': text,
    'createdAt': createdAt,
  };
}

class ChatMessage {
  final String id, text, createdAt, senderId;
  final bool mine;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.createdAt,
    this.senderId = '',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: _asString(j['id']),
    text: _asString(j['text']),
    mine: j['mine'] as bool? ?? false,
    createdAt: _asString(j['createdAt']),
  );

  factory ChatMessage.fromApi(Map<String, dynamic> j) {
    final sender = j['sender'] is Map
        ? Map<String, dynamic>.from(j['sender'] as Map)
        : const <String, dynamic>{};
    return ChatMessage(
      id: _asString(j['id']),
      text: _asString(j['body']),
      mine: j['mine'] == true,
      createdAt: _asString(j['created_at']),
      senderId: _asString(sender['id']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'mine': mine,
    'createdAt': createdAt,
  };
}

class Conversation {
  final Creator user;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.user,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromApi(Map<String, dynamic> j) {
    final user = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : const <String, dynamic>{};
    final last = j['last_message'] is Map
        ? Map<String, dynamic>.from(j['last_message'] as Map)
        : null;
    return Conversation(
      user: Creator.fromApi(user),
      lastMessage: last == null ? null : ChatMessage.fromApi(last),
      unreadCount: _asInt(j['unread_count']),
    );
  }

  Conversation copyWith({ChatMessage? lastMessage, int? unreadCount}) =>
      Conversation(
        user: user,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class AppNotice {
  final String id, type, title, body, targetType, targetId, image, createdAt;
  final bool isRead;

  const AppNotice({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.image = '',
    this.isRead = false,
  });

  factory AppNotice.fromApi(Map<String, dynamic> j) => AppNotice(
    id: _asString(j['id']),
    type: _asString(j['type']),
    title: _asString(j['title']),
    body: _asString(j['body']),
    targetType: _asString(j['target_type']),
    targetId: _asString(j['target_id']),
    image: _asString(j['image_url']),
    isRead: j['is_read'] == true,
    createdAt: _asString(j['created_at']),
  );

  AppNotice copyWith({bool? isRead}) => AppNotice(
    id: id,
    type: type,
    title: title,
    body: body,
    targetType: targetType,
    targetId: targetId,
    image: image,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}
