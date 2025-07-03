import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/chat_list_item.dart';
import '../models/chat_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<String> getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      // Handle case where user is not logged in
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sampark',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.accentOrange,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Search functionality
            },
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/your-profile');
                  break;
                case 'settings':
                  // Navigate to settings
                  break;
                case 'logout':
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Chats', true),
                const SizedBox(width: 16),
                _buildTab('Calls', false),
              ],
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('members', arrayContains: currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading chats'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No chats available'));
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatData =
                        chatDocs[index].data() as Map<String, dynamic>;
                    final chatId = chatDocs[index].id;
                    final members = List<String>.from(chatData['members']);
                    final lastMessage = chatData['lastMessage'] ?? '';
                    final lastTime =
                        (chatData['lastTime'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    // Find the other user's UID
                    final otherUserId = members.firstWhere(
                      (uid) => uid != currentUser!.uid,
                    );

                    // Fetch the other user's name
                    return FutureBuilder<String>(
                      future: getUserName(otherUserId),
                      builder: (context, nameSnapshot) {
                        if (nameSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading...'));
                        }
                        final name = nameSnapshot.data ?? 'Unknown';

                        final chat = ChatModel(
                          chatId: chatId,
                          name: name,
                          lastMessage: lastMessage,
                          lastTime: lastTime,
                          isOnline: false, // Implement logic if needed
                          unreadCount: 0, // Implement logic if needed
                          otherUserId: otherUserId,
                        );

                        return ChatListItem(
                          chat: chat,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'chatId': chatId,
                              'otherUserId': otherUserId,
                              'otherUserName': name,
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => Navigator.pushNamed(context, '/new-chat'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.cardBackground,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/profile');
              break;
            case 2:
              Navigator.pushNamed(context, '/new-contact');
              break;
            case 3:
              Navigator.pushNamed(context, '/call');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
