import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../models/chat_model.dart';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _hasResetUnreadCount = false; // Flag to prevent multiple resets
  int _lastMessageCount = 0; // Track message count to detect new messages

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _checkInitialMessage();
  }

  void _setupNotifications() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.data}');
      NotificationService.showNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'];
      final otherUserId = message.data['otherUserId'];
      final otherUserName = message.data['otherUserName'] ?? 'Unknown';
      if (chatId != null && ModalRoute.of(context)!.settings.arguments != null) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        if (args['chatId'] != chatId) {
          Navigator.pushReplacementNamed(
            context,
            '/chat',
            arguments: {
              'chatId': chatId,
              'otherUserId': otherUserId,
              'otherUserName': otherUserName,
            },
          );
        }
      }
    });
  }

  void _checkInitialMessage() async {
    // Handle notification tap when app is terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final chatId = initialMessage.data['chatId'];
      final otherUserId = initialMessage.data['otherUserId'];
      final otherUserName = initialMessage.data['otherUserName'] ?? 'Unknown';
      if (chatId != null) {
        Navigator.pushReplacementNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'otherUserId': otherUserId,
            'otherUserName': otherUserName,
          },
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset unread count when opening the chat
    if (!_hasResetUnreadCount && currentUser != null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final chatId = args['chatId'] as String;
        print('Resetting unread count for chatId: $chatId, user: ${currentUser!.uid}');
        FirebaseFirestore.instance.collection('chats').doc(chatId).update({
          'unreadCount_${currentUser!.uid}': 0,
        }).catchError((e) => print('Error resetting unread count: $e'));
        _hasResetUnreadCount = true; // Prevent multiple resets
      } else {
        print('Error: No navigation arguments provided');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String chatId) async {
    if (_messageController.text.trim().isNotEmpty && currentUser != null) {
      final messageText = _messageController.text.trim();
      try {
        // Add message to the messages subcollection
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': currentUser!.uid,
          'text': messageText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the parent chat document with lastMessage and lastTime
        await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
          'lastMessage': messageText,
          'lastTime': FieldValue.serverTimestamp(),
          'unreadCount_${currentUser!.uid}': 0, // Reset unread count for sender
          'unreadCount_${chatId.split('_').firstWhere((id) => id != currentUser!.uid)}':
              FieldValue.increment(1), // Increment unread count for recipient
        });

        _messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      0.0, // Top of the reversed list
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    // Retrieve navigation arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      print('Error: No navigation arguments provided');
      return const Scaffold(
        body: Center(child: Text('Error: Chat data not provided')),
      );
    }
    final chatId = args['chatId'] as String;
    final otherUserId = args['otherUserId'] as String;
    final otherUserName = args['otherUserName'] as String? ?? 'Unknown User'; // Fixed typo in key

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
          builder: (context, snapshot) {
            String profilePic = '';
            bool isOnline = false;
            String name = otherUserName;

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              print('ChatScreen user data for $otherUserId: $userData');
              profilePic = userData['profilePic']?.toString() ?? '';
              name = userData['name']?.toString() ?? otherUserName;
              final lastActive = (userData['lastActive'] as Timestamp?)?.toDate();
              isOnline = lastActive != null && DateTime.now().difference(lastActive).inMinutes < 5;
            } else {
              print('ChatScreen: No user data for $otherUserId');
            }

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                      backgroundColor: profilePic.isEmpty ? AppTheme.cardBackground : null,
                      child: profilePic.isEmpty
                          ? Icon(Icons.person, color: Colors.white, size: 20)
                          : null,
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.darkBackground,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: isOnline ? Colors.green : AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/call'),
            icon: const Icon(Icons.videocam),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/call'),
            icon: const Icon(Icons.call),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile', arguments: {'userId': otherUserId});
                  break;
                case 'media':
                  // Show media gallery (implement later)
                  break;
                case 'mute':
                  // Mute conversation (implement later)
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
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('Media & Files'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off),
                    SizedBox(width: 8),
                    Text('Mute'),
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
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error loading messages: ${snapshot.error}');
                  return const Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;
                // Scroll to bottom when new messages are added
                if (messages.length > _lastMessageCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  _lastMessageCount = messages.length;
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Show newest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final message = MessageModel(
                      message: messageData['text']?.toString() ?? '',
                      time: _formatTime((messageData['timestamp'] as Timestamp?)?.toDate()),
                      isMe: messageData['senderId'] == currentUser!.uid,
                    );
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                top: BorderSide(
                  color: Color(0xFF3C3C3E),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  onPressed: () {
                    _showAttachmentOptions();
                  },
                  icon: const Icon(
                    Icons.add,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                // Text Input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(chatId),
                    ),
                  ),
                ),
                // Send Button
                IconButton(
                  onPressed: () => _sendMessage(chatId),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
    } else if (date == DateTime(now.year, now.month, now.day - 1)) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year % 100}';
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  Icons.photo_camera,
                  'Camera',
                  Colors.red,
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  Colors.purple,
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'Document',
                  Colors.blue,
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  Icons.location_on,
                  'Location',
                  Colors.green,
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.person,
                  'Contact',
                  Colors.orange,
                  () {},
                ),
                _buildAttachmentOption(
                  Icons.mic,
                  'Audio',
                  Colors.teal,
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}