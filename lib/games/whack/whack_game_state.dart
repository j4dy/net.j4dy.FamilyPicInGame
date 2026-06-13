import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/face_profile.dart';

enum PortalType { empty, teamA, teamB }

class PortalState {
  final int index;
  PortalType type;
  FaceProfile? familyProfile;
  int showTimeLeft; // frames it stays visible

  PortalState({
    required this.index,
    this.type = PortalType.empty,
    this.familyProfile,
    this.showTimeLeft = 0,
  });
}

class WhackSparkle {
  final int index;
  final Offset offset;
  final String text;
  final bool isPenalty;
  double alpha;

  WhackSparkle({
    required this.index,
    required this.offset,
    required this.text,
    required this.isPenalty,
    this.alpha = 1.0,
  });
}

class WhackGameState {
  final List<FaceProfile> teamAProfiles;
  final List<FaceProfile> teamBProfiles;
  final double speedMultiplier;

  final List<PortalState> portals = List.generate(12, (i) => PortalState(index: i));
  final List<WhackSparkle> sparkles = [];

  int score = 0;
  int comboMultiplier = 1;
  int timeLeftSeconds = 45;

  bool isPlaying = false;
  bool isGameOver = false;
  String gameMessage = "TAP START TO PLAY";

  final int defaultRoundTime = 45;
  int _framesSinceLastSpawn = 0;

  final _random = math.Random();

  WhackGameState({
    required this.teamAProfiles,
    required this.teamBProfiles,
    this.speedMultiplier = 2.0,
  });

  int _getSpawnInterval() {
    int baseInterval;
    if (score > 5000) {
      baseInterval = 30; // ~500ms
    } else if (score > 3000) {
      baseInterval = 40;
    } else if (score > 1000) {
      baseInterval = 50;
    } else {
      baseInterval = 60; // ~1s
    }
    return (baseInterval / speedMultiplier).round().clamp(10, 100);
  }

  int _getPortalDuration() {
    int baseDuration;
    if (score > 5000) {
      baseDuration = 45; // ~750ms
    } else if (score > 3000) {
      baseDuration = 60;
    } else if (score > 1000) {
      baseDuration = 75;
    } else {
      baseDuration = 90; // ~1.5s
    }
    return (baseDuration / speedMultiplier).round().clamp(15, 120);
  }

  void startGame() {
    isPlaying = true;
    isGameOver = false;
    score = 0;
    comboMultiplier = 1;
    timeLeftSeconds = defaultRoundTime;
    sparkles.clear();
    _framesSinceLastSpawn = 0;
    for (final p in portals) {
      p.type = PortalType.empty;
      p.familyProfile = null;
      p.showTimeLeft = 0;
    }
    gameMessage = "Go Team! Speed: ${speedMultiplier}x!";
  }

  void resetGame() {
    isPlaying = false;
    isGameOver = false;
    score = 0;
    comboMultiplier = 1;
    timeLeftSeconds = defaultRoundTime;
    sparkles.clear();
    for (final p in portals) {
      p.type = PortalType.empty;
      p.familyProfile = null;
      p.showTimeLeft = 0;
    }
    gameMessage = "TAP START TO PLAY";
  }

  void tickSecond() {
    if (!isPlaying || isGameOver) return;
    timeLeftSeconds--;
    if (timeLeftSeconds <= 0) {
      _endGame();
    }
  }

  void tickFrame() {
    if (!isPlaying || isGameOver) return;

    // 1. Tick existing portal durations
    for (final portal in portals) {
      if (portal.type != PortalType.empty) {
        portal.showTimeLeft--;
        if (portal.showTimeLeft <= 0) {
          portal.type = PortalType.empty;
          portal.familyProfile = null;
        }
      }
    }

    // 2. Spawn new characters
    _framesSinceLastSpawn++;
    if (_framesSinceLastSpawn >= _getSpawnInterval()) {
      _framesSinceLastSpawn = 0;
      _spawnRandomPortal();
    }

    // 3. Tick sparkles alpha decay
    for (int i = sparkles.length - 1; i >= 0; i--) {
      sparkles[i].alpha -= 0.05;
      if (sparkles[i].alpha <= 0.0) {
        sparkles.removeAt(i);
      }
    }
  }

  void _spawnRandomPortal() {
    final emptyPortals = portals.where((p) => p.type == PortalType.empty).toList();
    if (emptyPortals.isEmpty) return;

    final portal = emptyPortals[_random.nextInt(emptyPortals.length)];
    final isTeamA = _random.nextDouble() < 0.50;

    if (isTeamA && teamAProfiles.isNotEmpty) {
      portal.type = PortalType.teamA;
      portal.familyProfile = teamAProfiles[_random.nextInt(teamAProfiles.length)];
    } else if (teamBProfiles.isNotEmpty) {
      portal.type = PortalType.teamB;
      portal.familyProfile = teamBProfiles[_random.nextInt(teamBProfiles.length)];
    } else {
      portal.type = PortalType.empty;
      portal.familyProfile = null;
    }

    if (portal.type != PortalType.empty) {
      portal.showTimeLeft = _getPortalDuration();
    }
  }

  void whackCell(int index) {
    if (!isPlaying || isGameOver || index < 0 || index >= 12) return;

    final portal = portals[index];
    switch (portal.type) {
      case PortalType.teamB:
        final points = 100 * comboMultiplier;
        score += points;
        comboMultiplier++;
        final name = portal.familyProfile?.name ?? "Opponent";
        sparkles.add(
          WhackSparkle(
            index: index,
            offset: Offset(_random.nextDouble() * 40 - 20, -50.0),
            text: "+$points",
            isPenalty: false,
          ),
        );
        gameMessage = "WHACKED $name! Combo x$comboMultiplier";
        portal.type = PortalType.empty;
        portal.familyProfile = null;
        break;

      case PortalType.teamA:
        const penalty = 200;
        score = (score - penalty).clamp(0, 999999);
        comboMultiplier = 1;
        final name = portal.familyProfile?.name ?? "Teammate";
        sparkles.add(
          WhackSparkle(
            index: index,
            offset: Offset(_random.nextDouble() * 40 - 20, -50.0),
            text: "Don't tap teammate $name! -$penalty",
            isPenalty: true,
          ),
        );
        gameMessage = "OW! That's teammate $name!";
        portal.type = PortalType.empty;
        portal.familyProfile = null;
        break;

      case PortalType.empty:
        comboMultiplier = 1;
        gameMessage = "MISS!";
        break;
    }
  }

  void _endGame() {
    isGameOver = true;
    isPlaying = false;
    gameMessage = "TIME'S UP! Game Over!";
  }
}
