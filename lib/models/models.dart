// Model netral: halaman tidak bergantung pada format respons backend tertentu.
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
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    image: j['image'] as String,
    authorId: j['authorId'] as String,
    category: j['category'] as String,
    vibe: j['vibe'] as String? ?? 'Calm',
    tags: List<String>.from(j['tags'] as List? ?? []),
    palette: List<int>.from(j['palette'] as List? ?? [0xFFDAC9B7]),
    aspectRatio: (j['aspectRatio'] as num? ?? .72).toDouble(),
    likes: j['likes'] as int? ?? 0,
    sourceUrl: j['sourceUrl'] as String? ?? '',
    createdAt: j['createdAt'] as String? ?? '',
  );
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
}

class Creator {
  final String id, name, username, bio, avatar;
  final int color;
  const Creator({
    required this.id,
    required this.name,
    required this.username,
    this.bio = '',
    this.avatar = '',
    this.color = 0xFFC3B2E7,
  });
}

class Board {
  final String id, title, description, createdAt;
  final bool secret;
  final List<String> pinIds;
  const Board({
    required this.id,
    required this.title,
    this.description = '',
    this.secret = false,
    this.pinIds = const [],
    this.createdAt = '',
  });
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
  );
  factory Board.fromJson(Map<String, dynamic> j) => Board(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String? ?? '',
    secret: j['secret'] as bool? ?? false,
    pinIds: List<String>.from(j['pinIds'] as List? ?? []),
    createdAt: j['createdAt'] as String? ?? '',
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
  final String name, username, email, bio, avatar;
  const UserProfile({
    this.name = 'Iza',
    this.username = 'iza.creates',
    this.email = 'demo@pinspire.app',
    this.bio = 'Mengumpulkan ide kecil untuk hal-hal besar.',
    this.avatar = '',
  });
  UserProfile copyWith({
    String? name,
    String? username,
    String? email,
    String? bio,
    String? avatar,
  }) => UserProfile(
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    bio: bio ?? this.bio,
    avatar: avatar ?? this.avatar,
  );
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] as String,
    username: j['username'] as String,
    email: j['email'] as String,
    bio: j['bio'] as String? ?? '',
    avatar: j['avatar'] as String? ?? '',
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
  const PinComment({
    required this.id,
    required this.pinId,
    required this.author,
    required this.text,
    required this.createdAt,
  });
  factory PinComment.fromJson(Map<String, dynamic> j) => PinComment(
    id: j['id'],
    pinId: j['pinId'],
    author: j['author'],
    text: j['text'],
    createdAt: j['createdAt'],
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
  final String id, text, createdAt;
  final bool mine;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.createdAt,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'],
    text: j['text'],
    mine: j['mine'],
    createdAt: j['createdAt'],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'mine': mine,
    'createdAt': createdAt,
  };
}
