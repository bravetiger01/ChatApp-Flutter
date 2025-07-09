import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../utils/app_theme.dart';
import '../models/chat_model.dart';
import 'dart:io';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isEdited;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.isEdited = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.cardBackground,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: message.isMe ? AppTheme.primaryBlue : AppTheme.cardBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                    bottomRight: Radius.circular(message.isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(context),
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.fileType != null) {
      return _buildFileMessage(context);
    } else {
      return _buildTextMessage(context);
    }
  }

  Widget _buildFileMessage(BuildContext context) {
    if (message.fileType == 'image') {
      return _buildImageMessage(context);
    } else {
      return _buildDocumentMessage(context);
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Stack(
            children: [
              Image.network(
                message.fileUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 40, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (!message.isMe)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.download, color: Colors.white, size: 20),
                      onPressed: () => _downloadFile(context),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                    onPressed: () => _showImageFullscreen(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (message.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        _buildMessageFooter(context),
      ],
    );
  }

  Widget _buildDocumentMessage(BuildContext context) {
    final fileName = message.fileName ?? _getFileNameFromUrl(message.fileUrl!);
    final fileExtension = path.extension(fileName).toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getFileTypeColor(fileExtension),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileTypeIcon(fileExtension),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileExtension.toUpperCase().replaceAll('.', '') + ' Document',
                      style: TextStyle(
                        color: message.isMe ? Colors.white70 : AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!message.isMe)
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: message.isMe ? Colors.white : AppTheme.textSecondary,
                  ),
                  onPressed: () => _downloadFile(context),
                ),
            ],
          ),
          if (message.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.message.isNotEmpty)
            SelectableText(
              message.message,
              style: TextStyle(
                color: message.isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          _buildMessageFooter(context),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.time,
            style: TextStyle(
              color: message.isMe ? Colors.white70 : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '(edited)',
              style: TextStyle(
                color: message.isMe ? Colors.yellow.shade300 : Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (message.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ],
      ),
    );
  }

  Color _getFileTypeColor(String extension) {
    switch (extension) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.txt':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        final parts = fileName.split('_');
        if (parts.length > 1) {
          return parts.sublist(1).join('_');
        }
        return fileName;
      }
      return 'Unknown File';
    } catch (e) {
      return 'Unknown File';
    }
  }

  Future<void> _downloadFile(BuildContext context) async {
    try {
      // Request storage permission for Android
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

      // Use fileName from MessageModel if available, else fallback to URL parsing
      final fileName = message.fileName ?? _getFileNameFromUrl(message.fileUrl!);

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
        message.fileUrl!,
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

  void _showImageFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!message.isMe)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadFile(context),
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                message.fileUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}