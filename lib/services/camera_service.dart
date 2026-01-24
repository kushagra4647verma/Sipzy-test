// lib/services/camera_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CameraService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  /// Check camera permission
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check photo library permission (iOS)
  Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request photo library permission
  Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Take a photo using camera
  Future<File?> takePhoto() async {
    try {
      // Check permission
      bool hasPermission = await hasCameraPermission();
      if (!hasPermission) {
        hasPermission = await requestCameraPermission();
        if (!hasPermission) {
          print('⚠️ Camera permission denied');
          return null;
        }
      }

      // Take photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  Future<File?> pickFromGallery() async {
    try {
      // Check permission
      bool hasPermission = await hasPhotoPermission();
      if (!hasPermission) {
        hasPermission = await requestPhotoPermission();
        if (!hasPermission) {
          print('⚠️ Photo library permission denied');
          return null;
        }
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Show photo source selection (Camera or Gallery)
  Future<File?> showPhotoSourceDialog(context) async {
    return await showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Add Photo', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF5B642)),
              title:
                  const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final photo = await takePhoto();
                Navigator.pop(context, photo);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFF5B642)),
              title:
                  const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final photo = await pickFromGallery();
                Navigator.pop(context, photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Upload photo to Supabase Storage
  Future<String?> uploadToSupabase(
    File file, {
    required String bucket,
    required String path,
  }) async {
    try {
      print('📤 Uploading to Supabase: $bucket/$path');

      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;

      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(path);

      print('✅ Upload successful: $url');
      return url;
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  /// Complete flow: Pick photo and upload
  Future<String?> pickAndUpload({
    required context,
    required String bucket,
    required String folder,
    String? filename,
  }) async {
    // Show source selection
    final file = await showPhotoSourceDialog(context);
    if (file == null) return null;

    // Generate filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = file.path.split('.').last;
    final path = '$folder/${filename ?? timestamp}.$ext';

    // Upload
    return await uploadToSupabase(file, bucket: bucket, path: path);
  }
}
