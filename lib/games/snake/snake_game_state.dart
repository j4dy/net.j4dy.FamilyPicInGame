import 'dart:math' as math;
import '../../models/face_profile.dart';
import '../common/vector_2d.dart';

enum SnakeDirection { up, down, left, right }

class SparkleParticle {
  final Vector2D gridPos;
  Vector2D offset;
  final Vector2D speed;
  double alpha;
  int age;
  final int maxAge;
  final bool isNeonPink;

  SparkleParticle({
    required this.gridPos,
    required this.offset,
    required this.speed,
    this.alpha = 1.0,
    this.age = 0,
    required this.maxAge,
    this.isNeonPink = false,
  });
}

class PortalRipple {
  final Vector2D gridPos;
  double alpha;
  final bool isNeonPink;

  PortalRipple({
    required this.gridPos,
    this.alpha = 1.0,
    required this.isNeonPink,
  });
}

class SnakeGameState {
  final FaceProfile headProfile;
  final FaceProfile foodProfile;
  final List<FaceProfile> allProfiles;

  // Grid dimensions
  final int gridWidth = 18;
  final int gridHeight = 22;

  // Game states
  final List<Vector2D> snake = [];
  SnakeDirection direction = SnakeDirection.right;
  SnakeDirection nextDirection = SnakeDirection.right;
  Vector2D foodPos = const Vector2D(12.0, 10.0);
  int score = 0;
  bool isGameOver = false;
  String gameMessage = "Swipe or tap controls to turn!";

  // Particles & animations
  final List<SparkleParticle> sparkles = [];
  final List<PortalRipple> portalRipples = [];

  final _random = math.Random();

  SnakeGameState({
    required this.headProfile,
    required this.foodProfile,
    required this.allProfiles,
  }) {
    resetGame();
  }

  void resetGame() {
    snake.clear();
    snake.addAll([
      const Vector2D(5.0, 10.0),
      const Vector2D(4.0, 10.0),
      const Vector2D(3.0, 10.0),
    ]);
    direction = SnakeDirection.right;
    nextDirection = SnakeDirection.right;
    score = 0;
    isGameOver = false;
    gameMessage = "Chomp the family food!";
    sparkles.clear();
    portalRipples.clear();
    spawnFood();
  }

  void spawnFood() {
    int attempts = 0;
    Vector2D newFood;
    do {
      newFood = Vector2D(
        _random.nextInt(gridWidth).toDouble(),
        _random.nextInt(gridHeight).toDouble(),
      );
      attempts++;
    } while (snake.any((segment) => segment.x == newFood.x && segment.y == newFood.y) && attempts < 100);
    foodPos = newFood;
  }

  void setSnakeDirection(SnakeDirection dir) {
    if (dir == SnakeDirection.up && direction == SnakeDirection.down) return;
    if (dir == SnakeDirection.down && direction == SnakeDirection.up) return;
    if (dir == SnakeDirection.left && direction == SnakeDirection.right) return;
    if (dir == SnakeDirection.right && direction == SnakeDirection.left) return;
    nextDirection = dir;
  }

  void tick() {
    if (isGameOver) return;

    direction = nextDirection;

    // Calculate next head position
    final head = snake.first;
    var nextHead = head;

    switch (direction) {
      case SnakeDirection.up:
        nextHead = Vector2D(head.x, head.y - 1);
        break;
      case SnakeDirection.down:
        nextHead = Vector2D(head.x, head.y + 1);
        break;
      case SnakeDirection.left:
        nextHead = Vector2D(head.x - 1, head.y);
        break;
      case SnakeDirection.right:
        nextHead = Vector2D(head.x + 1, head.y);
        break;
    }

    // Wrap around borders
    double wrappedX = nextHead.x;
    double wrappedY = nextHead.y;

    if (nextHead.x < 0) {
      wrappedX = (gridWidth - 1).toDouble();
    } else if (nextHead.x >= gridWidth) {
      wrappedX = 0.0;
    }

    if (nextHead.y < 0) {
      wrappedY = (gridHeight - 1).toDouble();
    } else if (nextHead.y >= gridHeight) {
      wrappedY = 0.0;
    }

    final didWrap = wrappedX != nextHead.x || wrappedY != nextHead.y;
    final wrapExit = head;
    nextHead = Vector2D(wrappedX, wrappedY);

    if (didWrap) {
      portalRipples.add(PortalRipple(gridPos: wrapExit, isNeonPink: false));
      portalRipples.add(PortalRipple(gridPos: nextHead, isNeonPink: true));
      _spawnPortalSparkles(wrapExit, false);
      _spawnPortalSparkles(nextHead, true);
    }

    // Check self-collision
    if (snake.any((segment) => segment.x == nextHead.x && segment.y == nextHead.y)) {
      isGameOver = true;
      gameMessage = "Oops! Ate your own tail! Score: $score";
      return;
    }

    // Insert new head
    snake.insert(0, nextHead);

    // Check food collision
    if (nextHead.x == foodPos.x && nextHead.y == foodPos.y) {
      score += 150;
      gameMessage = "Delicious! Score: $score";
      _spawnSparkles(nextHead);
      spawnFood();
    } else {
      if (snake.isNotEmpty) {
        snake.removeLast();
      }
    }

    // Update sparkles
    for (int i = sparkles.length - 1; i >= 0; i--) {
      final s = sparkles[i];
      s.offset = s.offset + s.speed;
      s.age++;
      s.alpha = 1.0 - (s.age / s.maxAge);
      if (s.age >= s.maxAge) {
        sparkles.removeAt(i);
      }
    }

    // Update portal ripples
    for (int i = portalRipples.length - 1; i >= 0; i--) {
      final r = portalRipples[i];
      r.alpha -= 0.15;
      if (r.alpha <= 0.0) {
        portalRipples.removeAt(i);
      }
    }
  }

  void _spawnSparkles(Vector2D pos) {
    for (int i = 0; i < 15; i++) {
      final angle = _random.nextDouble() * 2.0 * math.pi;
      final speedScalar = 1.0 + _random.nextDouble() * 4.0;
      final speed = Vector2D(
        math.cos(angle) * speedScalar,
        math.sin(angle) * speedScalar,
      );
      sparkles.add(
        SparkleParticle(
          gridPos: pos,
          offset: const Vector2D(0.0, 0.0),
          speed: speed,
          maxAge: 10 + _random.nextInt(10),
        ),
      );
    }
  }

  void _spawnPortalSparkles(Vector2D pos, bool isNeonPink) {
    for (int i = 0; i < 8; i++) {
      final angle = _random.nextDouble() * 2.0 * math.pi;
      final speedScalar = 0.5 + _random.nextDouble() * 2.0;
      final speed = Vector2D(
        math.cos(angle) * speedScalar,
        math.sin(angle) * speedScalar,
      );
      sparkles.add(
        SparkleParticle(
          gridPos: pos,
          offset: const Vector2D(0.0, 0.0),
          speed: speed,
          maxAge: 8 + _random.nextInt(8),
          isNeonPink: isNeonPink,
        ),
      );
    }
  }

  FaceProfile getProfileForSegment(int index) {
    if (index == 0) return headProfile;
    final bodyPool = allProfiles.where((p) => p.id != headProfile.id).toList();
    if (bodyPool.isEmpty) return headProfile;
    final poolIndex = (index - 1) % bodyPool.length;
    return bodyPool[poolIndex];
  }
}
