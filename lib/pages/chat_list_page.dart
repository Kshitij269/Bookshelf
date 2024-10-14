import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sangy/pages/view_chat_page.dart'; // Assuming this is the correct import for ChatPage

class ChatListPage extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No chats available',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          var chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatData = chatDocs[index].data() as Map<String, dynamic>?;
              if (chatData == null || !chatData.containsKey('participants')) {
                // Safely check if data exists
                return const ListTile(
                  title: Text('Error loading chat'),
                );
              }

              String chatId = chatDocs[index].id;
              List<dynamic> participants = chatData['participants'] ?? [];
              String otherUser = participants.firstWhere(
                    (p) => p != user.email,
                orElse: () => 'Unknown User',
              );

              return ListTile(
                title: Text(otherUser),
                subtitle: Text('Chat with $otherUser'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        otherUserEmail: otherUser,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
