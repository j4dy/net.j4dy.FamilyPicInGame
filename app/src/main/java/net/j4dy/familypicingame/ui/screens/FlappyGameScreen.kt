package net.j4dy.familypicingame.games.flappy

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import net.j4dy.familypicingame.data.FaceStorage
import net.j4dy.familypicingame.games.slingshot.RoleAvatarItem
import net.j4dy.familypicingame.model.FaceProfile
import net.j4dy.familypicingame.ui.theme.CardSlate
import net.j4dy.familypicingame.ui.theme.CyberPurple
import net.j4dy.familypicingame.ui.theme.DeepDarkBlue
import net.j4dy.familypicingame.ui.theme.ElectricCyan
import net.j4dy.familypicingame.ui.theme.IcyWhite
import net.j4dy.familypicingame.ui.theme.NeonPink
import net.j4dy.familypicingame.ui.theme.SoftGrey
import kotlinx.coroutines.delay
import java.io.File
import kotlin.random.Random

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FlappyGameScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    val profiles = remember { faceStorage.getProfiles() }
    
    var selectedPilot by remember { mutableStateOf<FaceProfile?>(null) }
    var selectedDifficulty by remember { mutableStateOf(FlappyDifficulty.HARD) }
    var gameStarted by remember { mutableStateOf(false) }

    if (!gameStarted) {
        // Avatar Selection Screen
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Setup Flappy Flight", fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = onBackClick) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = IcyWhite)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = DeepDarkBlue)
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(DeepDarkBlue)
                    .padding(24.dp),
                verticalArrangement = Arrangement.SpaceBetween,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        "ASSIGN GAME PILOT",
                        color = ElectricCyan,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 24.dp)
                    )

                    Text(
                        "Select who will pilot the space capsule:",
                        color = IcyWhite,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.align(Alignment.Start)
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedPilot?.id == profile.id,
                                color = ElectricCyan,
                                onClick = { selectedPilot = profile }
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(28.dp))
                    
                    Text(
                        "Select Mission Difficulty (Gap size):",
                        color = IcyWhite,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.align(Alignment.Start)
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FlappyDifficulty.values().forEach { diff ->
                            val isSelected = selectedDifficulty == diff
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(44.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(if (isSelected) NeonPink else CardSlate.copy(alpha = 0.5f))
                                    .border(
                                        width = 1.dp,
                                        color = if (isSelected) ElectricCyan else SoftGrey.copy(alpha = 0.3f),
                                        shape = RoundedCornerShape(8.dp)
                                    )
                                    .clickable { selectedDifficulty = diff },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = diff.displayName,
                                    color = if (isSelected) Color.White else SoftGrey,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        if (selectedPilot != null) {
                            gameStarted = true
                        }
                    },
                    enabled = selectedPilot != null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = NeonPink,
                        disabledContainerColor = SoftGrey.copy(alpha = 0.3f),
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("LAUNCH MISSION", fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
            }
        }
    } else {
        // Main Game loop and Screen
        val gameState = remember(selectedPilot, selectedDifficulty) {
            FlappyGameState(selectedPilot!!, selectedDifficulty)
        }
        var canvasSize by remember { mutableStateOf(Size.Zero) }

        // Tick loop (16ms = ~60fps)
        LaunchedEffect(gameState, gameState.isPlaying, gameState.isGameOver) {
            if (gameState.isPlaying && !gameState.isGameOver) {
                while (true) {
                    gameState.tick(canvasSize.width, canvasSize.height)
                    delay(16)
                }
            }
        }

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Family Flappy Flight", fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = { gameStarted = false }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = IcyWhite)
                        }
                    },
                    actions = {
                        IconButton(onClick = { gameState.resetGame() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Reset", tint = ElectricCyan)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = DeepDarkBlue)
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(DeepDarkBlue)
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                // Game Canvas with Tap Listener
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .border(1.dp, CyberPurple.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
                        .background(Color(0xFF090D1E))
                        .onSizeChanged { size ->
                            canvasSize = Size(size.width.toFloat(), size.height.toFloat())
                        }
                        .pointerInput(gameState) {
                            detectTapGestures(
                                onTap = {
                                    gameState.flap()
                                }
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    FlappyGameCanvas(state = gameState, modifier = Modifier.fillMaxSize())
                    
                    // Tap overlay indicator if not playing
                    if (!gameState.isPlaying && !gameState.isGameOver) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(alpha = 0.35f))
                        ) {
                            Text(
                                "TAP ANYWHERE TO JUMP",
                                color = ElectricCyan,
                                fontSize = 20.sp,
                                fontWeight = FontWeight.Black,
                                letterSpacing = 2.sp
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                "Avoid the glowing neon pillars",
                                color = SoftGrey,
                                fontSize = 14.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Score HUD card
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, CyberPurple.copy(alpha = 0.2f), RoundedCornerShape(20.dp)),
                    colors = CardDefaults.cardColors(containerColor = CardSlate.copy(alpha = 0.9f)),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Score: ${gameState.score}", color = ElectricCyan, fontWeight = FontWeight.Black, fontSize = 20.sp)
                            Text("${gameState.gameMessage} • ${gameState.difficulty.displayName}", color = IcyWhite, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        }
                        
                        if (gameState.isGameOver) {
                            Button(
                                onClick = { gameState.startGame() },
                                colors = ButtonDefaults.buttonColors(containerColor = NeonPink),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = "Retry", tint = Color.White)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("RETRY", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun FlappyGameCanvas(
    state: FlappyGameState,
    modifier: Modifier = Modifier
) {
    // Load astronaut head bitmap
    val pilotBitmap = remember(state.playerProfile.imagePath) {
        try { android.graphics.BitmapFactory.decodeFile(state.playerProfile.imagePath) } catch (e: Exception) { null }
    }
    
    // Maintain scrolling stars for background space aesthetic
    val stars = remember {
        List(25) {
            Offset(Random.nextFloat(), Random.nextFloat())
        }
    }

    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        
        // 1. Draw Space background stars
        stars.forEachIndexed { i, starOffset ->
            // Scroll stars slower for parallax
            val starX = ((starOffset.x * w) - (if (state.isPlaying) (state.score * 50 + (System.currentTimeMillis() / 40) % w.toInt()) else 0)) % w
            val normalizedStarX = if (starX < 0) starX + w else starX
            val starY = starOffset.y * h
            
            drawCircle(
                color = if (i % 2 == 0) ElectricCyan.copy(alpha = 0.5f) else NeonPink.copy(alpha = 0.4f),
                radius = if (i % 3 == 0) 3f else 1.5f,
                center = Offset(normalizedStarX.toFloat(), starY)
            )
        }

        // 2. Draw Pipes (Obstacles)
        state.pipes.forEach { pipe ->
            // Top Pipe
            drawRoundRect(
                brush = Brush.verticalGradient(
                    colors = listOf(CyberPurple, CyberPurple.copy(alpha = 0.6f))
                ),
                topLeft = Offset(pipe.x, 0f),
                size = Size(pipe.width, pipe.topHeight),
                cornerRadius = CornerRadius(8f, 8f)
            )
            // Top Pipe glowing lip
            drawRoundRect(
                color = ElectricCyan,
                topLeft = Offset(pipe.x - 4f, pipe.topHeight - 30f),
                size = Size(pipe.width + 8f, 30f),
                cornerRadius = CornerRadius(4f, 4f),
                style = Stroke(width = 2.dp.toPx())
            )

            // Bottom Pipe
            drawRoundRect(
                brush = Brush.verticalGradient(
                    colors = listOf(CyberPurple.copy(alpha = 0.6f), CyberPurple)
                ),
                topLeft = Offset(pipe.x, h - pipe.bottomHeight),
                size = Size(pipe.width, pipe.bottomHeight),
                cornerRadius = CornerRadius(8f, 8f)
            )
            // Bottom Pipe glowing lip
            drawRoundRect(
                color = ElectricCyan,
                topLeft = Offset(pipe.x - 4f, h - pipe.bottomHeight),
                size = Size(pipe.width + 8f, 30f),
                cornerRadius = CornerRadius(4f, 4f),
                style = Stroke(width = 2.dp.toPx())
            )
        }

        // 3. Draw Player Astronaut
        val pX = w * 0.25f
        val pY = state.birdY
        val faceRadius = 35f
        val center = Offset(pX, pY)
        
        if (pilotBitmap != null) {
            val image = pilotBitmap.asImageBitmap()
            drawContext.canvas.save()
            
            // Draw astronaut capsule backpack
            drawRoundRect(
                brush = Brush.horizontalGradient(listOf(CyberPurple, ElectricCyan)),
                topLeft = Offset(pX - 60f, pY - 25f),
                size = Size(20f, 50f),
                cornerRadius = CornerRadius(6f, 6f)
            )
            // Draw connector pipe
            drawLine(
                color = NeonPink,
                start = Offset(pX - 40f, pY),
                end = Offset(pX - 25f, pY),
                strokeWidth = 4f
            )

            // Clip & draw family head
            val clipPath = Path().apply {
                addOval(Rect(pX - faceRadius, pY - faceRadius, pX + faceRadius, pY + faceRadius))
            }
            clipPath(clipPath) {
                drawImage(
                    image = image,
                    dstOffset = IntOffset((pX - faceRadius).toInt(), (pY - faceRadius).toInt()),
                    dstSize = IntSize((faceRadius * 2).toInt(), (faceRadius * 2).toInt())
                )
            }
            drawContext.canvas.restore()
            
            // Draw Astronaut Helmet Glass Visor
            drawCircle(
                color = ElectricCyan.copy(alpha = 0.25f),
                radius = faceRadius + 7f,
                center = center
            )
            drawCircle(
                color = ElectricCyan,
                radius = faceRadius + 7f,
                center = center,
                style = Stroke(width = 2.dp.toPx())
            )
            // Visor shine highlight reflection
            drawArc(
                color = Color.White.copy(alpha = 0.5f),
                startAngle = -120f,
                sweepAngle = 60f,
                useCenter = false,
                topLeft = Offset(pX - faceRadius - 4f, pY - faceRadius - 4f),
                size = Size((faceRadius + 4f) * 2, (faceRadius + 4f) * 2),
                style = Stroke(width = 2f)
            )
        } else {
            // Fallback space pod
            drawCircle(color = ElectricCyan, radius = faceRadius, center = center)
        }
    }
}
