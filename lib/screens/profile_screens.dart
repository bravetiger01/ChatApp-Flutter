import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: const Text('Profile'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.cardBackground,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.darkBackground,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Info
            Text(
              'nitish838@gmail.com',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nitish Kumar',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bio Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hey everyone! I am using SamPark app to communicate with my friends.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Media Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Media',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View all',
                          style: TextStyle(color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMediaThumbnail(),
                      const SizedBox(width: 8),
                      _buildMediaThumbnail(),
                      const SizedBox(width: 8),
                      _buildMediaThumbnail(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButton(
              icon: Icons.message,
              title: 'Message',
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.call,
              title: 'Voice Call',
              onTap: () => Navigator.pushNamed(context, '/call'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.videocam,
              title: 'Video Call',
              onTap: () => Navigator.pushNamed(context, '/call'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail() {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
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
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// screens/new_chat_screen.dart
// class NewChatScreen extends StatefulWidget {
//   const NewChatScreen({super.key});

//   @override
//   State<NewChatScreen> createState() => _NewChatScreenState();
// }

// class _NewChatScreenState extends State<NewChatScreen> {
//   final TextEditingController _searchController = TextEditingController();
  
//   final List<String> contacts = [
//     'Nitish Kumar',
//     'Sahara Kumari',
//     'Rahul Singh',
//     'Priya Sharma',
//     'Amit Patel',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppTheme.darkBackground,
//         elevation: 0,
//         title: const Text('Select Contact'),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.close),
//         ),
//         actions: [
//           IconButton(
//             onPressed: () => Navigator.pushNamed(context, '/new-contact'),
//             icon: const Icon(Icons.person_add),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: const InputDecoration(
//                 hintText: 'Search contacts...',
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//           ),
          
//           // Contacts List
//           Expanded(
//             child: ListView.builder(
//               itemCount: contacts.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: AppTheme.cardBackground,
//                     child: Icon(
//                       Icons.person,
//                       color: Colors.white,
//                     ),
//                   ),
//                   title: Text(contacts[index]),
//                   subtitle: const Text('Online'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     Navigator.pushNamed(context, '/chat');
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppTheme.primaryBlue,
//         onPressed: () {},
//         child: const Icon(Icons.group_add, color: Colors.white),
//       ),
//     );
//   }
// }

// // screens/new_contact_screen.dart
// class NewContactScreen extends StatefulWidget {
//   const NewContactScreen({super.key});

//   @override
//   State<NewContactScreen> createState() => _NewContactScreenState();
// }

// class _NewContactScreenState extends State<NewContactScreen> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppTheme.darkBackground,
//         elevation: 0,
//         title: const Text('New Contact'),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back_ios),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Save contact logic
//               Navigator.pop(context);
//             },
//             child: const Text(
//               'SAVE',
//               style: TextStyle(
//                 color: AppTheme.primaryBlue,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             // Profile Picture
//             const CircleAvatar(
//               radius: 50,
//               backgroundColor: AppTheme.cardBackground,
//               child: Icon(
//                 Icons.person_add,
//                 color: Colors.white,
//                 size: 40,
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Name Field
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(
//                 labelText: 'Full name',
//                 prefixIcon: Icon(Icons.person),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Email Field
//             TextField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: const InputDecoration(
//                 labelText: 'Email id',
//                 prefixIcon: Icon(Icons.email),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Phone Field
//             TextField(
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(
//                 labelText: 'Phone number',
//                 prefixIcon: Icon(Icons.phone),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
