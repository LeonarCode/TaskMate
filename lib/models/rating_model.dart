import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String toName;
  final String serverId;
  final String serverName;
  final double score; // 1.0 – 5.0
  final String comment;
  final DateTime timestamp;

  const RatingModel({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.toName,
    required this.serverId,
    required this.serverName,
    required this.score,
    this.comment = '',
    required this.timestamp,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      toUid: data['toUid'] ?? '',
      toName: data['toName'] ?? '',
      serverId: data['serverId'] ?? '',
      serverName: data['serverName'] ?? '',
      score: (data['score'] ?? 3.0).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fromUid': fromUid,
    'fromName': fromName,
    'toUid': toUid,
    'toName': toName,
    'serverId': serverId,
    'serverName': serverName,
    'score': score,
    'comment': comment,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
