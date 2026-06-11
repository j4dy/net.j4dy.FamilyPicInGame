package net.j4dy.familypicingame.games.flappy

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import net.j4dy.familypicingame.model.FaceProfile
import kotlin.random.Random

class FlappyPipe(
    var x: Float,
    val topHeight: Float,
    val bottomHeight: Float,
    val width: Float = 140f,
    var passed: Boolean = false
)

enum class FlappyDifficulty(val displayName: String, val gapHeight: Float) {
    EASY("Space Cadet", 340f),
    MEDIUM("Pilot", 280f),
    HARD("Astronaut", 220f)
}

class FlappyGameState(
    val playerProfile: FaceProfile,
    val difficulty: FlappyDifficulty = FlappyDifficulty.HARD
) {
    var birdY by mutableStateOf(400f)
    var birdVelocity by mutableStateOf(0f)
    
    val pipes = mutableStateListOf<FlappyPipe>()
    
    var score by mutableStateOf(0)
    var isPlaying by mutableStateOf(false)
    var isGameOver by mutableStateOf(false)
    
    var gameMessage by mutableStateOf("TAP TO FLY")
    
    // Physics constants
    private val gravity = 0.5f
    private val jumpImpulse = -10f
    private val maxFallSpeed = 16f
    private val pipeSpeed = 6f
    private val pipeSpawnInterval = 100 // frames
    private var frameCount = 0

    fun startGame() {
        isPlaying = true
        isGameOver = false
        score = 0
        birdY = 350f
        birdVelocity = 0f
        pipes.clear()
        frameCount = 0
        gameMessage = "GO!"
    }

    fun flap() {
        if (isGameOver) {
            startGame()
            return
        }
        if (!isPlaying) {
            startGame()
        }
        birdVelocity = jumpImpulse
    }

    fun resetGame() {
        isPlaying = false
        isGameOver = false
        score = 0
        birdY = 400f
        birdVelocity = 0f
        pipes.clear()
        frameCount = 0
        gameMessage = "TAP TO FLY"
    }

    fun tick(canvasWidth: Float, canvasHeight: Float) {
        if (!isPlaying || isGameOver || canvasWidth <= 0 || canvasHeight <= 0) return
        
        // 1. Update physics
        birdVelocity = (birdVelocity + gravity).coerceIn(-12f, maxFallSpeed)
        birdY += birdVelocity
        
        // 2. Spawn pipes
        frameCount++
        if (frameCount % pipeSpawnInterval == 0 || pipes.isEmpty()) {
            spawnPipe(canvasWidth, canvasHeight)
        }
        
        // 3. Move pipes and check passing score
        val birdX = canvasWidth * 0.25f
        val birdRadius = 35f // collision radius of the face
        
        val iterator = pipes.iterator()
        while (iterator.hasNext()) {
            val pipe = iterator.next()
            pipe.x -= pipeSpeed
            
            // Check if pipe has been passed
            if (!pipe.passed && pipe.x + pipe.width < birdX) {
                pipe.passed = true
                score++
                gameMessage = when (score) {
                    5 -> "Nice flying!"
                    10 -> "Awesome!"
                    20 -> "Astronaut Status!"
                    else -> "Score: $score"
                }
            }
            
            // Remove off-screen pipes
            if (pipe.x + pipe.width < -100f) {
                // We will delete outside iteration to avoid concurrent exceptions,
                // but since it's a snapshot list we can clean it up after the loop or use a remove list
            }
        }
        
        // Clean up old pipes
        pipes.removeAll { it.x + it.width < -100f }
        
        // 4. Collision check
        // Check top and bottom boundaries
        if (birdY - birdRadius < 0f || birdY + birdRadius > canvasHeight) {
            endGame("Out of bounds!")
            return
        }
        
        // Check pipe collisions
        for (pipe in pipes) {
            // Horizontal overlap
            val withinX = birdX + birdRadius > pipe.x && birdX - birdRadius < pipe.x + pipe.width
            if (withinX) {
                // Vertical overlap with top pipe or bottom pipe
                val hitTop = birdY - birdRadius < pipe.topHeight
                val hitBottom = birdY + birdRadius > canvasHeight - pipe.bottomHeight
                if (hitTop || hitBottom) {
                    endGame("Ouch! Hit a pillar!")
                    return
                }
            }
        }
    }

    private fun spawnPipe(canvasWidth: Float, canvasHeight: Float) {
        // Gap size (adjust for difficulty)
        val gapHeight = difficulty.gapHeight
        val minHeight = 100f
        val maxHeight = canvasHeight - gapHeight - minHeight
        
        val topHeight = Random.nextFloat() * (maxHeight - minHeight) + minHeight
        val bottomHeight = canvasHeight - topHeight - gapHeight
        
        pipes.add(
            FlappyPipe(
                x = canvasWidth,
                topHeight = topHeight,
                bottomHeight = bottomHeight
            )
        )
    }

    private fun endGame(message: String) {
        isGameOver = true
        isPlaying = false
        gameMessage = "$message Game Over!"
    }
}
