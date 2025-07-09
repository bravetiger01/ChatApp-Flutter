import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
  bool _hasResetUnreadCount = false;
  int _lastMessageCount = 0;
  bool _isEditing = false;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _checkInitialMessage();
  }

  void _setupNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.data}');
      NotificationService.showNotification(message);
    });

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
    if (!_hasResetUnreadCount && currentUser != null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final chatId = args['chatId'] as String;
        print('Resetting unread count for chatId: $chatId, user: ${currentUser!.uid}');
        FirebaseFirestore.instance.collection('chats').doc(chatId).update({
          'unreadCount_${currentUser!.uid}': 0,
        }).catchError((e) => print('Error resetting unread count: $e'));
        _hasResetUnreadCount = true;
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
      
      if (_isEditing && _editingMessageId != null) {
        _updateMessage(chatId, _editingMessageId!, messageText);
        _cancelEdit();
      } else {
        try {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .add({
            'senderId': currentUser!.uid,
            'text': messageText,
            'timestamp': FieldValue.serverTimestamp(),
            'isEdited': false,
          });

          await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
            'lastMessage': messageText,
            'lastTime': FieldValue.serverTimestamp(),
            'unreadCount_${currentUser!.uid}': 0,
            'unreadCount_${chatId.split('_').firstWhere((id) => id != currentUser!.uid)}':
                FieldValue.increment(1),
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
  }

  Future<void> _sendFile(String chatId, File file, String type) async {
    try {
      String fileUrl = await _uploadFile(file, type);
      String fileName = file.path.split('/').last; // Store original file name
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUser!.uid,
        'text': '',
        'fileUrl': fileUrl,
        'fileType': type,
        'fileName': fileName, // Add file name to Firestore
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': type == 'image' ? 'Image' : 'Document',
        'lastTime': FieldValue.serverTimestamp(),
        'unreadCount_${currentUser!.uid}': 0,
        'unreadCount_${chatId.split('_').firstWhere((id) => id != currentUser!.uid)}':
            FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send file: $e')),
      );
    }
  }

  Future<String> _uploadFile(File file, String type) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    Reference storageRef = FirebaseStorage.instance.ref().child('chat_files/$type/$fileName');
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _updateMessage(String chatId, String messageId, String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated successfully')),
      );
    } catch (e) {
      print('Error updating message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update message: $e')),
      );
    }
  }

  void _deleteMessage(String chatId, String messageId) async {
    try {
      final messageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (messageDoc.exists) {
        final messageData = messageDoc.data() as Map<String, dynamic>;
        final fileUrl = messageData['fileUrl']?.toString();
        
        if (fileUrl != null && fileUrl.isNotEmpty) {
          await _deleteFileFromStorage(fileUrl);
        }
      }
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message: $e')),
      );
    }
  }

  Future<void> _deleteFileFromStorage(String fileUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();
      print('File deleted from storage successfully');
    } catch (e) {
      print('Error deleting file from storage: $e');
    }
  }

  void _startEditing(String messageId, String currentText) {
    setState(() {
      _isEditing = true;
      _editingMessageId = messageId;
      _messageController.text = currentText;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  void _showMessageOptions(String messageId, String messageText, String chatId, {String? fileUrl, String? fileName}) {
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
            if (fileUrl == null)
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _startEditing(messageId, messageText);
                },
              ),
            if (fileUrl != null)
              ListTile(
                leading: const Icon(Icons.download, color: AppTheme.primaryBlue),
                title: const Text('Download File'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(fileUrl, fileName ?? 'downloaded_file');
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(chatId, messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String chatId, String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(chatId, messageId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
            return;
          }
        }
      }

      // Get the downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access downloads directory')),
        );
        return;
      }

      final filePath = '${directory.path}/$fileName';
      final dio = Dio();
      
      // Download the file
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded to $filePath')),
      );
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImageFromCamera(String chatId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _sendFile(chatId, File(pickedFile.path), 'image');
    }
  }

  Future<void> _pickImageFromGallery(String chatId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _sendFile(chatId, File(pickedFile.path), 'image');
    }
  }

  Future<void> _pickDocument(String chatId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      _sendFile(chatId, File(result.files.single.path!), 'document');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      print('Error: No navigation arguments provided');
      return const Scaffold(
        body: Center(child: Text('Error: Chat data not provided')),
      );
    }
    final chatId = args['chatId'] as String;
    final otherUserId = args['otherUserId'] as String;
    final otherUserName = args['otherUserName'] as String? ?? 'Unknown User';

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
                  break;
                case 'mute':
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
          if (_isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Editing message...'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
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
                if (messages.length > _lastMessageCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  _lastMessageCount = messages.length;
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUser!.uid;
                    final isEdited = messageData['isEdited'] ?? false;
                    final fileUrl = messageData['fileUrl']?.toString();
                    final fileType = messageData['fileType']?.toString();
                    final fileName = messageData['fileName']?.toString();

                    final message = MessageModel(
                      message: messageData['text']?.toString() ?? '',
                      time: _formatTime((messageData['timestamp'] as Timestamp?)?.toDate()),
                      isMe: isMe,
                      fileUrl: fileUrl,
                      fileType: fileType,
                      fileName: fileName,
                    );

                    return GestureDetector(
                      onLongPress: () {
                        if (isMe || fileUrl != null) {
                          _showMessageOptions(
                            messageDoc.id,
                            messageData['text']?.toString() ?? '',
                            chatId,
                            fileUrl: fileUrl,
                            fileName: fileName,
                          );
                        }
                      },
                      child: MessageBubble(
                        message: message,
                        isEdited: isEdited,
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                if (!_isEditing)
                  IconButton(
                    onPressed: () {
                      _showAttachmentOptions(chatId);
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isEditing ? 'Edit message...' : 'Type here...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(chatId),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _sendMessage(chatId),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing ? Icons.check : Icons.send,
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

  void _showAttachmentOptions(String chatId) {
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
                  () => _pickImageFromCamera(chatId),
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  Colors.purple,
                  () => _pickImageFromGallery(chatId),
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'Document',
                  Colors.blue,
                  () => _pickDocument(chatId),
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