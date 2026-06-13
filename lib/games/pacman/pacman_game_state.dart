import 'dart:math' as math;
import 'dart:ui';
import '../../models/face_profile.dart';
import '../common/vector_2d.dart';

enum PacmanDirection { up, down, left, right, none }

class GridPos {
  final int x;
  final int y;

  const GridPos(this.x, this.y);

  GridPos plus(PacmanDirection dir) {
    switch (dir) {
      case PacmanDirection.up:
        return GridPos(x, y - 1);
      case PacmanDirection.down:
        return GridPos(x, y + 1);
      case PacmanDirection.left:
        return GridPos(x - 1, y);
      case PacmanDirection.right:
        return GridPos(x + 1, y);
      case PacmanDirection.none:
        return this;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPos && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class GhostState {
  final String id;
  final String name;
  final FaceProfile? profile;
  final int colorIndex; // 0: Red (Blinky), 1: Pink (Pinky), 2: Cyan (Inky), 3: Orange (Clyde)
  GridPos currentPos;
  GridPos nextPos;
  PacmanDirection dir;
  bool isVulnerable;
  bool isEaten;

  GhostState({
    required this.id,
    required this.name,
    this.profile,
    required this.colorIndex,
    required this.currentPos,
    required this.nextPos,
    this.dir = PacmanDirection.none,
    this.isVulnerable = false,
    this.isEaten = false,
  });
}

class PacmanSparkle {
  final Offset offset;
  final String text;
  double alpha;

  PacmanSparkle({
    required this.offset,
    required this.text,
    this.alpha = 1.0,
  });
}

class PacmanGameState {
  final FaceProfile playerProfile;
  final List<FaceProfile> ghostProfiles;

  // 15 cols by 19 rows
  final int gridWidth = 15;
  final int gridHeight = 19;

  static const List<String> originalMap = [
    "###############", // 0
    "#......#......#", // 1
    "#.####.#.####.#", // 2
    "#o####.#.####o#", // 3
    "#.............#", // 4
    "#.####.#.####.#", // 5
    "#......#......#", // 6
    "######   ######", // 7
    "     #   #     ", // 8 (Ghost house center)
    "######   ######", // 9
    "#......#......#", // 10
    "#.####.#.####.#", // 11
    "#o..##...##..o#", // 12
    "###.##.#.##.###", // 13
    "#......#......#", // 14
    "#.###########.#", // 15
    " ............. ", // 16 (tunnels)
    "#.............#", // 17
    "###############"  // 18
  ];

  final List<List<String>> board = [];

  // Player state
  GridPos playerCurrentPos = const GridPos(7, 14);
  GridPos playerNextPos = const GridPos(7, 14);
  PacmanDirection playerDir = PacmanDirection.none;
  PacmanDirection playerNextDir = PacmanDirection.none;
  double moveProgress = 0.0; // 0.0 to 1.0 between grid cells

  // Ghost states
  final List<GhostState> ghosts = [];
  double ghostProgress = 0.0;

  // Game vars
  int score = 0;
  int lives = 3;
  bool isPlaying = false;
  bool isGameOver = false;
  bool isVictory = false;
  String gameMessage = "TAP START TO PLAY";
  int totalDots = 0;
  int dotsEaten = 0;

  // Power pellet states
  int frightenedTimer = 0; // frames remaining of frightened state
  int ghostEatenMultiplier = 1;

  // Sparkles
  final List<PacmanSparkle> sparkles = [];

  final _random = math.Random();

  PacmanGameState({
    required this.playerProfile,
    required this.ghostProfiles,
  }) {
    resetGame();
  }

  bool isWall(int x, int y) {
    if (y < 0 || y >= gridHeight) return true;
    final wrappedX = (x + gridWidth) % gridWidth;
    return originalMap[y][wrappedX] == '#';
  }

  void resetGame() {
    isPlaying = false;
    isGameOver = false;
    isVictory = false;
    score = 0;
    lives = 3;
    dotsEaten = 0;
    frightenedTimer = 0;
    sparkles.clear();

    // Reset board grid and count dots
    board.clear();
    totalDots = 0;
    for (int y = 0; y < gridHeight; y++) {
      final List<String> rowList = [];
      for (int x = 0; x < gridWidth; x++) {
        final char = originalMap[y][x];
        rowList.add(char);
        if (char == '.' || char == 'o') {
          totalDots++;
        }
      }
      board.add(rowList);
    }

    _resetRoundPositions();
    gameMessage = "READY PLAYER ONE";
  }

  void _resetRoundPositions() {
    playerCurrentPos = const GridPos(7, 14);
    playerNextPos = const GridPos(7, 14);
    playerDir = PacmanDirection.none;
    playerNextDir = PacmanDirection.none;
    moveProgress = 0.0;

    ghosts.clear();
    ghostProgress = 0.0;

    // Setup 4 ghosts
    final ghostColors = [0, 1, 2, 3];
    final spawnPoints = [
      const GridPos(6, 8), // Blinky
      const GridPos(7, 8), // Pinky
      const GridPos(8, 8), // Inky
      const GridPos(7, 8)  // Clyde
    ];

    for (int i = 0; i < 4; i++) {
      final profile = i < ghostProfiles.length ? ghostProfiles[i] : null;
      final name = profile?.name ??
          (i == 0
              ? "Blinky"
              : i == 1
                  ? "Pinky"
                  : i == 2
                      ? "Inky"
                      : "Clyde");
      ghosts.add(
        GhostState(
          id: profile?.id ?? "fallback_$i",
          name: name,
          profile: profile,
          colorIndex: ghostColors[i],
          currentPos: spawnPoints[i],
          nextPos: spawnPoints[i],
          dir: PacmanDirection.up,
        ),
      );
    }
  }

  void startGame() {
    isPlaying = true;
    isGameOver = false;
    isVictory = false;
    gameMessage = "CHOMP THEM ALL!";
  }

  void setPlayerDirection(PacmanDirection dir) {
    if (!isPlaying || isGameOver) return;
    playerNextDir = dir;
    if (playerDir == PacmanDirection.none) {
      final next = playerCurrentPos.plus(dir);
      if (!isWall(next.x, next.y)) {
        playerDir = dir;
        playerNextPos = _wrapGridPos(next);
        moveProgress = 0.0;
      }
    }
  }

  GridPos _wrapGridPos(GridPos pos) {
    final wrappedX = (pos.x + gridWidth) % gridWidth;
    return GridPos(wrappedX, pos.y);
  }

  void tickFrame() {
    if (!isPlaying || isGameOver || isVictory) return;

    // 1. Tick power pellet frightened timer
    if (frightenedTimer > 0) {
      frightenedTimer--;
      if (frightenedTimer == 0) {
        for (final ghost in ghosts) {
          ghost.isVulnerable = false;
        }
        ghostEatenMultiplier = 1;
      }
    }

    // 2. Tick sparkles
    for (int i = sparkles.length - 1; i >= 0; i--) {
      sparkles[i].alpha -= 0.04;
      if (sparkles[i].alpha <= 0.0) {
        sparkles.removeAt(i);
      }
    }

    // 3. Advance player movement
    const double basePlayerSpeed = 0.08; // ~12 frames
    moveProgress += basePlayerSpeed;
    if (moveProgress >= 1.0) {
      moveProgress = 0.0;
      playerCurrentPos = playerNextPos;

      // Eat dot
      _eatPellet(playerCurrentPos);

      // Next step
      final nextWithBuffer = playerCurrentPos.plus(playerNextDir);
      if (!isWall(nextWithBuffer.x, nextWithBuffer.y)) {
        playerDir = playerNextDir;
        playerNextPos = _wrapGridPos(nextWithBuffer);
      } else {
        final nextWithCurrent = playerCurrentPos.plus(playerDir);
        if (!isWall(nextWithCurrent.x, nextWithCurrent.y)) {
          playerNextPos = _wrapGridPos(nextWithCurrent);
        } else {
          playerDir = PacmanDirection.none;
          playerNextPos = playerCurrentPos;
        }
      }
    }

    // 4. Advance ghosts
    final double baseGhostSpeed = frightenedTimer > 0 ? 0.04 : 0.07;
    ghostProgress += baseGhostSpeed;
    if (ghostProgress >= 1.0) {
      ghostProgress = 0.0;

      for (final ghost in ghosts) {
        ghost.currentPos = ghost.nextPos;

        if (ghost.isEaten && ghost.currentPos == const GridPos(7, 8)) {
          ghost.isEaten = false;
          ghost.isVulnerable = false;
        }

        final target = _getGhostTargetTile(ghost);
        final nextDir = _getGhostNextDirection(ghost, target);
        ghost.dir = nextDir;
        ghost.nextPos = _wrapGridPos(ghost.currentPos.plus(nextDir));
      }
    }

    // 5. Collision checks
    _checkCollisions();
  }

  void _eatPellet(GridPos pos) {
    final y = pos.y;
    final x = pos.x;
    if (y >= 0 && y < gridHeight && x >= 0 && x < gridWidth) {
      final item = board[y][x];
      if (item == '.') {
        board[y][x] = ' ';
        score += 10;
        dotsEaten++;
        _checkVictory();
      } else if (item == 'o') {
        board[y][x] = ' ';
        score += 50;
        dotsEaten++;
        _triggerPowerPellet();
        _checkVictory();
      }
    }
  }

  void _triggerPowerPellet() {
    frightenedTimer = 450; // ~7.5 seconds
    ghostEatenMultiplier = 1;
    for (final ghost in ghosts) {
      if (!ghost.isEaten) {
        ghost.isVulnerable = true;
      }
    }
    gameMessage = "GHOSTS ARE VULNERABLE!";
  }

  void _checkVictory() {
    if (dotsEaten >= totalDots) {
      isVictory = true;
      isPlaying = false;
      gameMessage = "VICTORY! Score: $score";
    }
  }

  void _checkCollisions() {
    final pOffset = _getInterpolatedGridOffset(playerCurrentPos, playerNextPos, moveProgress);

    for (final ghost in ghosts) {
      final gOffset = _getInterpolatedGridOffset(ghost.currentPos, ghost.nextPos, ghostProgress);
      final dist = pOffset.distance(gOffset);

      if (dist < 0.7) {
        if (ghost.isVulnerable && !ghost.isEaten) {
          ghost.isEaten = true;
          ghost.isVulnerable = false;
          final points = 200 * ghostEatenMultiplier;
          score += points;

          // Spawn sparkle
          final double drawX = gOffset.x * 40.0;
          final double drawY = gOffset.y * 40.0;
          sparkles.add(PacmanSparkle(offset: Offset(drawX, drawY), text: "+$points"));

          gameMessage = "ATE GHOST ${ghost.name}! +$points";
          ghostEatenMultiplier = (ghostEatenMultiplier * 2).clamp(1, 8);
        } else if (!ghost.isEaten && !ghost.isVulnerable) {
          _loseLife();
          return;
        }
      }
    }
  }

  void _loseLife() {
    lives--;
    if (lives <= 0) {
      isGameOver = true;
      isPlaying = false;
      gameMessage = "GAME OVER! Final Score: $score";
    } else {
      _resetRoundPositions();
      gameMessage = "READY! Lives left: $lives";
    }
  }

  Vector2D _getInterpolatedGridOffset(GridPos current, GridPos next, double progress) {
    final diffX = next.x - current.x;
    final diffY = next.y - current.y;
    if (diffX.abs() > 1) {
      if (current.x == 0 && next.x == gridWidth - 1) {
        return Vector2D(0.0 - progress, current.y.toDouble());
      } else {
        return Vector2D((gridWidth - 1).toDouble() + progress, current.y.toDouble());
      }
    }
    return Vector2D(current.x + diffX * progress, current.y + diffY * progress);
  }

  GridPos _getGhostTargetTile(GhostState ghost) {
    if (ghost.isEaten) {
      return const GridPos(7, 8); // Spawn center
    }
    if (ghost.isVulnerable) {
      return const GridPos(0, 0); // Flee corner
    }

    switch (ghost.colorIndex) {
      case 0: // Blinky: Direct chase
        return playerCurrentPos;
      case 1: // Pinky: Ambush
        return playerCurrentPos.plus(playerDir).plus(playerDir);
      case 2: // Inky: Mirror Vector
        final blinkyList = ghosts.where((g) => g.colorIndex == 0).toList();
        if (blinkyList.isNotEmpty) {
          final blinky = blinkyList.first;
          final pX = playerCurrentPos.x;
          final pY = playerCurrentPos.y;
          final bX = blinky.currentPos.x;
          final bY = blinky.currentPos.y;
          final targetX = pX + (pX - bX);
          final targetY = pY + (pY - bY);
          return GridPos(targetX.clamp(0, gridWidth - 1), targetY.clamp(0, gridHeight - 1));
        }
        return playerCurrentPos;
      default: // Clyde
        final dx = ghost.currentPos.x - playerCurrentPos.x;
        final dy = ghost.currentPos.y - playerCurrentPos.y;
        final distSq = dx * dx + dy * dy;
        if (distSq > 16) {
          return playerCurrentPos;
        } else {
          return GridPos(0, gridHeight - 1); // Scatter bottom left
        }
    }
  }

  PacmanDirection _getGhostNextDirection(GhostState ghost, GridPos target) {
    final directions = [PacmanDirection.up, PacmanDirection.down, PacmanDirection.left, PacmanDirection.right];
    final validDirs = directions.where((dir) {
      final isReverse = (dir == PacmanDirection.up && ghost.dir == PacmanDirection.down) ||
          (dir == PacmanDirection.down && ghost.dir == PacmanDirection.up) ||
          (dir == PacmanDirection.left && ghost.dir == PacmanDirection.right) ||
          (dir == PacmanDirection.right && ghost.dir == PacmanDirection.left);
      if (isReverse) return false;
      final next = ghost.currentPos.plus(dir);
      return !isWall(next.x, next.y);
    }).toList();

    if (validDirs.isEmpty) {
      switch (ghost.dir) {
        case PacmanDirection.up:
          return PacmanDirection.down;
        case PacmanDirection.down:
          return PacmanDirection.up;
        case PacmanDirection.left:
          return PacmanDirection.right;
        case PacmanDirection.right:
          return PacmanDirection.left;
        default:
          return PacmanDirection.up;
      }
    }

    if (ghost.isVulnerable) {
      return validDirs[_random.nextInt(validDirs.length)];
    }

    // Min squared distance direction to target
    double minDistance = double.infinity;
    PacmanDirection bestDir = PacmanDirection.up;

    for (final dir in validDirs) {
      final next = ghost.currentPos.plus(dir);
      final dx = next.x - target.x;
      final dy = next.y - target.y;
      final dist = (dx * dx + dy * dy).toDouble();
      if (dist < minDistance) {
        minDistance = dist;
        bestDir = dir;
      }
    }

    return bestDir;
  }
}
