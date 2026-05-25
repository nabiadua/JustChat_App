import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final Timestamp? lastMessageAt;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
    );
  }
}
