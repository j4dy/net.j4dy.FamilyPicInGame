package net.j4dy.familypicingame.games.pacman

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import net.j4dy.familypicingame.model.FaceProfile
import kotlin.math.abs
import kotlin.random.Random

enum class PacmanDirection {
    UP, DOWN, LEFT, RIGHT, NONE
}

data class GridPos(val x: Int, val y: Int) {
    fun plus(dir: PacmanDirection) = when (dir) {
        PacmanDirection.UP -> GridPos(x, y - 1)
        PacmanDirection.DOWN -> GridPos(x, y + 1)
        PacmanDirection.LEFT -> GridPos(x - 1, y)
        PacmanDirection.RIGHT -> GridPos(x + 1, y)
        PacmanDirection.NONE -> this
    }
}

class GhostState(
    val id: String,
    val name: String,
    val profile: FaceProfile?,
    val colorIndex: Int, // 0: Red (Blinky), 1: Pink (Pinky), 2: Cyan (Inky), 3: Orange (Clyde)
    var currentPos: GridPos,
    var nextPos: GridPos,
    var dir: PacmanDirection = PacmanDirection.NONE,
    var isVulnerable: Boolean = false,
    var isEaten: Boolean = false
)

class PacmanSparkle(
    val offset: Offset,
    val text: String,
    var alpha: Float = 1.0f
)

