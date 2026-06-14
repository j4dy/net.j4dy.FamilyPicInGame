import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';
import '../../games/connect4/connect4_game_state.dart';

class Connect4GameScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final VoidCallback onBackClick;

  const Connect4GameScreen({
    super.key,
    required this.faceStorage,
    required this.onBackClick,
  });

  @override
  State<Connect4GameScreen> createState() => _Connect4GameScreenState();
}

class _Connect4GameScreenState extends State<Connect4GameScreen>
    with SingleTickerProviderStateMixin {
  late Connect4GameState _gameState;
  late List<FaceProfile> _profiles;

  FaceProfile? _playerFace;
  FaceProfile? _aiFace;

  int? _hoverColumn;
  int _playerScore = 0;
  int _aiScore = 0;

  bool _isAiThinking = false;
  bool _gameStarted = false;
  bool _showResult = false;
  String _resultMessage = '';
  int _gameSessionId = 0;

  // Animation for dropping pieces
  late AnimationController _dropController;
  late Animation<double> _dropAnimation;
  bool _isAnimating = false;
  int _animatingCol = -1;
  int _animatingRow = -1;

  // Win animation
  late AnimationController _winController;
  late Animation<double> _winPulse;

  // Board dimensions
  static const double _cellSize = 48.0;
  static const double _chipRadius = 20.0;
  static const double _columnWidth = 56.0;

  @override
  void initState() {
    super.initState();
    _gameState = Connect4GameState();
    _profiles = widget.faceStorage.getProfiles();

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dropAnimation = CurvedAnimation(
      parent: _dropController,
      curve: Curves.bounceOut,
    );

    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winPulse = CurvedAnimation(
      parent: _winController,
      curve: Curves.easeInOut,
    );

    _assignFaces();
  }

  void _assignFaces() {
    final custom = _profiles.where((p) => !p.isDefault).toList();
    final defaults = _profiles.where((p) => p.isDefault).toList();

    if (custom.length >= 2) {
      _playerFace = custom[0];
      _aiFace = custom[1];
    } else if (custom.length == 1) {
      _playerFace = custom[0];
      _aiFace = defaults.isNotEmpty ? defaults[0] : null;
    } else {
      if (defaults.length >= 2) {
        _playerFace = defaults[0];
        _aiFace = defaults[1];
      } else if (defaults.length == 1) {
        _playerFace = defaults[0];
        _aiFace = defaults[0];
      }
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _winController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameSessionId++;
      _gameState.reset();
      _gameStarted = true;
      _showResult = false;
      _hoverColumn = null;
      _isAiThinking = false;
      _isAnimating = false;
    });
  }

  Future<void> _handleColumnTap(int col) async {
    if (!_gameStarted ||
        _isAnimating ||
        _isAiThinking ||
        _gameState.isGameOver) {
      return;
    }

    final sessionId = _gameSessionId;

    final result = _gameState.dropInColumn(col);
    if (result != DropResult.ok) return;

    // Record which cell for animation
    _animatingCol = col;
    _animatingRow = _gameState.lastRow!;
    _isAnimating = true;
    try {
      await _dropController.forward(from: 0.0);
    } catch (_) {}
    if (!mounted || _gameSessionId != sessionId) return;
    _isAnimating = false;

    setState(() {}); // refresh board

    // Check game over
    if (_gameState.isGameOver) {
      _handleGameOver();
      return;
    }

    // AI turn
    _isAiThinking = true;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _gameSessionId != sessionId) return;

    final aiCol = _gameState.computeAiMove();
    if (aiCol < 0) return;

    _gameState.dropInColumn(aiCol);
    _animatingCol = aiCol;
    _animatingRow = _gameState.lastRow!;
    _isAnimating = true;
    try {
      await _dropController.forward(from: 0.0);
    } catch (_) {}
    if (!mounted || _gameSessionId != sessionId) return;
    _isAnimating = false;

    _isAiThinking = false;
    setState(() {});

    if (_gameState.isGameOver) {
      _handleGameOver();
    }
  }

  void _handleGameOver() {
    final winner = _gameState.winningCells != null
        ? _gameState.board[_gameState.winningCells!.first.$1]
            [_gameState.winningCells!.first.$2]
        : null;

    if (winner == Connect4Cell.playerA) {
      _playerScore++;
      _resultMessage = 'YOU WIN!';
    } else if (winner == Connect4Cell.playerB) {
      _aiScore++;
      _resultMessage = 'AI WINS!';
    } else {
      _resultMessage = "IT'S A DRAW!";
    }

    _winController.repeat(reverse: true);
    setState(() => _showResult = true);
  }

  Widget _buildFaceImage(FaceProfile? profile, double size) {
    if (profile == null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: cardSlate,
          shape: BoxShape.circle,
        ),
      );
    }
    final hasImage = profile.imagePath.isNotEmpty && File(profile.imagePath).existsSync();
    return ClipOval(
      child: hasImage
          ? Image.file(
              File(profile.imagePath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: cardSlate,
                    shape: BoxShape.circle,
                    border: Border.all(color: softGrey, width: 1),
                  ),
                  child: const Icon(Icons.face, color: softGrey, size: 20),
                );
              },
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: cardSlate,
                shape: BoxShape.circle,
                border: Border.all(color: softGrey, width: 1),
              ),
              child: const Icon(Icons.face, color: softGrey, size: 20),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E17), Color(0xFF0F1628), Color(0xFF0A0E17)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!_gameStarted)
                _buildStartScreen()
              else ...[
                _buildScoreBoard(),
                Expanded(child: _buildGameBoard()),
                if (_showResult) _buildResultOverlay(),
                _buildBottomBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: icyWhite),
            onPressed: widget.onBackClick,
          ),
          const Spacer(),
          const Text(
            'CONNECT 4',
            style: TextStyle(
              color: electricCyan,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // balance back button
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Player faces preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFaceCard('YOU', _playerFace, neonPink),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: electricCyan,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: electricCyan,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFaceCard('AI', _aiFace, cyberPurple),
                ],
              ),
              const SizedBox(height: 48),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardSlate.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: electricCyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'RULES',
                      style: TextStyle(
                        color: electricCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Drop your face token into a column.\n'
                      'First to line up 4 in a row wins!\n'
                      'Horizontally, vertically, or diagonally.',
                      style: TextStyle(color: softGrey, fontSize: 14, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildNeonButton('START GAME', electricCyan, _startGame),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceCard(String label, FaceProfile? face, Color glowColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: glowColor.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildFaceImage(face, 76),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: glowColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardSlate.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: electricCyan.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreItem('YOU', _playerScore, neonPink, _playerFace),
          Container(
            height: 30,
            width: 1,
            color: electricCyan.withOpacity(0.3),
          ),
          _buildScoreItem('AI', _aiScore, cyberPurple, _aiFace),
        ],
      ),
    );
  }

  Widget _buildScoreItem(
      String label, int score, Color color, FaceProfile? face) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: _buildFaceImage(face, 28),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                color: icyWhite,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = Connect4GameState.cols * _columnWidth;
        final boardHeight = Connect4GameState.rows * _cellSize + 20;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Turn indicator
              if (!_gameState.isGameOver)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardSlate,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAiThinking
                          ? cyberPurple.withOpacity(0.5)
                          : neonPink.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAiThinking) ...[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: _buildFaceImage(_aiFace, 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI is thinking...',
                          style: TextStyle(color: cyberPurple, fontSize: 13),
                        ),
                      ] else ...[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: _buildFaceImage(_playerFace, 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your turn',
                          style: TextStyle(color: neonPink, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              // Board
              Container(
                width: boardWidth + 16,
                height: boardHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: electricCyan.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: electricCyan.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Column selection buttons
                    SizedBox(
                      height: 20,
                      child: Row(
                        children:
                            List.generate(Connect4GameState.cols, (col) {
                          final isFull =
                              _gameState.board[0][col] != Connect4Cell.empty;
                          return Expanded(
                            child: InkWell(
                              onTap:
                                  isFull ? null : () => _handleColumnTap(col),
                              onHover: (hover) {
                                if (!isFull && !_gameState.isGameOver) {
                                  setState(() =>
                                      _hoverColumn = hover ? col : null);
                                }
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _hoverColumn == col && !_gameState.isGameOver
                                      ? neonPink.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                                child: Center(
                                  child: Icon(
                                    _gameState.isGameOver
                                        ? Icons.remove
                                        : Icons.arrow_drop_down,
                                    color: _hoverColumn == col
                                        ? neonPink
                                        : electricCyan.withOpacity(0.4),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Board grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              List.generate(Connect4GameState.rows, (row) {
                            return Row(
                              children: List.generate(
                                  Connect4GameState.cols, (col) {
                                final cell = _gameState.board[row][col];
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: _buildCell(row, col, cell),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(int row, int col, Connect4Cell cell) {
    final isWinning = _gameState.winningCells != null &&
        _gameState.winningCells!.any((c) => c.$1 == row && c.$2 == col);

    final isAnimating = _animatingCol == col &&
        _animatingRow == row &&
        _isAnimating;

    double? dropOffset;
    if (isAnimating) {
      final progress = _dropAnimation.value;
      // Simulate dropping from top of the board
      final totalDistance = (row + 1) * _cellSize;
      dropOffset = -totalDistance + (totalDistance * progress);
    }

    Color? chipColor;
    if (cell == Connect4Cell.playerA) {
      chipColor = neonPink;
    } else if (cell == Connect4Cell.playerB) {
      chipColor = cyberPurple;
    }

    Widget chip;
    if (cell == Connect4Cell.empty) {
      chip = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A1628),
          border: Border.all(
            color: const Color(0xFF1A2A40),
            width: 1,
          ),
        ),
      );
    } else {
      final face = cell == Connect4Cell.playerA ? _playerFace : _aiFace;
      final size = _chipRadius * 2;
      final hasImage = face != null && face.imagePath.isNotEmpty && File(face.imagePath).existsSync();

      Widget faceChip = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isWinning ? Colors.white : chipColor!,
            width: isWinning ? 2.5 : 1.5,
          ),
          boxShadow: isWinning
              ? [
                  BoxShadow(
                    color: chipColor!.withOpacity(0.6),
                    blurRadius: 8 + _winPulse.value * 6,
                    spreadRadius: 1 + _winPulse.value * 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: chipColor!.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: ClipOval(
          child: hasImage
              ? Image.file(
                  File(face!.imagePath),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: chipColor,
                      child: Icon(
                        cell == Connect4Cell.playerA
                            ? Icons.person
                            : Icons.smart_toy,
                        color: Colors.white,
                        size: _chipRadius,
                      ),
                    );
                  },
                )
              : Container(
                  color: chipColor,
                  child: Icon(
                    cell == Connect4Cell.playerA
                        ? Icons.person
                        : Icons.smart_toy,
                    color: Colors.white,
                    size: _chipRadius,
                  ),
                ),
        ),
      );

      if (isAnimating && dropOffset != null) {
        chip = Transform.translate(
          offset: Offset(0, dropOffset),
          child: faceChip,
        );
      } else {
        chip = faceChip;
      }
    }

    // Winning pulse scale
    if (isWinning) {
      chip = AnimatedBuilder(
        animation: _winPulse,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _winPulse.value * 0.08,
            child: child,
          );
        },
        child: chip,
      );
    }

    return chip;
  }

  Widget _buildResultOverlay() {
    final isWin = _resultMessage == 'YOU WIN!';
    final isDraw = _resultMessage == "IT'S A DRAW!";
    final color = isWin ? neonPink : (isDraw ? electricCyan : cyberPurple);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cardSlate.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _resultMessage,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 15),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNeonButton('PLAY AGAIN', electricCyan, () {
                _winController.stop();
                _showResult = false;
                _startGame();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: _buildNeonButton('RESTART', neonPink, () {
        _winController.stop();
        _showResult = false;
        _startGame();
      }),
    );
  }

  Widget _buildNeonButton(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
