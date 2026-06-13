import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/pacman/pacman_game_state.dart';

class PacmanGameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const PacmanGameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<PacmanGameScreen> createState() => _PacmanGameScreenState();
}

class _PacmanGameScreenState extends State<PacmanGameScreen> with SingleTickerProviderStateMixin {
  late List<FaceProfile> _profiles;
  FaceProfile? _selectedPlayer;
  final List<FaceProfile?> _selectedGhosts = List.filled(4, null);
  bool _gameStarted = false;

  PacmanGameState? _gameState;
  final Map<String, ui.Image> _profileImages = {};
  late final Ticker _frameTicker;

  @override
  void initState() {
    super.initState();
    _profiles = widget.faceStorage.getProfiles();

    // Default setups
    if (_profiles.isNotEmpty) {
      _selectedPlayer = _profiles[0];
      _autoAssignGhosts(_profiles[0]);
    }

    _frameTicker = createTicker((elapsed) {
      if (_gameStarted && _gameState != null && _gameState!.isPlaying && !_gameState!.isGameOver) {
        setState(() {
          _gameState!.tickFrame();
        });
      }
    });
    _frameTicker.start();
  }

  void _autoAssignGhosts(FaceProfile player) {
    final otherProfiles = _profiles.where((p) => p.id != player.id).toList();
    for (int i = 0; i < 4; i++) {
      if (i < otherProfiles.length) {
        _selectedGhosts[i] = otherProfiles[i];
      } else {
        // Fallback to repeat if not enough profiles
        _selectedGhosts[i] = _profiles[i % _profiles.length];
      }
    }
  }

  @override
  void dispose() {
    _frameTicker.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 100);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _startGame() async {
    if (_selectedPlayer == null) return;
    try {
      // Pre-load all profile images in memory
      for (final p in _profiles) {
        final img = await _loadImage(p.imagePath);
        _profileImages[p.id] = img;
      }

      // Collect ghosts list
      final List<FaceProfile> ghosts = [];
      for (final g in _selectedGhosts) {
        if (g != null) {
          ghosts.add(g);
        }
      }

      setState(() {
        _gameState = PacmanGameState(
          playerProfile: _selectedPlayer!,
          ghostProfiles: ghosts,
        )..startGame();
        _gameStarted = true;
      });
    } catch (e) {
      debugPrint('Error starting Pac-Man: $e');
    }
  }

