// screens/call_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Timer? _callTimer;

  int _callDuration = 0;

  late RtcEngine? _engine;
  StreamSubscription<DocumentSnapshot>? _signalingSubscription;

  // ignore: unused_field
  bool _localUserJoined = false;
  // ignore: unused_field
  bool _remoteUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  bool _isCallActive = false;
  bool _hasEnded = false;

  final String appId = dotenv.env['AGORA_APP_ID'] ?? "";

  late String channelName;
  late String receiverId;
  late bool isCaller;

  late String receiverName;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // We need to wait for the screen to build to get arguements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        channelName = args['chatId'];
        receiverId = args['receiverId'];
        receiverName = args['receiverName'];
        isCaller = args['isCaller'];
      });
      // Starting Engine
      _initAgora();
      _startFirebaseSignaling();
    });
  }

  Future<void> _initAgora() async {
    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      Navigator.pop(context);
      return;
    }

    // Creating Agora Engine
    _engine = createAgoraRtcEngine();
    await _engine?.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Setting Up Listeners(What happenss when someone joins/leave)
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          debugPrint("Local user joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          debugPrint("Remote User UID: $remoteUid joined");
          setState(() {
            _remoteUserJoined = true;
            _isCallActive = true;
          });
          _startCallTimer(); //starting the call timer
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          debugPrint("Remote User Left");
          _endCall(); //Someone left so ending call
        },
      ),
    );

    // Turning on Microphone
    await _engine?.enableAudio();
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Join The Channel
    await _engine?.joinChannel(
      token: '', // for testing it should be blank
      channelId: channelName,
      uid: 0, // It means Agora will set automatic
      options: const ChannelMediaOptions(),
    );
  }

  void _startCallTimer() {
    if (_callTimer != null) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _callDuration++;
      });
    });
  }

  // The Ringing Signal (Initiating the Call)
  Future<void> _startFirebaseSignaling() async {
    if (isCaller) {
      final currentUser = FirebaseAuth.instance.currentUser;

      // 1. Create the call document to make the other person's phone ring
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(channelName)
          .set({
            'callerId': currentUser!.uid,
            'callerName': currentUser.displayName ?? 'Unknown',
            'receiverId': receiverId,
            'status': 'ringing',
            'channelId': channelName,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 2. Listen to if they reject the call
      _signalingSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(channelName)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists || !mounted) return;
            final data = snapshot.data() as Map<String, dynamic>;
            if (data['status'] == 'rejected') {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Call Declined')));
              }
              _endCall();
            } else if (data['status'] == 'accepted') {
              if (mounted) {
                setState(() {
                  _isCallActive = true;
                });
              }
            }
          });
    }
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and options
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _endCall(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Profile Section
              Column(
                children: [
                  // Profile Picture with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isCallActive ? 1.0 : _pulseAnimation.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(80),
                            boxShadow: _isCallActive
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B73FF),
                              borderRadius: BorderRadius.circular(80),
                            ),
                            child: const Center(
                              child: Text(
                                '👨‍💼',
                                style: TextStyle(fontSize: 80),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Contact Name
                  Text(
                    receiverName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Call Status
                  Text(
                    _isCallActive
                        ? _formatDuration(_callDuration)
                        : 'Calling...',
                    style: TextStyle(
                      color: _isCallActive ? Colors.green : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Control Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // Top row of controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          isActive: _isMuted,
                          onTap: () {
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                            _engine?.muteLocalAudioStream(_isMuted);
                          },
                        ),
                        _buildControlButton(icon: Icons.add_call, onTap: () {}),
                        _buildControlButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          isActive: _isSpeakerOn,
                          onTap: () {
                            setState(() {
                              _isSpeakerOn = !_isSpeakerOn;
                            });
                            _engine?.setEnableSpeakerphone(_isSpeakerOn);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Bottom row with video and end call
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // End Call Button
                        GestureDetector(
                          onTap: _endCall,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),

                        _buildControlButton(
                          icon: Icons.dialpad,
                          onTap: () => _showDialpad(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _endCall() {
    if (_hasEnded) return;
    _hasEnded = true;

    _callTimer?.cancel();
    _pulseController.stop();

    // Officially Leave Server
    _engine?.leaveChannel();

    FirebaseFirestore.instance.collection('calls').doc(channelName).delete();


    // Show end call animation or navigate back
    if (mounted) Navigator.pop(context);
  }

  void _showDialpad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2D3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),

              // Dialpad grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final keys = [
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '6',
                      '7',
                      '8',
                      '9',
                      '*',
                      '0',
                      '#',
                    ];
                    final letters = [
                      '',
                      'ABC',
                      'DEF',
                      'GHI',
                      'JKL',
                      'MNO',
                      'PQRS',
                      'TUV',
                      'WXYZ',
                      '',
                      '+',
                      '',
                    ];

                    return GestureDetector(
                      onTap: () {
                        // Handle dialpad key press
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              keys[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (letters[index].isNotEmpty)
                              Text(
                                letters[index],
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _signalingSubscription?.cancel();
    _pulseController.dispose();

    // Destroying engine to release memory
    _engine?.leaveChannel();
    _engine?.release();

    super.dispose();
  }
}
