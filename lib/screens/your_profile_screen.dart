// screens/your_profile_screen.dart
import 'package:flutter/material.dart';

class YourProfileScreen extends StatefulWidget {
  const YourProfileScreen({super.key});

  @override
  State<YourProfileScreen> createState() => _YourProfileScreenState();
}

class _YourProfileScreenState extends State<YourProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current user data
    _nameController.text = 'Nitish kumar';
    _aboutController.text = 'I am Great';
    _emailController.text = 'Nitishkr833@gmail.com';
    _phoneController.text = '+91 7033616175';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2D3A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
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

          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Profile Picture Section
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B73FF),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: const Center(
                          child: Text(
                            '👨‍💼',
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF2A2D3A),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Profile Fields
                  _buildProfileField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person,
                    editable: _isEditing,
                  ),

                  const SizedBox(height: 20),

                  _buildProfileField(
                    label: 'About',
                    controller: _aboutController,
                    icon: Icons.info,
                    editable: _isEditing,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  _buildProfileField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email,
                    editable: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  _buildProfileField(
                    label: 'Phone',
                    controller: _phoneController,
                    icon: Icons.phone,
                    editable: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 40),

                  // Save Button (only visible when editing)
                  if (_isEditing) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SAVE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Additional Options
                  if (!_isEditing) ...[
                    _buildOptionTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    _buildOptionTile(
                      icon: Icons.privacy_tip,
                      title: 'Privacy',
                      onTap: () {},
                    ),
                    _buildOptionTile(
                      icon: Icons.help,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildOptionTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _showLogoutDialog(),
                      textColor: Colors.red,
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool editable,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3D4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            enabled: editable,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(
              color: editable ? Colors.white : Colors.white70,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: Colors.white60,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          decoration: BoxDecoration(
            color: const Color(0xFF3A3D4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor ?? Colors.white70,
                size: 22,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A3D4A),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
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
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}