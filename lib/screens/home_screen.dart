import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/chat_list_item.dart';
import '../models/chat_model.dart';
import '../services/message_cache.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _selectedTab = 'Chats';

  // To keep track of our call listner
  StreamSubscription<QuerySnapshot>? _callSubscription;

  // Cache user data to avoid re-fetching on every StreamBuilder rebuild.
  // Key: uid, Value: {name, profilePic}
  final Map<String, Map<String, String>> _userCache = {};

  bool _isIncomingDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    if (currentUser == null) return;

    // Listen to calls collection where we are reciever and it's ringing
    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser?.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              if (_isIncomingDialogVisible) return;
              final callData = change.doc.data() as Map<String, dynamic>;
              _showIncomingCallDialog(callData, change.doc.id);
            }
          }
        });
  }

  void _showIncomingCallDialog(
    Map<String, dynamic> callData,
    String callDocId,
  ) {
    _isIncomingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          title: const Text(
            'Incoming Call',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${callData['callerName']} is calling you!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Decline
                FirebaseFirestore.instance
                    .collection('calls')
                    .doc(callDocId)
                    .update({'status': 'rejected'});
                Navigator.pop(context);
              },
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                // Accept
                await FirebaseFirestore.instance
                    .collection('calls')
                    .doc(callDocId)
                    .update({'status': 'accepted'});
                Navigator.pop(context); //Close dialog
                Navigator.pushNamed(
                  context,
                  '/call',
                  arguments: {
                    'chatId': callData['channelId'],
                    'receiverId': currentUser!.uid,
                    'receiverName': callData['callerName'],
                    'isCaller': false,
                  },
                );
              },
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      _isIncomingDialogVisible = false; //resets when dialog closes
    });
  }

  Future<Map<String, String>> getUserData(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userDoc.exists
          ? {
              'name':
                  (userDoc.data() as Map<String, dynamic>)['name']
                      ?.toString() ??
                  'Unknown',
              'profilePic':
                  (userDoc.data() as Map<String, dynamic>)['profilePic']
                      ?.toString() ??
                  '',
            }
          : {'name': 'Unknown', 'profilePic': ''};
      _userCache[uid] = data;
      return data;
    } catch (e) {
      // Don't cache errors so a retry is possible next time.
      return {'name': 'Unknown', 'profilePic': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Chats', _selectedTab == 'Chats'),
                const SizedBox(width: 16),
                _buildTab('Contacts', _selectedTab == 'Contacts'),
                const SizedBox(width: 16),
                _buildTab('Calls', _selectedTab == 'Calls'),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'Chats'
                ? _buildChatsList()
                : _selectedTab == 'Contacts'
                ? _buildContactsList()
                : _buildCallsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => Navigator.pushNamed(context, '/new-contact'),
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
              break;
            case 1:
              Navigator.pushNamed(context, '/new-contact');
              break;
            case 2:
              setState(() {
                _selectedTab = 'Calls';
              });
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: currentUser!.uid)
          .orderBy('lastTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Error in chats StreamBuilder: ${snapshot.error}');
          return const Center(
            child: Text('Failed to load chats. Please try again.'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No chats available'));
        }

        final chatDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data() as Map<String, dynamic>;
            final chatId = chatDocs[index].id;
            final members = List<String>.from(chatData['members'] ?? []);
            final lastMessage = chatData['lastMessage'] ?? '';
            final lastTime =
                (chatData['lastTime'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final otherUserId = members.firstWhere(
              (uid) => uid != currentUser!.uid,
              orElse: () => '',
            );

            final unreadCount =
                (chatData['unreadCount_${currentUser!.uid}'] as int?) ?? 0;

            if (otherUserId.isEmpty) {
              return const ListTile(title: Text('Invalid chat data'));
            }

            // Fire-and-forget prefetch so ChatScreen opens instantly.
            MessageCache.instance.prefetch(chatId);

            return FutureBuilder<Map<String, String>>(
              future: getUserData(otherUserId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text('Loading...'));
                }
                if (userSnapshot.hasError) {
                  print('Error in userSnapshot: ${userSnapshot.error}');
                  return const ListTile(title: Text('Error loading user'));
                }
                final userData =
                    userSnapshot.data ?? {'name': 'Unknown', 'profilePic': ''};
                final name = userData['name']!;
                final profilePic = userData['profilePic']!;

                final chat = ChatModel(
                  chatId: chatId,
                  name: name,
                  lastMessage: lastMessage,
                  lastTime: lastTime,
                  isOnline: false,
                  unreadCount: unreadCount,
                  otherUserId: otherUserId,
                  profilePicURL: profilePic,
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
                      'profilePic': profilePic,
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContactsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('contacts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('Error in contacts StreamBuilder: ${snapshot.error}');
          return const Center(
            child: Text('Failed to load contacts. Please try again.'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No contacts available'));
        }

        final contactDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: contactDocs.length,
          itemBuilder: (context, index) {
            final contactData =
                contactDocs[index].data() as Map<String, dynamic>;
            final contactId = contactDocs[index].id;
            final name = contactData['name'] ?? 'Unknown';
            final email = contactData['email'] ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                email,
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () async {
                try {
                  final chatId = _generateChatId(currentUser!.uid, contactId);
                  print('Opening chat: $chatId for contact: $contactId');

                  final chatDoc = await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .get();

                  if (!chatDoc.exists) {
                    print('Creating new chat document: $chatId');
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .set({
                          'members': [currentUser!.uid, contactId],
                          'lastMessage': '',
                          'lastTime': FieldValue.serverTimestamp(),
                          'unreadCount_${currentUser!.uid}': 0,
                          'unreadCount_$contactId': 0,
                        });
                  }

                  print('Navigating to chat screen with args');
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'chatId': chatId,
                      'otherUserId': contactId,
                      'otherUserName': name,
                      'profilePic': contactData['profilePic'] ?? '',
                    },
                  );
                } catch (e) {
                  print('Error opening chat from contact: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCallsList() {
    return const Center(child: Text('Calls not implemented'));
  }

  String _generateChatId(String uid1, String uid2) {
    final uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }
}
