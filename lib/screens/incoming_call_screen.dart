import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  // Call info - filled from navigation
  String callerName = '';
  String callerId = '';
  String channelId = '';
  String callerPhoto = '';



  // Listens to firestore so if caller cancels, we autoclose
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  // Pulsing ring animation around the avatar
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set up the pulse animation(avatar slowly grows and shrinks)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wait for first frame before reading route arguements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        callerName = args['callerName'] ?? 'Unknown';
        callerId = args['callerId'] ?? '';
        channelId = args['channelId'] ?? '';
        callerPhoto = args['callerPhoto'] ?? '';
      });
      _listenForCallerCancel();
    });
  }

  // If caller hangs up before reciever answers, the Firestore doc is deleted.
  // We watch for that and close this screen automatically
  void _listenForCallerCancel() {
    if (channelId.isEmpty) return;
    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(channelId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists && mounted) {
            Navigator.pop(context); //Caller Canceled
          }
        });
  }

  // Accept the call: write 'accepted' to firestore then go to CallScreen
  Future<void> _acceptCall() async {
    _callSubscription?.cancel(); //Stop listening before we navigate away
    await FirebaseFirestore.instance.collection('calls').doc(channelId).update({
      'status': 'accepted',
    });
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/call',
      arguments: {
        'chatId': channelId,
        'receiverId': FirebaseAuth.instance.currentUser!.uid,
        'receiverName': callerName,
        'isCaller': false,
      },
    );
  }

  // Decline the call: write 'rejected' to firestore and then close this screen
  Future<void> _declineCall() async {
    _callSubscription?.cancel();
    await FirebaseFirestore.instance.collection('calls').doc(channelId).update({
      'status': 'rejected',
    });
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callSubscription?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // ---------------------------Caller Avatar------------------------
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: callerPhoto.isNotEmpty
                      ? Image.network(callerPhoto, fit: BoxFit.cover)
                      : Container(
                          color: Colors.deepPurple.shade800,
                          child: const Icon(
                            Icons.person,
                            size: 65,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ---------------------Caller Name--------------------------
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming Voice Call',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),

            const Spacer(),

            // Two clear action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline (red)
                GestureDetector(
                  onTap: _declineCall,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Accept (green)
                GestureDetector(
                  onTap: _acceptCall,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
