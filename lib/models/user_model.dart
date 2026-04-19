import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final int age;
  final UserType userType;
  final String? photoUrl;
  final DateTime createdAt;
  final String? fcmToken;
  final double averageRating;
  final int ratingCount;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    required this.age,
    required this.userType,
    this.photoUrl,
    required this.createdAt,
    this.fcmToken,
    this.averageRating = 0.0,
    this.ratingCount = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      age: data['age'] ?? 0,
      userType:
          data['userType'] == 'employee' ? UserType.employee : UserType.student,
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'fullName': fullName,
    'username': username,
    'age': age,
    'userType': userType.name,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'fcmToken': fcmToken,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
  };

  UserModel copyWith({
    String? fullName,
    String? username,
    int? age,
    UserType? userType,
    String? photoUrl,
    String? fcmToken,
    double? averageRating,
    int? ratingCount,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      age: age ?? this.age,
      userType: userType ?? this.userType,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
