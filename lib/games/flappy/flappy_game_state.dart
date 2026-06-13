import 'dart:math' as math;
import '../../models/face_profile.dart';

class FlappyPipe {
  double x;
  final double topHeight;
  final double bottomHeight;
  final double width;
  bool passed;

  FlappyPipe({
    required this.x,
    required this.topHeight,
    required this.bottomHeight,
    this.width = 140.0,
    this.passed = false,
  });
}

enum FlappyDifficulty {
  easy("Space Cadet", 340.0),
  medium("Pilot", 280.0),
  hard("Astronaut", 220.0);

  final String displayName;
  final double gapHeight;
  const FlappyDifficulty(this.displayName, this.gapHeight);
}

class FlappyGameState {
  final FaceProfile playerProfile;
  final FlappyDifficulty difficulty;

  double birdY = 400.0;
  double birdVelocity = 0.0;

  final List<FlappyPipe> pipes = [];

  int score = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  String gameMessage = "TAP TO FLY";

  // Physics constants
  final double gravity = 0.5;
  final double jumpImpulse = -10.0;
  final double maxFallSpeed = 16.0;
  final double pipeSpeed = 6.0;
  final int pipeSpawnInterval = 100; // frames
  int _frameCount = 0;

  final _random = math.Random();

  FlappyGameState({
    required this.playerProfile,
    this.difficulty = FlappyDifficulty.hard,
  });

  void startGame() {
    isPlaying = true;
    isGameOver = false;
    score = 0;
    birdY = 350.0;
    birdVelocity = 0.0;
    pipes.clear();
    _frameCount = 0;
    gameMessage = "GO!";
  }

  void flap() {
    if (isGameOver) {
      startGame();
      return;
    }
    if (!isPlaying) {
      startGame();
    }
    birdVelocity = jumpImpulse;
  }

  void resetGame() {
    isPlaying = false;
    isGameOver = false;
    score = 0;
    birdY = 400.0;
    birdVelocity = 0.0;
    pipes.clear();
    _frameCount = 0;
    gameMessage = "TAP TO FLY";
  }

  void tick(double canvasWidth, double canvasHeight) {
    if (!isPlaying || isGameOver || canvasWidth <= 0 || canvasHeight <= 0) return;

    // 1. Update physics
    birdVelocity = (birdVelocity + gravity).clamp(-12.0, maxFallSpeed);
    birdY += birdVelocity;

    // 2. Spawn pipes
    _frameCount++;
    if (_frameCount % pipeSpawnInterval == 0 || pipes.isEmpty) {
      _spawnPipe(canvasWidth, canvasHeight);
    }

    // 3. Move pipes and check score
    final double birdX = canvasWidth * 0.25;
    const double birdRadius = 35.0;

    for (int i = pipes.length - 1; i >= 0; i--) {
      final pipe = pipes[i];
      pipe.x -= pipeSpeed;

      // Check if passed
      if (!pipe.passed && pipe.x + pipe.width < birdX) {
        pipe.passed = true;
        score++;
        gameMessage = _getMessageForScore(score);
      }
    }

    // Clean up offscreen pipes
    pipes.removeWhere((pipe) => pipe.x + pipe.width < -100.0);

    // 4. Collision check
    if (birdY - birdRadius < 0.0 || birdY + birdRadius > canvasHeight) {
      _endGame("Out of bounds!");
      return;
    }

    for (final pipe in pipes) {
      final withinX = birdX + birdRadius > pipe.x && birdX - birdRadius < pipe.x + pipe.width;
      if (withinX) {
        final hitTop = birdY - birdRadius < pipe.topHeight;
        final hitBottom = birdY + birdRadius > canvasHeight - pipe.bottomHeight;
        if (hitTop || hitBottom) {
          _endGame("Ouch! Hit a pillar!");
          return;
        }
      }
    }
  }

  String _getMessageForScore(int currentScore) {
    switch (currentScore) {
      case 5:
        return "Nice flying!";
      case 10:
        return "Awesome!";
      case 20:
        return "Astronaut Status!";
      default:
        return "Score: $currentScore";
    }
  }

  void _spawnPipe(double canvasWidth, double canvasHeight) {
    final gapHeight = difficulty.gapHeight;
    const double minHeight = 100.0;
    final double maxHeight = canvasHeight - gapHeight - minHeight;

    final double topHeight = _random.nextDouble() * (maxHeight - minHeight) + minHeight;
    final double bottomHeight = canvasHeight - topHeight - gapHeight;

    pipes.add(
      FlappyPipe(
        x: canvasWidth,
        topHeight: topHeight,
        bottomHeight: bottomHeight,
      ),
    );
  }

  void _endGame(String message) {
    isGameOver = true;
    isPlaying = false;
    gameMessage = "$message Game Over!";
  }
}
