import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, taskRef, systemMsg }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final String? taskRefId; // for task reference messages

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.taskRefId,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values[data['type'] ?? 0],
      imageUrl: data['imageUrl'],
      taskRefId: data['taskRefId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'type': type.index,
    'imageUrl': imageUrl,
    'taskRefId': taskRefId,
  };
}

class DMModel {
  final String id; // sorted uid1_uid2
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;

  const DMModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory DMModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DMModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participants': participants,
    'lastMessage': lastMessage,
    'lastMessageTime':
        lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
    'unreadCount': unreadCount,
  };

  static String buildDmId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }
}
