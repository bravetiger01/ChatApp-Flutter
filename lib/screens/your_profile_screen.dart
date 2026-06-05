// screens/your_profile_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isFetching = true;  // true while loading initial data
  String _profilePicUrl = '';
  File? _pendingImage;       // locally picked image before save

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Load from Firestore ──────────────────────────────────────
  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _nameController.text = data['name']?.toString() ?? '';
        _aboutController.text = data['about']?.toString() ?? '';
        setState(() {
          _profilePicUrl = data['profilePic']?.toString() ?? '';
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Pick photo from gallery ──────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (picked != null && mounted) {
      setState(() => _pendingImage = File(picked.path));
    }
  }

  // ── Upload photo & return download URL ───────────────────────
  Future<String?> _uploadPhoto(String uid) async {
    if (_pendingImage == null) return null;
    try {
      final ref = _storage.ref().child('profile_pics').child('$uid.jpg');
      await ref.putFile(_pendingImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Save name/about (+ optional new photo) to Firestore ──────
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      // Upload new photo if one was selected
      String? newUrl;
      if (_pendingImage != null) {
        newUrl = await _uploadPhoto(uid);
      }

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'about': _aboutController.text.trim(),
      };
      if (newUrl != null) updates['profilePic'] = newUrl;

      await _db.collection('users').doc(uid).update(updates);

      if (mounted) {
        setState(() {
          if (newUrl != null) _profilePicUrl = newUrl;
          _pendingImage = null;
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2D3A),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Profile',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (_isEditing) {
                              // Cancel editing — revert pending image
                              setState(() {
                                _isEditing = false;
                                _pendingImage = null;
                              });
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                          icon: Icon(
                            _isEditing ? Icons.close : Icons.edit,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Profile picture ──
                        GestureDetector(
                          onTap: _isEditing ? _pickPhoto : null,
                          child: Stack(
                            children: [
                              _buildAvatar(),
                              if (_isEditing)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2A2D3A), width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        // Email (read-only, from Auth)
                        Text(
                          _auth.currentUser?.email ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),

                        const SizedBox(height: 28),

                        // ── Fields ──
                        _buildField(label: 'Name', controller: _nameController, icon: Icons.person),
                        const SizedBox(height: 18),
                        _buildField(label: 'About', controller: _aboutController, icon: Icons.info_outline, maxLines: 3),

                        const SizedBox(height: 32),

                        // ── Save button ──
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),

                        // ── Option tiles (when not editing) ──
                        if (!_isEditing) ...[
                          _buildOptionTile(icon: Icons.notifications, title: 'Notifications', onTap: () {}),
                          _buildOptionTile(icon: Icons.privacy_tip, title: 'Privacy', onTap: () {}),
                          _buildOptionTile(icon: Icons.help, title: 'Help & Support', onTap: () {}),
                          _buildOptionTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            onTap: _showLogoutDialog,
                            textColor: Colors.red,
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Avatar widget ────────────────────────────────────────────
  Widget _buildAvatar() {
    const double r = 60;
    // Show pending local image instantly for fast feedback
    if (_pendingImage != null) {
      return CircleAvatar(
        radius: r,
        backgroundImage: FileImage(_pendingImage!),
      );
    }
    if (_profilePicUrl.isNotEmpty) {
      return CircleAvatar(
        radius: r,
        backgroundColor: AppTheme.cardBackground,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: _profilePicUrl,
            width: r * 2,
            height: r * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Icon(Icons.person, color: Colors.white, size: 48),
            errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 48),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: r,
      backgroundColor: AppTheme.cardBackground,
      child: Icon(Icons.person, color: Colors.white, size: 48),
    );
  }

  // ── Profile field ────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF3A3D4A), borderRadius: BorderRadius.circular(12)),
          child: TextFormField(
            controller: controller,
            enabled: _isEditing,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: _isEditing ? Colors.white : Colors.white70, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Option tile ──────────────────────────────────────────────
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF3A3D4A), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? Colors.white70, size: 22),
              const SizedBox(width: 15),
              Text(title,
                  style: TextStyle(color: textColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout dialog ────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3D4A),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}