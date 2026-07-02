import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { pending, accepted, declined, completed }

class MatchModel {
  final String id;
  final String borrowerId;
  final String lenderId;
  final String requestId;
  final MatchStatus status;
  final bool contactUnlockedByLender;
  final bool contactUnlockedByBorrower;
  final String? chatRoomId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MatchModel({
    required this.id,
    required this.borrowerId,
    required this.lenderId,
    required this.requestId,
    this.status = MatchStatus.pending,
    this.contactUnlockedByLender = false,
    this.contactUnlockedByBorrower = false,
    this.chatRoomId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id:                        id,
      borrowerId:                map['borrowerId'] ?? '',
      lenderId:                  map['lenderId'] ?? '',
      requestId:                 map['requestId'] ?? '',
      status:                    MatchStatus.values.firstWhere(
                                   (e) => e.name == map['status'],
                                   orElse: () => MatchStatus.pending),
      contactUnlockedByLender:   map['contactUnlockedByLender'] ?? false,
      contactUnlockedByBorrower: map['contactUnlockedByBorrower'] ?? false,
      chatRoomId:                map['chatRoomId'],
      createdAt:                 (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:                 (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'borrowerId':                borrowerId,
    'lenderId':                  lenderId,
    'requestId':                 requestId,
    'status':                    status.name,
    'contactUnlockedByLender':   contactUnlockedByLender,
    'contactUnlockedByBorrower': contactUnlockedByBorrower,
    'chatRoomId':                chatRoomId,
    'createdAt':                 Timestamp.fromDate(createdAt),
    'updatedAt':                 Timestamp.fromDate(updatedAt),
  };
}

// ──────────────────────────────────────────────────
// Chat Message
// ──────────────────────────────────────────────────
enum MessageType { text, image, document, location, system }

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final bool isRead;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.isRead = false,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id:       id,
      senderId: map['senderId'] ?? '',
      content:  map['content'] ?? '',
      type:     MessageType.values.firstWhere(
                  (e) => e.name == map['type'],
                  orElse: () => MessageType.text),
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      isRead:   map['isRead'] ?? false,
      sentAt:   (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'content':  content,
    'type':     type.name,
    'mediaUrl': mediaUrl,
    'fileName': fileName,
    'isRead':   isRead,
    'sentAt':   Timestamp.fromDate(sentAt),
  };
}

// ──────────────────────────────────────────────────
// Review
// ──────────────────────────────────────────────────
class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhoto;
  final String targetId; // lender or borrower id
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhoto,
    required this.targetId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id:            id,
      reviewerId:    map['reviewerId'] ?? '',
      reviewerName:  map['reviewerName'] ?? '',
      reviewerPhoto: map['reviewerPhoto'],
      targetId:      map['targetId'] ?? '',
      rating:        (map['rating'] ?? 0).toDouble(),
      comment:       map['comment'] ?? '',
      createdAt:     (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewerId':    reviewerId,
    'reviewerName':  reviewerName,
    'reviewerPhoto': reviewerPhoto,
    'targetId':      targetId,
    'rating':        rating,
    'comment':       comment,
    'createdAt':     Timestamp.fromDate(createdAt),
  };
}
