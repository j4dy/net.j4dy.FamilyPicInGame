package net.j4dy.familypicingame

import android.content.pm.ActivityInfo
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import net.j4dy.familypicingame.games.GameDescriptor
import net.j4dy.familypicingame.games.flappy.FlappyGameScreen
import net.j4dy.familypicingame.games.slingshot.SlingshotGameScreen
import net.j4dy.familypicingame.games.snake.SnakeGameScreen
import net.j4dy.familypicingame.games.whack.WhackGameScreen
import net.j4dy.familypicingame.games.pacman.PacmanGameScreen
import net.j4dy.familypicingame.ui.screens.FaceCropScreen
import net.j4dy.familypicingame.ui.screens.FaceManagerScreen
import net.j4dy.familypicingame.ui.screens.HomeScreen
import net.j4dy.familypicingame.ui.theme.FamilyPicInGameTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // Lock screen to portrait by default on startup
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        setContent {
            FamilyPicInGameTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    
                    // Register available games (easy to extend with more descriptors in the future)
                    val registeredGames = remember {
                        listOf(
                            GameDescriptor(
                                id = "slingshot",
                                title = "Family Slingshot",
                                description = "Launch your family birds with a neon slingshot to crash wood & glass defenses!",
                                route = "game_slingshot"
                            ),
                            GameDescriptor(
                                id = "snake",
                                title = "Family Nibbles",
                                description = "Collect food and watch your family members join the chasing snake body!",
                                route = "game_snake"
                            ),
                            GameDescriptor(
                                id = "flappy",
                                title = "Family Flappy Flight",
                                description = "Steer your family astronaut between neon pillars in space!",
                                route = "game_flappy"
                            ),
                            GameDescriptor(
                                id = "whack",
                                title = "Whack-a-Monster",
                                description = "Tap pop-up alien monsters but avoid tapping your family members!",
                                route = "game_whack"
                            ),
                            GameDescriptor(
                                id = "pacman",
                                title = "Family Pac-Man",
                                description = "Munch neon dots in a retro maze as your favorite family member and escape family ghosts!",
                                route = "game_pacman"
                            )
                        )
                    }

                    NavHost(
                        navController = navController,
                        startDestination = "home"
                    ) {
                        // Home Screen Dashboard
                        composable("home") {
                            HomeScreen(
                                games = registeredGames,
                                onGameSelect = { game ->
                                    navController.navigate(game.route)
                                },
                                onManageFacesSelect = {
                                    navController.navigate("manage_faces")
                                }
                            )
                        }

                        // Face Manager Screen
                        composable("manage_faces") {
                            FaceManagerScreen(
                                onPhotoSelected = { uri ->
                                    // URL encode URI to prevent path parsing bugs in compose navigation
                                    val encodedUri = Uri.encode(uri.toString())
                                    navController.navigate("crop_face/$encodedUri")
                                },
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }

                        // Circular Cropping Screen
                        composable(
                            route = "crop_face/{imageUri}",
                            arguments = listOf(navArgument("imageUri") { type = NavType.StringType })
                        ) { backStackEntry ->
                            val encodedUri = backStackEntry.arguments?.getString("imageUri") ?: ""
                            val decodedUri = Uri.parse(Uri.decode(encodedUri))
                            
                            FaceCropScreen(
                                imageUri = decodedUri,
                                onCropSuccess = {
                                    navController.popBackStack("manage_faces", inclusive = false)
                                },
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }

                        // Slingshot Physics Game Screen
                        composable("game_slingshot") {
                            SlingshotGameScreen(
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }

                        // Snake/Nibbles Game Screen
                        composable("game_snake") {
                            SnakeGameScreen(
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }

                        // Flappy Flight Game Screen
                        composable("game_flappy") {
                            FlappyGameScreen(
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }

                        // Whack-a-Monster Game Screen
                        composable("game_whack") {
                            WhackGameScreen(
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }
                        
                        // Pac-Man Game Screen
                        composable("game_pacman") {
                            PacmanGameScreen(
                                onBackClick = {
                                    navController.popBackStack()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}
