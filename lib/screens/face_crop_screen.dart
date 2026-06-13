import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../data/face_storage.dart';

class FaceCropScreen extends StatefulWidget {
  final File imageFile;
  final FaceStorage faceStorage;
  final VoidCallback onCropSuccess;
  final VoidCallback onBackClick;

  const FaceCropScreen({
    super.key,
    required this.imageFile,
    required this.faceStorage,
    required this.onCropSuccess,
    required this.onBackClick,
  });

  @override
  State<FaceCropScreen> createState() => _FaceCropScreenState();
}

class _HomeScreenState {}

class _FaceCropScreenState extends State<FaceCropScreen> {
  ui.Image? _uiImage;
  bool _loadingError = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  bool _showError = false;

  // Touch transform states
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;

  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      // Downsample image to max width of 1024 to prevent memory issues
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1024);
      final frame = await codec.getNextFrame();
      setState(() {
        _uiImage = frame.image;
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      setState(() {
        _loadingError = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCrop() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _showError = true;
      });
      return;
    }

    final img = _uiImage;
    if (img == null || _canvasSize == Size.zero) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final croppedImage = await _cropImageNatively(
        img,
        _scale,
        _offset,
        _canvasSize.width,
        _canvasSize.height,
      );

      await widget.faceStorage.addProfile(name, croppedImage);
      widget.onCropSuccess();
    } catch (e) {
      debugPrint('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving cropped head: $e'),
          backgroundColor: neonPink,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<ui.Image> _cropImageNatively(
    ui.Image src,
    double gestureScale,
    Offset gestureOffset,
    double canvasWidth,
    double canvasHeight,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double size = 256.0;
    final double widthVal = canvasWidth > 0 ? canvasWidth : 800.0;
    final double heightVal = canvasHeight > 0 ? canvasHeight : 800.0;

    final double circleRadius = math.min(widthVal, heightVal) * 0.35;
    final double centerX = widthVal / 2.0;
    final double centerY = heightVal / 2.0;

    final double imgWidth = src.width.toDouble();
    final double imgHeight = src.height.toDouble();

    // Replicate layout scale calculations
    final double baseScale = math.min(widthVal / imgWidth, heightVal / imgHeight);
    final double finalScale = baseScale * gestureScale;

    final double drawWidth = imgWidth * finalScale;
    final double drawHeight = imgHeight * finalScale;

    // Center coordinates
    final double startX = (widthVal - drawWidth) / 2.0 + gestureOffset.dx;
    final double startY = (heightVal - drawHeight) / 2.0 + gestureOffset.dy;

    // 1. Clip to a circular crop path in 256x256 dimensions
    final clipPath = Path()..addOval(const Rect.fromLTRB(0, 0, size, size));
    canvas.clipPath(clipPath);

    // 2. Perform matrix transform matching preview layout
    canvas.translate(128.0, 128.0);
    canvas.scale(128.0 / circleRadius);
    canvas.translate(startX - centerX, startY - centerY);
    canvas.scale(finalScale);

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImage(src, Offset.zero, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(256, 256);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingError) {
      return Scaffold(
        appBar: AppBar(title: const Text("Crop Character Head")),
        body: const Center(
          child: Text(
            "Failed to load image. Please try another.",
            style: TextStyle(color: neonPink),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_uiImage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Crop Character Head")),
        body: const Center(
          child: CircularProgressIndicator(color: neonPink),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Character Head"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackClick,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "Pinch to zoom and drag to position family member's head inside the circle.",
                style: TextStyle(color: softGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // The Crop Canvas
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: const Color(0xFF0F1424),
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
                          onScaleStart: (details) {
                            _baseScale = _scale;
                            _baseOffset = _offset;
                          },
                          onScaleUpdate: (details) {
                            setState(() {
                              _scale = (_baseScale * details.scale).clamp(0.5, 5.0);
                              _offset = _baseOffset + details.focalPointDelta;
                            });
                          },
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _CropPreviewPainter(
                              image: _uiImage!,
                              scale: _scale,
                              offset: _offset,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name Input field
              TextField(
                controller: _nameController,
                onChanged: (text) {
                  if (_showError) {
                    setState(() {
                      _showError = false;
                    });
                  }
                },
                style: const TextStyle(color: icyWhite),
                decoration: InputDecoration(
                  labelText: "Family Member Name (e.g., Dad, Mom)",
                  labelStyle: const TextStyle(color: softGrey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: electricCyan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cyberPurple),
                  ),
                  errorText: _showError ? "Please enter a valid name." : null,
                  errorStyle: const TextStyle(color: neonPink),
                ),
              ),

              const SizedBox(height: 16),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCrop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonPink,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE CHARACTER FACE",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropPreviewPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;

  _CropPreviewPainter({
    required this.image,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = size.width;
    final canvasHeight = size.height;
    final circleRadius = math.min(canvasWidth, canvasHeight) * 0.35;
    final center = Offset(canvasWidth / 2.0, canvasHeight / 2.0);

    // 1. Draw image with scale and offset centered
    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();

    final baseScale = math.min(canvasWidth / imgWidth, canvasHeight / imgHeight);
    final finalScale = baseScale * scale;

    final drawWidth = imgWidth * finalScale;
    final drawHeight = imgHeight * finalScale;

    final startX = (canvasWidth - drawWidth) / 2.0 + offset.dx;
    final startY = (canvasHeight - drawHeight) / 2.0 + offset.dy;

    canvas.save();
    canvas.translate(startX, startY);
    canvas.scale(finalScale);

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();

    // 2. Draw glass overlay with circular hole
    final path = Path()..addRect(Rect.fromLTRB(0, 0, canvasWidth, canvasHeight));
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: circleRadius));

    // Subtract circle from rect (Difference)
    final differencePath = Path.combine(
      PathOperation.difference,
      path,
      circlePath,
    );

    final overlayPaint = Paint()
      ..color = const Color(0xAA0A0E17)
      ..style = PaintingStyle.fill;
    canvas.drawPath(differencePath, overlayPaint);

    // Draw neon border circle helper
    final borderPaint = Paint()
      ..color = electricCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, circleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropPreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
