import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';
import '../../models/face_profile.dart';
import '../../data/face_storage.dart';

class FaceManagerScreen extends StatefulWidget {
  final FaceStorage faceStorage;
  final ValueChanged<File> onPhotoSelected;
  final VoidCallback onBackClick;

  const FaceManagerScreen({
    super.key,
    required this.faceStorage,
    required this.onPhotoSelected,
    required this.onBackClick,
  });

  @override
  State<FaceManagerScreen> createState() => _FaceManagerScreenState();
}

class _FaceManagerScreenState extends State<FaceManagerScreen> {
  late List<FaceProfile> _profiles;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profiles = widget.faceStorage.getProfiles();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        widget.onPhotoSelected(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting photo: $e'),
          backgroundColor: neonPink,
        ),
      );
    }
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "SELECT PHOTO SOURCE",
                  style: TextStyle(
                    color: electricCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: icyWhite),
                  title: const Text("Photo Gallery", style: TextStyle(color: icyWhite)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: icyWhite),
                  title: const Text("Camera", style: TextStyle(color: icyWhite)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Family Face Database"),
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
                "Create characters by adding family photos! They will be mapped onto the characters and entities inside all games.",
                style: TextStyle(color: softGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Profiles Grid
              Expanded(
                child: _profiles.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: neonPink))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return _ProfileCard(
                            profile: profile,
                            onDelete: () async {
                              await widget.faceStorage.deleteProfile(profile.id);
                              _loadProfiles();
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Add character button
              ElevatedButton(
                onPressed: _showSourceDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonPink,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ADD NEW CHARACTER",
                  style: TextStyle(
                    fontSize: 16,
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
}

class _ProfileCard extends StatelessWidget {
  final FaceProfile profile;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardSlate.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: profile.isDefault ? electricCyan.withOpacity(0.2) : neonPink.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: profile.isDefault ? electricCyan.withOpacity(0.15) : neonPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  profile.isDefault ? "DEFAULT" : "CUSTOM",
                  style: TextStyle(
                    color: profile.isDefault ? electricCyan : neonPink,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!profile.isDefault)
                IconButton(
                  icon: const Icon(Icons.delete, color: neonPink, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                )
              else
                const SizedBox(height: 24),
            ],
          ),
          
          // Image Avatar
          CircleAvatar(
            radius: 42,
            backgroundColor: profile.isDefault ? electricCyan : neonPink,
            child: CircleAvatar(
              radius: 40.5,
              backgroundImage: FileImage(File(profile.imagePath)),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            profile.name,
            style: const TextStyle(
              color: icyWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
