import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewContactScreen extends StatefulWidget {
  const NewContactScreen({super.key});

  @override
  State<NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

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
                  'New Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B73FF),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2A2D3A),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email-id',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveContact,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white60, size: 20),
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

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to add a contact.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final email = _emailController.text.trim().toLowerCase();

        // Query Firestore to find the user by email
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found with this email.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final otherUser = userQuery.docs.first;
        final otherUserId = otherUser.id;
        Map<String, dynamic> otherUserData = otherUser.data();
        final otherUserName = otherUserData['name'];
        final otherUserAbout = otherUserData['about'];

        if (otherUserId == currentUser.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You cannot add yourself as a contact.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = userData?['name'];
        final userAbout = userData?['about'];


        // Check if contact already exists
        final contactDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('contacts')
            .doc(otherUserId)
            .get();

        if (contactDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This contact already exists.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // 1. Get a batch object from Firestore
        final batch = FirebaseFirestore.instance.batch();

        // 2. Reference the two document locations
        final currentUserContactRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('contacts')
            .doc(otherUserId);

        batch.set(currentUserContactRef, {
          'name': otherUserName,
          'email': email,
          'about': otherUserAbout,
          'addedAt': FieldValue.serverTimestamp(),
        });

        final otherUserContactRef = FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .collection('contacts')
            .doc(currentUser.uid);

        batch.set(otherUserContactRef, {
          'name': userName,
          'email': currentUser.email,
          'about': userAbout,
          'addedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        // Create a new chat
        final chatId = _generateChatId(currentUser.uid, otherUserId);
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();

        if (!chatDoc.exists) {
          await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
            'members': [currentUser.uid, otherUserId],
            'lastMessage': 'New chat started',
            'lastTime': FieldValue.serverTimestamp(),
          });
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact and chat created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        print('Error saving contact: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generateChatId(String uid1, String uid2) {
    // Generate a consistent chat ID by sorting UIDs
    final uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
