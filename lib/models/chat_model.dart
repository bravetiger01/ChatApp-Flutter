// models/chat_model.dart
// models/chat_model.dart
class ChatModel {
  final String chatId; // To store the chat document ID (e.g., uid1_uid2)
  final String name; // Name of the other user
  final String lastMessage;
  final DateTime lastTime;
  final bool isOnline; // Optional, requires additional logic
  final int unreadCount; // Optional, requires additional logic
  final String otherUserId; // UID of the other user
  final String? profilePicURL;

  ChatModel({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.otherUserId,
    this.profilePicURL,
    
  });
}

class MessageModel {
  final String message;
  final String time;
  final bool isMe;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;

  MessageModel({
    required this.message,
    required this.time,
    required this.isMe,
    this.fileUrl,
    this.fileType,
    this.fileName,
  });
}


enum MessageType {
  text,
  image,
  audio,
  video,
}

class ContactModel {
  final String name;
  final String? email;
  final String? phone;
  final bool isOnline;
  final String? avatar;

  ContactModel({
    required this.name,
    this.email,
    this.phone,
    required this.isOnline,
    this.avatar,
  });
}