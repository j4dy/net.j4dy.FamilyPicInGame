package net.j4dy.familypicingame

import android.content.pm.ActivityInfo
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import net.j4dy.familypicingame.games.GameDescriptor
import net.j4dy.familypicingame.games.slingshot.SlingshotGameScreen
import net.j4dy.familypicingame.games.snake.SnakeGameScreen
import net.j4dy.familypicingame.ui.screens.FaceCropScreen
import net.j4dy.familypicingame.ui.screens.FaceManagerScreen
import net.j4dy.familypicingame.ui.screens.HomeScreen
import net.j4dy.familypicingame.ui.theme.FamilyPicInGameTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
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
                    }
                }
            }
        }
    }
}
