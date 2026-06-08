// lib/services/file_download.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileDownloadService {
  static Future<void> downloadFile(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) async {
    try {
      // Request Storage permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Storage permission is required to download files.',
                ),
              ),
            );
            return;
          }
        }
      }

      // Get download directory
      final directory = await getDownloadsDirectory();

      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to access download directory.')),
        );
        return;
      }

      final filePath = '${directory.path}/$fileName';

      final dio = Dio();

      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              "Download Progress : ${(received / total * 100).toStringAsFixed(0)}%",
            );
          }
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File Download to $filePath')));
    } catch (e) {
      debugPrint("Error Downloading File $fileName, Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download file: $e')));
    }
  }
}
