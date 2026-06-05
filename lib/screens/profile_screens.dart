// screens/profile_screens.dart
// Contact profile — shown when viewing another user's profile from the chat/contacts list.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Receive userId passed via Navigator.pushNamed arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Profile'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('No user selected', style: TextStyle(color: Colors.white70)))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('Could not load profile', style: TextStyle(color: Colors.white70)),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name']?.toString() ?? 'Unknown';
                final email = data['email']?.toString() ?? '';
                final about = data['about']?.toString() ?? '';
                final profilePic = data['profilePic']?.toString() ?? '';
                final lastActive = (data['lastActive'] as Timestamp?)?.toDate();
                final isOnline = lastActive != null &&
                    DateTime.now().difference(lastActive).inMinutes < 5;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ── Avatar ──
                      Stack(
                        children: [
                          _buildAvatar(profilePic),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.darkBackground, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Name ──
                      Text(name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),

                      // ── Email ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email, color: AppTheme.textSecondary, size: 14),
                          const SizedBox(width: 6),
                          Text(email, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Online badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOnline ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── About ──
                      if (about.isNotEmpty)
                        _buildInfoCard(
                          context,
                          title: 'About',
                          body: about,
                        ),
                      if (about.isNotEmpty) const SizedBox(height: 16),

                      // ── Action buttons ──
                      _buildActionButton(
                        context,
                        icon: Icons.message,
                        title: 'Message',
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.call,
                        title: 'Voice Call',
                        onTap: () => Navigator.pushNamed(context, '/call'),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        context,
                        icon: Icons.videocam,
                        title: 'Video Call',
                        onTap: () => Navigator.pushNamed(context, '/call'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── Avatar ──────────────────────────────────────────────────
  Widget _buildAvatar(String url) {
    const double r = 60;
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: r,
        backgroundColor: AppTheme.cardBackground,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
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

  // ── Info card ───────────────────────────────────────────────
  Widget _buildInfoCard(BuildContext context, {required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ── Action button ───────────────────────────────────────────
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
