package net.j4dy.familypicingame.games.whack

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import net.j4dy.familypicingame.model.FaceProfile
import kotlin.random.Random

enum class PortalType {
    EMPTY,
    MONSTER,
    FAMILY
}

class PortalState(
    val index: Int
) {
    var type by mutableStateOf(PortalType.EMPTY)
    var familyProfile by mutableStateOf<FaceProfile?>(null)
    var showTimeLeft by mutableStateOf(0) // frames it stays visible
}

class WhackSparkle(
    val index: Int,
    val offset: Offset,
    val text: String,
    val isPenalty: Boolean,
    var alpha: Float = 1.0f
)

class WhackGameState(
    val allProfiles: List<FaceProfile>
) {
    val portals = List(9) { PortalState(it) }
    val sparkles = mutableStateListOf<WhackSparkle>()
    
    var score by mutableStateOf(0)
    var comboMultiplier by mutableStateOf(1)
    var timeLeftSeconds by mutableStateOf(45)
    
    var isPlaying by mutableStateOf(false)
    var isGameOver by mutableStateOf(false)
    var gameMessage by mutableStateOf("TAP START TO WHACK")
    
    private val defaultRoundTime = 45
    private var framesSinceLastSpawn = 0
    
    // Scale speed as score gets higher
    private fun getSpawnInterval(): Int {
        return when {
            score > 5000 -> 30 // spawn every 30 frames (~500ms)
            score > 3000 -> 40
            score > 1000 -> 50
            else -> 60 // ~1s
        }
    }
    
    private fun getPortalDuration(): Int {
        return when {
            score > 5000 -> 45 // stays up for 750ms
            score > 3000 -> 60
            score > 1000 -> 75
            else -> 90 // stays up for 1.5s
        }
    }

    fun startGame() {
        isPlaying = true
        isGameOver = false
        score = 0
        comboMultiplier = 1
        timeLeftSeconds = defaultRoundTime
        sparkles.clear()
        framesSinceLastSpawn = 0
        portals.forEach {
            it.type = PortalType.EMPTY
            it.familyProfile = null
            it.showTimeLeft = 0
        }
        gameMessage = "Round Started! Go!"
    }

    fun resetGame() {
        isPlaying = false
        isGameOver = false
        score = 0
        comboMultiplier = 1
        timeLeftSeconds = defaultRoundTime
        sparkles.clear()
        portals.forEach {
            it.type = PortalType.EMPTY
            it.familyProfile = null
            it.showTimeLeft = 0
        }
        gameMessage = "TAP START TO WHACK"
    }

    fun tickSecond() {
        if (!isPlaying || isGameOver) return
        timeLeftSeconds--
        if (timeLeftSeconds <= 0) {
            endGame()
        }
    }

    fun tickFrame() {
        if (!isPlaying || isGameOver) return
        
        // 1. Tick existing portal durations
        portals.forEach { portal ->
            if (portal.type != PortalType.EMPTY) {
                portal.showTimeLeft--
                if (portal.showTimeLeft <= 0) {
                    // Reset to empty when time expires
                    portal.type = PortalType.EMPTY
                    portal.familyProfile = null
                }
            }
        }
        
        // 2. Spawn new characters randomly
        framesSinceLastSpawn++
        if (framesSinceLastSpawn >= getSpawnInterval()) {
            framesSinceLastSpawn = 0
            spawnRandomPortal()
        }
        
        // 3. Tick sparkles alpha decay
        val iterator = sparkles.iterator()
        while (iterator.hasNext()) {
            val sparkle = iterator.next()
            sparkle.alpha -= 0.05f
        }
        sparkles.removeAll { it.alpha <= 0f }
    }

    private fun spawnRandomPortal() {
        // Find empty portals
        val emptyPortals = portals.filter { it.type == PortalType.EMPTY }
        if (emptyPortals.isEmpty()) return
        
        // Select a random empty portal
        val portal = emptyPortals[Random.nextInt(emptyPortals.size)]
        
        // 70% chance of Monster, 30% chance of Family member
        val isFamily = Random.nextFloat() < 0.30f && allProfiles.isNotEmpty()
        
        if (isFamily) {
            portal.type = PortalType.FAMILY
            // Pick a random family member
            portal.familyProfile = allProfiles[Random.nextInt(allProfiles.size)]
        } else {
            portal.type = PortalType.MONSTER
            portal.familyProfile = null
        }
        
        portal.showTimeLeft = getPortalDuration()
    }

    fun whackCell(index: Int) {
        if (!isPlaying || isGameOver || index !in 0..8) return
        
        val portal = portals[index]
        when (portal.type) {
            PortalType.MONSTER -> {
                val points = 100 * comboMultiplier
                score += points
                comboMultiplier++
                
                // Add positive feedback sparkle
                sparkles.add(
                    WhackSparkle(
                        index = index,
                        offset = Offset(Random.nextFloat() * 40 - 20, -50f),
                        text = "+$points",
                        isPenalty = false
                    )
                )
                
                gameMessage = "HIT! Combo x$comboMultiplier"
                portal.type = PortalType.EMPTY
                portal.familyProfile = null
            }
            PortalType.FAMILY -> {
                // Tapping family member is a penalty
                val penalty = 200
                score = (score - penalty).coerceAtLeast(0)
                comboMultiplier = 1
                
                val familyName = portal.familyProfile?.name ?: "Family"
                // Add penalty feedback sparkle
                sparkles.add(
                    WhackSparkle(
                        index = index,
                        offset = Offset(Random.nextFloat() * 40 - 20, -50f),
                        text = "Don't tap $familyName! -$penalty",
                        isPenalty = true
                    )
                )
                
                gameMessage = "OW! That's $familyName!"
                portal.type = PortalType.EMPTY
                portal.familyProfile = null
            }
            PortalType.EMPTY -> {
                // Optional minor miss penalty
                comboMultiplier = 1
                gameMessage = "MISS!"
            }
        }
    }

    private fun endGame() {
        isGameOver = true
        isPlaying = false
        gameMessage = "TIME'S UP! Game Over!"
    }
}
