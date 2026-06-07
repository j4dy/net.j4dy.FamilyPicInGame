package net.j4dy.familypicingame.games.snake

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
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowUp
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
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import net.j4dy.familypicingame.data.FaceStorage
import net.j4dy.familypicingame.games.common.Vector2D
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SnakeGameScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    val profiles = remember { faceStorage.getProfiles() }

    var selectedHead by remember { mutableStateOf<FaceProfile?>(null) }
    var selectedFood by remember { mutableStateOf<FaceProfile?>(null) }
    var gameStarted by remember { mutableStateOf(false) }

    if (!gameStarted) {
        // Selection Screen
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Setup Snake Nibbles", fontWeight = FontWeight.Bold) },
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
                        "ASSIGN GAME ROLES",
                        color = ElectricCyan,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 24.dp)
                    )

                    // Head Selector
                    Text("Select the Snake Head (Player):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedHead?.id == profile.id,
                                color = ElectricCyan,
                                onClick = { selectedHead = profile }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Food Selector
                    Text("Select the Snake Food (Target):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedFood?.id == profile.id,
                                color = NeonPink,
                                onClick = { selectedFood = profile }
                            )
                        }
                    }
                }

                Button(
                    onClick = {
                        if (selectedHead != null && selectedFood != null) {
                            gameStarted = true
                        }
                    },
                    enabled = selectedHead != null && selectedFood != null,
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
                    Text("START MISSION", fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
            }
        }
    } else {
        // Game Playing Screen
        val gameState = remember { SnakeGameState(selectedHead!!, selectedFood!!, profiles) }
        
        // Game Tick Loop (200ms per step)
        // By adding gameState.isGameOver as a key, this coroutine loop automatically
        // cancels and restarts whenever the game resets (changing isGameOver back to false!)
        LaunchedEffect(gameState, gameState.isGameOver) {
            if (!gameState.isGameOver) {
                while (true) {
                    gameState.tick()
                    delay(200)
                }
            }
        }

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Family Snake", fontWeight = FontWeight.Bold) },
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
                // Game Canvas Grid with Swipe Listener
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .border(1.dp, CyberPurple.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
                        .background(Color(0xFF0D1222))
                        .pointerInput(gameState) {
                            detectTapGestures { offset ->
                                val w = size.width.toFloat()
                                val h = size.height.toFloat()
                                val cX = w / 2f
                                val cY = h / 2f
                                val dx = offset.x - cX
                                val dy = offset.y - cY
                                
                                val normDx = dx / w
                                val normDy = dy / h
                                
                                if (Math.abs(normDx) > Math.abs(normDy)) {
                                    if (normDx > 0f) gameState.setSnakeDirection(SnakeDirection.RIGHT)
                                    else gameState.setSnakeDirection(SnakeDirection.LEFT)
                                } else {
                                    if (normDy > 0f) gameState.setSnakeDirection(SnakeDirection.DOWN)
                                    else gameState.setSnakeDirection(SnakeDirection.UP)
                                }
                            }
                        },
                    contentAlignment = Alignment.Center
                ) {
                    SnakeGameCanvas(state = gameState, modifier = Modifier.fillMaxSize())
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Score Card / Controller panel
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, CyberPurple.copy(alpha = 0.2f), RoundedCornerShape(20.dp)),
                    colors = CardDefaults.cardColors(containerColor = CardSlate.copy(alpha = 0.9f)),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Score: ${gameState.score}", color = ElectricCyan, fontWeight = FontWeight.Black, fontSize = 18.sp)
                                Text(gameState.gameMessage, color = IcyWhite, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                            }
                            
                            if (gameState.isGameOver) {
                                Button(
                                    onClick = { gameState.resetGame() },
                                    colors = ButtonDefaults.buttonColors(containerColor = NeonPink),
                                    shape = RoundedCornerShape(8.dp),
                                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                                ) {
                                    Icon(Icons.Default.Refresh, contentDescription = "Restart", tint = Color.White, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("RETRY", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1, softWrap = false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private val TranslucentWhite = Color(0x15FFFFFF)

@Composable
fun SnakeGameCanvas(
    state: SnakeGameState,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    
    // Load bitmaps in memory for drawing on Grid Canvas
    val headBitmap = remember(state.headProfile.imagePath) {
        try { android.graphics.BitmapFactory.decodeFile(state.headProfile.imagePath) } catch (e: Exception) { null }
    }
    val foodBitmap = remember(state.foodProfile.imagePath) {
        try { android.graphics.BitmapFactory.decodeFile(state.foodProfile.imagePath) } catch (e: Exception) { null }
    }
    val allBitmaps = remember(state.allProfiles) {
        state.allProfiles.associate { profile ->
            profile.id to try { android.graphics.BitmapFactory.decodeFile(profile.imagePath) } catch (e: Exception) { null }
        }
    }

    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        
        val cellW = w / state.gridWidth
        val cellH = h / state.gridHeight
        
        // 1. Draw subtle background grid cells
        for (i in 0 until state.gridWidth) {
            for (j in 0 until state.gridHeight) {
                drawRect(
                    color = Color(0xFF1E293B).copy(alpha = 0.15f),
                    topLeft = Offset(i * cellW, j * cellH),
                    size = Size(cellW - 1, cellH - 1)
                )
            }
        }

        // 1.5 Draw diagonal boundary lines and soft arrow chevrons for tap zone guides (high visibility)
        val dashEffect = PathEffect.dashPathEffect(floatArrayOf(20f, 20f), 0f)
        drawLine(
            color = CyberPurple.copy(alpha = 0.45f),
            start = Offset(0f, 0f),
            end = Offset(w, h),
            strokeWidth = 2.dp.toPx(),
            pathEffect = dashEffect
        )
        drawLine(
            color = CyberPurple.copy(alpha = 0.45f),
            start = Offset(w, 0f),
            end = Offset(0f, h),
            strokeWidth = 2.dp.toPx(),
            pathEffect = dashEffect
        )
        
        // Soft directional guides (triangles scaled dynamically in Dp)
        val arrowSize = 16.dp.toPx()
        val margin = 24.dp.toPx()
        val guideColor = ElectricCyan.copy(alpha = 0.35f)
        
        // UP
        val upPath = Path().apply {
            moveTo(w / 2f, margin)
            lineTo(w / 2f - arrowSize, margin + arrowSize)
            lineTo(w / 2f + arrowSize, margin + arrowSize)
            close()
        }
        drawPath(upPath, color = guideColor)
        
        // DOWN
        val downPath = Path().apply {
            moveTo(w / 2f, h - margin)
            lineTo(w / 2f - arrowSize, h - margin - arrowSize)
            lineTo(w / 2f + arrowSize, h - margin - arrowSize)
            close()
        }
        drawPath(downPath, color = guideColor)
        
        // LEFT
        val leftPath = Path().apply {
            moveTo(margin, h / 2f)
            lineTo(margin + arrowSize, h / 2f - arrowSize)
            lineTo(margin + arrowSize, h / 2f + arrowSize)
            close()
        }
        drawPath(leftPath, color = guideColor)
        
        // RIGHT
        val rightPath = Path().apply {
            moveTo(w - margin, h / 2f)
            lineTo(w - margin - arrowSize, h / 2f - arrowSize)
            lineTo(w - margin - arrowSize, h / 2f + arrowSize)
            close()
        }
        drawPath(rightPath, color = guideColor)

        // 2. Draw Food target (circular face)
        val foodX = state.foodPos.x * cellW + cellW/2
        val foodY = state.foodPos.y * cellH + cellH/2
        val foodRadius = Math.min(cellW, cellH) * 0.45f
        val foodCenter = Offset(foodX, foodY)
        
        if (foodBitmap != null) {
            val foodImage = foodBitmap.asImageBitmap()
            drawContext.canvas.save()
            
            // Neon pink food glow ring
            drawCircle(
                color = NeonPink.copy(alpha = 0.35f),
                radius = foodRadius + 4f,
                center = foodCenter
            )

            val circleClip = Path().apply {
                addOval(Rect(foodX - foodRadius, foodY - foodRadius, foodX + foodRadius, foodY + foodRadius))
            }
            clipPath(circleClip) {
                drawImage(
                    image = foodImage,
                    dstOffset = IntOffset((foodX - foodRadius).toInt(), (foodY - foodRadius).toInt()),
                    dstSize = IntSize((foodRadius * 2).toInt(), (foodRadius * 2).toInt())
                )
            }
            drawContext.canvas.restore()
            
            drawCircle(
                color = NeonPink,
                radius = foodRadius,
                center = foodCenter,
                style = Stroke(width = 1.5.dp.toPx())
            )
        } else {
            drawCircle(color = NeonPink, radius = foodRadius, center = foodCenter)
        }

        // 3. Draw Snake Segment bodies (heads and alternating family member faces!)
        state.snake.forEachIndexed { index, segment ->
            val segX = segment.x * cellW + cellW/2
            val segY = segment.y * cellH + cellH/2
            val segRadius = Math.min(cellW, cellH) * 0.44f
            val segCenter = Offset(segX, segY)
            
            val isHead = index == 0
            
            // Get designated profile for this segment
            val profile = state.getProfileForSegment(index)
            val segmentBitmap = allBitmaps[profile.id]
            
            if (segmentBitmap != null) {
                val segImage = segmentBitmap.asImageBitmap()
                drawContext.canvas.save()
                
                // Draw slight connector line between segments
                if (index < state.snake.size - 1) {
                    val nextSeg = state.snake[index + 1]
                    val nextX = nextSeg.x * cellW + cellW/2
                    val nextY = nextSeg.y * cellH + cellH/2
                    drawLine(
                        color = if (isHead) ElectricCyan.copy(alpha = 0.6f) else CyberPurple.copy(alpha = 0.4f),
                        start = segCenter,
                        end = Offset(nextX, nextY),
                        strokeWidth = 6f
                    )
                }

                // Draw circle clip avatar
                val circleClip = Path().apply {
                    addOval(Rect(segX - segRadius, segY - segRadius, segX + segRadius, segY + segRadius))
                }
                clipPath(circleClip) {
                    drawImage(
                        image = segImage,
                        dstOffset = IntOffset((segX - segRadius).toInt(), (segY - segRadius).toInt()),
                        dstSize = IntSize((segRadius * 2).toInt(), (segRadius * 2).toInt())
                    )
                }
                drawContext.canvas.restore()
                
                // Cyan border for head, cyber purple for body segments
                drawCircle(
                    color = if (isHead) ElectricCyan else CyberPurple,
                    radius = segRadius,
                    center = segCenter,
                    style = Stroke(width = if (isHead) 2.5.dp.toPx() else 1.5.dp.toPx())
                )
            } else {
                // Fallback colored circles
                drawCircle(
                    color = if (isHead) ElectricCyan else CyberPurple,
                    radius = segRadius,
                    center = segCenter
                )
            }
        }

        // 4. Draw food sparkle particles on chomps
        state.sparkles.forEach { s ->
            val spX = s.gridPos.x * cellW + cellW/2 + s.offset.x
            val spY = s.gridPos.y * cellH + cellH/2 + s.offset.y
            drawCircle(
                color = ElectricCyan.copy(alpha = s.alpha),
                radius = 4f * s.alpha,
                center = Offset(spX, spY)
            )
        }
    }
}
