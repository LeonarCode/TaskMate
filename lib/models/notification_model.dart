import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotifType type;
  final DateTime timestamp;
  final bool isRead;
  final String? refId; // taskId, serverId, dmId, etc.

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.refId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotifType.values[data['type'] ?? 0],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      refId: data['refId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.index,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'refId': refId,
  };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      refId: refId,
    );
  }
}
