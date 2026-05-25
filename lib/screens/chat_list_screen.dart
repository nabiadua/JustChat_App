import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  // ── FIX 1: Proper logout ────────────────────────────────────────────────────
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Replace entire stack with login route so back button can't return here
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ── Unread count: messages after lastRead timestamp ─────────────────────────
  Widget _buildUnreadBadge(
    String convoId,
    String uid,
    Map<String, dynamic> convoData,
  ) {
    final lastReadMap = convoData['lastRead'] as Map<String, dynamic>? ?? {};
    final lastRead = lastReadMap[uid] as Timestamp?;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(convoId)
          .collection('messages')
          .where('senderId', isNotEqualTo: uid) // only other person's messages
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        // Count messages sent AFTER our lastRead timestamp
        final unread = snap.data!.docs.where((doc) {
          if (lastRead == null) return true;
          final msgTime = (doc.data() as Map)['createdAt'] as Timestamp?;
          if (msgTime == null) return false;
          return msgTime.toDate().isAfter(lastRead.toDate());
        }).length;

        if (unread == 0) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Color(0xFF5C35CC),
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          child: Text(
            unread > 99 ? '99+' : '$unread',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          // ── FIX 2: logout now calls _logout which clears the nav stack ──
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aTime = (a.data() as Map)['lastMessageTime'] as Timestamp?;
            final bTime = (b.data() as Map)['lastMessageTime'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to start one!',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 76,
              endIndent: 16,
              color: Color(0xFFEEEEEE),
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>;

              final otherUserId =
                  participants.firstWhere((id) => id != uid, orElse: () => '')
                      as String;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnap) {
                  String displayName = 'Loading...';
                  String? photoUrl;
                  bool isOnline = false;

                  if (userSnap.hasData && userSnap.data!.exists) {
                    final u = userSnap.data!.data() as Map<String, dynamic>;
                    displayName = u['displayName'] ?? u['email'] ?? 'Unknown';
                    photoUrl = u['photoUrl'];
                    isOnline = u['isOnline'] == true;
                  }

                  final lastMessage =
                      data['lastMessage'] as String? ?? 'No messages yet...';
                  final lastMessageTime = data['lastMessageTime'] as Timestamp?;

                  // Check if there are unread messages to bold the tile
                  final lastReadMap =
                      data['lastRead'] as Map<String, dynamic>? ?? {};
                  final myLastRead = lastReadMap[uid] as Timestamp?;
                  final lastMsgTime = data['lastMessageTime'] as Timestamp?;
                  final hasUnread =
                      myLastRead == null ||
                      (lastMsgTime != null &&
                          lastMsgTime.toDate().isAfter(myLastRead.toDate()));

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.deepPurple[100],
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                )
                              : null,
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight
                                        .w700 // bold if unread
                                  : FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            // Purple timestamp if unread, grey if read
                            color: hasUnread
                                ? const Color(0xFF5C35CC)
                                : Colors.grey[500],
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                // Bold preview text if unread
                                color: hasUnread
                                    ? Colors.black87
                                    : Colors.grey[500],
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ── FIX 3: Unread count badge ──────────────────
                          if (uid != null) _buildUnreadBadge(doc.id, uid, data),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: doc.id,
                            otherUserId: otherUserId,
                            peerName: '',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5C35CC),
        onPressed: () => Navigator.pushNamed(context, '/new-chat'),
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }
}
