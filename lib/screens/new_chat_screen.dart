// screens/new_chat_screen.dart
import 'package:flutter/material.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Contact> contacts = [
    Contact(
      name: 'Nitish Kumar',
      email: 'nitishkr833@gmail.com',
      avatar: '👨‍💼',
      isOnline: true,
    ),
    Contact(
      name: 'Nitish Kumar',
      email: 'nitishkr833@gmail.com',
      avatar: '👨‍💼',
      isOnline: false,
    ),
    Contact(
      name: 'Nitish Kumar',
      email: 'nitishkr833@gmail.com',
      avatar: '👨‍💼',
      isOnline: true,
    ),
    Contact(
      name: 'Nitish Kumar',
      email: 'nitishkr833@gmail.com',
      avatar: '👨‍💼',
      isOnline: false,
    ),
    Contact(
      name: 'Nitish Kumar',
      email: 'nitishkr833@gmail.com',
      avatar: '👨‍💼',
      isOnline: true,
    ),
  ];

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
                  'Select contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.person_add,
                  title: 'New Contact',
                  onTap: () => Navigator.pushNamed(context, '/new-contact'),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.group_add,
                  title: 'New group',
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Contacts Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contacts on SamPark',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Contact List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _buildContactItem(contact);
              },
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3D4A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/chat'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3D4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        contact.avatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  if (contact.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0xFF3A3D4A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.email,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class Contact {
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;

  Contact({
    required this.name,
    required this.email,
    required this.avatar,
    required this.isOnline,
  });
}