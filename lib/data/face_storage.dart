import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/face_profile.dart';

class FaceStorage {
  final SharedPreferences prefs;
  final Directory facesDir;

  FaceStorage({
    required this.prefs,
    required this.facesDir,
  });

  static Future<FaceStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    final docDir = await getApplicationDocumentsDirectory();
    final facesDir = Directory('${docDir.path}/faces');
    if (!await facesDir.exists()) {
      await facesDir.create(recursive: true);
    }

    final storage = FaceStorage(prefs: prefs, facesDir: facesDir);
    await storage._initDefaults();
    return storage;
  }

  Future<void> _initDefaults() async {
    // Check if profiles already exist
    final jsonStr = prefs.getString('profiles') ?? '[]';
    final List<dynamic> list = json.decode(jsonStr);
    if (list.isEmpty) {
      await _createDefaultProfiles();
    }
  }

  List<FaceProfile> _getRawProfiles() {
    final jsonStr = prefs.getString('profiles') ?? '[]';
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => FaceProfile.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error decoding profiles: $e');
      return [];
    }
  }

  List<FaceProfile> getProfiles() {
    final rawList = _getRawProfiles();
    final custom = rawList.where((p) => !p.isDefault).toList();
    final defaults = rawList.where((p) => p.isDefault).toList();
    // Custom newest first + default profiles
    return custom.reversed.toList() + defaults;
  }

  Future<void> _saveProfiles(List<FaceProfile> profiles) async {
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await prefs.setString('profiles', json.encode(jsonList));
  }

  Future<FaceProfile> addProfile(String name, ui.Image circularImage) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${facesDir.path}/$id.png');

    // Convert image to PNG bytes
    final byteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to get PNG bytes from image');
    }
    final bytes = byteData.buffer.asUint8List();
    await file.writeAsBytes(bytes);

    final newProfile = FaceProfile(
      id: id,
      name: name,
      imagePath: file.path,
      isDefault: false,
    );

    final updatedList = _getRawProfiles()..add(newProfile);
    await _saveProfiles(updatedList);
    return newProfile;
  }

  Future<void> deleteProfile(String id) async {
    final currentProfiles = _getRawProfiles();
    final targetIndex = currentProfiles.indexWhere((p) => p.id == id);
    if (targetIndex != -1) {
      final target = currentProfiles[targetIndex];
      if (!target.isDefault) {
        final file = File(target.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      currentProfiles.removeAt(targetIndex);
      await _saveProfiles(currentProfiles);
    }
  }

  Future<void> _createDefaultProfiles() async {
    final defaults = [
      _DefaultConfig("Hero Red", const Color(0xFFFF4C4C), "angry_bird"),
      _DefaultConfig("Chubby Blue", const Color(0xFF4C8DFF), "blue_bird"),
      _DefaultConfig("Piggy Green", const Color(0xFF5CD65C), "green_pig"),
      _DefaultConfig("Cookie Yellow", const Color(0xFFFFD633), "cookie_monster"),
    ];

    final List<FaceProfile> list = [];

    for (final cfg in defaults) {
      final id = 'default_${cfg.type}';
      final file = File('${facesDir.path}/$id.png');
      
      final image = await _createCartoonFace(cfg.color, cfg.type);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await file.writeAsBytes(bytes);
      }

      list.add(
        FaceProfile(
          id: id,
          name: cfg.name,
          imagePath: file.path,
          isDefault: true,
        ),
      );
    }

    await _saveProfiles(list);
  }

  Future<ui.Image> _createCartoonFace(Color bgColor, String type) async {
    const size = 256.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    const radius = size / 2;

    // 1. Draw main body circle
    paint.color = bgColor;
    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    // 2. Draw facial features
    switch (type) {
      case "angry_bird":
        // Angry eyebrows (black)
        paint.color = Colors.black;
        paint.strokeWidth = 12.0;
        paint.style = PaintingStyle.stroke;
        // Left eyebrow
        canvas.drawLine(const Offset(50, 90), const Offset(120, 115), paint);
        // Right eyebrow
        canvas.drawLine(const Offset(206, 90), const Offset(136, 115), paint);

        // Large white eyes
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(const Offset(90, 130), 25, paint);
        canvas.drawCircle(const Offset(166, 130), 25, paint);

        // Black pupils looking inwards
        paint.color = Colors.black;
        canvas.drawCircle(const Offset(100, 130), 10, paint);
        canvas.drawCircle(const Offset(156, 130), 10, paint);

        // Orange triangle beak
        paint.color = const Color(0xFFFFA500);
        final path = Path()
          ..moveTo(128, 125)
          ..lineTo(100, 165)
          ..lineTo(156, 165)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case "blue_bird":
        // Cute happy eyes
        paint.color = Colors.white;
        canvas.drawCircle(const Offset(85, 120), 22, paint);
        canvas.drawCircle(const Offset(171, 120), 22, paint);

        paint.color = const Color(0xFF1A1A1A);
        canvas.drawCircle(const Offset(85, 120), 8, paint);
        canvas.drawCircle(const Offset(171, 120), 8, paint);

        // Cheeks (blush pink)
        paint.color = const Color(0xFFFF9999);
        canvas.drawCircle(const Offset(55, 155), 15, paint);
        canvas.drawCircle(const Offset(201, 155), 15, paint);

        // Small yellow bill
        paint.color = const Color(0xFFFFCC00);
        final path = Path()
          ..moveTo(128, 120)
          ..lineTo(113, 150)
          ..lineTo(143, 150)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case "green_pig":
        // Pig eyes (black dots with white circles)
        paint.color = Colors.white;
        canvas.drawCircle(const Offset(80, 110), 16, paint);
        canvas.drawCircle(const Offset(176, 110), 16, paint);
        paint.color = Colors.black;
        canvas.drawCircle(const Offset(80, 110), 6, paint);
        canvas.drawCircle(const Offset(176, 110), 6, paint);

        // Huge pig snout (lighter green)
        paint.color = const Color(0xFF8AE68A);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(88, 125, 168, 175),
            const Radius.circular(20),
          ),
          paint,
        );

        // Snout nostrils
        paint.color = const Color(0xFF336633);
        canvas.drawCircle(const Offset(108, 150), 8, paint);
        canvas.drawCircle(const Offset(148, 150), 8, paint);
        break;

      default:
        // "cookie_monster" / happy face
        // Giant goofy eyes
        paint.color = Colors.white;
        canvas.drawCircle(const Offset(100, 95), 28, paint);
        canvas.drawCircle(const Offset(156, 95), 28, paint);

        paint.color = Colors.black;
        canvas.drawCircle(const Offset(95, 95), 10, paint);
        canvas.drawCircle(const Offset(151, 90), 10, paint); // silly misaligned pupil

        // Wide open black mouth
        paint.color = Colors.black;
        canvas.drawArc(
          const Rect.fromLTRB(64, 110, 192, 210),
          0.0,
          math.pi,
          true,
          paint,
        );
        break;
    }

    final picture = recorder.endRecording();
    return picture.toImage(size.toInt(), size.toInt());
  }
}

class _DefaultConfig {
  final String name;
  final Color color;
  final String type;

  _DefaultConfig(this.name, this.color, this.type);
}
