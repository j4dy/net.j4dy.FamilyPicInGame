import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'models/game_descriptor.dart';
import 'data/face_storage.dart';
import 'screens/home_screen.dart';
import 'screens/face_manager_screen.dart';
import 'screens/face_crop_screen.dart';
import 'screens/games/slingshot_game.dart';
import 'screens/games/snake_game.dart';
import 'screens/games/flappy_game.dart';
import 'screens/games/whack_game.dart';
import 'screens/games/pacman_game.dart';
import 'screens/games/connect4_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set custom error widget to show crash logs on screen in all modes
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApplicationErrorScreen(details: details);
  };

  // Set preferred orientations initially to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MaterialApplicationErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const MaterialApplicationErrorScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1A0000),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🔴 APP CRASH DETECTED",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exception.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.stack.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFFAAAA),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Pic-In-Game',
      theme: getCyberTheme(),
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum AppScreen {
  loading,
  home,
  faceManager,
  faceCrop,
  gameSlingshot,
  gameSnake,
  gameFlappy,
  gameWhack,
  gamePacman,
  gameConnect4
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  AppScreen _currentScreen = AppScreen.loading;
  FaceStorage? _faceStorage;
  File? _selectedPhotoFile;

  final List<GameDescriptor> _gamesList = const [
    GameDescriptor(
      id: 'connect4',
      title: 'Family Connect 4',
      description: 'Drop your family face tokens into the grid. First to line up 4 in a row wins!',
      route: 'connect4_game',
    ),
    GameDescriptor(
      id: 'slingshot',
      title: 'Family Slingshot',
      description: 'Aim and launch your family characters to knock down block fortresses and squash targets!',
      route: 'slingshot_game',
    ),
    GameDescriptor(
      id: 'snake',
      title: 'Family Nibbles (Snake)',
      description: 'Guide the snake to eat food. Watch the tail grow with segments of family faces!',
      route: 'snake_game',
    ),
    GameDescriptor(
      id: 'flappy',
      title: 'Family Flappy Flight',
      description: 'Fly through energy pillars with spaceship helmet character faces!',
      route: 'flappy_game',
    ),
    GameDescriptor(
      id: 'whack',
      title: 'Whack-a-Monster',
      description: 'Whack the opponent team characters popping from cylinders, but avoid whacking your own team!',
      route: 'whack_game',
    ),
    GameDescriptor(
      id: 'pacman',
      title: 'Family Pac-Man',
      description: 'Chomp pellets around the maze as a family face, and run away from or eat the ghost family faces!',
      route: 'pacman_game',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final storage = await FaceStorage.create();
      setState(() {
        _faceStorage = storage;
        _currentScreen = AppScreen.home;
      });
    } catch (e, stack) {
      debugPrint('Error initializing app: $e');
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: stack,
        library: 'app initialization',
        context: ErrorDescription('while initializing FaceStorage'),
      ));
    }
  }

  void _navigateToScreen(AppScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _onGameSelect(GameDescriptor game) {
    switch (game.id) {
      case 'slingshot':
        _navigateToScreen(AppScreen.gameSlingshot);
        break;
      case 'snake':
        _navigateToScreen(AppScreen.gameSnake);
        break;
      case 'flappy':
        _navigateToScreen(AppScreen.gameFlappy);
        break;
      case 'whack':
        _navigateToScreen(AppScreen.gameWhack);
        break;
      case 'pacman':
        _navigateToScreen(AppScreen.gamePacman);
        break;
      case 'connect4':
        _navigateToScreen(AppScreen.gameConnect4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == AppScreen.loading || _faceStorage == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "FAMILY PIC-IN-GAME",
                style: TextStyle(
                  color: electricCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: neonPink),
            ],
          ),
        ),
      );
    }

    switch (_currentScreen) {
      case AppScreen.home:
        return HomeScreen(
          games: _gamesList,
          onGameSelect: _onGameSelect,
          onManageFacesSelect: () => _navigateToScreen(AppScreen.faceManager),
          faceStorage: _faceStorage!,
        );

      case AppScreen.faceManager:
        return FaceManagerScreen(
          faceStorage: _faceStorage!,
          onPhotoSelected: (file) {
            setState(() {
              _selectedPhotoFile = file;
              _currentScreen = AppScreen.faceCrop;
            });
          },
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.faceCrop:
        if (_selectedPhotoFile == null) {
          return const Scaffold(body: Center(child: Text("No photo selected.")));
        }
        return FaceCropScreen(
          imageFile: _selectedPhotoFile!,
          faceStorage: _faceStorage!,
          onCropSuccess: () {
            setState(() {
              _selectedPhotoFile = null;
              _currentScreen = AppScreen.faceManager;
            });
          },
          onBackClick: () {
            setState(() {
              _selectedPhotoFile = null;
              _currentScreen = AppScreen.faceManager;
            });
          },
        );

      case AppScreen.gameSlingshot:
        return SlingshotGameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.gameSnake:
        return SnakeGameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.gameFlappy:
        return FlappyGameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.gameWhack:
        return WhackGameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.gamePacman:
        return PacmanGameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      case AppScreen.gameConnect4:
        return Connect4GameScreen(
          faceStorage: _faceStorage!,
          onBackClick: () => _navigateToScreen(AppScreen.home),
        );

      default:
        return HomeScreen(
          games: _gamesList,
          onGameSelect: _onGameSelect,
          onManageFacesSelect: () => _navigateToScreen(AppScreen.faceManager),
          faceStorage: _faceStorage!,
        );
    }
  }
}
