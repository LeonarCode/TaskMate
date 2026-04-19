import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/server_model.dart';
import '../models/rating_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Tasks ────────────────────────────────────────────────────────────────────
  Future<void> syncTask(TaskModel task) async {
    await _db.collection(AppStrings.colTasks).doc(task.id).set(task.toFirestore());
  }

  Future<List<TaskModel>> fetchUserTasks(String uid) async {
    final query = await _db
        .collection(AppStrings.colTasks)
        .where('uid', isEqualTo: uid)
        .get();
    return query.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  // ── Direct Messages (DMs) ─────────────────────────────────────────────────────
  Stream<List<DMModel>> userDMsStream(String uid) {
    return _db
        .collection(AppStrings.colDMs)
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => DMModel.fromFirestore(doc)).toList());
  }

  Future<String> getOrCreateDM(String currentUid, String otherUid) async {
    final dmId = DMModel.buildDmId(currentUid, otherUid);
    final docRef = _db.collection(AppStrings.colDMs).doc(dmId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      await docRef.set({
        'participants': [currentUid, otherUid],
        'unreadCount': {currentUid: 0, otherUid: 0},
      });
    }
    return dmId;
  }

  Future<void> sendDM(String dmId, MessageModel message) async {
    final docRef = _db.collection(AppStrings.colDMs).doc(dmId);
    await docRef.collection(AppStrings.colMessages).add(message.toFirestore());

    final docSnap = await docRef.get();
    final participants = List<String>.from(docSnap.data()?['participants'] ?? []);
    final unreadCount = Map<String, int>.from(docSnap.data()?['unreadCount'] ?? {});

    for (final p in participants) {
      if (p != message.senderId) {
        unreadCount[p] = (unreadCount[p] ?? 0) + 1;
      }
    }

    await docRef.update({
      'lastMessage': message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'unreadCount': unreadCount,
    });
  }

  Stream<List<MessageModel>> dmMessagesStream(String dmId) {
    return _db
        .collection(AppStrings.colDMs)
        .doc(dmId)
        .collection(AppStrings.colMessages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> markDMRead(String dmId, String currentUid) async {
    await _db.collection(AppStrings.colDMs).doc(dmId).update({
      'unreadCount.$currentUid': 0,
    });
  }

  // ── Users ────────────────────────────────────────────────────────────────────
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection(AppStrings.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final q = query.toLowerCase();
    final snap = await _db
        .collection(AppStrings.colUsers)
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: '$q\uf8ff')
        .get();
    return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppStrings.colUsers).doc(uid).update(data);
  }

  // ── Servers ──────────────────────────────────────────────────────────────────
  Stream<List<ServerModel>> userServersStream(String uid) {
    return _db
        .collection(AppStrings.colServers)
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ServerModel.fromFirestore(doc)).toList());
  }

  Stream<List<ServerModel>> publicServersStream() {
    return _db
        .collection(AppStrings.colServers)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ServerModel.fromFirestore(doc)).toList());
  }

  Future<void> joinServer(String serverId, String uid) async {
    await _db.collection(AppStrings.colServers).doc(serverId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'memberCount': FieldValue.increment(1),
    });
  }

  Future<void> createServer(ServerModel server) async {
    final docRef = _db.collection(AppStrings.colServers).doc();
    await docRef.set(server.toFirestore());
  }

  // ── Ratings ──────────────────────────────────────────────────────────────────
  Stream<List<RatingModel>> userRatingsStream(String uid) {
    return _db
        .collection(AppStrings.colUsers)
        .doc(uid)
        .collection(AppStrings.colRatings)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => RatingModel.fromFirestore(doc)).toList());
  }
}
