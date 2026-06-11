package net.j4dy.familypicingame.games.whack

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
import androidx.compose.material.icons.filled.PlayArrow
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
fun WhackGameScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    val profiles = remember { faceStorage.getProfiles() }
    
    var gameStarted by remember { mutableStateOf(false) }
    var teamA by remember { mutableStateOf(setOf<String>()) } // Teammates (avoid)
    var teamB by remember { mutableStateOf(setOf<String>()) } // Opponents (whack)
    var speedMultiplier by remember { mutableStateOf(2.0f) }   // Default 2.0x (double speed)
    
    if (!gameStarted) {
        // Selection Screen
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Setup Whack Teams", fontWeight = FontWeight.Bold) },
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
                        "ASSIGN GAME TEAMS",
                        color = ElectricCyan,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 24.dp)
                    )

                    // Team A (Teammates) Selector
                    Text("Select Teammates (Team A - Do NOT Tap):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = profile.id in teamA,
                                color = ElectricCyan,
                                onClick = {
                                    val id = profile.id
                                    if (id in teamA) {
                                        teamA = teamA - id
                                    } else {
                                        teamA = teamA + id
                                        teamB = teamB - id // exclusive mapping
                                    }
                                }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Team B (Opponents) Selector
                    Text("Select Opponents (Team B - Whack Them!):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = profile.id in teamB,
                                color = NeonPink,
                                onClick = {
                                    val id = profile.id
                                    if (id in teamB) {
                                        teamB = teamB - id
                                    } else {
                                        teamB = teamB + id
                                        teamA = teamA - id // exclusive mapping
                                    }
                                }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Speed Control settings
                    Text("Select Speed Multiplier:", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        val speeds = listOf(1.0f, 1.5f, 2.0f, 3.0f)
                        val labels = listOf("1.0x (Slow)", "1.5x (Normal)", "2.0x (Fast)", "3.0x (Insane)")
                        
                        speeds.forEachIndexed { i, speed ->
                            val isSelected = speedMultiplier == speed
                            Button(
                                onClick = { speedMultiplier = speed },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = if (isSelected) ElectricCyan else CardSlate,
                                    contentColor = if (isSelected) Color.Black else IcyWhite
                                ),
                                contentPadding = PaddingValues(horizontal = 4.dp, vertical = 8.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = if (isSelected) null else androidx.compose.foundation.BorderStroke(1.dp, SoftGrey.copy(alpha = 0.3f))
                            ) {
                                Text(labels[i], fontSize = 10.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }

                Button(
                    onClick = {
                        if (teamA.isNotEmpty() && teamB.isNotEmpty()) {
                            gameStarted = true
                        }
                    },
                    enabled = teamA.isNotEmpty() && teamB.isNotEmpty(),
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
                    Text("LAUNCH CHALLENGE", fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
            }
        }
    } else {
        // Game Playing Screen
        val gameState = remember(teamA, teamB, speedMultiplier) {
            WhackGameState(
                teamAProfiles = profiles.filter { it.id in teamA },
                teamBProfiles = profiles.filter { it.id in teamB },
                speedMultiplier = speedMultiplier
            )
        }
        var canvasSize by remember { mutableStateOf(Size.Zero) }

        // Game loops: Timer loop (1s) and render frame loop (16ms)
        LaunchedEffect(gameState, gameState.isPlaying, gameState.isGameOver) {
            if (gameState.isPlaying && !gameState.isGameOver) {
                while (true) {
                    gameState.tickFrame()
                    delay(16)
                }
            }
        }
        
        LaunchedEffect(gameState, gameState.isPlaying, gameState.isGameOver) {
            if (gameState.isPlaying && !gameState.isGameOver) {
                while (true) {
                    delay(1000)
                    gameState.tickSecond()
                }
            }
        }

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Teammates vs Opponents (${speedMultiplier}x)", fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = { gameStarted = false }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = IcyWhite)
                        }
                    },
                    actions = {
                        TextButton(
                            onClick = { gameState.resetGame() },
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                        ) {
                            Icon(Icons.Default.Refresh, contentDescription = "Reset", tint = ElectricCyan, modifier = Modifier.size(22.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("RESET", color = ElectricCyan, fontSize = 18.sp, fontWeight = FontWeight.Bold)
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
                // Header stats HUD
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
                        Text("TIME LEFT", color = SoftGrey, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                        Text("${gameState.timeLeftSeconds}s", color = if (gameState.timeLeftSeconds <= 10) NeonPink else IcyWhite, fontSize = 22.sp, fontWeight = FontWeight.Black)
                    }
                }

                // Time progress bar
                LinearProgressIndicator(
                    progress = gameState.timeLeftSeconds / 45f,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 6.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = if (gameState.timeLeftSeconds <= 10) NeonPink else ElectricCyan,
                    trackColor = CyberPurple.copy(alpha = 0.2f)
                )

                // Game Play Grid with Tap Coordinates (3x4 Grid)
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
                                onTap = { offset ->
                                    val cellW = canvasSize.width / 3f
                                    val cellH = canvasSize.height / 4f
                                    val col = (offset.x / cellW).toInt().coerceIn(0, 2)
                                    val row = (offset.y / cellH).toInt().coerceIn(0, 3)
                                    val index = row * 3 + col
                                    gameState.whackCell(index)
                                }
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    WhackGameCanvas(state = gameState, modifier = Modifier.fillMaxSize())
                    
                    // Play overlay
                    if (!gameState.isPlaying) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier
                                .fillMaxSize()
                                .background(Color.Black.copy(alpha = 0.6f))
                        ) {
                            Text(
                                if (gameState.isGameOver) "GAME OVER" else "TEAM WHACK CHALLENGE",
                                color = if (gameState.isGameOver) NeonPink else ElectricCyan,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Black,
                                letterSpacing = 2.sp
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                if (gameState.isGameOver) "Final Score: ${gameState.score}" else "Whack Opponents (Neon Pink).\nDo NOT tap Teammates (Electric Cyan)!",
                                color = IcyWhite,
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(horizontal = 24.dp)
                            )
                            
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            Button(
                                onClick = { gameState.startGame() },
                                colors = ButtonDefaults.buttonColors(containerColor = NeonPink),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 24.dp, vertical = 14.dp)
                            ) {
                                Icon(Icons.Default.PlayArrow, contentDescription = "Start", tint = Color.White, modifier = Modifier.size(26.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(if (gameState.isGameOver) "PLAY AGAIN / RESET" else "START MATCH", fontWeight = FontWeight.Bold, fontSize = 22.sp)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Footer HUD
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
                            Text("COMBO", color = SoftGrey, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                            Text("x${gameState.comboMultiplier}", color = ElectricCyan, fontSize = 20.sp, fontWeight = FontWeight.Black)
                        }
                        Text(
                            gameState.gameMessage,
                            color = IcyWhite,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.End,
                            maxLines = 1,
                            modifier = Modifier.weight(1f).padding(start = 12.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun WhackGameCanvas(
    state: WhackGameState,
    modifier: Modifier = Modifier
) {
    // Cache family face bitmaps
    val allBitmaps = remember(state.teamAProfiles, state.teamBProfiles) {
        val merged = state.teamAProfiles + state.teamBProfiles
        merged.associate { profile ->
            profile.id to try { android.graphics.BitmapFactory.decodeFile(profile.imagePath) } catch (e: Exception) { null }
        }
    }

    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        
        val cellW = w / 3f
        val cellH = h / 4f // 3 columns by 4 rows (12 slots)
        
        // 1. Draw glowing grid partition borders
        for (i in 1..2) {
            // Vertical separators
            drawLine(
                color = CyberPurple.copy(alpha = 0.2f),
                start = Offset(i * cellW, 0f),
                end = Offset(i * cellW, h),
                strokeWidth = 2f
            )
        }
        for (i in 1..3) {
            // Horizontal separators
            drawLine(
                color = CyberPurple.copy(alpha = 0.2f),
                start = Offset(0f, i * cellH),
                end = Offset(w, i * cellH),
                strokeWidth = 2f
            )
        }

        // 2. Draw holes & popped up characters
        for (row in 0..3) {
            for (col in 0..2) {
                val index = row * 3 + col
                val portal = state.portals[index]
                
                val cX = col * cellW + cellW / 2
                val cY = row * cellH + cellH / 2
                
                val radius = Math.min(cellW, cellH) * 0.35f
                val holeRadiusX = radius * 1.1f
                val holeRadiusY = radius * 0.45f
                
                // Draw portal hole backing shadow (dark ellipse)
                drawOval(
                    color = Color(0xFF030712),
                    topLeft = Offset(cX - holeRadiusX, cY + radius * 0.3f - holeRadiusY),
                    size = Size(holeRadiusX * 2, holeRadiusY * 2)
                )

                // If portal has character, draw it popping out!
                if (portal.type != PortalType.EMPTY && portal.familyProfile != null) {
                    val charCenterY = cY - radius * 0.1f // center it slightly above the hole
                    
                    drawContext.canvas.save()
                    
                    // Clip drawing to avoid extending too far below portal hole base
                    val clipRect = Path().apply {
                        addRect(Rect(col * cellW, row * cellH, (col + 1) * cellW, cY + radius * 0.3f + 10f))
                    }
                    clipPath(clipRect) {
                        val profile = portal.familyProfile!!
                        val bitmap = allBitmaps[profile.id]
                        val faceR = radius * 0.8f
                        
                        if (bitmap != null) {
                            val image = bitmap.asImageBitmap()
                            val facePath = Path().apply {
                                addOval(Rect(cX - faceR, charCenterY - faceR, cX + faceR, charCenterY + faceR))
                            }
                            clipPath(facePath) {
                                drawImage(
                                    image = image,
                                    dstOffset = IntOffset((cX - faceR).toInt(), (charCenterY - faceR).toInt()),
                                    dstSize = IntSize((faceR * 2).toInt(), (faceR * 2).toInt())
                                )
                            }
                        } else {
                            // Fallback colored circle with initial letter/label if bitmap null
                            drawCircle(
                                color = if (portal.type == PortalType.TEAM_B) NeonPink else ElectricCyan,
                                radius = faceR,
                                center = Offset(cX, charCenterY)
                            )
                        }
                        
                        // Glow ring
                        drawCircle(
                            color = (if (portal.type == PortalType.TEAM_B) NeonPink else ElectricCyan).copy(alpha = 0.25f),
                            radius = faceR + 5f,
                            center = Offset(cX, charCenterY),
                            style = Stroke(width = 1.5.dp.toPx())
                        )
                        
                        // Border color: Neon Pink for opponent (Team B), Electric Cyan for teammate (Team A)
                        drawCircle(
                            color = if (portal.type == PortalType.TEAM_B) NeonPink else ElectricCyan,
                            radius = faceR,
                            center = Offset(cX, charCenterY),
                            style = Stroke(width = 2.dp.toPx())
                        )
                    }
                    drawContext.canvas.restore()
                }

                // Draw portal hole front glowing lip (half ellipse)
                drawArc(
                    color = CyberPurple,
                    startAngle = 0f,
                    sweepAngle = 180f,
                    useCenter = false,
                    topLeft = Offset(cX - holeRadiusX, cY + radius * 0.3f - holeRadiusY),
                    size = Size(holeRadiusX * 2, holeRadiusY * 2),
                    style = Stroke(width = 3.dp.toPx())
                )
            }
        }

        // 3. Draw score / penalty sparkles
        state.sparkles.forEach { sparkle ->
            val cellX = (sparkle.index % 3) * cellW + cellW / 2
            val cellY = (sparkle.index / 3) * cellH + cellH / 2
            
            // Draw floating glowing circles
            drawCircle(
                color = (if (sparkle.isPenalty) NeonPink else ElectricCyan).copy(alpha = sparkle.alpha * 0.4f),
                radius = 30f,
                center = Offset(cellX + sparkle.offset.x, cellY + sparkle.offset.y)
            )
            
            // Floating sparkles
            drawCircle(
                color = (if (sparkle.isPenalty) NeonPink else ElectricCyan).copy(alpha = sparkle.alpha),
                radius = 6f,
                center = Offset(cellX + sparkle.offset.x - 15f, cellY + sparkle.offset.y - 10f)
            )
            drawCircle(
                color = (if (sparkle.isPenalty) NeonPink else ElectricCyan).copy(alpha = sparkle.alpha),
                radius = 4f,
                center = Offset(cellX + sparkle.offset.x + 20f, cellY + sparkle.offset.y + 15f)
            )
        }
    }
}
