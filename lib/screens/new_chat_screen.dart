import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  String _searchQuery = "";
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _startConversation(String targetUserId, String peerName) async {
    if (_currentUserId == null) return;

    // 1. Check if a conversation between these two already exists
    final existingConvo = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _currentUserId)
        .get();

    String? convoId;
    for (var doc in existingConvo.docs) {
      List participants = doc['participants'];
      if (participants.contains(targetUserId)) {
        convoId = doc.id;
        break;
      }
    }

    // 2. If it doesn't exist, create a new one
    if (convoId == null) {
      final newConvo = await FirebaseFirestore.instance
          .collection('conversations')
          .add({
            'participants': [_currentUserId, targetUserId],
            'lastMessage': '',
            'lastMessageTime':
                FieldValue.serverTimestamp(), // ✅ consistent field name
            'typingStatus': {_currentUserId: false, targetUserId: false},
            'lastRead': {
              _currentUserId: FieldValue.serverTimestamp(),
              targetUserId: FieldValue.serverTimestamp(),
            },
          });
      convoId = newConvo.id;
    }

    // 3. Navigate to the chat screen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convoId!,
          otherUserId: targetUserId,
          peerName: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C35CC),
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search by email...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white60),
          ),
          onChanged: (val) =>
              setState(() => _searchQuery = val.toLowerCase().trim()),
        ),
      ),
      body: _searchQuery.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Search for someone to chat with',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isGreaterThanOrEqualTo: _searchQuery)
                  .where('email', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users =
                    snapshot.data?.docs
                        .where((doc) => doc.id != _currentUserId)
                        .toList() ??
                    [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users found for "$_searchQuery"',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 72,
                    color: Color(0xFFEEEEEE),
                  ),
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;
                    final email = userData['email'] ?? 'Unknown';
                    final displayName = userData['displayName'] ?? email;
                    final photoUrl = userData['photoUrl'] as String?;
                    final isOnline = userData['isOnline'] == true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.deepPurple[100],
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
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
                                width: 12,
                                height: 12,
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
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C35CC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Message',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      onTap: () =>
                          _startConversation(users[index].id, displayName),
                    );
                  },
                );
              },
            ),
    );
  }
}
