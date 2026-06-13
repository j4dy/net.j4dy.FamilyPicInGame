import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/game_descriptor.dart';
import '../../data/face_storage.dart';

class HomeScreen extends StatefulWidget {
  final List<GameDescriptor> games;
  final ValueChanged<GameDescriptor> onGameSelect;
  final VoidCallback onManageFacesSelect;
  final FaceStorage faceStorage;

  const HomeScreen({
    super.key,
    required this.games,
    required this.onGameSelect,
    required this.onManageFacesSelect,
    required this.faceStorage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  int _faceCount = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _updateFaceCount();
  }

  void _updateFaceCount() {
    setState(() {
      _faceCount = widget.faceStorage.getProfiles().length;
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFaceCount();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful animated cosmic background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AnimatedBackgroundPainter(progress: _bgController.value),
                child: Container(),
              );
            },
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Title Header
                  const SizedBox(height: 16),
                  const Text(
                    "FAMILY",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 6.0,
                      fontWeight: FontWeight.w900,
                      color: electricCyan,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [neonPink, cyberPurple, electricCyan],
                    ).createShader(bounds),
                    child: const Text(
                      "Pic-In-Game",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Play classic games with family face characters!",
                    style: TextStyle(color: softGrey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),

                  // Games List Section
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      itemCount: widget.games.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "SELECT MISSION",
                              style: TextStyle(
                                color: Color(0xCC8F9CAE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          );
                        }
                        final game = widget.games[index - 1];
                        return _GameCard(
                          game: game,
                          onClick: () => widget.onGameSelect(game),
                        );
                      },
                    ),
                  ),

                  // Footer Manage Faces (Glassmorphic)
                  InkWell(
                    onTap: () async {
                      widget.onManageFacesSelect();
                      // Wait for returning and update count
                      await Future.delayed(const Duration(milliseconds: 300));
                      _updateFaceCount();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: cardSlate.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: electricCyan.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: neonPink.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.face_retouching_natural,
                                  color: neonPink,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Family Faces",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: icyWhite,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "$_faceCount Characters Ready",
                                    style: const TextStyle(
                                      color: softGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Text(
                            "MANAGE",
                            style: TextStyle(
                              color: electricCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameDescriptor game;
  final VoidCallback onClick;

  const _GameCard({
    required this.game,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final isSlingshot = game.id == 'slingshot';

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: cardSlate.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSlingshot ? neonPink.withOpacity(0.8) : electricCyan.withOpacity(0.8),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: icyWhite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isSlingshot ? neonPink.withOpacity(0.15) : electricCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          isSlingshot ? "PHYSICS" : "ARCADE",
                          style: TextStyle(
                            color: isSlingshot ? neonPink : electricCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: const TextStyle(
                      color: softGrey,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow,
                color: icyWhite,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress;

  _AnimatedBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pulse size scale
    final pulseScale = 0.9 + 0.2 * math.sin(progress * 2.0 * math.pi);

    // Draw cosmic glow spheres
    // Sphere 1: Magenta glow top left
    final paint1 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.1, h * 0.2),
        w * 0.7,
        [neonPink.withOpacity(0.15 * pulseScale), Colors.transparent],
      );
    canvas.drawCircle(Offset(w * 0.1, h * 0.2), w * 0.7, paint1);

    // Sphere 2: Cyan glow bottom right
    final paint2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.9, h * 0.8),
        w * 0.8,
        [electricCyan.withOpacity(0.12 * pulseScale), Colors.transparent],
      );
    canvas.drawCircle(Offset(w * 0.9, h * 0.8), w * 0.8, paint2);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
