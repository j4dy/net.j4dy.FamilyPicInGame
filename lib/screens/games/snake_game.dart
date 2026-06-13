import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/snake/snake_game_state.dart';
import '../../games/common/vector_2d.dart';

class SnakeGameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const SnakeGameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> {
  late List<FaceProfile> _profiles;
  FaceProfile? _selectedHead;
  FaceProfile? _selectedFood;
  bool _gameStarted = false;

  SnakeGameState? _gameState;
  final Map<String, ui.Image> _profileImages = {};
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _profiles = widget.faceStorage.getProfiles();

    if (_profiles.isNotEmpty) {
      _selectedHead = _profiles[0];
      if (_profiles.length > 1) {
        _selectedFood = _profiles[1];
      } else {
        _selectedFood = _profiles[0];
      }
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _startGame() async {
    if (_selectedHead == null || _selectedFood == null) return;
    try {
      // Pre-load all profile images in memory
      for (final p in _profiles) {
        final img = await _loadImage(p.imagePath);
        _profileImages[p.id] = img;
      }

      setState(() {
        _gameState = SnakeGameState(
          headProfile: _selectedHead!,
          foodProfile: _selectedFood!,
          allProfiles: _profiles,
        );
        _gameStarted = true;
      });

      // Start periodic tick timer (180ms per tick)
      _gameTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
        if (_gameStarted && _gameState != null && !_gameState!.isGameOver) {
          setState(() {
            _gameState!.tick();
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting snake game: $e');
    }
  }

  void _stopGame() {
    _gameTimer?.cancel();
    setState(() {
      _gameStarted = false;
      _gameState = null;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (_gameState == null || _gameState!.isGameOver) return;
    final velocity = details.velocity.pixelsPerSecond;
    
    // Determine primary swipe axis
    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > 100) {
        _gameState!.setSnakeDirection(SnakeDirection.right);
      } else if (velocity.dx < -100) {
        _gameState!.setSnakeDirection(SnakeDirection.left);
      }
    } else {
      if (velocity.dy > 100) {
        _gameState!.setSnakeDirection(SnakeDirection.down);
      } else if (velocity.dy < -100) {
        _gameState!.setSnakeDirection(SnakeDirection.up);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      // Setup UI (Portrait)
      return Scaffold(
        appBar: AppBar(
          title: const Text("Setup Snake"),
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
                        "ASSIGN GAME ROLES",
                        style: TextStyle(
                          color: electricCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Snake Head selector
                    const Text(
                      "Select Snake Head (Player):",
                      style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                            isSelected: _selectedHead?.id == profile.id,
                            color: electricCyan,
                            onClick: () {
                              setState(() {
                                _selectedHead = profile;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Food Selector
                    const Text(
                      "Select Food (Chomp Character):",
                      style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                            isSelected: _selectedFood?.id == profile.id,
                            color: neonPink,
                            onClick: () {
                              setState(() {
                                _selectedFood = profile;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: (_selectedHead != null && _selectedFood != null) ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonPink,
                    disabledBackgroundColor: softGrey.withOpacity(0.3),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "LAUNCH GAME",
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
        title: Text("Score: ${state.score}", style: const TextStyle(fontWeight: FontWeight.w900, color: electricCyan)),
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
        child: Column(
          children: [
            // Game Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                state.gameMessage,
                style: const TextStyle(color: softGrey, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

            // Game Board
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: state.gridWidth / state.gridHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1424),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cyberPurple.withOpacity(0.4), width: 2.0),
                    ),
                    child: GestureDetector(
                      onHorizontalDragEnd: _handleSwipe,
                      onVerticalDragEnd: _handleSwipe,
                      child: CustomPaint(
                        painter: _SnakeBoardPainter(
                          state: state,
                          profileImages: _profileImages,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // D-Pad Controller Overlay (bottom row)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Direction controls (cross layout)
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up, color: electricCyan, size: 36),
                        onPressed: () => state.setSnakeDirection(SnakeDirection.up),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_left, color: electricCyan, size: 36),
                            onPressed: () => state.setSnakeDirection(SnakeDirection.left),
                          ),
                          const SizedBox(width: 36),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_right, color: electricCyan, size: 36),
                            onPressed: () => state.setSnakeDirection(SnakeDirection.right),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: electricCyan, size: 36),
                        onPressed: () => state.setSnakeDirection(SnakeDirection.down),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

class _SnakeBoardPainter extends CustomPainter {
  final SnakeGameState state;
  final Map<String, ui.Image> profileImages;

  _SnakeBoardPainter({
    required this.state,
    required this.profileImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / state.gridWidth;
    final cellH = size.height / state.gridHeight;

    final gridPaint = Paint()
      ..color = cyberPurple.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw grid mesh lines for arcade look
    for (int col = 1; col < state.gridWidth; col++) {
      canvas.drawLine(Offset(col * cellW, 0), Offset(col * cellW, size.height), gridPaint);
    }
    for (int row = 1; row < state.gridHeight; row++) {
      canvas.drawLine(Offset(0, row * cellH), Offset(size.width, row * cellH), gridPaint);
    }

    // 1. Draw Food
    final foodCenter = Offset(state.foodPos.x * cellW + cellW / 2.0, state.foodPos.y * cellH + cellH / 2.0);
    final foodRadius = math.min(cellW, cellH) * 0.45;
    
    // Food Glow
    canvas.drawCircle(foodCenter, foodRadius + 4.0, Paint()..color = neonPink.withOpacity(0.3));

    final foodImg = profileImages[state.foodProfile.id];
    if (foodImg != null) {
      canvas.save();
      final clipPath = Path()..addOval(Rect.fromCircle(center: foodCenter, radius: foodRadius));
      canvas.clipPath(clipPath);
      canvas.drawImageRect(
        foodImg,
        Rect.fromLTRB(0, 0, foodImg.width.toDouble(), foodImg.height.toDouble()),
        Rect.fromCircle(center: foodCenter, radius: foodRadius),
        Paint()..isAntiAlias = true,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(foodCenter, foodRadius, Paint()..color = neonPink);
    }
    // Outer food border
    canvas.drawCircle(foodCenter, foodRadius, Paint()..color = neonPink..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // 2. Draw Snake segments
    for (int i = 0; i < state.snake.length; i++) {
      final segment = state.snake[i];
      final center = Offset(segment.x * cellW + cellW / 2.0, segment.y * cellH + cellH / 2.0);
      final radius = math.min(cellW, cellH) * 0.45;

      // Draw segment connections (hide if wrapping/portal event)
      if (i < state.snake.length - 1) {
        final nextSegment = state.snake[i + 1];
        final diffX = (segment.x - nextSegment.x).abs();
        final diffY = (segment.y - nextSegment.y).abs();
        // Only draw connection line if adjacent (i.e. not wrapping across the board)
        if (diffX <= 1.1 && diffY <= 1.1) {
          final nextCenter = Offset(nextSegment.x * cellW + cellW / 2.0, nextSegment.y * cellH + cellH / 2.0);
          canvas.drawLine(
            center,
            nextCenter,
            Paint()
              ..color = electricCyan.withOpacity(0.6)
              ..strokeWidth = 6.0
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      // Draw Glow behind head
      if (i == 0) {
        canvas.drawCircle(center, radius + 5.0, Paint()..color = electricCyan.withOpacity(0.3));
      }

      // Draw segment avatar
      final profile = state.getProfileForSegment(i);
      final img = profileImages[profile.id];
      if (img != null) {
        canvas.save();
        final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
        canvas.clipPath(clipPath);
        canvas.drawImageRect(
          img,
          Rect.fromLTRB(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCircle(center: center, radius: radius),
          Paint()..isAntiAlias = true,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(center, radius, Paint()..color = electricCyan);
      }

      // Outer border: Cyan for head, Purple/Cyan for body
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = i == 0 ? electricCyan : cyberPurple
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 2.5 : 1.5,
      );
    }

    // 3. Draw Portal ripples
    for (final r in state.portalRipples) {
      final center = Offset(r.gridPos.x * cellW + cellW / 2.0, r.gridPos.y * cellH + cellH / 2.0);
      final rippleRadius = math.min(cellW, cellH) * (1.2 - r.alpha);

      canvas.drawCircle(
        center,
        rippleRadius,
        Paint()
          ..color = r.isNeonPink ? neonPink.withOpacity(r.alpha) : electricCyan.withOpacity(r.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // 4. Draw Sparkles
    for (final p in state.sparkles) {
      final center = Offset(p.gridPos.x * cellW + cellW / 2.0 + p.offset.x, p.gridPos.y * cellH + cellH / 2.0 + p.offset.y);
      canvas.drawCircle(
        center,
        2.5 * p.alpha,
        Paint()
          ..color = p.isNeonPink ? neonPink.withOpacity(p.alpha) : electricCyan.withOpacity(p.alpha)
          ..style = PaintingStyle.fill,
      );
    }

    // 5. Draw Game Over Overlay in Painter if needed (handled in UI, but good to paint a thin overlay)
    if (state.isGameOver) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnakeBoardPainter oldDelegate) {
    return true; // Keep repainting for particle movements and animations
  }
}
