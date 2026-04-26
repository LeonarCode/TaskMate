import 'package:cloud_firestore/cloud_firestore.dart';

class ServerModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> memberIds;
  final List<String> chats;
  final List<String> tasks;
  final int iconColorValue;
  final String? iconEmoji;
  final DateTime createdAt;
  final int memberCount;

  const ServerModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    this.memberIds = const [],
    this.chats = const [],
    this.tasks = const [],
    this.iconColorValue = 0xFF7C3AED,
    this.iconEmoji,
    required this.createdAt,
    this.memberCount = 1,
  });

  factory ServerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServerModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      chats: List<String>.from(data['chats'] ?? []),
      tasks: List<String>.from(data['tasks'] ?? []),
      iconColorValue: data['iconColorValue'] ?? 0xFF7C3AED,
      iconEmoji: data['iconEmoji'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberCount: data['memberCount'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'memberIds': memberIds,
    'chats': chats,
    'tasks': tasks,
    'iconColorValue': iconColorValue,
    'iconEmoji': iconEmoji,
    'createdAt': Timestamp.fromDate(createdAt),
    'memberCount': memberCount,
  };

  ServerModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    List<String>? chats,
    List<String>? tasks,
    int? iconColorValue,
    String? iconEmoji,
    int? memberCount,
  }) {
    return ServerModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      chats: chats ?? this.chats,
      tasks: tasks ?? this.tasks,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
