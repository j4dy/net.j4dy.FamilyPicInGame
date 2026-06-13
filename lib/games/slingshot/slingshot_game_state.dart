import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/face_profile.dart';
import '../common/vector_2d.dart';

class PhysicsParticle {
  Vector2D pos;
  Vector2D vel;
  final Color color;
  double alpha;
  double size;
  int age;
  final int maxAge;

  PhysicsParticle({
    required this.pos,
    required this.vel,
    required this.color,
    this.alpha = 1.0,
    this.size = 8.0,
    this.age = 0,
    this.maxAge = 30,
  });
}

class TargetObstacle {
  final String id;
  Vector2D pos;
  Vector2D vel;
  final double radius;
  final FaceProfile profile;
  bool isDestroyed;
  int hitPoints;

  TargetObstacle({
    required this.id,
    required this.pos,
    required this.profile,
    Vector2D? vel,
    this.radius = 45.0,
    this.isDestroyed = false,
    this.hitPoints = 1,
  }) : vel = vel ?? const Vector2D(0.0, 0.0);
}

class BlockObstacle {
  final String id;
  final double left;
  double top; // var so they can fall!
  final double width;
  final double height;
  final Color color;
  bool isDestroyed;
  final bool isGlass;
  double velY; // vertical velocity for falling physics
  double velX; // horizontal velocity for sliding/toppling
  double rotation; // rotation angle in radians (Kotlin used degrees, let's keep radians or degrees, but radians is standard in canvas rotate)
  double velRot; // rotational velocity
  double xOffset; // horizontal displacement offset

  BlockObstacle({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    this.isDestroyed = false,
    this.isGlass = false,
    this.velY = 0.0,
    this.velX = 0.0,
    this.rotation = 0.0,
    this.velRot = 0.0,
    this.xOffset = 0.0,
  });
}

class SlingshotGameState {
  final FaceProfile heroProfile;
  final FaceProfile targetProfile;

  // Slingshot anchor
  final slingAnchor = const Vector2D(280.0, 460.0);
  final double maxDragDist = 120.0;

  // Game entities
  Vector2D birdPos = const Vector2D(280.0, 460.0);
  Vector2D birdVel = const Vector2D(0.0, 0.0);
  final double birdRadius = 38.0;

  // Playing states
  bool isDragging = false;
  bool isFlying = false;
  int shotsLeft = 3;
  int score = 0;
  String gameStateMessage = "Pull back to launch!";
  double screenShake = 0.0;

  // Level progression
  int currentLevel = 1;
  final int maxLevels = 3;

  // Lists of objects
  List<TargetObstacle> targets = [];
  List<BlockObstacle> blocks = [];
  List<PhysicsParticle> particles = [];

  // Physics constants
  final gravity = const Vector2D(0.0, 0.45);
  final double bounceFactor = 0.4;

  final _random = math.Random();

  SlingshotGameState({
    required this.heroProfile,
    required this.targetProfile,
  }) {
    resetLevel();
  }

  void nextLevel() {
    if (currentLevel < maxLevels) {
      currentLevel++;
      resetLevel();
    }
  }

