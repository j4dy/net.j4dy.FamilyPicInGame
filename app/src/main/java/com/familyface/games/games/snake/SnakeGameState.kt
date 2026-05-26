package com.familyface.games.games.snake

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.familyface.games.games.common.Vector2D
import com.familyface.games.model.FaceProfile
import java.util.Random

enum class SnakeDirection {
    UP, DOWN, LEFT, RIGHT
}

data class SparkleParticle(
    val gridPos: Vector2D,
    var offset: Vector2D,
    var speed: Vector2D,
    var alpha: Float = 1f,
    var age: Int = 0,
    val maxAge: Int = 15
)

class SnakeGameState(
    val headProfile: FaceProfile,
    val foodProfile: FaceProfile,
    val allProfiles: List<FaceProfile>
) {
    // Grid settings
    val gridWidth = 18
    val gridHeight = 22

    // Game states (Observable Compose state list)
    val snake = mutableStateListOf<Vector2D>()
    var direction by mutableStateOf(SnakeDirection.RIGHT)
    var nextDirection = SnakeDirection.RIGHT
    var foodPos by mutableStateOf(Vector2D(12f, 10f))
    var score by mutableStateOf(0)
    var isGameOver by mutableStateOf(false)
    var gameMessage by mutableStateOf("Swipe or tap controls to turn!")
    
    // Sparkles when snake eats food
    val sparkles = mutableStateListOf<SparkleParticle>()

    private val random = Random()

    init {
        resetGame()
    }

    fun resetGame() {
        snake.clear()
        snake.addAll(listOf(
            Vector2D(5f, 10f),
            Vector2D(4f, 10f),
            Vector2D(3f, 10f)
        ))
        direction = SnakeDirection.RIGHT
        nextDirection = SnakeDirection.RIGHT
        score = 0
        isGameOver = false
        gameMessage = "Chomp the family food!"
        sparkles.clear()
        spawnFood()
    }

    fun spawnFood() {
        var attempts = 0
        var newFood: Vector2D
        do {
            newFood = Vector2D(
                random.nextInt(gridWidth).toFloat(),
                random.nextInt(gridHeight).toFloat()
            )
            attempts++
        } while (snake.contains(newFood) && attempts < 100)
        foodPos = newFood
    }

    fun setSnakeDirection(dir: SnakeDirection) {
        // Prevent turning 180 degrees directly
        if (dir == SnakeDirection.UP && direction == SnakeDirection.DOWN) return
        if (dir == SnakeDirection.DOWN && direction == SnakeDirection.UP) return
        if (dir == SnakeDirection.LEFT && direction == SnakeDirection.RIGHT) return
        if (dir == SnakeDirection.RIGHT && direction == SnakeDirection.LEFT) return
        nextDirection = dir
    }

    /**
     * Performs a single step movement tick of the snake.
     */
    fun tick() {
        if (isGameOver) return

        // Update active direction
        direction = nextDirection

        // Calculate new head position
        val head = snake.first()
        val nextHead = when (direction) {
            SnakeDirection.UP -> Vector2D(head.x, head.y - 1)
            SnakeDirection.DOWN -> Vector2D(head.x, head.y + 1)
            SnakeDirection.LEFT -> Vector2D(head.x - 1, head.y)
            SnakeDirection.RIGHT -> Vector2D(head.x + 1, head.y)
        }

        // Check boundary collisions
        if (nextHead.x < 0 || nextHead.x >= gridWidth || nextHead.y < 0 || nextHead.y >= gridHeight) {
            isGameOver = true
            gameMessage = "Ouch! Crashed into the border! Score: $score"
            return
        }

        // Check self-collision (excluding tail if it's going to move, but standard is checking body)
        if (snake.contains(nextHead)) {
            isGameOver = true
            gameMessage = "Oops! Ate your own tail! Score: $score"
            return
        }

        // Insert new head
        snake.add(0, nextHead)

        // Check food collision
        if (nextHead == foodPos) {
            // Eat food! Grow, add score, spawn new food
            score += 150
            gameMessage = "Delicious! Score: $score"
            spawnSparkles(nextHead)
            spawnFood()
        } else {
            // Remove tail to maintain size
            if (snake.size > 0) {
                snake.removeAt(snake.size - 1)
            }
        }

        // Update sparkles particles
        val sIterator = sparkles.iterator()
        while (sIterator.hasNext()) {
            val s = sIterator.next()
            s.offset = s.offset + s.speed
            s.age++
            s.alpha = 1f - (s.age.toFloat() / s.maxAge.toFloat())
            if (s.age >= s.maxAge) {
                sIterator.remove()
            }
        }
    }

    private fun spawnSparkles(pos: Vector2D) {
        for (i in 0 until 15) {
            val angle = random.nextFloat() * 2 * Math.PI
            val speedScalar = 1f + random.nextFloat() * 4f
            val speed = Vector2D(
                (Math.cos(angle) * speedScalar).toFloat(),
                (Math.sin(angle) * speedScalar).toFloat()
            )
            sparkles.add(
                SparkleParticle(
                    gridPos = pos,
                    offset = Vector2D(0f, 0f),
                    speed = speed,
                    maxAge = 10 + random.nextInt(10)
                )
            )
        }
    }

    /**
     * Helper to get an alternating face profile for a specific body segment index
     * so that the snake body displays a funny progression of all other configured family members!
     */
    fun getProfileForSegment(index: Int): FaceProfile {
        if (index == 0) return headProfile
        
        // Filter profiles that are not the head
        val bodyPool = allProfiles.filter { it.id != headProfile.id }
        if (bodyPool.isEmpty()) return headProfile
        
        // Return alternating profile from the pool
        val poolIndex = (index - 1) % bodyPool.size
        return bodyPool[poolIndex]
    }
}
