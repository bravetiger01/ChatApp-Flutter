// models/chat_model.dart
class ChatModel {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final String? avatar;

  ChatModel({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    this.avatar,
  });
}

class MessageModel {
  final String message;
  final String time;
  final bool isMe;
  final MessageType type;

  MessageModel({
    required this.message,
    required this.time,
    required this.isMe,
    this.type = MessageType.text,
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