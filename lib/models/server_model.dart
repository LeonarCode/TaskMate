import 'package:cloud_firestore/cloud_firestore.dart';

class ServerModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> memberIds;
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
    'iconColorValue': iconColorValue,
    'iconEmoji': iconEmoji,
    'createdAt': Timestamp.fromDate(createdAt),
    'memberCount': memberCount,
  };

  ServerModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
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
      iconColorValue: iconColorValue ?? this.iconColorValue,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      createdAt: createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
