// screens/call_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Timer _callTimer;
  
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = false;
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    
    // Start call timer
    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
        if (_callDuration == 3) {
          _isCallActive = true;
        }
      });
    });
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
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
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
                      onPressed: () => Navigator.pop(context),
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
                            boxShadow: _isCallActive ? [] : [
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
                  const Text(
                    'Nitish Kumar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Call Status
                  Text(
                    _isCallActive ? _formatDuration(_callDuration) : 'Calling...',
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
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.add_call,
                          onTap: () {},
                        ),
                        _buildControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          isActive: _isSpeakerOn,
                          onTap: () {
                            setState(() {
                              _isSpeakerOn = !_isSpeakerOn;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Bottom row with video and end call
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                          isActive: _isVideoOn,
                          onTap: () {
                            setState(() {
                              _isVideoOn = !_isVideoOn;
                            });
                          },
                        ),
                        
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
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _endCall() {
    _callTimer.cancel();
    _pulseController.stop();
    
    // Show end call animation or navigate back
    Navigator.pop(context);
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
                    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];
                    final letters = ['', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV', 'WXYZ', '', '+', ''];
                    
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
    _callTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}