class PacmanGameState(
    val playerProfile: FaceProfile,
    val ghostProfiles: List<FaceProfile>
) {
    // 15 cols by 19 rows
    val gridWidth = 15
    val gridHeight = 19

    val MAP = listOf(
        "###############", // 0
        "#......#......#", // 1
        "#.####.#.####.#", // 2
        "#o####.#.####o#", // 3
        "#.............#", // 4
        "#.####.#.####.#", // 5
        "#......#......#", // 6
        "######   ######", // 7 (Ghost house top gate)
        "     #   #     ", // 8 (Ghost house center)
        "######   ######", // 9 (Ghost house bottom gate)
        "#......#......#", // 10
        "#.####.#.####.#", // 11
        "#o..##...##..o#", // 12
        "###.##.#.##.###", // 13
        "#......#......#", // 14
        "#.###########.#", // 15
        " ............. ", // 16 (tunnels)
        "#............#", // 17
        "###############"  // 18
    )

    val board = mutableStateListOf<MutableList<Char>>()
    
    // Player state
    var playerCurrentPos by mutableStateOf(GridPos(7, 14))
    var playerNextPos by mutableStateOf(GridPos(7, 14))
    var playerDir by mutableStateOf(PacmanDirection.NONE)
    var playerNextDir by mutableStateOf(PacmanDirection.NONE)
    var moveProgress by mutableStateOf(0f) // 0f to 1f between grid cells
    
    // Ghost states
    val ghosts = mutableStateListOf<GhostState>()
    var ghostProgress by mutableStateOf(0f)
    
    // Game variables
    var score by mutableStateOf(0)
    var lives by mutableStateOf(3)
    var isPlaying by mutableStateOf(false)
    var isGameOver by mutableStateOf(false)
    var gameMessage by mutableStateOf("TAP START TO PLAY")
    var totalDots = 0
    var dotsEaten = 0
    var isVictory by mutableStateOf(false)
    
    // Power pellet states
    var frightenedTimer by mutableStateOf(0) // frames remaining of frightened state
    var ghostEatenMultiplier = 1
    
    // Sparkles
    val sparkles = mutableStateListOf<PacmanSparkle>()
    
    init {
        resetGame()
    }

    fun isWall(x: Int, y: Int): Boolean {
        if (y < 0 || y >= gridHeight) return true
        val wrappedX = (x + gridWidth) % gridWidth
        return MAP[y][wrappedX] == '#'
    }

    fun resetGame() {
        isPlaying = false
        isGameOver = false
        isVictory = false
        score = 0
        lives = 3
        dotsEaten = 0
        frightenedTimer = 0
        sparkles.clear()
        
        // Reset board grid and count dots
        board.clear()
        totalDots = 0
        for (y in 0 until gridHeight) {
            val rowList = mutableStateListOf<Char>()
            for (x in 0 until gridWidth) {
                val char = MAP[y][x]
                rowList.add(char)
                if (char == '.' || char == 'o') {
                    totalDots++
                }
            }
            board.add(rowList)
        }
        
        resetRoundPositions()
        gameMessage = "READY PLAYER ONE"
    }

    private fun resetRoundPositions() {
        playerCurrentPos = GridPos(7, 14)
        playerNextPos = GridPos(7, 14)
        playerDir = PacmanDirection.NONE
        playerNextDir = PacmanDirection.NONE
        moveProgress = 0f
        
        ghosts.clear()
        ghostProgress = 0f
        
        // Setup ghosts (Max 4). If profiles size < 4, we use null for remaining ghosts to render fallbacks.
        val ghostColors = listOf(0, 1, 2, 3) // Red, Pink, Cyan, Orange
        val spawnPoints = listOf(
            GridPos(6, 8), // Blinky
            GridPos(7, 8), // Pinky
            GridPos(8, 8), // Inky
            GridPos(7, 8)  // Clyde
        )
        
        for (i in 0..3) {
            val profile = if (i < ghostProfiles.size) ghostProfiles[i] else null
            val name = profile?.name ?: when(i) {
                0 -> "Blinky"
                1 -> "Pinky"
                2 -> "Inky"
                else -> "Clyde"
            }
            ghosts.add(
                GhostState(
                    id = profile?.id ?: "fallback_$i",
                    name = name,
                    profile = profile,
                    colorIndex = ghostColors[i],
                    currentPos = spawnPoints[i],
                    nextPos = spawnPoints[i],
                    dir = PacmanDirection.UP
                )
            )
        }
    }

    fun startGame() {
        isPlaying = true
        isGameOver = false
        isVictory = false
        gameMessage = "CHOMP THEM ALL!"
    }

    fun setPlayerDirection(dir: PacmanDirection) {
        if (!isPlaying || isGameOver) return
        playerNextDir = dir
        // If stopped, start moving immediately
        if (playerDir == PacmanDirection.NONE) {
            val next = playerCurrentPos.plus(dir)
            if (!isWall(next.x, next.y)) {
                playerDir = dir
                playerNextPos = wrapGridPos(next)
                moveProgress = 0f
            }
        }
    }

    private fun wrapGridPos(pos: GridPos): GridPos {
        val wrappedX = (pos.x + gridWidth) % gridWidth
        return GridPos(wrappedX, pos.y)
    }

    fun tickFrame() {
        if (!isPlaying || isGameOver || isVictory) return
        
        // 1. Tick power pellet frightened timer
        if (frightenedTimer > 0) {
            frightenedTimer--
            if (frightenedTimer == 0) {
                ghosts.forEach { it.isVulnerable = false }
                ghostEatenMultiplier = 1
            }
        }

        // 2. Tick sparkles
        val iterator = sparkles.iterator()
        while (iterator.hasNext()) {
            val s = iterator.next()
            s.alpha -= 0.04f
        }
        sparkles.removeAll { it.alpha <= 0f }

        // 3. Advance player movement (Smooth 60fps interpolation)
        val basePlayerSpeed = 0.08f // takes ~12 frames (200ms) to move 1 cell
        moveProgress += basePlayerSpeed
        if (moveProgress >= 1.0f) {
            moveProgress = 0f
            playerCurrentPos = playerNextPos
            
            // Eat dot at current position
            eatPellet(playerCurrentPos)

            // Calculate next step
            val nextWithBuffer = playerCurrentPos.plus(playerNextDir)
            if (!isWall(nextWithBuffer.x, nextWithBuffer.y)) {
                playerDir = playerNextDir
                playerNextPos = wrapGridPos(nextWithBuffer)
            } else {
                val nextWithCurrent = playerCurrentPos.plus(playerDir)
                if (!isWall(nextWithCurrent.x, nextWithCurrent.y)) {
                    playerNextPos = wrapGridPos(nextWithCurrent)
                } else {
                    playerDir = PacmanDirection.NONE
                    playerNextPos = playerCurrentPos
                }
            }
        }

        // 4. Advance ghost movement
        val baseGhostSpeed = if (frightenedTimer > 0) 0.04f else 0.07f // ghosts slower in vulnerable state
        ghostProgress += baseGhostSpeed
        if (ghostProgress >= 1.0f) {
            ghostProgress = 0f
            
            ghosts.forEach { ghost ->
                ghost.currentPos = ghost.nextPos
                
                // If ghost is eaten and reaches ghost house, revive it
                if (ghost.isEaten && ghost.currentPos == GridPos(7, 8)) {
                    ghost.isEaten = false
                    ghost.isVulnerable = false
                }

                // Determine target tile based on personality and state
                val target = getGhostTargetTile(ghost)
                
                // Get next direction
                val nextDir = getGhostNextDirection(ghost, target)
                ghost.dir = nextDir
                ghost.nextPos = wrapGridPos(ghost.currentPos.plus(nextDir))
            }
        }

        // 5. Check Collisions (in grid space, using closest current/next coordinates)
        checkCollisions()
    }

    private fun eatPellet(pos: GridPos) {
        val y = pos.y
        val x = pos.x
        if (y in 0 until gridHeight && x in 0 until gridWidth) {
            val item = board[y][x]
            if (item == '.') {
                board[y][x] = ' '
                score += 10
                dotsEaten++
                checkVictory()
            } else if (item == 'o') {
                board[y][x] = ' '
                score += 50
                dotsEaten++
                triggerPowerPellet()
                checkVictory()
            }
        }
    }

    private fun triggerPowerPellet() {
        frightenedTimer = 450 // stays up for 450 frames (~7.5 seconds)
        ghostEatenMultiplier = 1
        ghosts.forEach { ghost ->
            if (!ghost.isEaten) {
                ghost.isVulnerable = true
            }
        }
        gameMessage = "GHOSTS ARE VULNERABLE!"
    }

    private fun checkVictory() {
        if (dotsEaten >= totalDots) {
            isVictory = true
            isPlaying = false
            gameMessage = "VICTORY! Score: $score"
        }
    }

    private fun checkCollisions() {
        // Calculate interpolated coordinate offsets for collision check
        val pOffset = getInterpolatedGridOffset(playerCurrentPos, playerNextPos, moveProgress)
        
        ghosts.forEach { ghost ->
            val gOffset = getInterpolatedGridOffset(ghost.currentPos, ghost.nextPos, ghostProgress)
            val dist = pOffset.distance(gOffset)
            
            // Collide within 0.7 grid units
            if (dist < 0.7f) {
                if (ghost.isVulnerable && !ghost.isEaten) {
                    // Eat ghost!
                    ghost.isEaten = true
                    ghost.isVulnerable = false
                    val points = 200 * ghostEatenMultiplier
                    score += points
                    
                    // Spawn score float text
                    val drawX = gOffset.x * 40f // scaling helper
                    val drawY = gOffset.y * 40f
                    sparkles.add(PacmanSparkle(Offset(drawX, drawY), "+$points"))
                    
                    gameMessage = "ATE GHOST ${ghost.name}! +$points"
                    ghostEatenMultiplier = (ghostEatenMultiplier * 2).coerceAtMost(8)
                } else if (!ghost.isEaten && !ghost.isVulnerable) {
                    // Lose a life!
                    loseLife()
                }
            }
        }
    }

    private fun loseLife() {
        lives--
        if (lives <= 0) {
            isGameOver = true
            isPlaying = false
            gameMessage = "GAME OVER! Final Score: $score"
        } else {
            resetRoundPositions()
            gameMessage = "READY! Lives left: $lives"
        }
    }

    private fun getInterpolatedGridOffset(current: GridPos, next: GridPos, progress: Float): Vector2D {
        val diffX = next.x - current.x
        val diffY = next.y - current.y
        if (abs(diffX) > 1) { // Wrapping horizontally
            return if (current.x == 0 && next.x == gridWidth - 1) {
                Vector2D(0f - progress, current.y.toFloat())
            } else {
                Vector2D((gridWidth - 1).toFloat() + progress, current.y.toFloat())
            }
        }
        return Vector2D(current.x + diffX * progress, current.y + diffY * progress)
    }

    private fun getGhostTargetTile(ghost: GhostState): GridPos {
        if (ghost.isEaten) {
            return GridPos(7, 8) // Spawn center
        }
        if (ghost.isVulnerable) {
            // Flee randomly, handled inside direction finder
            return GridPos(0, 0)
        }

        // Distinct personalities
        return when (ghost.colorIndex) {
            0 -> { // Blinky (Red): Direct Chase
                playerCurrentPos
            }
            1 -> { // Pinky (Pink): Ambush (2 cells ahead of Pac-man)
                playerCurrentPos.plus(playerDir).plus(playerDir)
            }
            2 -> { // Inky (Cyan): Mirror vector from Pacman to Blinky
                val blinky = ghosts.firstOrNull { it.colorIndex == 0 }
                if (blinky != null) {
                    val pX = playerCurrentPos.x
                    val pY = playerCurrentPos.y
                    val bX = blinky.currentPos.x
                    val bY = blinky.currentPos.y
                    val targetX = pX + (pX - bX)
                    val targetY = pY + (pY - bY)
                    GridPos(targetX.coerceIn(0, gridWidth - 1), targetY.coerceIn(0, gridHeight - 1))
                } else {
                    playerCurrentPos
                }
            }
            else -> { // Clyde (Orange): Scatter if close, chase if far
                val dx = ghost.currentPos.x - playerCurrentPos.x
                val dy = ghost.currentPos.y - playerCurrentPos.y
                val distSq = dx * dx + dy * dy
                if (distSq > 16) {
                    playerCurrentPos
                } else {
                    GridPos(0, gridHeight - 1) // bottom left corner
                }
            }
        }
    }

    private fun getGhostNextDirection(ghost: GhostState, target: GridPos): PacmanDirection {
        val directions = listOf(PacmanDirection.UP, PacmanDirection.DOWN, PacmanDirection.LEFT, PacmanDirection.RIGHT)
        val validDirs = directions.filter { dir ->
            // Cannot reverse unless forced or stuck
            val isReverse = when (dir) {
                PacmanDirection.UP -> ghost.dir == PacmanDirection.DOWN
                PacmanDirection.DOWN -> ghost.dir == PacmanDirection.UP
                PacmanDirection.LEFT -> ghost.dir == PacmanDirection.RIGHT
                PacmanDirection.RIGHT -> ghost.dir == PacmanDirection.LEFT
                PacmanDirection.NONE -> false
            }
            if (isReverse) return@filter false
            val next = ghost.currentPos.plus(dir)
            !isWall(next.x, next.y)
        }

        if (validDirs.isEmpty()) {
            // Return reverse direction
            return when (ghost.dir) {
                PacmanDirection.UP -> PacmanDirection.DOWN
                PacmanDirection.DOWN -> PacmanDirection.UP
                PacmanDirection.LEFT -> PacmanDirection.RIGHT
                PacmanDirection.RIGHT -> PacmanDirection.LEFT
                PacmanDirection.NONE -> PacmanDirection.UP
            }
        }

        if (ghost.isVulnerable) {
            // Choose completely random valid direction
            return validDirs[Random.nextInt(validDirs.size)]
        }

        // Choose the direction closest to target Pos
        return validDirs.minByOrNull { dir ->
            val next = ghost.currentPos.plus(dir)
            val dx = next.x - target.x
            val dy = next.y - target.y
            dx * dx + dy * dy
        } ?: PacmanDirection.UP
    }
}

data class Vector2D(val x: Float, val y: Float) {
    fun distance(other: Vector2D): Float {
        val dx = x - other.x
        val dy = y - other.y
        return kotlin.math.sqrt(dx * dx + dy * dy)
    }
}