  void _stopGame() {
    setState(() {
      _gameStarted = false;
      _gameState = null;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (_gameState == null || !_gameState!.isPlaying || _gameState!.isGameOver) return;
    final velocity = details.velocity.pixelsPerSecond;

    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > 100) {
        _gameState!.setPlayerDirection(PacmanDirection.right);
      } else if (velocity.dx < -100) {
        _gameState!.setPlayerDirection(PacmanDirection.left);
      }
    } else {
      if (velocity.dy > 100) {
        _gameState!.setPlayerDirection(PacmanDirection.down);
      } else if (velocity.dy < -100) {
        _gameState!.setPlayerDirection(PacmanDirection.up);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      // Setup UI
      return Scaffold(
        appBar: AppBar(
          title: const Text("Setup Pac-Man"),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
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

                        // Pac-man (Chomper) Selector
                        const Text(
                          "Select Player (Chomper):",
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
                                isSelected: _selectedPlayer?.id == profile.id,
                                color: electricCyan,
                                onClick: () {
                                  setState(() {
                                    _selectedPlayer = profile;
                                    _autoAssignGhosts(profile);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ghost Assign previews
                        const Text(
                          "Assigned Ghosts (Tap to change):",
                          style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: List.generate(4, (ghostIndex) {
                            final ghostNames = ["Blinky (Red)", "Pinky (Pink)", "Inky (Cyan)", "Clyde (Orange)"];
                            final ghostColors = [Colors.red, Colors.pink, Colors.cyan, Colors.orange];
                            final currentGhost = _selectedGhosts[ghostIndex];

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: cardSlate,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ghostColors[ghostIndex].withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: ghostColors[ghostIndex],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        ghostNames[ghostIndex],
                                        style: const TextStyle(color: icyWhite, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  DropdownButton<String>(
                                    value: currentGhost?.id,
                                    dropdownColor: cardSlate,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down, color: softGrey),
                                    items: _profiles.map((p) {
                                      return DropdownMenuItem<String>(
                                        value: p.id,
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(color: icyWhite, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (id) {
                                      if (id == null) return;
                                      final target = _profiles.firstWhere((p) => p.id == id);
                                      setState(() {
                                        _selectedGhosts[ghostIndex] = target;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (_selectedPlayer != null) ? _startGame : null,
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

    // Gameplay Screen
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
            // Game Message / Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                state.gameMessage,
                style: TextStyle(
                  color: state.isGameOver
                      ? neonPink
                      : state.isVictory
                          ? electricCyan
                          : state.frightenedTimer > 0
                              ? Colors.yellow
                              : softGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Lives indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("LIVES: ", style: TextStyle(color: softGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Row(
                    children: List.generate(3, (index) {
                      final hasLife = index < state.lives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Icon(
                          Icons.face,
                          color: hasLife ? electricCyan : softGrey.withOpacity(0.2),
                          size: 20,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Aspect Ratio Board Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: AspectRatio(
                  aspectRatio: state.gridWidth / state.gridHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B19),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cyberPurple.withOpacity(0.4), width: 2.0),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onHorizontalDragEnd: _handleSwipe,
                            onVerticalDragEnd: _handleSwipe,
                            child: CustomPaint(
                              painter: _PacmanBoardPainter(
                                state: state,
                                profileImages: _profileImages,
                              ),
                            ),
                          ),
                        ),

                        // Overlay for game over, start, or victory
                        if (!state.isPlaying || state.isGameOver || state.isVictory)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.isVictory
                                      ? "VICTORY!"
                                      : state.isGameOver
                                          ? "GAME OVER"
                                          : "READY CHOMPER!",
                                  style: TextStyle(
                                    color: state.isVictory ? electricCyan : neonPink,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.isVictory
                                      ? "You ate all the dots! Final: ${state.score}"
                                      : state.isGameOver
                                          ? "Final Score: ${state.score}"
                                          : "Swipe in any direction to move and chomp dots. Eat power pellets to vulnerable ghosts!",
                                  style: const TextStyle(color: icyWhite, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      if (state.isGameOver || state.isVictory) {
                                        state.resetGame();
                                      }
                                      state.startGame();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: neonPink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  ),
                                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                                  label: Text(
                                    state.isGameOver || state.isVictory ? "PLAY AGAIN" : "START MATCH",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // D-Pad Controller
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up, color: electricCyan, size: 36),
                        onPressed: () => state.setPlayerDirection(PacmanDirection.up),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_left, color: electricCyan, size: 36),
                            onPressed: () => state.setPlayerDirection(PacmanDirection.left),
                          ),
                          const SizedBox(width: 36),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_right, color: electricCyan, size: 36),
                            onPressed: () => state.setPlayerDirection(PacmanDirection.right),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: electricCyan, size: 36),
                        onPressed: () => state.setPlayerDirection(PacmanDirection.down),
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

class _PacmanBoardPainter extends CustomPainter {
  final PacmanGameState state;
  final Map<String, ui.Image> profileImages;

  _PacmanBoardPainter({
    required this.state,
    required this.profileImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / state.gridWidth;
    final cellH = size.height / state.gridHeight;

    final double dotRadius = math.min(cellW, cellH) * 0.15;
    final double powerPelletRadius = math.min(cellW, cellH) * 0.35;

    // Glowing pellet paint
    final pelletPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    // 1. Draw connected neon walls
    final wallGlow = Paint()
      ..color = electricCyan.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final wallCore = Paint()
      ..color = electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int y = 0; y < state.gridHeight; y++) {
      for (int x = 0; x < state.gridWidth; x++) {
        if (state.isWall(x, y)) {
          final center = Offset(x * cellW + cellW / 2.0, y * cellH + cellH / 2.0);

          // Draw backdrop grid cell block (darker blue block)
          canvas.drawRect(
            Rect.fromLTRB(x * cellW + 1, y * cellH + 1, (x + 1) * cellW - 1, (y + 1) * cellH - 1),
            Paint()..color = const Color(0xFF0D1C3D),
          );

          // Draw connected pipes
          final directions = [
            Offset(-cellW, 0), // left
            Offset(cellW, 0),  // right
            Offset(0, -cellH), // up
            Offset(0, cellH)   // down
          ];

          for (final dir in directions) {
            final int nextX = x + (dir.dx / cellW).toInt();
            final int nextY = y + (dir.dy / cellH).toInt();
            if (nextX >= 0 && nextX < state.gridWidth && nextY >= 0 && nextY < state.gridHeight) {
              if (state.isWall(nextX, nextY)) {
                final target = Offset(center.dx + dir.dx / 2.0, center.dy + dir.dy / 2.0);
                canvas.drawLine(center, target, wallGlow);
                canvas.drawLine(center, target, wallCore);
              }
            }
          }
        }
      }
    }

    // 2. Draw pellets & power pellets
    final pulseVal = 0.85 + 0.15 * math.sin(DateTime.now().millisecondsSinceEpoch / 140.0);
    for (int y = 0; y < state.gridHeight; y++) {
      for (int x = 0; x < state.gridWidth; x++) {
        final char = state.board[y][x];
        final center = Offset(x * cellW + cellW / 2.0, y * cellH + cellH / 2.0);

        if (char == '.') {
          canvas.drawCircle(center, dotRadius, pelletPaint);
        } else if (char == 'o') {
          // Pulse the size
          final size = powerPelletRadius * pulseVal;
          canvas.drawCircle(center, size + 2.0, Paint()..color = const Color(0xFFFFCC00).withOpacity(0.3));
          canvas.drawCircle(center, size, Paint()..color = const Color(0xFFFFB300));
        }
      }
    }

    // 3. Draw Player Pac-Man (Chomper)
    final double playerInterpX = state.playerCurrentPos.x + (state.playerNextPos.x - state.playerCurrentPos.x) * state.moveProgress;
    final double playerInterpY = state.playerCurrentPos.y + (state.playerNextPos.y - state.playerCurrentPos.y) * state.moveProgress;
    final playerCenter = Offset(playerInterpX * cellW + cellW / 2.0, playerInterpY * cellH + cellH / 2.0);
    final playerRadius = math.min(cellW, cellH) * 0.45;

    // Draw Chomper glowing background ring
    canvas.drawCircle(playerCenter, playerRadius + 3.0, Paint()..color = electricCyan.withOpacity(0.3));

    final playerImg = profileImages[state.playerProfile.id];
    if (playerImg != null) {
      canvas.save();
      // Clip profile to circle
      final clipPath = Path()..addOval(Rect.fromCircle(center: playerCenter, radius: playerRadius));
      canvas.clipPath(clipPath);

      canvas.drawImageRect(
        playerImg,
        Rect.fromLTRB(0, 0, playerImg.width.toDouble(), playerImg.height.toDouble()),
        Rect.fromCircle(center: playerCenter, radius: playerRadius),
        Paint()..isAntiAlias = true,
      );
      canvas.restore();
    } else {
      // Fallback: draw solid yellow circle
      canvas.drawCircle(playerCenter, playerRadius, Paint()..color = const Color(0xFFFFEB3B));
    }

    // Draw chomping mouth wedge overlay (black sector)
    if (state.isPlaying && !state.isGameOver && !state.isVictory) {
      double rotation = 0.0;
      switch (state.playerDir) {
        case PacmanDirection.right:
          rotation = 0.0;
          break;
        case PacmanDirection.down:
          rotation = math.pi / 2.0;
          break;
        case PacmanDirection.left:
          rotation = math.pi;
          break;
        case PacmanDirection.up:
          rotation = -math.pi / 2.0;
          break;
        case PacmanDirection.none:
          rotation = 0.0;
          break;
      }

      // Mouth opening angle in radians: oscillates over time
      final double mouthAngle = state.playerDir == PacmanDirection.none
          ? 0.0
          : 0.55 * (1.0 + math.sin(DateTime.now().millisecondsSinceEpoch / 70.0)) * 0.8;

      if (mouthAngle > 0.05) {
        canvas.save();
        // Rotate mouth wedge in direction of travel
        canvas.translate(playerCenter.dx, playerCenter.dy);
        canvas.rotate(rotation);

        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: playerRadius + 1.0),
          -mouthAngle / 2.0,
          mouthAngle,
          true,
          Paint()..color = const Color(0xFF070B19), // Match board background color
        );

        canvas.restore();
      }
    }

    // Border around player
    canvas.drawCircle(
      playerCenter,
      playerRadius,
      Paint()
        ..color = electricCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 4. Draw Ghosts
    for (final ghost in state.ghosts) {
      final double ghostInterpX = ghost.currentPos.x + (ghost.nextPos.x - ghost.currentPos.x) * state.ghostProgress;
      final double ghostInterpY = ghost.currentPos.y + (ghost.nextPos.y - ghost.currentPos.y) * state.ghostProgress;
      final ghostCenter = Offset(ghostInterpX * cellW + cellW / 2.0, ghostInterpY * cellH + cellH / 2.0);
      final ghostRadius = math.min(cellW, cellH) * 0.45;

      final ghostColors = [
        const Color(0xFFFF3333), // Blinky: Red
        const Color(0xFFFF66CC), // Pinky: Pink
        const Color(0xFF33FFFF), // Inky: Cyan
        const Color(0xFFFF9933)  // Clyde: Orange
      ];

      final ghostColor = state.frightenedTimer > 0
          ? (state.frightenedTimer < 120 && (state.frightenedTimer ~/ 15) % 2 == 0
              ? Colors.white
              : const Color(0xFF1E3A8A)) // Flashing white/blue
          : ghostColors[ghost.colorIndex];

      if (ghost.isEaten) {
        // Eaten state: Only draw white eyes with small blue pupils
        final eyeW = ghostRadius * 0.35;
        final leftEyeCenter = Offset(ghostCenter.dx - ghostRadius * 0.3, ghostCenter.dy - ghostRadius * 0.1);
        final rightEyeCenter = Offset(ghostCenter.dx + ghostRadius * 0.3, ghostCenter.dy - ghostRadius * 0.1);

        canvas.drawCircle(leftEyeCenter, eyeW, Paint()..color = Colors.white);
        canvas.drawCircle(rightEyeCenter, eyeW, Paint()..color = Colors.white);

        canvas.drawCircle(leftEyeCenter, eyeW * 0.4, Paint()..color = Colors.blue);
        canvas.drawCircle(rightEyeCenter, eyeW * 0.4, Paint()..color = Colors.blue);
      } else {
        // Normal or Vulnerable state: Draw ghost body shape
        final bodyPath = Path();
        final rect = Rect.fromCircle(center: ghostCenter, radius: ghostRadius);
        
        // Draw dome shape
        bodyPath.moveTo(rect.left, rect.bottom);
        bodyPath.arcTo(
          Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + rect.height),
          math.pi,
          math.pi,
          false,
        );
        bodyPath.lineTo(rect.right, rect.bottom);

        // Wavy skirt at bottom
        final int waveCount = 3;
        final double waveW = rect.width / waveCount;
        for (int i = waveCount; i >= 0; i--) {
          final xPos = rect.left + i * waveW;
          final isUp = i % 2 == 0;
          bodyPath.lineTo(xPos, rect.bottom - (isUp ? 4.0 : 0.0));
        }
        bodyPath.close();

        // Draw body shape
        canvas.drawPath(bodyPath, Paint()..color = ghostColor);
        canvas.drawPath(
          bodyPath,
          Paint()
            ..color = ghostColor.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Draw profile image cropped inside the dome (like a helmet visor/face)
        if (ghost.profile != null) {
          final double visorR = ghostRadius * 0.55;
          final visorCenter = Offset(ghostCenter.dx, ghostCenter.dy - ghostRadius * 0.05);

          final gImg = profileImages[ghost.profile!.id];
          if (gImg != null) {
            canvas.save();
            final visorPath = Path()..addOval(Rect.fromCircle(center: visorCenter, radius: visorR));
            canvas.clipPath(visorPath);

            // Scared tint
            final gPaint = Paint()..isAntiAlias = true;
            if (state.frightenedTimer > 0) {
              gPaint.colorFilter = const ColorFilter.mode(Colors.blueAccent, BlendMode.color);
            }

            canvas.drawImageRect(
              gImg,
              Rect.fromLTRB(0, 0, gImg.width.toDouble(), gImg.height.toDouble()),
              Rect.fromCircle(center: visorCenter, radius: visorR),
              gPaint,
            );
            canvas.restore();
          } else {
            // Fallback inside visor
            canvas.drawCircle(visorCenter, visorR, Paint()..color = Colors.black.withOpacity(0.4));
          }

          // Visor border
          canvas.drawCircle(
            visorCenter,
            visorR,
            Paint()
              ..color = Colors.black.withOpacity(0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        } else {
          // Fallback classic eyes if no profile
          final eyeW = ghostRadius * 0.3;
          final leftEyeCenter = Offset(ghostCenter.dx - ghostRadius * 0.25, ghostCenter.dy - ghostRadius * 0.1);
          final rightEyeCenter = Offset(ghostCenter.dx + ghostRadius * 0.25, ghostCenter.dy - ghostRadius * 0.1);
          canvas.drawCircle(leftEyeCenter, eyeW, Paint()..color = Colors.white);
          canvas.drawCircle(rightEyeCenter, eyeW, Paint()..color = Colors.white);
          canvas.drawCircle(leftEyeCenter, eyeW * 0.4, Paint()..color = Colors.blue);
          canvas.drawCircle(rightEyeCenter, eyeW * 0.4, Paint()..color = Colors.blue);
        }
      }
    }

    // 5. Draw Sparkles
    for (final sparkle in state.sparkles) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: sparkle.text,
          style: TextStyle(
            color: electricCyan.withOpacity(sparkle.alpha),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(sparkle.offset.dx - textPainter.width / 2.0, sparkle.offset.dy - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PacmanBoardPainter oldDelegate) {
    return true; // Keep repainting for pacman mouth oscillations and animations
  }
}
