import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/whack/whack_game_state.dart';

class WhackGameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const WhackGameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<WhackGameScreen> createState() => _WhackGameScreenState();
}

class _WhackGameScreenState extends State<WhackGameScreen> with SingleTickerProviderStateMixin {
  late List<FaceProfile> _profiles;
  final Set<String> _teamA = {}; // Teammates (avoid)
  final Set<String> _teamB = {}; // Opponents (whack)
  double _speedMultiplier = 2.0; // Default 2.0x (double speed)
  bool _gameStarted = false;

  WhackGameState? _gameState;
  final Map<String, ui.Image> _profileImages = {};
  
  Timer? _secondTimer;
  late final Ticker _frameTicker;

  @override
  void initState() {
    super.initState();
    _profiles = widget.faceStorage.getProfiles();

    // Default setups
    if (_profiles.isNotEmpty) {
      _teamA.add(_profiles[0].id);
      if (_profiles.length > 1) {
        _teamB.add(_profiles[1].id);
      }
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

  @override
  void dispose() {
    _frameTicker.dispose();
    _secondTimer?.cancel();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _startGame() async {
    if (_teamA.isEmpty || _teamB.isEmpty) return;
    try {
      // Pre-load all profile images in memory
      for (final p in _profiles) {
        final img = await _loadImage(p.imagePath);
        _profileImages[p.id] = img;
      }

      setState(() {
        _gameState = WhackGameState(
          teamAProfiles: _profiles.where((p) => _teamA.contains(p.id)).toList(),
          teamBProfiles: _profiles.where((p) => _teamB.contains(p.id)).toList(),
          speedMultiplier: _speedMultiplier,
        )..startGame();
        _gameStarted = true;
      });

      _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_gameStarted && _gameState != null && _gameState!.isPlaying && !_gameState!.isGameOver) {
          setState(() {
            _gameState!.tickSecond();
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting whack game: $e');
    }
  }

  void _stopGame() {
    _secondTimer?.cancel();
    setState(() {
      _gameStarted = false;
      _gameState = null;
    });
  }

  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      // Setup UI (Portrait)
      return Scaffold(
        appBar: AppBar(
          title: const Text("Setup Whack Teams"),
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
                            "ASSIGN GAME TEAMS",
                            style: TextStyle(
                              color: electricCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Team A
                        const Text(
                          "Select Teammates (Team A - Do NOT Tap):",
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
                              final isSelected = _teamA.contains(profile.id);
                              return _RoleAvatarItem(
                                profile: profile,
                                isSelected: isSelected,
                                color: electricCyan,
                                onClick: () {
                                  setState(() {
                                    if (isSelected) {
                                      _teamA.remove(profile.id);
                                    } else {
                                      _teamA.add(profile.id);
                                      _teamB.remove(profile.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Team B
                        const Text(
                          "Select Opponents (Team B - Whack Them!):",
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
                              final isSelected = _teamB.contains(profile.id);
                              return _RoleAvatarItem(
                                profile: profile,
                                isSelected: isSelected,
                                color: neonPink,
                                onClick: () {
                                  setState(() {
                                    if (isSelected) {
                                      _teamB.remove(profile.id);
                                    } else {
                                      _teamB.add(profile.id);
                                      _teamA.remove(profile.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Speed multiplier
                        const Text(
                          "Select Speed Multiplier:",
                          style: TextStyle(color: icyWhite, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [1.0, 1.5, 2.0, 3.0].map((speed) {
                            final isSelected = _speedMultiplier == speed;
                            final labels = {
                              1.0: "1.0x (Slow)",
                              1.5: "1.5x (Normal)",
                              2.0: "2.0x (Fast)",
                              3.0: "3.0x (Insane)"
                            };
                            return Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _speedMultiplier = speed;
                                  });
                                },
                                child: Container(
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? electricCyan : cardSlate,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : softGrey.withOpacity(0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    labels[speed]!,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : icyWhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: (_teamA.isNotEmpty && _teamB.isNotEmpty) ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonPink,
                    disabledBackgroundColor: softGrey.withOpacity(0.3),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "LAUNCH CHALLENGE",
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
        title: Text("Teammates vs Opponents (${_speedMultiplier}x)"),
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
              // Stats HUD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SCORE", style: TextStyle(color: softGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      Text("${state.score}", style: const TextStyle(color: electricCyan, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("TIME LEFT", style: TextStyle(color: softGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      Text(
                        "${state.timeLeftSeconds}s",
                        style: TextStyle(
                          color: state.timeLeftSeconds <= 10 ? neonPink : icyWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Time progress bar
              LinearProgressIndicator(
                value: state.timeLeftSeconds / 45.0,
                color: state.timeLeftSeconds <= 10 ? neonPink : electricCyan,
                backgroundColor: cyberPurple.withOpacity(0.2),
                minHeight: 6.0,
                borderRadius: BorderRadius.circular(4.0),
              ),
              const SizedBox(height: 12),

              // Board Game Grid (3x4 Grid)
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
                          onTapUp: (details) {
                            if (!state.isPlaying) return;
                            final cellW = _canvasSize.width / 3.0;
                            final cellH = _canvasSize.height / 4.0;
                            final int col = (details.localPosition.dx / cellW).toInt().clamp(0, 2);
                            final int row = (details.localPosition.dy / cellH).toInt().clamp(0, 3);
                            final int index = row * 3 + col;
                            setState(() {
                              state.whackCell(index);
                            });
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _WhackPainter(
                                    state: state,
                                    profileImages: _profileImages,
                                  ),
                                ),
                              ),
                              if (!state.isPlaying)
                                Container(
                                  color: Colors.black.withOpacity(0.6),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        state.isGameOver ? "GAME OVER" : "TEAM WHACK CHALLENGE",
                                        style: TextStyle(
                                          color: state.isGameOver ? neonPink : electricCyan,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.isGameOver
                                            ? "Final Score: ${state.score}"
                                            : "Whack Opponents (Neon Pink).\nDo NOT tap Teammates (Electric Cyan)!",
                                        style: const TextStyle(color: icyWhite, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () => setState(() => state.startGame()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: neonPink,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        ),
                                        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                                        label: Text(
                                          state.isGameOver ? "PLAY AGAIN" : "START MATCH",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
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

              // Bottom HUD Combo card
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
                        const Text("COMBO", style: TextStyle(color: softGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        Text("x${state.comboMultiplier}", style: const TextStyle(color: electricCyan, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        state.gameMessage,
                        style: const TextStyle(color: icyWhite, fontSize: 14, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _WhackPainter extends CustomPainter {
  final WhackGameState state;
  final Map<String, ui.Image> profileImages;

  _WhackPainter({
    required this.state,
    required this.profileImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cellW = w / 3.0;
    final cellH = h / 4.0;

    final gridPaint = Paint()
      ..color = cyberPurple.withOpacity(0.2)
      ..strokeWidth = 2.0;

    // Draw dividers
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, h), gridPaint);
    }
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(Offset(0, i * cellH), Offset(w, i * cellH), gridPaint);
    }

    // Draw holes & characters
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 3; col++) {
        final index = row * 3 + col;
        final portal = state.portals[index];

        final cX = col * cellW + cellW / 2.0;
        final cY = row * cellH + cellH / 2.0;

        final radius = math.min(cellW, cellH) * 0.35;
        final holeRadiusX = radius * 1.1;
        final holeRadiusY = radius * 0.45;

        // Draw portal hole backing shadow (dark ellipse)
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cX, cY + radius * 0.3), width: holeRadiusX * 2, height: holeRadiusY * 2),
          Paint()..color = const Color(0xFF030712),
        );

        // Draw character popping out
        if (portal.type != PortalType.empty && portal.familyProfile != null) {
          final double charCenterY = cY - radius * 0.1;
          final double faceR = radius * 0.8;

          canvas.save();
          // Clip drawing so it doesn't bleed out of cell bottom
          final cellClip = Path()..addRect(Rect.fromLTRB(col * cellW, row * cellH, (col + 1) * cellW, cY + radius * 0.3 + 10.0));
          canvas.clipPath(cellClip);

          final profile = portal.familyProfile!;
          final img = profileImages[profile.id];
          if (img != null) {
            canvas.save();
            final faceClip = Path()..addOval(Rect.fromCircle(center: Offset(cX, charCenterY), radius: faceR));
            canvas.clipPath(faceClip);
            canvas.drawImageRect(
              img,
              Rect.fromLTRB(0.0, 0.0, img.width.toDouble(), img.height.toDouble()),
              Rect.fromCircle(center: Offset(cX, charCenterY), radius: faceR),
              Paint()..isAntiAlias = true,
            );
            canvas.restore();
          } else {
            // Fallback circle
            canvas.drawCircle(
              Offset(cX, charCenterY),
              faceR,
              Paint()..color = portal.type == PortalType.teamB ? neonPink : electricCyan,
            );
          }

          // Glow ring
          canvas.drawCircle(
            Offset(cX, charCenterY),
            faceR + 5.0,
            Paint()
              ..color = (portal.type == PortalType.teamB ? neonPink : electricCyan).withOpacity(0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );

          // Face border
          canvas.drawCircle(
            Offset(cX, charCenterY),
            faceR,
            Paint()
              ..color = portal.type == PortalType.teamB ? neonPink : electricCyan
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0,
          );

          canvas.restore();
        }

        // Draw portal hole front lip (ellipse outline)
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cX, cY + radius * 0.3), width: holeRadiusX * 2, height: holeRadiusY * 2),
          0.0,
          math.pi, // Draw only bottom half
          false,
          Paint()
            ..color = cyberPurple
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0,
        );
      }
    }

    // Draw sparkles
    for (final s in state.sparkles) {
      final cellX = (s.index % 3) * cellW + cellW / 2.0;
      final cellY = (s.index / 3) * cellH + cellH / 2.0;

      final color = s.isPenalty ? neonPink : electricCyan;

      // Glow circle
      canvas.drawCircle(
        Offset(cellX + s.offset.dx, cellY + s.offset.dy),
        30.0,
        Paint()..color = color.withOpacity(s.alpha * 0.4),
      );

      // Mini sparks
      canvas.drawCircle(
        Offset(cellX + s.offset.dx - 15.0, cellY + s.offset.dy - 10.0),
        6.0,
        Paint()..color = color.withOpacity(s.alpha),
      );
      canvas.drawCircle(
        Offset(cellX + s.offset.dx + 20.0, cellY + s.offset.dy + 15.0),
        4.0,
        Paint()..color = color.withOpacity(s.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WhackPainter oldDelegate) {
    return true; // Keep repainting for sparkles decay and portal timers
  }
}
