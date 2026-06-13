import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/slingshot/slingshot_game_state.dart';
import '../../games/common/vector_2d.dart';

class SlingshotGameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const SlingshotGameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<SlingshotGameScreen> createState() => _SlingshotGameScreenState();
}

class _SlingshotGameScreenState extends State<SlingshotGameScreen> with SingleTickerProviderStateMixin {
  late List<FaceProfile> _profiles;
  FaceProfile? _selectedHero;
  FaceProfile? _selectedTarget;
  bool _gameStarted = false;

  SlingshotGameState? _gameState;
  ui.Image? _heroImage;
  ui.Image? _targetImage;

  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _profiles = widget.faceStorage.getProfiles();

    // Default selection if available
    if (_profiles.isNotEmpty) {
      _selectedHero = _profiles[0];
      if (_profiles.length > 1) {
        _selectedTarget = _profiles[1];
      } else {
        _selectedTarget = _profiles[0];
      }
    }

    _ticker = createTicker((elapsed) {
      if (_gameStarted && _gameState != null) {
        setState(() {
          _gameState!.update();
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _startGame() async {
    if (_selectedHero == null || _selectedTarget == null) return;
    try {
      _heroImage = await _loadImage(_selectedHero!.imagePath);
      _targetImage = await _loadImage(_selectedTarget!.imagePath);

      // Lock screen to Landscape when starting gameplay
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      setState(() {
        _gameState = SlingshotGameState(
          heroProfile: _selectedHero!,
          targetProfile: _selectedTarget!,
        );
        _gameStarted = true;
      });
    } catch (e) {
      debugPrint('Error starting game: $e');
    }
  }

  void _stopGame() {
    // Lock back to Portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
          title: const Text("Setup Slingshot"),
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

                    // Hero selection list
                    const Text(
                      "Select the Hero (Bird Character):",
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
                            isSelected: _selectedHero?.id == profile.id,
                            color: electricCyan,
                            onClick: () {
                              setState(() {
                                _selectedHero = profile;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Target selection list
                    const Text(
                      "Select the Targets (Pig Characters):",
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
                            isSelected: _selectedTarget?.id == profile.id,
                            color: neonPink,
                            onClick: () {
                              setState(() {
                                _selectedTarget = profile;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: (_selectedHero != null && _selectedTarget != null) ? _startGame : null,
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

    // Game view (Landscape)
    final state = _gameState!;
    final isGameOver = state.shotsLeft <= 0 || state.targets.every((t) => t.isDestroyed);
    final isVictory = state.targets.every((t) => t.isDestroyed);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Game Canvas
          Positioned.fill(
            child: _SlingshotGameCanvas(
              state: state,
              heroImage: _heroImage!,
              targetImage: _targetImage!,
            ),
          ),

          // 2. Floating Back Button (top-left)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: electricCyan.withOpacity(0.5), width: 1.0),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: icyWhite),
                onPressed: _stopGame,
              ),
            ),
          ),

          // 3. Floating Reset Button (top-right)
          Positioned(
            right: 16,
            top: 16,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => state.resetLevel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.6),
                side: BorderSide(color: electricCyan.withOpacity(0.5), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.refresh, color: electricCyan, size: 20),
              label: const Text(
                "RESET",
                style: TextStyle(color: electricCyan, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 4. Floating HUD Badge (top-center glassmorphic bar)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: cardSlate.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cyberPurple.withOpacity(0.3), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Score: ${state.score}",
                      style: const TextStyle(color: electricCyan, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Container(
                      width: 1.0,
                      height: 16,
                      color: softGrey.withOpacity(0.4),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Text(
                      "Level: ${state.currentLevel}/${state.maxLevels}",
                      style: const TextStyle(color: icyWhite, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      width: 1.0,
                      height: 16,
                      color: softGrey.withOpacity(0.4),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Row(
                      children: [
                        const Text(
                          "Shots: ",
                          style: TextStyle(color: icyWhite, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(3, (i) {
                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < state.shotsLeft ? neonPink : Colors.grey[800],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Temporary Floating Game Message Banner (bottom-center)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  state.gameStateMessage,
                  style: TextStyle(color: icyWhite.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // 6. Centered Victory / Game Over Overlay Modal
          if (isGameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                alignment: Alignment.center,
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: cardSlate.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVictory ? electricCyan : neonPink,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVictory ? "VICTORY!" : "GAME OVER",
                        style: TextStyle(
                          color: isVictory ? electricCyan : neonPink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVictory
                            ? "You demolished the targets!"
                            : "You ran out of slingshot shots.",
                        style: const TextStyle(color: icyWhite, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Final Score: ${state.score}",
                        style: const TextStyle(
                          color: electricCyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: _stopGame,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: softGrey, width: 1.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "ROLES",
                                style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (isVictory && state.currentLevel < state.maxLevels) {
                                    state.nextLevel();
                                  } else {
                                    state.resetLevel();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isVictory && state.currentLevel < state.maxLevels
                                    ? electricCyan
                                    : neonPink,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                isVictory && state.currentLevel < state.maxLevels ? "NEXT LEVEL" : "PLAY AGAIN",
                                style: TextStyle(
                                  color: isVictory && state.currentLevel < state.maxLevels
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

class _SlingshotGameCanvas extends StatefulWidget {
  final SlingshotGameState state;
  final ui.Image heroImage;
  final ui.Image targetImage;

  const _SlingshotGameCanvas({
    required this.state,
    required this.heroImage,
    required this.targetImage,
  });

  @override
  State<_SlingshotGameCanvas> createState() => _SlingshotGameCanvasState();
}

class _SlingshotGameCanvasState extends State<_SlingshotGameCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);

        final scaleX = box.size.width / 1280.0;
        final scaleY = box.size.height / 720.0;
        final scale = math.min(scaleX, scaleY);
        final offsetX = (box.size.width - 1280.0 * scale) / 2.0;
        final offsetY = (box.size.height - 720.0 * scale) / 2.0;

        final touchVec = Vector2D(
          (localPos.dx - offsetX) / scale,
          (localPos.dy - offsetY) / scale,
        );

        if (widget.state.birdPos.distance(touchVec) < widget.state.birdRadius * 2.2) {
          setState(() {
            widget.state.onDrag(Offset(touchVec.x, touchVec.y));
          });
        }
      },
      onPanUpdate: (details) {
        if (widget.state.isDragging) {
          final box = context.findRenderObject() as RenderBox;
          final localPos = box.globalToLocal(details.globalPosition);

          final scaleX = box.size.width / 1280.0;
          final scaleY = box.size.height / 720.0;
          final scale = math.min(scaleX, scaleY);
          final offsetX = (box.size.width - 1280.0 * scale) / 2.0;
          final offsetY = (box.size.height - 720.0 * scale) / 2.0;

          final logicalX = (localPos.dx - offsetX) / scale;
          final logicalY = (localPos.dy - offsetY) / scale;

          setState(() {
            widget.state.onDrag(Offset(logicalX, logicalY));
          });
        }
      },
      onPanEnd: (details) {
        if (widget.state.isDragging) {
          setState(() {
            widget.state.onRelease();
          });
        }
      },
      child: CustomPaint(
        painter: _SlingshotPainter(
          state: widget.state,
          heroImage: widget.heroImage,
          targetImage: widget.targetImage,
        ),
      ),
    );
  }
}

class _SlingshotPainter extends CustomPainter {
  final SlingshotGameState state;
  final ui.Image heroImage;
  final ui.Image targetImage;

  _SlingshotPainter({
    required this.state,
    required this.heroImage,
    required this.targetImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final physicalW = size.width;
    final physicalH = size.height;

    final scaleX = physicalW / 1280.0;
    final scaleY = physicalH / 720.0;
    final scale = math.min(scaleX, scaleY);
    final offsetX = (physicalW - 1280.0 * scale) / 2.0;
    final offsetY = (physicalH - 720.0 * scale) / 2.0;

    const double groundY = 560.0;

    // 1. Draw hills background extended to screen edges
    final double physicalGroundY = groundY * scale + offsetY;
    final hillPath = Path()
      ..moveTo(0, physicalGroundY)
      ..quadraticBezierTo(physicalW * 0.25, physicalGroundY - 140.0 * scale, physicalW * 0.5, physicalGroundY)
      ..quadraticBezierTo(physicalW * 0.75, physicalGroundY - 80.0 * scale, physicalW, physicalGroundY)
      ..lineTo(physicalW, physicalH)
      ..lineTo(0, physicalH)
      ..close();

    final hillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, physicalGroundY),
        Offset(0, physicalH),
        [const Color(0xFF1E2642), const Color(0xFF151C33)],
      );
    canvas.drawPath(hillPath, hillPaint);

    // 2. Draw ground level extended to screen edges
    final groundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, physicalGroundY),
        Offset(0, physicalH),
        [const Color(0xFF22C55E), const Color(0xFF15803D)],
      );
    canvas.drawRect(Rect.fromLTRB(0, physicalGroundY, physicalW, physicalH), groundPaint);

    // Ground top border neon line
    final groundLinePaint = Paint()
      ..color = electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(0, physicalGroundY), Offset(physicalW, physicalGroundY), groundLinePaint);

    // Save context for scaled drawing
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // Apply Screen Shake
    if (state.screenShake > 0.0) {
      final double shakeX = (math.Random().nextDouble() * 2.0 - 1.0) * state.screenShake;
      final double shakeY = (math.Random().nextDouble() * 2.0 - 1.0) * state.screenShake;
      canvas.translate(shakeX, shakeY);
    }

    // 3. Draw slingshot poles (brown neon sticks)
    final double anchorX = state.slingAnchor.x;
    final double anchorY = state.slingAnchor.y;
    final Offset hookLeft = Offset(anchorX - 30.0, anchorY - 60.0);
    final Offset hookRight = Offset(anchorX + 30.0, anchorY - 60.0);

    final woodPaintMain = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;
    final woodPaintBranch = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(anchorX, groundY), Offset(anchorX, anchorY - 40.0), woodPaintMain);
    canvas.drawLine(Offset(anchorX, anchorY - 40.0), hookLeft, woodPaintBranch);
    canvas.drawLine(Offset(anchorX, anchorY - 40.0), hookRight, woodPaintBranch);

    // 4. Draw trajectory dots
    if (state.isDragging) {
      final trajectory = state.getTrajectoryPoints();
      final dotPaint = Paint()
        ..color = electricCyan.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < trajectory.length; i++) {
        if (i % 2 == 0) {
          canvas.drawCircle(trajectory[i], 6.0, dotPaint);
        }
      }
    }

    // 5. Draw back rubber band
    if (state.isDragging) {
      final bandPaint = Paint()
        ..color = neonPink
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(hookLeft, Offset(state.birdPos.x, state.birdPos.y), bandPaint);
    }

    // 6. Draw Bird (Hero Character)
    final double birdRadius = state.birdRadius;
    final Offset birdCenter = Offset(state.birdPos.x, state.birdPos.y);

    // Draw glow
    final glowPaint = Paint()
      ..color = electricCyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(birdCenter, birdRadius + 8.0, glowPaint);

    // Clip to circle and draw hero avatar
    canvas.save();
    final birdClipPath = Path()
      ..addOval(Rect.fromCircle(center: birdCenter, radius: birdRadius));
    canvas.clipPath(birdClipPath);
    canvas.drawImageRect(
      heroImage,
      Rect.fromLTRB(0, 0, heroImage.width.toDouble(), heroImage.height.toDouble()),
      Rect.fromCircle(center: birdCenter, radius: birdRadius),
      Paint()..isAntiAlias = true,
    );
    canvas.restore();

    // Border circle
    final birdBorderPaint = Paint()
      ..color = electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(birdCenter, birdRadius, birdBorderPaint);

    // 7. Draw front rubber band
    if (state.isDragging) {
      final bandPaint = Paint()
        ..color = neonPink
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(hookRight, Offset(state.birdPos.x, state.birdPos.y), bandPaint);
    }

    // 8. Draw blocks
    for (final block in state.blocks) {
      if (block.isDestroyed) continue;

      canvas.save();
      final double blockCenterX = block.left + block.xOffset + block.width / 2.0;
      final double blockCenterY = block.top + block.height / 2.0;

      canvas.translate(blockCenterX, blockCenterY);
      canvas.rotate(block.rotation);
      canvas.translate(-blockCenterX, -blockCenterY);

      final blockPaint = Paint()
        ..color = block.color
        ..style = block.isGlass ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = block.isGlass ? 2.5 : 1.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(block.left + block.xOffset, block.top, block.left + block.xOffset + block.width, block.top + block.height),
          const Radius.circular(8.0),
        ),
        blockPaint,
      );

      if (block.isGlass) {
        // Highlight inside glass block
        final glassHighlightPaint = Paint()
          ..color = electricCyan.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTRB(block.left + block.xOffset, block.top, block.left + block.xOffset + block.width, block.top + block.height),
          glassHighlightPaint,
        );
      }

      canvas.restore();
    }

    // 9. Draw Targets
    for (final target in state.targets) {
      if (target.isDestroyed) continue;

      final Offset targetCenter = Offset(target.pos.x, target.pos.y);
      final double targetRadius = target.radius;

      // Draw glow
      final targetGlowPaint = Paint()
        ..color = neonPink.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetCenter, targetRadius + 6.0, targetGlowPaint);

      // Clip and draw target avatar
      canvas.save();
      final targetClipPath = Path()
        ..addOval(Rect.fromCircle(center: targetCenter, radius: targetRadius));
      canvas.clipPath(targetClipPath);
      canvas.drawImageRect(
        targetImage,
        Rect.fromLTRB(0, 0, targetImage.width.toDouble(), targetImage.height.toDouble()),
        Rect.fromCircle(center: targetCenter, radius: targetRadius),
        Paint()..isAntiAlias = true,
      );
      canvas.restore();

      // Border circle
      final targetBorderPaint = Paint()
        ..color = neonPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(targetCenter, targetRadius, targetBorderPaint);
    }

    // 10. Draw Explosion Particles
    for (final p in state.particles) {
      final pPaint = Paint()
        ..color = p.color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), p.size * p.alpha, pPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SlingshotPainter oldDelegate) {
    return true; // Continuously repaint as state updates in the ticker loop
  }
}