  void resetLevel() {
    birdPos = slingAnchor;
    birdVel = const Vector2D(0.0, 0.0);
    isDragging = false;
    isFlying = false;
    shotsLeft = 3;
    score = 0;
    gameStateMessage = "Level $currentLevel: Aim carefully!";
    screenShake = 0.0;
    particles = [];

    switch (currentLevel) {
      case 1:
        // Level 1: Twin Towers
        targets = [
          TargetObstacle(id: "t1", pos: const Vector2D(920.0, 500.0), profile: targetProfile),
          TargetObstacle(id: "t2", pos: const Vector2D(1080.0, 500.0), profile: targetProfile),
          TargetObstacle(id: "t3", pos: const Vector2D(1000.0, 320.0), profile: targetProfile),
        ];
        blocks = [
          // Vertical wooden pillars
          BlockObstacle(id: "b1", left: 870, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b2", left: 970, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b3", left: 1030, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b4", left: 1130, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          // Glass ceilings
          BlockObstacle(id: "b5", left: 860, top: 410, width: 150, height: 30, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b6", left: 1020, top: 410, width: 150, height: 30, color: const Color(0xCC00F5FF), isGlass: true),
        ];
        break;
      case 2:
        // Level 2: The Pyramid Arch
        targets = [
          TargetObstacle(id: "t1", pos: const Vector2D(900.0, 515.0), profile: targetProfile),
          TargetObstacle(id: "t2", pos: const Vector2D(1060.0, 515.0), profile: targetProfile),
          TargetObstacle(id: "t3", pos: const Vector2D(980.0, 400.0), profile: targetProfile),
        ];
        blocks = [
          BlockObstacle(id: "b1", left: 830, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b2", left: 940, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b3", left: 1020, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b4", left: 1130, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b5", left: 820, top: 410, width: 160, height: 30, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b6", left: 1010, top: 410, width: 160, height: 30, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b7", left: 900, top: 290, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b8", left: 1050, top: 290, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b9", left: 880, top: 260, width: 220, height: 30, color: const Color(0xFFC68B59)),
        ];
        break;
      case 3:
        // Level 3: Multi-Layer Fort
        targets = [
          TargetObstacle(id: "t1", pos: const Vector2D(880.0, 515.0), profile: targetProfile),
          TargetObstacle(id: "t2", pos: const Vector2D(980.0, 515.0), profile: targetProfile),
          TargetObstacle(id: "t3", pos: const Vector2D(1080.0, 515.0), profile: targetProfile),
          TargetObstacle(id: "t4", pos: const Vector2D(980.0, 320.0), profile: targetProfile),
        ];
        blocks = [
          BlockObstacle(id: "b1", left: 800, top: 440, width: 30, height: 120, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b2", left: 1140, top: 440, width: 30, height: 120, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b3", left: 900, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b4", left: 1040, top: 440, width: 30, height: 120, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b5", left: 880, top: 410, width: 200, height: 30, color: const Color(0xFFC68B59)),
          BlockObstacle(id: "b6", left: 930, top: 290, width: 30, height: 120, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b7", left: 1010, top: 290, width: 30, height: 120, color: const Color(0xCC00F5FF), isGlass: true),
          BlockObstacle(id: "b8", left: 910, top: 260, width: 150, height: 30, color: const Color(0xFFC68B59)),
        ];
        break;
    }
  }

  void onDrag(Offset dragPos) {
    if (isFlying) return;
    isDragging = true;
    final dragVec = Vector2D(dragPos.dx, dragPos.dy);
    final offset = dragVec - slingAnchor;
    birdPos = slingAnchor + offset.limit(maxDragDist);
  }

  void onRelease() {
    if (isFlying || !isDragging) return;
    isDragging = false;
    isFlying = true;
    final dragOffset = slingAnchor - birdPos;
    birdVel = dragOffset * 0.85;
    gameStateMessage = "Flying!";
  }

  void update() {
    // Decay screen shake
    if (screenShake > 0) {
      screenShake *= 0.85;
      if (screenShake < 0.2) screenShake = 0.0;
    }

    // 1. Update particles
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.pos = p.pos + p.vel;
      p.age++;
      p.alpha = 1.0 - (p.age / p.maxAge);
      if (p.age >= p.maxAge) {
        particles.removeAt(i);
      }
    }

    // 2. Update blocks gravity & physics
    const double groundY = 560.0;
    for (final b in blocks) {
      if (b.isDestroyed) continue;

      final List<Map<String, double>> supports = [];
      bool restingOnGround = false;

      if (b.top + b.height >= groundY - 4.0) {
        restingOnGround = true;
      } else {
        for (final other in blocks) {
          if (identical(other, b) || other.isDestroyed) continue;

          final bLeft = b.left + b.xOffset;
          final otherLeft = other.left + other.xOffset;
          final hOverlap = bLeft < otherLeft + other.width && bLeft + b.width > otherLeft;

          if (hOverlap) {
            final verticalDist = other.top - (b.top + b.height);
            if (verticalDist >= -5.0 && verticalDist <= 6.0 && b.velY >= 0.0) {
              final contactMin = math.max(bLeft, otherLeft);
              final contactMax = math.min(bLeft + b.width, otherLeft + other.width);
              supports.add({'min': contactMin, 'max': contactMax});
            }
          }
        }
      }

      if (restingOnGround) {
        b.top = groundY - b.height;
        b.velY = 0.0;
        b.velX = 0.0;
        b.velRot = 0.0;
        b.rotation = 0.0;
      } else if (supports.isEmpty) {
        // Fall
        b.velY += 0.45;
        b.top += b.velY;
        b.rotation += b.velRot;
        b.xOffset += b.velX;
      } else {
        // Balanced or falling off
        b.velY = 0.0;
        final center = (b.left + b.xOffset) + b.width / 2.0;

        if (supports.length == 1) {
          final contact = supports[0];
          if (center < contact['min']!) {
            b.velRot -= 0.01; // Radians based rotation torque (smaller delta than degree based 0.6)
            b.velX -= 0.3;
            b.rotation += b.velRot;
            b.xOffset += b.velX;
            b.top += 0.8;
          } else if (center > contact['max']!) {
            b.velRot += 0.01;
            b.velX += 0.3;
            b.rotation += b.velRot;
            b.xOffset += b.velX;
            b.top += 0.8;
          } else {
            b.velX = 0.0;
            b.velRot = 0.0;
            b.rotation = 0.0;
          }
        } else {
          double leftmost = b.left + b.xOffset;
          double rightmost = b.left + b.xOffset + b.width;
          try {
            leftmost = supports.map((s) => s['min']!).reduce(math.min);
            rightmost = supports.map((s) => s['max']!).reduce(math.max);
          } catch (_) {}

          if (center < leftmost) {
            b.velRot -= 0.01;
            b.velX -= 0.3;
            b.rotation += b.velRot;
            b.xOffset += b.velX;
            b.top += 0.8;
          } else if (center > rightmost) {
            b.velRot += 0.01;
            b.velX += 0.3;
            b.rotation += b.velRot;
            b.xOffset += b.velX;
            b.top += 0.8;
          } else {
            b.velX = 0.0;
            b.velRot = 0.0;
            b.rotation = 0.0;
          }
        }
      }
    }

    // 3. Falling blocks squashing targets
    for (final block in blocks) {
      if (block.isDestroyed || (block.velY.abs() < 1.0 && block.velX.abs() < 1.0 && block.velRot.abs() < 0.05)) continue;
      for (final target in targets) {
        if (target.isDestroyed) continue;

        final blockLeft = block.left + block.xOffset;
        final closestX = math.max(blockLeft, math.min(target.pos.x, blockLeft + block.width));
        final closestY = math.max(block.top, math.min(target.pos.y, block.top + block.height));
        final distanceSquared = (target.pos.x - closestX) * (target.pos.x - closestX) + (target.pos.y - closestY) * (target.pos.y - closestY);

        if (distanceSquared < target.radius * target.radius) {
          target.isDestroyed = true;
          score += 200;
          screenShake += 10.0;
          _spawnExplosion(target.pos, const Color(0xFFFF2E93), 20);
        }
      }
    }

    // 4. Update bird flight and collisions
    if (isFlying) {
      birdVel = birdVel + gravity;
      birdPos = birdPos + birdVel;

      // Wall bounds
      if (birdPos.y - birdRadius < 0.0) {
        birdPos = Vector2D(birdPos.x, birdRadius);
        birdVel = Vector2D(birdVel.x, -birdVel.y * bounceFactor);
      }

      // Ground bounce
      if (birdPos.y + birdRadius > groundY) {
        birdPos = Vector2D(birdPos.x, groundY - birdRadius);
        birdVel = Vector2D(birdVel.x * 0.8, -birdVel.y * bounceFactor);

        if (birdVel.y.abs() < 0.6 && birdVel.x.abs() < 0.6) {
          _endFlight();
        }
      }

      // Right/Left bounds
      if (birdPos.x + birdRadius > 1280.0 || birdPos.x - birdRadius < 0.0) {
        _endFlight();
      }

      // Block collisions
      for (final block in blocks) {
        if (block.isDestroyed) continue;

        final blockLeft = block.left + block.xOffset;
        final closestX = math.max(blockLeft, math.min(birdPos.x, blockLeft + block.width));
        final closestY = math.max(block.top, math.min(birdPos.y, block.top + block.height));
        final distanceSquared = (birdPos.x - closestX) * (birdPos.x - closestX) + (birdPos.y - closestY) * (birdPos.y - closestY);

        if (distanceSquared < birdRadius * birdRadius) {
          block.isDestroyed = true;
          score += block.isGlass ? 50 : 100;
          screenShake += 8.0;

          _spawnExplosion(
            Vector2D(blockLeft + block.width / 2.0, block.top + block.height / 2.0),
            block.isGlass ? const Color(0xCC00F5FF) : const Color(0xFFC68B59),
            12,
          );

          final normal = Vector2D(birdPos.x - closestX, birdPos.y - closestY);
          final unitNormal = normal.length() > 0.1 ? normal.normalize() : const Vector2D(0.0, -1.0);

          final dot = birdVel.dot(unitNormal);
          final reflectedVel = birdVel - unitNormal * (2.0 * dot);

          final speedLoss = block.isGlass ? 0.9 : 0.8;
          birdVel = (birdVel * 0.8 + reflectedVel * 0.2) * speedLoss;
        }
      }

      // Target collisions
      for (final target in targets) {
        if (target.isDestroyed) continue;

        final dist = birdPos.distance(target.pos);
        if (dist < birdRadius + target.radius) {
          target.isDestroyed = true;
          score += 200;
          screenShake += 16.0;

          _spawnExplosion(target.pos, const Color(0xFFFF2E93), 25);

          final normal = (birdPos - target.pos).normalize();
          birdVel = normal * (birdVel.length() * 0.8);
        }
      }
    }

    _checkGameStatus();
  }

  void _endFlight() {
    isFlying = false;
    birdPos = slingAnchor;
    birdVel = const Vector2D(0.0, 0.0);
    shotsLeft--;
    if (shotsLeft > 0) {
      gameStateMessage = "Shots remaining: $shotsLeft! Aim carefully!";
    }
  }

  void _checkGameStatus() {
    final allDestroyed = targets.every((t) => t.isDestroyed);
    if (allDestroyed) {
      gameStateMessage = currentLevel < maxLevels
          ? "VICTORY! All targets defeated in Level $currentLevel!"
          : "CONGRATULATIONS! Game completed! Score: $score";
      isFlying = false;
    } else if (shotsLeft <= 0 && !isFlying) {
      gameStateMessage = "GAME OVER! Tap Reset to retry!";
    }
  }

  void _spawnExplosion(Vector2D center, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2.0 * math.pi;
      final speed = 2.0 + _random.nextDouble() * 6.0;
      final vel = Vector2D(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      particles.add(
        PhysicsParticle(
          pos: center,
          vel: vel,
          color: color,
          size: 5.0 + _random.nextDouble() * 10.0,
          maxAge: 20 + _random.nextInt(20),
        ),
      );
    }
  }

  List<Offset> getTrajectoryPoints() {
    final List<Offset> points = [];
    if (!isDragging) return points;

    var tempPos = birdPos;
    final dragOffset = slingAnchor - birdPos;
    var tempVel = dragOffset * 0.85;

    for (int i = 0; i < 120; i++) {
      tempVel = tempVel + gravity;
      tempPos = tempPos + tempVel;

      // Ceiling boundary
      if (tempPos.y - birdRadius < 0.0) {
        tempPos = Vector2D(tempPos.x, birdRadius);
        tempVel = Vector2D(tempVel.x, -tempVel.y * bounceFactor);
      }

      // Ground boundary
      const double groundY = 560.0;
      if (tempPos.y + birdRadius > groundY) {
        tempPos = Vector2D(tempPos.x, groundY - birdRadius);
        points.add(Offset(tempPos.x, tempPos.y));
        break;
      }

      // Left/Right boundaries
      if (tempPos.x + birdRadius > 1280.0 || tempPos.x - birdRadius < 0.0) {
        points.add(Offset(tempPos.x, tempPos.y));
        break;
      }

      points.add(Offset(tempPos.x, tempPos.y));
    }
    return points;
  }
}
