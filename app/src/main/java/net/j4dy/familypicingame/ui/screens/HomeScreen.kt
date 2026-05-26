package net.j4dy.familypicingame.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Face
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import net.j4dy.familypicingame.data.FaceStorage
import net.j4dy.familypicingame.games.GameDescriptor
import net.j4dy.familypicingame.ui.theme.CardSlate
import net.j4dy.familypicingame.ui.theme.CyberPurple
import net.j4dy.familypicingame.ui.theme.DeepDarkBlue
import net.j4dy.familypicingame.ui.theme.ElectricCyan
import net.j4dy.familypicingame.ui.theme.IcyWhite
import net.j4dy.familypicingame.ui.theme.NeonPink
import net.j4dy.familypicingame.ui.theme.SoftGrey
import kotlinx.coroutines.delay

@Composable
fun HomeScreen(
    games: List<GameDescriptor>,
    onGameSelect: (GameDescriptor) -> Unit,
    onManageFacesSelect: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    var faceCount by remember { mutableStateOf(faceStorage.getProfiles().size) }

    // Update count when navigating back
    LaunchedEffect(Unit) {
        faceCount = faceStorage.getProfiles().size
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DeepDarkBlue)
    ) {
        // 1. Beautiful animated cosmic grid / floating particles background
        AnimatedParticleBackground()

        // 2. Main content container
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(top = 16.dp)
            ) {
                Text(
                    text = "FAMILY",
                    style = MaterialTheme.typography.labelMedium.copy(
                        fontSize = 14.sp,
                        letterSpacing = 6.sp,
                        color = ElectricCyan
                    ),
                    fontWeight = FontWeight.Black
                )
                Text(
                    text = "Pic-In-Game",
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontSize = 38.sp,
                        lineHeight = 44.sp,
                        fontWeight = FontWeight.Black,
                        brush = Brush.linearGradient(
                            colors = listOf(NeonPink, CyberPurple, ElectricCyan)
                        )
                    )
                )
                Text(
                    text = "Play classic games with family face characters!",
                    style = MaterialTheme.typography.bodyMedium,
                    color = SoftGrey,
                    modifier = Modifier.padding(top = 8.dp),
                    textAlign = TextAlign.Center
                )
            }

            // Games Container
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(vertical = 32.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "SELECT MISSION",
                    color = SoftGrey.copy(alpha = 0.8f),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                    textAlign = TextAlign.Start
                )

                games.forEach { game ->
                    GameCard(
                        game = game,
                        onClick = { onGameSelect(game) }
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }

            // Footer Manager card (Glassmorphic)
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(90.dp)
                    .border(
                        width = 1.dp,
                        brush = Brush.linearGradient(
                            colors = listOf(ElectricCyan.copy(alpha = 0.5f), Color.Transparent)
                        ),
                        shape = RoundedCornerShape(20.dp)
                    )
                    .clickable { onManageFacesSelect() },
                colors = CardDefaults.cardColors(
                    containerColor = CardSlate.copy(alpha = 0.7f)
                ),
                shape = RoundedCornerShape(20.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 20.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(50.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(NeonPink.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Face,
                                contentDescription = "Faces",
                                tint = NeonPink,
                                modifier = Modifier.size(30.dp)
                            )
                        }
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        Column {
                            Text(
                                text = "Family Faces",
                                fontWeight = FontWeight.Bold,
                                color = IcyWhite,
                                fontSize = 16.sp
                            )
                            Text(
                                text = "$faceCount Characters Ready",
                                color = SoftGrey,
                                fontSize = 13.sp
                            )
                        }
                    }
                    
                    Text(
                        text = "MANAGE",
                        color = ElectricCyan,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }
        }
    }
}

@Composable
fun GameCard(
    game: GameDescriptor,
    onClick: () -> Unit
) {
    val isSlingshot = game.id == "slingshot"
    val borderGradient = Brush.linearGradient(
        colors = if (isSlingshot) {
            listOf(NeonPink, CyberPurple.copy(alpha = 0.2f))
        } else {
            listOf(ElectricCyan, CyberPurple.copy(alpha = 0.2f))
        }
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(110.dp)
            .border(width = 1.dp, brush = borderGradient, shape = RoundedCornerShape(24.dp))
            .clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = CardSlate.copy(alpha = 0.6f)),
        shape = RoundedCornerShape(24.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = game.title,
                        fontWeight = FontWeight.Black,
                        fontSize = 20.sp,
                        color = IcyWhite
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isSlingshot) "PHYSICS" else "ARCADE",
                        color = if (isSlingshot) NeonPink else ElectricCyan,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .background(
                                if (isSlingshot) NeonPink.copy(alpha = 0.15f) else ElectricCyan.copy(alpha = 0.15f),
                                RoundedCornerShape(4.dp)
                            )
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = game.description,
                    color = SoftGrey,
                    fontSize = 13.sp,
                    maxLines = 2
                )
            }
            
            // Visual launcher indicator arrow
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(TranslucentWhite),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "▶",
                    color = IcyWhite,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

private val TranslucentWhite = Color(0x10FFFFFF)

/**
 * Animated Particle Canvas background for a highly premium, futuristic, and responsive feel.
 */
@Composable
fun AnimatedParticleBackground() {
    val infiniteTransition = rememberInfiniteTransition()
    
    // Slow continuous cycle
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(40000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        )
    )

    val scaleState by infiniteTransition.animateFloat(
        initialValue = 0.9f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(8000, easing = SineIntensityEasing),
            repeatMode = RepeatMode.Reverse
        )
    )

    Canvas(modifier = Modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height
        
        // Draw cosmic glow spheres
        // Sphere 1: Magenta glow top left
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(NeonPink.copy(alpha = 0.15f * scaleState), Color.Transparent),
                center = Offset(w * 0.1f, h * 0.2f),
                radius = w * 0.7f
            ),
            radius = w * 0.7f,
            center = Offset(w * 0.1f, h * 0.2f)
        )

        // Sphere 2: Cyan glow bottom right
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(ElectricCyan.copy(alpha = 0.12f * scaleState), Color.Transparent),
                center = Offset(w * 0.9f, h * 0.8f),
                radius = w * 0.8f
            ),
            radius = w * 0.8f,
            center = Offset(w * 0.9f, h * 0.8f)
        )
    }
}

private val SineIntensityEasing = Easing { fraction ->
    Math.sin(fraction * Math.PI).toFloat()
}
