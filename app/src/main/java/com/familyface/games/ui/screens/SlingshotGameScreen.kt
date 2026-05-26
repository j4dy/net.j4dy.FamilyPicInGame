package com.familyface.games.games.slingshot

import android.graphics.BitmapFactory
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
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
import com.familyface.games.data.FaceStorage
import com.familyface.games.games.common.Vector2D
import com.familyface.games.model.FaceProfile
import com.familyface.games.ui.theme.CardSlate
import com.familyface.games.ui.theme.CyberPurple
import com.familyface.games.ui.theme.DeepDarkBlue
import com.familyface.games.ui.theme.ElectricCyan
import com.familyface.games.ui.theme.IcyWhite
import com.familyface.games.ui.theme.NeonPink
import com.familyface.games.ui.theme.SoftGrey
import kotlinx.coroutines.delay
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SlingshotGameScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    val profiles = remember { faceStorage.getProfiles() }

    var selectedHero by remember { mutableStateOf<FaceProfile?>(null) }
    var selectedTarget by remember { mutableStateOf<FaceProfile?>(null) }
    var gameStarted by remember { mutableStateOf(false) }

    // Dynamically lock screen to landscape ONLY when gameplay starts; keep setup in portrait!
    DisposableEffect(gameStarted) {
        val activity = context as? android.app.Activity
        val originalOrientation = activity?.requestedOrientation ?: android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        if (gameStarted) {
            activity?.requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        } else {
            activity?.requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
        onDispose {
            activity?.requestedOrientation = originalOrientation
        }
    }

    if (!gameStarted) {
        // Selection Screen
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Setup Slingshot", fontWeight = FontWeight.Bold) },
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

                    // Hero Selector
                    Text("Select the Hero (Bird Character):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedHero?.id == profile.id,
                                color = ElectricCyan,
                                onClick = { selectedHero = profile }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Target Selector
                    Text("Select the Targets (Pig Characters):", color = IcyWhite, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Start))
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(profiles) { profile ->
                            RoleAvatarItem(
                                profile = profile,
                                isSelected = selectedTarget?.id == profile.id,
                                color = NeonPink,
                                onClick = { selectedTarget = profile }
                            )
                        }
                    }
                }

                Button(
                    onClick = {
                        if (selectedHero != null && selectedTarget != null) {
                            gameStarted = true
                        }
                    },
                    enabled = selectedHero != null && selectedTarget != null,
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
                    Text("LAUNCH GAME", fontSize = 18.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
            }
        }
    } else {
        // Game Playing Screen
        val gameState = remember { SlingshotGameState(selectedHero!!, selectedTarget!!) }

        // Start Physics Tick Engine
        LaunchedEffect(gameState) {
            while (true) {
                gameState.update()
                delay(16) // 60 FPS update tick
            }
        }

        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Family Slingshot", fontWeight = FontWeight.Bold) },
                    navigationIcon = {
                        IconButton(onClick = { gameStarted = false }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = IcyWhite)
                        }
                    },
                    actions = {
                        IconButton(onClick = { gameState.resetLevel() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Reset Level", tint = ElectricCyan)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = DeepDarkBlue)
                )
            }
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(DeepDarkBlue)
            ) {
                // Game Canvas
                SlingshotGameCanvas(
                    state = gameState,
                    modifier = Modifier.fillMaxSize()
                )

                // Bottom Dashboard HUD (score, message, lives)
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, CyberPurple.copy(alpha = 0.3f), RoundedCornerShape(16.dp)),
                        colors = CardDefaults.cardColors(containerColor = CardSlate.copy(alpha = 0.85f)),
                        shape = RoundedCornerShape(16.dp)
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
                                Text("Score: ${gameState.score}", color = ElectricCyan, fontWeight = FontWeight.Black, fontSize = 20.sp)
                                Row {
                                    for (i in 0 until 3) {
                                        Box(
                                            modifier = Modifier
                                                .size(16.dp)
                                                .padding(horizontal = 2.dp)
                                                .clip(CircleShape)
                                                .background(
                                                    if (i < gameState.shotsLeft) NeonPink else Color.DarkGray
                                                )
                                        )
                                    }
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = gameState.gameStateMessage,
                                color = IcyWhite,
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }

                    // Reset button overlay if out of shots or victory
                    val isGameOver = gameState.shotsLeft <= 0 || gameState.targets.all { it.isDestroyed }
                    AnimatedVisibility(visible = isGameOver) {
                        Button(
                            onClick = { gameState.resetLevel() },
                            modifier = Modifier
                                .padding(top = 16.dp)
                                .fillMaxWidth()
                                .height(50.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = ElectricCyan),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("PLAY AGAIN", color = DeepDarkBlue, fontWeight = FontWeight.Black, fontSize = 16.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun RoleAvatarItem(
    profile: FaceProfile,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .width(90.dp)
            .clickable { onClick() }
            .padding(vertical = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(70.dp)
                .clip(CircleShape)
                .background(CardSlate)
                .border(
                    width = if (isSelected) 3.dp else 1.dp,
                    color = if (isSelected) color else color.copy(alpha = 0.3f),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            val file = File(profile.imagePath)
            if (file.exists()) {
                val bitmap = remember(profile.imagePath) {
                    android.graphics.BitmapFactory.decodeFile(profile.imagePath)
                }
                if (bitmap != null) {
                    androidx.compose.foundation.Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = profile.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = profile.name,
            color = if (isSelected) color else SoftGrey,
            fontSize = 12.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            textAlign = TextAlign.Center,
            maxLines = 1
        )
    }
}

@Composable
fun SlingshotGameCanvas(
    state: SlingshotGameState,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    
    // Load bitmaps in memory for rendering on canvas
    val heroBitmap = remember(state.heroProfile.imagePath) {
        android.graphics.BitmapFactory.decodeFile(state.heroProfile.imagePath)
    }
    val targetBitmap = remember(state.targetProfile.imagePath) {
        android.graphics.BitmapFactory.decodeFile(state.targetProfile.imagePath)
    }

    Box(
        modifier = modifier
            .pointerInput(state) {
                detectDragGestures(
                    onDragStart = { offset ->
                        val scaleX = size.width.toFloat() / 1280f
                        val scaleY = size.height.toFloat() / 720f
                        val touchVec = Vector2D(offset.x / scaleX, offset.y / scaleY)
                        if (state.birdPos.distance(touchVec) < state.birdRadius * 2.2f) {
                            state.onDrag(Offset(offset.x / scaleX, offset.y / scaleY))
                        }
                    },
                    onDrag = { change, _ ->
                        if (state.isDragging) {
                            val scaleX = size.width.toFloat() / 1280f
                            val scaleY = size.height.toFloat() / 720f
                            state.onDrag(Offset(change.position.x / scaleX, change.position.y / scaleY))
                        }
                    },
                    onDragEnd = {
                        if (state.isDragging) {
                            state.onRelease()
                        }
                    }
                )
            }
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val physicalW = size.width
            val physicalH = size.height
            
            val scaleX = physicalW / 1280f
            val scaleY = physicalH / 720f
            
            val w = 1280f
            val h = 720f
            val groundY = 560f
            
            // Screen Shake Transform
            val shakeX = if (state.screenShake > 0) (Math.random().toFloat() * 2 - 1) * state.screenShake else 0f
            val shakeY = if (state.screenShake > 0) (Math.random().toFloat() * 2 - 1) * state.screenShake else 0f
            
            drawContext.canvas.save()
            // Scale to standard landscape grid first, then apply translate shake
            drawContext.canvas.scale(scaleX, scaleY)
            drawContext.canvas.translate(shakeX, shakeY)

            // 1. Draw beautiful hills in the background (parallax)
            drawPath(
                path = Path().apply {
                    moveTo(0f, groundY)
                    quadraticBezierTo(w * 0.25f, groundY - 140f, w * 0.5f, groundY)
                    quadraticBezierTo(w * 0.75f, groundY - 80f, w, groundY)
                    lineTo(w, h)
                    lineTo(0f, h)
                    close()
                },
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF1E2642), Color(0xFF151C33))
                )
            )

            // 2. Draw ground level
            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF22C55E), Color(0xFF15803D)) // Green ground
                ),
                topLeft = Offset(0f, groundY),
                size = Size(w, h - groundY)
            )
            // Ground top neon thin border line
            drawLine(
                color = ElectricCyan,
                start = Offset(0f, groundY),
                end = Offset(w, groundY),
                strokeWidth = 2.dp.toPx()
            )

            // 3. Draw slingshot poles (rustic neon brown sticks)
            val anchorX = state.slingAnchor.x
            val anchorY = state.slingAnchor.y
            
            // Left & Right rubber-band hooks
            val hookLeft = Offset(anchorX - 30f, anchorY - 60f)
            val hookRight = Offset(anchorX + 30f, anchorY - 60f)
            
            // Slingshot frame
            drawLine(
                color = Color(0xFF8B5A2B),
                start = Offset(anchorX, groundY),
                end = Offset(anchorX, anchorY - 40f),
                strokeWidth = 14f
            )
            drawLine(
                color = Color(0xFF8B5A2B),
                start = Offset(anchorX, anchorY - 40f),
                end = hookLeft,
                strokeWidth = 10f
            )
            drawLine(
                color = Color(0xFF8B5A2B),
                start = Offset(anchorX, anchorY - 40f),
                end = hookRight,
                strokeWidth = 10f
            )

            // 4. Draw trajectory dots (dotted prediction line)
            if (state.isDragging) {
                val trajectory = state.getTrajectoryPoints()
                trajectory.forEachIndexed { index, point ->
                    if (index % 2 == 0) { // draw every 2nd dot
                        drawCircle(
                            color = ElectricCyan.copy(alpha = 0.7f),
                            radius = 6f,
                            center = point
                        )
                    }
                }
            }

            // 5. Draw slingshot rubber bands behind the bird
            if (state.isDragging) {
                drawLine(
                    color = NeonPink,
                    start = hookLeft,
                    end = Offset(state.birdPos.x, state.birdPos.y),
                    strokeWidth = 8f
                )
            }

            // 6. Draw the Bird (Hero Character circular face)
            val birdRadius = state.birdRadius
            val birdCenter = Offset(state.birdPos.x, state.birdPos.y)
            
            if (heroBitmap != null) {
                val heroImage = heroBitmap.asImageBitmap()
                drawContext.canvas.save()
                
                // Draw glow behind bird
                drawCircle(
                    color = ElectricCyan.copy(alpha = 0.3f),
                    radius = birdRadius + 8f,
                    center = birdCenter
                )

                // Clip to circular region to draw avatar
                val circleClip = Path().apply {
                    addOval(Rect(birdCenter.x - birdRadius, birdCenter.y - birdRadius, birdCenter.x + birdRadius, birdCenter.y + birdRadius))
                }
                clipPath(circleClip) {
                    drawImage(
                        image = heroImage,
                        dstOffset = IntOffset((birdCenter.x - birdRadius).toInt(), (birdCenter.y - birdRadius).toInt()),
                        dstSize = IntSize((birdRadius * 2).toInt(), (birdRadius * 2).toInt())
                    )
                }
                
                drawContext.canvas.restore()
                
                // Outer cyan circle border
                drawCircle(
                    color = ElectricCyan,
                    radius = birdRadius,
                    center = birdCenter,
                    style = Stroke(width = 2.dp.toPx())
                )
            } else {
                // Fallback circle if bitmap null
                drawCircle(color = ElectricCyan, radius = birdRadius, center = birdCenter)
            }

            // 7. Draw front rubber band
            if (state.isDragging) {
                drawLine(
                    color = NeonPink,
                    start = hookRight,
                    end = Offset(state.birdPos.x, state.birdPos.y),
                    strokeWidth = 8f
                )
            }

            // 8. Draw structural Block obstacles
            for (block in state.blocks) {
                if (block.isDestroyed) continue
                
                // Wooden / Glass blocks
                drawRoundRect(
                    color = block.color,
                    topLeft = Offset(block.left, block.top),
                    size = Size(block.width, block.height),
                    cornerRadius = CornerRadius(8f, 8f),
                    style = if (block.isGlass) Stroke(width = 2.dp.toPx()) else androidx.compose.ui.graphics.drawscope.Fill
                )
                
                // Highlight inside glass block
                if (block.isGlass) {
                    drawRect(
                        color = ElectricCyan.copy(alpha = 0.2f),
                        topLeft = Offset(block.left, block.top),
                        size = Size(block.width, block.height)
                    )
                }
            }

            // 9. Draw Targets (Enemies with circular face)
            for (target in state.targets) {
                if (target.isDestroyed) continue
                
                val targetCenter = Offset(target.pos.x, target.pos.y)
                val targetRadius = target.radius
                
                if (targetBitmap != null) {
                    val targetImage = targetBitmap.asImageBitmap()
                    drawContext.canvas.save()

                    // Glow behind target
                    drawCircle(
                        color = NeonPink.copy(alpha = 0.3f),
                        radius = targetRadius + 6f,
                        center = targetCenter
                    )

                    val circleClip = Path().apply {
                        addOval(Rect(targetCenter.x - targetRadius, targetCenter.y - targetRadius, targetCenter.x + targetRadius, targetCenter.y + targetRadius))
                    }
                    clipPath(circleClip) {
                        drawImage(
                            image = targetImage,
                            dstOffset = IntOffset((targetCenter.x - targetRadius).toInt(), (targetCenter.y - targetRadius).toInt()),
                            dstSize = IntSize((targetRadius * 2).toInt(), (targetRadius * 2).toInt())
                        )
                    }
                    
                    drawContext.canvas.restore()

                    // Outer pink border
                    drawCircle(
                        color = NeonPink,
                        radius = targetRadius,
                        center = targetCenter,
                        style = Stroke(width = 2.dp.toPx())
                    )
                } else {
                    // Fallback
                    drawCircle(color = NeonPink, radius = targetRadius, center = targetCenter)
                }
            }

            // 10. Draw Explosion Particles
            for (p in state.particles) {
                drawCircle(
                    color = p.color.copy(alpha = p.alpha),
                    radius = p.size * p.alpha,
                    center = Offset(p.pos.x, p.pos.y)
                )
            }

            drawContext.canvas.restore()
        }
    }
}
