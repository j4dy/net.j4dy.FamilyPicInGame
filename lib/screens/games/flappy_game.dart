import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/flappy/flappy_game_state.dart';

class FlappyGameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const FlappyGameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<FlappyGameScreen> createState() => _FlappyGameScreenState();
}

class _FlappyGameScreenState extends State<FlappyGameScreen> with SingleTickerProviderStateMixin {
  late List<FaceProfile> _profiles;
  FaceProfile? _selectedPilot;
  FlappyDifficulty _selectedDifficulty = FlappyDifficulty.hard;
  bool _gameStarted = false;

  FlappyGameState? _gameState;
  ui.Image? _pilotImage;
  late Ticker _ticker;

  final List<Offset> _stars = List.generate(25, (index) {
    final random = math.Random();
    return Offset(random.nextDouble(), random.nextDouble());
  });

  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _profiles = widget.faceStorage.getProfiles();

    if (_profiles.isNotEmpty) {
      _selectedPilot = _profiles[0];
    }

    _ticker = createTicker((elapsed) {
      if (_gameStarted && _gameState != null && _gameState!.isPlaying && !_gameState!.isGameOver) {
        setState(() {
          _gameState!.tick(_canvasSize.width, _canvasSize.height);
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _startGame() async {
    if (_selectedPilot == null) return;
    try {
      _pilotImage = await _loadImage(_selectedPilot!.imagePath);
      setState(() {
        _gameState = FlappyGameState(
          playerProfile: _selectedPilot!,
          difficulty: _selectedDifficulty,
        )..startGame();
        _gameStarted = true;
      });
    } catch (e) {
      debugPrint('Error starting flappy game: $e');
    }
  }

  void _stopGame() {
    setState(() {
      _gameStarted = false;
      _gameState = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      // Setup UI (Portrait)
      return Scaffold(
        appBar: AppBar(
          title: const Text("Setup Flappy Flight"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBackClick,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "ASSIGN GAME PILOT",
                        style: TextStyle(
                          color: electricCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Select who will pilot the space capsule:",
                      style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _profiles.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return _RoleAvatarItem(
                            profile: profile,
                            isSelected: _selectedPilot?.id == profile.id,
                            color: electricCyan,
                            onClick: () {
                              setState(() {
                                _selectedPilot = profile;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      "Select Mission Difficulty (Gap size):",
                      style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: FlappyDifficulty.values.map((diff) {
                        final isSelected = _selectedDifficulty == diff;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDifficulty = diff;
                              });
                            },
                            child: Container(
                              height: 44,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: isSelected ? neonPink : cardSlate.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? electricCyan : softGrey.withOpacity(0.3),
                                  width: 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                diff.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : softGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: _selectedPilot != null ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonPink,
                    disabledBackgroundColor: softGrey.withOpacity(0.3),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "LAUNCH MISSION",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Gameplay Screen (Portrait)
    final state = _gameState!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Flappy Flight"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _stopGame,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => state.resetGame()),
            icon: const Icon(Icons.refresh, color: electricCyan, size: 18),
            label: const Text("RESET", style: TextStyle(color: electricCyan, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Canvas container
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cyberPurple.withOpacity(0.4), width: 1.0),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);
                          if (_canvasSize != size) {
                            setState(() {
                              _canvasSize = size;
                            });
                          }
                        });

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              state.flap();
                            });
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _FlappyPainter(
                                    state: state,
                                    pilotImage: _pilotImage!,
                                    stars: _stars,
                                    isPlaying: state.isPlaying,
                                  ),
                                ),
                              ),
                              if (!state.isPlaying && !state.isGameOver)
                                Container(
                                  color: Colors.black.withOpacity(0.35),
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "TAP ANYWHERE TO JUMP",
                                        style: TextStyle(
                                          color: electricCyan,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Avoid the glowing neon pillars",
                                        style: TextStyle(color: softGrey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Score HUD card
              Container(
                decoration: BoxDecoration(
                  color: cardSlate.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cyberPurple.withOpacity(0.2), width: 1.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Score: ${state.score}",
                          style: const TextStyle(color: electricCyan, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        Text(
                          "${state.gameMessage} • ${state.difficulty.displayName}",
                          style: const TextStyle(color: icyWhite, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (state.isGameOver)
                      ElevatedButton.icon(
                        onPressed: () => setState(() => state.startGame()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        label: const Text(
                          "RETRY",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
}

class _RoleAvatarItem extends StatelessWidget {
  final FaceProfile profile;
  final bool isSelected;
  final Color color;
  final VoidCallback onClick;

  const _RoleAvatarItem({
    required this.profile,
    required this.isSelected,
    required this.color,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: cardSlate,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 3.0 : 1.0,
              ),
              image: DecorationImage(
                image: FileImage(File(profile.imagePath)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.name,
            style: TextStyle(
              color: isSelected ? color : softGrey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FlappyPainter extends CustomPainter {
  final FlappyGameState state;
  final ui.Image pilotImage;
  final List<Offset> stars;
  final bool isPlaying;

  _FlappyPainter({
    required this.state,
    required this.pilotImage,
    required this.stars,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Space background stars with slow scrolling
    final elapsedMillis = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < stars.length; i++) {
      final starOffset = stars[i];
      // Slow parallax scroll
      final double speedOffset = isPlaying ? (state.score * 50 + (elapsedMillis / 40.0) % w) : 0.0;
      final double starX = ((starOffset.dx * w) - speedOffset) % w;
      final double normalizedStarX = starX < 0 ? starX + w : starX;
      final double starY = starOffset.dy * h;

      canvas.drawCircle(
        Offset(normalizedStarX, starY),
        (i % 3 == 0) ? 3.0 : 1.5,
        Paint()
          ..color = (i % 2 == 0) ? electricCyan.withOpacity(0.5) : neonPink.withOpacity(0.4)
          ..style = PaintingStyle.fill,
      );
    }

    // 2. Draw Pipes (Obstacles)
    for (final pipe in state.pipes) {
      // Top Pipe
      final topRect = Rect.fromLTRB(pipe.x, 0.0, pipe.x + pipe.width, pipe.topHeight);
      final topPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(pipe.x, 0.0),
          Offset(pipe.x, pipe.topHeight),
          [cyberPurple, cyberPurple.withOpacity(0.6)],
        );
      canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(8.0)), topPaint);

      // Top Pipe Lip (border line)
      final topLipRect = Rect.fromLTRB(pipe.x - 4.0, pipe.topHeight - 30.0, pipe.x + pipe.width + 4.0, pipe.topHeight);
      final lipPaint = Paint()
        ..color = electricCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(topLipRect, const Radius.circular(4.0)), lipPaint);

      // Bottom Pipe
      final bottomRect = Rect.fromLTRB(pipe.x, h - pipe.bottomHeight, pipe.x + pipe.width, h);
      final bottomPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(pipe.x, h - pipe.bottomHeight),
          Offset(pipe.x, h),
          [cyberPurple.withOpacity(0.6), cyberPurple],
        );
      canvas.drawRRect(RRect.fromRectAndRadius(bottomRect, const Radius.circular(8.0)), bottomPaint);

      // Bottom Pipe Lip (border line)
      final bottomLipRect = Rect.fromLTRB(pipe.x - 4.0, h - pipe.bottomHeight, pipe.x + pipe.width + 4.0, h - pipe.bottomHeight + 30.0);
      canvas.drawRRect(RRect.fromRectAndRadius(bottomLipRect, const Radius.circular(4.0)), lipPaint);
    }

    // 3. Draw Player Astronaut
    final double pX = w * 0.25;
    final double pY = state.birdY;
    const double faceRadius = 35.0;
    final Offset center = Offset(pX, pY);

    // Draw astronaut backpack capsule
    final backpackRect = Rect.fromLTRB(pX - 60.0, pY - 25.0, pX - 40.0, pY + 25.0);
    final backpackPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(pX - 60.0, pY),
        Offset(pX - 40.0, pY),
        [cyberPurple, electricCyan],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(backpackRect, const Radius.circular(6.0)), backpackPaint);

    // Draw connector line
    canvas.drawLine(
      Offset(pX - 40.0, pY),
      Offset(pX - 25.0, pY),
      Paint()
        ..color = neonPink
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Draw clipped astronaut pilot head
    canvas.save();
    final pilotClipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: faceRadius));
    canvas.clipPath(pilotClipPath);
    canvas.drawImageRect(
      pilotImage,
      Rect.fromLTRB(0.0, 0.0, pilotImage.width.toDouble(), pilotImage.height.toDouble()),
      Rect.fromCircle(center: center, radius: faceRadius),
      Paint()..isAntiAlias = true,
    );
    canvas.restore();

    // Draw Astronaut Helmet Glass Visor
    canvas.drawCircle(
      center,
      faceRadius + 7.0,
      Paint()
        ..color = electricCyan.withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      faceRadius + 7.0,
      Paint()
        ..color = electricCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Glass reflection curve
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: faceRadius + 4.0),
      -2.09, // ~ -120 degrees in radians
      1.05,  // ~ 60 degrees in radians
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _FlappyPainter oldDelegate) {
    return true; // Keep repainting for stars parallax and animations
  }
}
