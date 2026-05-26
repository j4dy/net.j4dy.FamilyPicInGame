package net.j4dy.familypicingame.games.slingshot

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import net.j4dy.familypicingame.games.common.Vector2D
import net.j4dy.familypicingame.model.FaceProfile
import net.j4dy.familypicingame.ui.theme.NeonPink
import java.util.Random

// Represents explosion particle effects
data class PhysicsParticle(
    var pos: Vector2D,
    var vel: Vector2D,
    val color: Color,
    var alpha: Float = 1f,
    var size: Float = 8f,
    var age: Int = 0,
    val maxAge: Int = 30
)

data class TargetObstacle(
    val id: String,
    var pos: Vector2D,
    var vel: Vector2D = Vector2D(0f, 0f),
    val radius: Float = 45f,
    val profile: FaceProfile,
    var isDestroyed: Boolean = false,
    var hitPoints: Int = 1
)

data class BlockObstacle(
    val id: String,
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
    val color: Color,
    var isDestroyed: Boolean = false,
    val isGlass: Boolean = false
)

class SlingshotGameState(
    val heroProfile: FaceProfile,
    val targetProfile: FaceProfile
) {
    // Slingshot anchor (moved further from left edge to allow more pulling room)
    val slingAnchor = Vector2D(280f, 460f)
    val maxDragDist = 120f
    
    // Game entities
    var birdPos by mutableStateOf(slingAnchor)
    var birdVel by mutableStateOf(Vector2D(0f, 0f))
    val birdRadius = 38f
    
    // Playing states
    var isDragging by mutableStateOf(false)
    var isFlying by mutableStateOf(false)
    var shotsLeft by mutableStateOf(3)
    var score by mutableStateOf(0)
    var gameStateMessage by mutableStateOf("Pull back to launch!")
    var screenShake by mutableStateOf(0f)

    // Lists of objects
    var targets = mutableListOf<TargetObstacle>()
    var blocks = mutableListOf<BlockObstacle>()
    var particles = mutableListOf<PhysicsParticle>()

    // Level dimensions (assumed standard viewport size for physics scale, say 1280x720)
    val gravity = Vector2D(0f, 0.45f)
    val bounceFactor = 0.4f
    
    private val random = Random()

    init {
        resetLevel()
    }

    fun resetLevel() {
        birdPos = slingAnchor
        birdVel = Vector2D(0f, 0f)
        isDragging = false
        isFlying = false
        shotsLeft = 3
        score = 0
        gameStateMessage = "Pull back the slingshot!"
        screenShake = 0f
        
        // Spawn 3 targets at landscape-spaced positions on the right
        targets = mutableListOf(
            TargetObstacle("t1", Vector2D(920f, 500f), profile = targetProfile),
            TargetObstacle("t2", Vector2D(1080f, 500f), profile = targetProfile),
            TargetObstacle("t3", Vector2D(1000f, 320f), profile = targetProfile)
        )

        // Wooden/glass defensive structures (AABB blocks)
        blocks = mutableListOf(
            // Vertical pillars
            BlockObstacle("b1", 870f, 440f, 30f, 120f, Color(0xFFC68B59)), // Wood pillar left
            BlockObstacle("b2", 970f, 440f, 30f, 120f, Color(0xFFC68B59)), // Wood pillar right
            BlockObstacle("b3", 1030f, 440f, 30f, 120f, Color(0xFFC68B59)), 
            BlockObstacle("b4", 1130f, 440f, 30f, 120f, Color(0xFFC68B59)), 
            
            // Roof planks
            BlockObstacle("b5", 860f, 410f, 150f, 30f, Color(0xCC00F5FF), isGlass = true), // Glass ceiling
            BlockObstacle("b6", 1020f, 410f, 150f, 30f, Color(0xCC00F5FF), isGlass = true)
        )
        
        particles = mutableListOf()
    }

    /**
     * Handles dragging of the bird.
     */
    fun onDrag(dragPos: Offset) {
        if (isFlying) return
        isDragging = true
        val dragVec = Vector2D(dragPos.x, dragPos.y)
        val offset = dragVec - slingAnchor
        
        // Limit drag length
        birdPos = slingAnchor + offset.limit(maxDragDist)
    }

    /**
     * Releases the bird, launching it.
     */
    fun onRelease() {
        if (isFlying || !isDragging) return
        isDragging = false
        isFlying = true
        
        // Velocity proportional to inverse drag displacement
        val dragOffset = slingAnchor - birdPos
        birdVel = dragOffset * 0.85f // flight intensity scalar (5.3x current speed)
        
        gameStateMessage = "Flying!"
    }

    /**
     * Physics frame tick.
     */
    fun update() {
        // Handle screen shake decay
        if (screenShake > 0) {
            screenShake *= 0.85f
            if (screenShake < 0.2f) screenShake = 0f
        }

        // 1. Update particles
        val pIterator = particles.iterator()
        while (pIterator.hasNext()) {
            val p = pIterator.next()
            p.pos = p.pos + p.vel
            p.age++
            p.alpha = 1f - (p.age.toFloat() / p.maxAge.toFloat())
            if (p.age >= p.maxAge) {
                pIterator.remove()
            }
        }

        // 2. Update bird flight
        if (isFlying) {
            // Apply gravity
            birdVel = birdVel + gravity
            birdPos = birdPos + birdVel
            
            // Wall collisions (bounce/destroy boundaries)
            // Ceiling boundary
            if (birdPos.y - birdRadius < 0) {
                birdPos = Vector2D(birdPos.x, birdRadius)
                birdVel = Vector2D(birdVel.x, -birdVel.y * bounceFactor)
            }
            
            // Ground bounce
            val groundY = 560f
            if (birdPos.y + birdRadius > groundY) {
                birdPos = Vector2D(birdPos.x, groundY - birdRadius)
                birdVel = Vector2D(birdVel.x * 0.8f, -birdVel.y * bounceFactor)
                
                // If velocity drops, end the flight
                if (Math.abs(birdVel.y) < 0.6f && Math.abs(birdVel.x) < 0.6f) {
                    endFlight()
                }
            }

            // Right border limit
            if (birdPos.x + birdRadius > 1280f || birdPos.x - birdRadius < 0f) {
                endFlight()
            }

            // 3. Collision with Blocks (rectangles)
            for (block in blocks) {
                if (block.isDestroyed) continue
                
                if (circleCollidesWithRect(birdPos, birdRadius, block)) {
                    // Destroy block!
                    block.isDestroyed = true
                    score += if (block.isGlass) 50 else 100
                    screenShake += 8f
                    
                    // Spawn particles
                    spawnExplosion(
                        center = Vector2D(block.left + block.width/2, block.top + block.height/2),
                        color = if (block.isGlass) Color(0xCC00F5FF) else Color(0xFFC68B59),
                        count = 12
                    )

                    // Bounce bird slightly
                    birdVel = Vector2D(-birdVel.x * 0.6f, -birdVel.y * 0.6f)
                }
            }

            // 4. Collision with Targets (circles)
            for (target in targets) {
                if (target.isDestroyed) continue
                
                val dist = birdPos.distance(target.pos)
                if (dist < birdRadius + target.radius) {
                    // Bounce / destroy target
                    target.isDestroyed = true
                    score += 200
                    screenShake += 16f
                    
                    // Explode!
                    spawnExplosion(target.pos, NeonPink, count = 25)
                    
                    // Bounce bird off target
                    val normal = (birdPos - target.pos).normalize()
                    birdVel = normal * (birdVel.length() * 0.8f)
                }
            }
        }

        // Check victory / defeat conditions
        checkGameStatus()
    }

    private fun endFlight() {
        isFlying = false
        birdPos = slingAnchor
        birdVel = Vector2D(0f, 0f)
        shotsLeft--
        if (shotsLeft > 0) {
            gameStateMessage = "Shots remaining: $shotsLeft! Aim carefully!"
        }
    }

    private fun checkGameStatus() {
        val allDestroyed = targets.all { it.isDestroyed }
        if (allDestroyed) {
            gameStateMessage = "VICTORY! All targets defeated! Score: $score"
            isFlying = false
        } else if (shotsLeft <= 0 && !isFlying) {
            gameStateMessage = "GAME OVER! Tap Reset to retry!"
        }
    }

    private fun circleCollidesWithRect(circle: Vector2D, radius: Float, rect: BlockObstacle): Boolean {
        // Find closest point on rectangle to circle center
        val closestX = Math.max(rect.left, Math.min(circle.x, rect.left + rect.width))
        val closestY = Math.max(rect.top, Math.min(circle.y, rect.top + rect.height))
        
        val distanceX = circle.x - closestX
        val distanceY = circle.y - closestY
        
        val distanceSquared = distanceX * distanceX + distanceY * distanceY
        return distanceSquared < radius * radius
    }

    private fun spawnExplosion(center: Vector2D, color: Color, count: Int) {
        for (i in 0 until count) {
            val angle = random.nextFloat() * 2 * Math.PI
            val speed = 2f + random.nextFloat() * 6f
            val vel = Vector2D(
                (Math.cos(angle) * speed).toFloat(),
                (Math.sin(angle) * speed).toFloat()
            )
            particles.add(
                PhysicsParticle(
                    pos = center,
                    vel = vel,
                    color = color,
                    size = 5f + random.nextFloat() * 10f,
                    maxAge = 20 + random.nextInt(20)
                )
            )
        }
    }

    /**
     * Calculates future flight points to show trajectory dotted line
     */
    fun getTrajectoryPoints(): List<Offset> {
        val points = mutableListOf<Offset>()
        if (!isDragging) return points
        
        var tempPos = birdPos
        val dragOffset = slingAnchor - birdPos
        var tempVel = dragOffset * 0.16f
        
        // Project 30 ticks forward
        for (i in 0 until 30) {
            tempVel += gravity
            tempPos += tempVel
            points.add(Offset(tempPos.x, tempPos.y))
            
            // Ground intersection stops projection
            if (tempPos.y > 560f) break
        }
        return points
    }
}
