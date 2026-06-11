package net.j4dy.familypicingame.games.pacman

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.nativeCanvas
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
import kotlin.math.abs
import kotlin.math.sin

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PacmanGameScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    val profiles = remember { faceStorage.getProfiles() }

    var selectedPlayer by remember { mutableStateOf<FaceProfile?>(null) }
    var selectedGhosts by remember { mutableStateOf(setOf<String>()) }
    var gameStarted by remember { mutableStateOf(false) }

    if (!gameStarted) {
        // Selection Screen
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Setup Family Pac-Man", fontWeight = FontWeight.Bold) },
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
                        "CHOOSE ROLES",
                        color = ElectricCyan,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 24.dp)
                    )

                    // Pacman Selector
                    Text("Select Pac-Man (Player):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedPlayer?.id == profile.id,
                                color = ElectricCyan,
                                onClick = {
                                    selectedPlayer = profile
                                    // Remove from ghosts if selected as player
                                    selectedGhosts = selectedGhosts - profile.id
                                }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Ghosts Selector
                    Text("Select Ghosts (Opponents):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            // Cannot select player as ghost
                            val isPlayer = selectedPlayer?.id == profile.id
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = profile.id in selectedGhosts,
                                color = NeonPink,
                                onClick = {
                                    if (!isPlayer) {
                                        selectedGhosts = if (profile.id in selectedGhosts) {
                                            selectedGhosts - profile.id
                                        } else {
                                            selectedGhosts + profile.id
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

                Button(
                    onClick = {
                        if (selectedPlayer != null && selectedGhosts.isNotEmpty()) {
                            gameStarted = true
                        }
                    },
                    enabled = selectedPlayer != null && selectedGhosts.isNotEmpty(),
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
                    Text("LAUNCH CHOMP", fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
            }
        }
    } else {
        // Game Playing Screen
        val ghostProfilesSelected = remember(selectedGhosts) {
            profiles.filter { it.id in selectedGhosts }
        }
        val gameState = remember(selectedPlayer, ghostProfilesSelected) {
            PacmanGameState(selectedPlayer!!, ghostProfilesSelected)
        }
        var canvasSize by remember { mutableStateOf(Size.Zero) }

        // Game loop: tick every 16ms
        LaunchedEffect(gameState, gameState.isPlaying, gameState.isGameOver, gameState.isVictory) {
            if (gameState.isPlaying && !gameState.isGameOver && !gameState.isVictory) {
                while (true) {
                    gameState.tickFrame()
                    delay(16)
                }
            }
        }

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Family Pac-Man", fontWeight = FontWeight.Bold) },
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
                // Stats HUD
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text("SCORE", color = SoftGrey, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                        Text("${gameState.score}", color = ElectricCyan, fontSize = 22.sp, fontWeight = FontWeight.Black)
                    }
                    
                    Column(horizontalAlignment = Alignment.End) {
                        Text("LIVES", color = SoftGrey, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            for (i in 0 until gameState.lives) {
                                Box(
                                    modifier = Modifier
                                        .size(16.dp)
                                        .background(Color.Yellow, CircleShape)
                                )
                            }
                        }
                    }
                }

                // Grid Game Play Maze Box
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .border(1.dp, CyberPurple.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
                        .background(Color(0xFF030712))
                        .onSizeChanged { size ->
                            canvasSize = Size(size.width.toFloat(), size.height.toFloat())
                        }
                        .pointerInput(gameState) {
                            var dragAccumulator = Offset.Zero
                            detectDragGestures(
                                onDragStart = {
                                    dragAccumulator = Offset.Zero
                                },
                                onDrag = { change, dragAmount ->
                                    change.consume()
                                    dragAccumulator += dragAmount
                                    val threshold = 50f
                                    if (dragAccumulator.getDistance() > threshold) {
                                        if (abs(dragAccumulator.x) > abs(dragAccumulator.y)) {
                                            if (dragAccumulator.x > 0f) gameState.setPlayerDirection(PacmanDirection.RIGHT)
                                            else gameState.setPlayerDirection(PacmanDirection.LEFT)
                                        } else {
                                            if (dragAccumulator.y > 0f) gameState.setPlayerDirection(PacmanDirection.DOWN)
                                            else gameState.setPlayerDirection(PacmanDirection.UP)
                                        }
                                        dragAccumulator = Offset.Zero
                                    }
                                },
                                onDragEnd = {
                                    dragAccumulator = Offset.Zero
                                },
                                onDragCancel = {
                                    dragAccumulator = Offset.Zero
                                }
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    PacmanGameCanvas(state = gameState, modifier = Modifier.fillMaxSize())

                    // Overlay menu
                    if (!gameState.isPlaying || gameState.isGameOver || gameState.isVictory) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(alpha = 0.7f))
                        ) {
                            Text(
                                if (gameState.isVictory) "VICTORY!" else if (gameState.isGameOver) "GAME OVER" else "FAMILY PAC-MAN",
                                color = if (gameState.isVictory) ElectricCyan else if (gameState.isGameOver) NeonPink else Color.Yellow,
                                fontSize = 26.sp,
                                fontWeight = FontWeight.Black,
                                letterSpacing = 2.sp
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                if (gameState.isVictory || gameState.isGameOver) "Final Score: ${gameState.score}" else "Swipe to turn Pac-Man.\nEat dots, grab Power Pellets, and eat ghosts!",
                                color = IcyWhite,
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(horizontal = 24.dp)
                            )
                            
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            Button(
                                onClick = {
                                    if (gameState.isGameOver || gameState.isVictory) {
                                        gameState.resetGame()
                                    }
                                    gameState.startGame()
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = NeonPink),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 10.dp)
                            ) {
                                Icon(Icons.Default.PlayArrow, contentDescription = "Start", tint = Color.White, modifier = Modifier.size(20.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(if (gameState.isGameOver || gameState.isVictory) "PLAY AGAIN" else "START MATCH", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Bottom HUD Ticker
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
                        Text(
                            gameState.gameMessage,
                            color = IcyWhite,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun PacmanGameCanvas(
    state: PacmanGameState,
    modifier: Modifier = Modifier
) {
    // Cache bitmaps
    val playerBitmap = remember(state.playerProfile.imagePath) {
        try { android.graphics.BitmapFactory.decodeFile(state.playerProfile.imagePath) } catch (e: Exception) { null }
    }
    val allBitmaps = remember(state.ghostProfiles) {
        state.ghostProfiles.associate { profile ->
            profile.id to try { android.graphics.BitmapFactory.decodeFile(profile.imagePath) } catch (e: Exception) { null }
        }
    }

    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        
        val cellW = w / state.gridWidth
        val cellH = h / state.gridHeight
        
        // 1. Draw glowing connected walls
        for (y in 0 until state.gridHeight) {
            for (x in 0 until state.gridWidth) {
                if (state.isWall(x, y)) {
                    val rectL = x * cellW
                    val rectT = y * cellH
                    
                    // Draw solid base wall cell
                    drawRect(
                        color = Color(0xFF0F172A),
                        topLeft = Offset(rectL, rectT),
                        size = Size(cellW, cellH)
                    )
                    
                    // Draw outline borders only if neighbors are NOT walls
                    val outlineColor = Color(0xFF0066FF).copy(alpha = 0.8f)
                    val outlineW = 2.dp.toPx()
                    
                    if (!state.isWall(x - 1, y)) {
                        drawLine(
                            color = outlineColor,
                            start = Offset(rectL, rectT),
                            end = Offset(rectL, rectT + cellH),
                            strokeWidth = outlineW
                        )
                    }
                    if (!state.isWall(x + 1, y)) {
                        drawLine(
                            color = outlineColor,
                            start = Offset(rectL + cellW, rectT),
                            end = Offset(rectL + cellW, rectT + cellH),
                            strokeWidth = outlineW
                        )
                    }
                    if (!state.isWall(x, y - 1)) {
                        drawLine(
                            color = outlineColor,
                            start = Offset(rectL, rectT),
                            end = Offset(rectL + cellW, rectT),
                            strokeWidth = outlineW
                        )
                    }
                    if (!state.isWall(x, y + 1)) {
                        drawLine(
                            color = outlineColor,
                            start = Offset(rectL, rectT + cellH),
                            end = Offset(rectL + cellW, rectT + cellH),
                            strokeWidth = outlineW
                        )
                    }
                }
            }
        }

        // 2. Draw pellets & power pellets
        val powerPelletBlink = (System.currentTimeMillis() % 500) < 250
        
        for (y in 0 until state.gridHeight) {
            for (x in 0 until state.gridWidth) {
                if (y < state.board.size && x < state.board[y].size) {
                    val char = state.board[y][x]
                    val cX = x * cellW + cellW / 2
                    val cY = y * cellH + cellH / 2
                    
                    if (char == '.') {
                        drawCircle(
                            color = ElectricCyan,
                            radius = cellW * 0.12f,
                            center = Offset(cX, cY)
                        )
                    } else if (char == 'o') {
                        if (powerPelletBlink) {
                            // Pulsating outer glow
                            drawCircle(
                                color = NeonPink.copy(alpha = 0.4f),
                                radius = cellW * 0.4f,
                                center = Offset(cX, cY)
                            )
                            drawCircle(
                                color = NeonPink,
                                radius = cellW * 0.28f,
                                center = Offset(cX, cY)
                            )
                        }
                    }
                }
            }
        }

        // 3. Draw Pac-Man (Chomper Yellow + family photo cropped avatar)
        val pOffset = getInterpolatedDrawOffset(
            state.playerCurrentPos,
            state.playerNextPos,
            state.moveProgress,
            cellW,
            cellH,
            state.gridWidth
        )
        val pRadius = Math.min(cellW, cellH) * 0.45f
        
        // Animate mouth opening angle
        val mouthAngle = abs(sin(System.currentTimeMillis() * 0.01f)) * 38f
        
        val startArcAngle = when (state.playerDir) {
            PacmanDirection.RIGHT -> mouthAngle
            PacmanDirection.LEFT -> 180f + mouthAngle
            PacmanDirection.UP -> 270f + mouthAngle
            PacmanDirection.DOWN -> 90f + mouthAngle
            PacmanDirection.NONE -> 0f
        }
        val sweepArcAngle = if (state.playerDir == PacmanDirection.NONE) 360f else 360f - mouthAngle * 2
        
        // Draw Pacman Yellow base chomping head
        drawArc(
            color = Color(0xFFFACC15), // Yellow
            startAngle = startArcAngle,
            sweepAngle = sweepArcAngle,
            useCenter = true,
            topLeft = Offset(pOffset.x - pRadius, pOffset.y - pRadius),
            size = Size(pRadius * 2, pRadius * 2)
        )
        
        // Draw player circular cropped face avatar
        if (playerBitmap != null) {
            val image = playerBitmap.asImageBitmap()
            val faceRadius = pRadius * 0.7f
            drawContext.canvas.save()
            
            // Clip path to draw inside chomping yellow head, slightly smaller
            val circleClip = Path().apply {
                addOval(Rect(pOffset.x - faceRadius, pOffset.y - faceRadius, pOffset.x + faceRadius, pOffset.y + faceRadius))
            }
            clipPath(circleClip) {
                drawImage(
                    image = image,
                    dstOffset = IntOffset((pOffset.x - faceRadius).toInt(), (pOffset.y - faceRadius).toInt()),
                    dstSize = IntSize((faceRadius * 2).toInt(), (faceRadius * 2).toInt())
                )
            }
            drawContext.canvas.restore()
            
            // Draw cyan neon border rim
            drawCircle(
                color = ElectricCyan,
                radius = faceRadius,
                center = pOffset,
                style = Stroke(width = 1.5.dp.toPx())
            )
        }

        // 4. Draw Ghosts
        state.ghosts.toList().forEach { ghost ->
            val gOffset = getInterpolatedDrawOffset(
                ghost.currentPos,
                ghost.nextPos,
                state.ghostProgress,
                cellW,
                cellH,
                state.gridWidth
            )
            val gRadius = Math.min(cellW, cellH) * 0.44f
            
            if (ghost.isEaten) {
                // Eaten state: Draw floating eyeballs only
                drawGhostEyes(this, gOffset, gRadius, ghost.dir)
            } else {
                // Ghost colors
                val ghostColor = if (ghost.isVulnerable) {
                    // Blink blue and white if vulnerable state is ending (<120 frames left)
                    if (state.frightenedTimer < 120 && (state.frightenedTimer / 10) % 2 == 0) {
                        IcyWhite
                    } else {
                        Color(0xFF1D4ED8) // Deep Blue
                    }
                } else {
                    when (ghost.colorIndex) {
                        0 -> Color(0xFFEF4444) // Red
                        1 -> Color(0xFFEC4899) // Pink
                        2 -> Color(0xFF06B6D4) // Cyan
                        else -> Color(0xFFF97316) // Orange
                    }
                }

                // Draw standard ghost sheet body path (dome top + wavy bottom)
                val bodyPath = Path().apply {
                    // Start bottom left corner of ghost body
                    val left = gOffset.x - gRadius
                    val right = gOffset.x + gRadius
                    val top = gOffset.y - gRadius
                    val bottom = gOffset.y + gRadius
                    val height = gRadius * 2
                    val width = gRadius * 2
                    
                    moveTo(left, bottom)
                    lineTo(left, top + gRadius) // Left straight wall
                    
                    // Dome arc at top
                    addArc(
                        oval = Rect(left, top, right, top + height),
                        startAngleDegrees = 180f,
                        sweepAngleDegrees = 180f
                    )
                    
                    lineTo(right, bottom) // Right straight wall
                    
                    // Bottom waves/tails
                    val waveWidth = width / 3f
                    lineTo(right - waveWidth * 0.5f, bottom - gRadius * 0.2f)
                    lineTo(right - waveWidth * 1.0f, bottom)
                    lineTo(right - waveWidth * 1.5f, bottom - gRadius * 0.2f)
                    lineTo(right - waveWidth * 2.0f, bottom)
                    lineTo(right - waveWidth * 2.5f, bottom - gRadius * 0.2f)
                    lineTo(left, bottom)
                    close()
                }
                
                // Draw sheet
                drawPath(
                    path = bodyPath,
                    color = ghostColor
                )
                
                // Draw circular cropped face inside the ghost dome head
                val bitmap = allBitmaps[ghost.id]
                if (bitmap != null) {
                    val image = bitmap.asImageBitmap()
                    val faceRadius = gRadius * 0.85f
                    val faceY = gOffset.y - gRadius * 0.05f
                    
                    drawContext.canvas.save()
                    val circleClip = Path().apply {
                        addOval(Rect(gOffset.x - faceRadius, faceY - faceRadius, gOffset.x + faceRadius, faceY + faceRadius))
                    }
                    clipPath(circleClip) {
                        drawImage(
                            image = image,
                            dstOffset = IntOffset((gOffset.x - faceRadius).toInt(), (faceY - faceRadius).toInt()),
                            dstSize = IntSize((faceRadius * 2).toInt(), (faceRadius * 2).toInt())
                        )
                    }
                    drawContext.canvas.restore()
                    
                    // Draw outer border rim
                    drawCircle(
                        color = Color.White.copy(alpha = 0.6f),
                        radius = faceRadius,
                        center = Offset(gOffset.x, faceY),
                        style = Stroke(width = 1.dp.toPx())
                    )
                }

                // Draw eyes on top of the ghost sheet
                drawGhostEyes(this, gOffset, gRadius, ghost.dir)
            }
        }

        // 5. Draw sparkles (score texts)
        state.sparkles.toList().forEach { s ->
            drawContext.canvas.save()
            // Floating text drawn on Canvas
            val paint = android.graphics.Paint().apply {
                color = android.graphics.Color.YELLOW
                textSize = cellW * 0.6f
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                alpha = (s.alpha * 255).toInt()
            }
            drawContext.canvas.nativeCanvas.drawText(
                s.text,
                s.offset.x - cellW * 0.5f,
                s.offset.y + cellH * 0.2f,
                paint
            )
            drawContext.canvas.restore()
        }
    }
}

private fun drawGhostEyes(
    drawScope: androidx.compose.ui.graphics.drawscope.DrawScope,
    center: Offset,
    radius: Float,
    dir: PacmanDirection
) {
    with(drawScope) {
        val eyeW = radius * 0.35f
        val eyeH = radius * 0.45f
        val spacing = radius * 0.45f
        
        // Pupil offsets depending on direction
        val pX = when (dir) {
            PacmanDirection.LEFT -> -3f
            PacmanDirection.RIGHT -> 3f
            else -> 0f
        }
        val pY = when (dir) {
            PacmanDirection.UP -> -3f
            PacmanDirection.DOWN -> 3f
            else -> 0f
        }
        
        // Left eye
        val eyeLX = center.x - spacing / 2 - eyeW / 2
        val eyeLY = center.y - radius * 0.45f
        drawOval(
            color = Color.White,
            topLeft = Offset(eyeLX, eyeLY),
            size = Size(eyeW, eyeH)
        )
        drawCircle(
            color = Color.Blue,
            radius = eyeW * 0.35f,
            center = Offset(eyeLX + eyeW / 2 + pX, eyeLY + eyeH / 2 + pY)
        )
        
        // Right eye
        val eyeRX = center.x + spacing / 2 - eyeW / 2
        val eyeRY = center.y - radius * 0.45f
        drawOval(
            color = Color.White,
            topLeft = Offset(eyeRX, eyeRY),
            size = Size(eyeW, eyeH)
        )
        drawCircle(
            color = Color.Blue,
            radius = eyeW * 0.35f,
            center = Offset(eyeRX + eyeW / 2 + pX, eyeRY + eyeH / 2 + pY)
        )
    }
}

private fun getInterpolatedDrawOffset(
    current: GridPos,
    next: GridPos,
    progress: Float,
    cellW: Float,
    cellH: Float,
    gridWidth: Int
): Offset {
    val diffX = next.x - current.x
    val diffY = next.y - current.y
    
    if (abs(diffX) > 1) { // Wrapping horizontally
        val drawX = if (current.x == 0 && next.x == gridWidth - 1) {
            if (progress < 0.5f) {
                (0f - progress) * cellW + cellW / 2
            } else {
                (gridWidth.toFloat() - (1f - progress)) * cellW + cellW / 2
            }
        } else {
            if (progress < 0.5f) {
                ((gridWidth - 1).toFloat() + progress) * cellW + cellW / 2
            } else {
                (-1f + (1f - progress)) * cellW + cellW / 2
            }
        }
        val drawY = current.y * cellH + cellH / 2
        return Offset(drawX, drawY)
    } else {
        val drawX = (current.x + diffX * progress) * cellW + cellW / 2
        val drawY = (current.y + diffY * progress) * cellH + cellH / 2
        return Offset(drawX, drawY)
    }
}
