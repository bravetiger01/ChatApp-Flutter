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

  // Vertical drag position from navigation arguements
  double _dragOffset = 0.0;
  // How far user must drag before it counts as a decision
  final double _threshold = 90.0;

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

  // Background tints green when dragging up, red when dragging down
  Color get _bgColor {
    if (_dragOffset < -30) {
      final t = ((-_dragOffset - 30) / 60).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF0D0D1A), const Color(0xFF1B5E20), t)!;
    }
    if (_dragOffset > 30) {
      final t = ((_dragOffset - 30) / 60).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF0D0D1A), const Color(0xFFB71C1C), t)!;
    }
    return const Color(0xFF0D0D1A);
  }

  Color get _buttonColor {
    if (_dragOffset < -30) return Colors.greenAccent;
    if (_dragOffset > 30) return Colors.redAccent;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
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

            // -----------------------------Instruction Hint-----------------------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                key: ValueKey(
                  _dragOffset < -30
                      ? 'release-accept'
                      : _dragOffset > 30
                      ? 'release-decline'
                      : 'hint',
                ),
                _dragOffset < -30
                    ? 'Release to accept'
                    : _dragOffset > 30
                    ? 'Release to Decline'
                    : 'Slide up to accept . down to decline',
                style: TextStyle(
                  color: _dragOffset < -30
                      ? Colors.greenAccent
                      : _dragOffset > 30
                      ? Colors.redAccent
                      : Colors.white38,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // -------------------Draggable phone button--------------------------------
            // This is the main WhatsApp-style interaction.
            // The button physically moves with your finger.
            // Slide up 90px → accept. Slide down 90px → decline
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dy;
                  // Clamp so it doesn't fly off screen
                  _dragOffset = _dragOffset.clamp(
                    -_threshold - 30,
                    _threshold + 30,
                  );
                });
              },
              onVerticalDragEnd: (_) {
                if (_dragOffset <= -_threshold) {
                  _acceptCall();
                } else if (_dragOffset >= _threshold) {
                  _declineCall();
                } else {
                  // Didn't reach threshole. Back to center
                  setState(() => _dragOffset = 0.0);
                }
              },
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _buttonColor,
                    boxShadow: [
                      BoxShadow(
                        color: _buttonColor.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.phone,
                    size: 36,
                    color: _dragOffset.abs() > 30
                        ? Colors.black87
                        : Colors.black87,
                  ),
                ),
              ),
            ),
            // Extra space so button has room to slide up/down
            const SizedBox(height: 120),

            // ── Tap Buttons (fallback for users who don't know to drag) ────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                GestureDetector(
                  onTap: _declineCall,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Accept
                GestureDetector(
                  onTap: _acceptCall,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
