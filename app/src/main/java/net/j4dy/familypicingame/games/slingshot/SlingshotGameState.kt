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
    var top: Float, // var so they can fall!
    val width: Float,
    val height: Float,
    val color: Color,
    var isDestroyed: Boolean = false,
    val isGlass: Boolean = false,
    var velY: Float = 0f,     // vertical velocity for falling physics
    var velX: Float = 0f,     // horizontal velocity for sliding/toppling
    var rotation: Float = 0f, // rotation angle in degrees
    var velRot: Float = 0f,   // rotational velocity in degrees/frame
    var xOffset: Float = 0f   // horizontal displacement offset
)

class SlingshotGameState(
    val heroProfile: FaceProfile,
    val targetProfile: FaceProfile
) {
    // Slingshot anchor
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

    // Level progression
    var currentLevel by mutableStateOf(1)
    val maxLevels = 3

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

    fun nextLevel() {
        if (currentLevel < maxLevels) {
            currentLevel++
            resetLevel()
        }
    }

    fun resetLevel() {
        birdPos = slingAnchor
        birdVel = Vector2D(0f, 0f)
        isDragging = false
        isFlying = false
        shotsLeft = 3
        score = 0
        gameStateMessage = "Level $currentLevel: Aim carefully!"
        screenShake = 0f
        particles = mutableListOf()
        
        when (currentLevel) {
            1 -> {
                // Level 1: Original Twin Towers
                targets = mutableListOf(
                    TargetObstacle("t1", Vector2D(920f, 500f), profile = targetProfile),
                    TargetObstacle("t2", Vector2D(1080f, 500f), profile = targetProfile),
                    TargetObstacle("t3", Vector2D(1000f, 320f), profile = targetProfile)
                )
                blocks = mutableListOf(
                    // Vertical wooden pillars
                    BlockObstacle("b1", 870f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b2", 970f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b3", 1030f, 440f, 30f, 120f, Color(0xFFC68B59)), 
                    BlockObstacle("b4", 1130f, 440f, 30f, 120f, Color(0xFFC68B59)), 
                    // Glass ceilings
                    BlockObstacle("b5", 860f, 410f, 150f, 30f, Color(0xCC00F5FF), isGlass = true),
                    BlockObstacle("b6", 1020f, 410f, 150f, 30f, Color(0xCC00F5FF), isGlass = true)
                )
            }
            2 -> {
                // Level 2: The Pyramid Arch (tunnel protecting targets underneath)
                targets = mutableListOf(
                    TargetObstacle("t1", Vector2D(900f, 515f), profile = targetProfile),
                    TargetObstacle("t2", Vector2D(1060f, 515f), profile = targetProfile),
                    TargetObstacle("t3", Vector2D(980f, 400f), profile = targetProfile)
                )
                blocks = mutableListOf(
                    // Lower vertical pillars
                    BlockObstacle("b1", 830f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b2", 940f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b3", 1020f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b4", 1130f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    // Mid level glass floors
                    BlockObstacle("b5", 820f, 410f, 160f, 30f, Color(0xCC00F5FF), isGlass = true),
                    BlockObstacle("b6", 1010f, 410f, 160f, 30f, Color(0xCC00F5FF), isGlass = true),
                    // Second story vertical pillars
                    BlockObstacle("b7", 900f, 290f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b8", 1050f, 290f, 30f, 120f, Color(0xFFC68B59)),
                    // Top roof horizontal plank
                    BlockObstacle("b9", 880f, 260f, 220f, 30f, Color(0xFFC68B59))
                )
            }
            3 -> {
                // Level 3: The Multi-Layer Fort
                targets = mutableListOf(
                    TargetObstacle("t1", Vector2D(880f, 515f), profile = targetProfile),
                    TargetObstacle("t2", Vector2D(980f, 515f), profile = targetProfile),
                    TargetObstacle("t3", Vector2D(1080f, 515f), profile = targetProfile),
                    TargetObstacle("t4", Vector2D(980f, 320f), profile = targetProfile)
                )
                blocks = mutableListOf(
                    // Outer glass columns
                    BlockObstacle("b1", 800f, 440f, 30f, 120f, Color(0xCC00F5FF), isGlass = true),
                    BlockObstacle("b2", 1140f, 440f, 30f, 120f, Color(0xCC00F5FF), isGlass = true),
                    // Inner wooden pillars
                    BlockObstacle("b3", 900f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    BlockObstacle("b4", 1040f, 440f, 30f, 120f, Color(0xFFC68B59)),
                    // Mid roof platform
                    BlockObstacle("b5", 880f, 410f, 200f, 30f, Color(0xFFC68B59)),
                    // Top story columns
                    BlockObstacle("b6", 930f, 290f, 30f, 120f, Color(0xCC00F5FF), isGlass = true),
                    BlockObstacle("b7", 1010f, 290f, 30f, 120f, Color(0xCC00F5FF), isGlass = true),
                    // Topmost heavy roof
                    BlockObstacle("b8", 910f, 260f, 150f, 30f, Color(0xFFC68B59))
                )
            }
        }
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
        
        val dragOffset = slingAnchor - birdPos
        birdVel = dragOffset * 0.85f
        
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

        // 2. Update block gravity & toppling slide-rotation physics
        val groundY = 560f
        for (b in blocks) {
            if (b.isDestroyed) continue
            
            // Check supports underneath block
            val supports = mutableListOf<Pair<Float, Float>>()
            var restingOnGround = false
            
            if (b.top + b.height >= groundY - 4f) {
                restingOnGround = true
            } else {
                for (other in blocks) {
                    if (other === b || other.isDestroyed) continue
                    
                    val bLeft = b.left + b.xOffset
                    val otherLeft = other.left + other.xOffset
                    val hOverlap = bLeft < otherLeft + other.width && bLeft + b.width > otherLeft
                    
                    if (hOverlap) {
                        val verticalDist = other.top - (b.top + b.height)
                        if (verticalDist in -5f..6f && b.velY >= 0f) {
                            val contactMin = Math.max(bLeft, otherLeft)
                            val contactMax = Math.min(bLeft + b.width, otherLeft + other.width)
                            supports.add(Pair(contactMin, contactMax))
                        }
                    }
                }
            }
            
            if (restingOnGround) {
                b.top = groundY - b.height
                b.velY = 0f
                b.velX = 0f
                b.velRot = 0f
                b.rotation = 0f
            } else if (supports.isEmpty()) {
                // Free fall
                b.velY += 0.45f
                b.top += b.velY
                
                b.rotation += b.velRot
                b.xOffset += b.velX
            } else {
                // Supported - solve balanced pivot / toppling torque
                b.velY = 0f
                val center = (b.left + b.xOffset) + b.width / 2f
                
                if (supports.size == 1) {
                    val contact = supports[0]
                    if (center < contact.first) {
                        // Unstable - topple to the left
                        b.velRot -= 0.6f
                        b.velX -= 0.3f
                        b.rotation += b.velRot
                        b.xOffset += b.velX
                        b.top += 0.8f // tilt downwards dip
                    } else if (center > contact.second) {
                        // Unstable - topple to the right
                        b.velRot += 0.6f
                        b.velX += 0.3f
                        b.rotation += b.velRot
                        b.xOffset += b.velX
                        b.top += 0.8f
                    } else {
                        // Stable balanced
                        b.velX = 0f
                        b.velRot = 0f
                        b.rotation = 0f
                    }
                } else {
                    // Multiple supports
                    val leftmost = supports.map { it.first }.minOrNull() ?: (b.left + b.xOffset)
                    val rightmost = supports.map { it.second }.maxOrNull() ?: (b.left + b.xOffset + b.width)
                    
                    if (center < leftmost) {
                        b.velRot -= 0.6f
                        b.velX -= 0.3f
                        b.rotation += b.velRot
                        b.xOffset += b.velX
                        b.top += 0.8f
                    } else if (center > rightmost) {
                        b.velRot += 0.6f
                        b.velX += 0.3f
                        b.rotation += b.velRot
                        b.xOffset += b.velX
                        b.top += 0.8f
                    } else {
                        // Stable spanning supports
                        b.velX = 0f
                        b.velRot = 0f
                        b.rotation = 0f
                    }
                }
            }
        }

        // 3. Falling/Toppling blocks squashing targets underneath them
        for (block in blocks) {
            if (block.isDestroyed || (Math.abs(block.velY) < 1.0f && Math.abs(block.velX) < 1.0f && Math.abs(block.velRot) < 1.0f)) continue
            for (target in targets) {
                if (target.isDestroyed) continue
                
                val blockLeft = block.left + block.xOffset
                val closestX = Math.max(blockLeft, Math.min(target.pos.x, blockLeft + block.width))
                val closestY = Math.max(block.top, Math.min(target.pos.y, block.top + block.height))
                val distanceSquared = (target.pos.x - closestX) * (target.pos.x - closestX) + (target.pos.y - closestY) * (target.pos.y - closestY)
                
                if (distanceSquared < target.radius * target.radius) {
                    target.isDestroyed = true
                    score += 200
                    screenShake += 10f
                    spawnExplosion(target.pos, NeonPink, count = 20)
                }
            }
        }

        // 4. Update bird flight and collisions
        if (isFlying) {
            birdVel = birdVel + gravity
            birdPos = birdPos + birdVel
            
            // Wall collisions
            if (birdPos.y - birdRadius < 0) {
                birdPos = Vector2D(birdPos.x, birdRadius)
                birdVel = Vector2D(birdVel.x, -birdVel.y * bounceFactor)
            }
            
            // Ground bounce
            if (birdPos.y + birdRadius > groundY) {
                birdPos = Vector2D(birdPos.x, groundY - birdRadius)
                birdVel = Vector2D(birdVel.x * 0.8f, -birdVel.y * bounceFactor)
                
                if (Math.abs(birdVel.y) < 0.6f && Math.abs(birdVel.x) < 0.6f) {
                    endFlight()
                }
            }

            // Right/Left border limit
            if (birdPos.x + birdRadius > 1280f || birdPos.x - birdRadius < 0f) {
                endFlight()
            }

            // Collision with Blocks (rectangles)
            for (block in blocks) {
                if (block.isDestroyed) continue
                
                val blockLeft = block.left + block.xOffset
                val closestX = Math.max(blockLeft, Math.min(birdPos.x, blockLeft + block.width))
                val closestY = Math.max(block.top, Math.min(birdPos.y, block.top + block.height))
                val distanceSquared = (birdPos.x - closestX) * (birdPos.x - closestX) + (birdPos.y - closestY) * (birdPos.y - closestY)
                
                if (distanceSquared < birdRadius * birdRadius) {
                    block.isDestroyed = true
                    score += if (block.isGlass) 50 else 100
                    screenShake += 8f
                    
                    spawnExplosion(
                        center = Vector2D(blockLeft + block.width/2, block.top + block.height/2),
                        color = if (block.isGlass) Color(0xCC00F5FF) else Color(0xFFC68B59),
                        count = 12
                    )

                    val normal = Vector2D(birdPos.x - closestX, birdPos.y - closestY)
                    val unitNormal = if (normal.length() > 0.1f) normal.normalize() else Vector2D(0f, -1f)
                    
                    val dot = birdVel.dot(unitNormal)
                    val reflectedVel = birdVel - unitNormal * (2f * dot)
                    
                    val speedLoss = if (block.isGlass) 0.9f else 0.8f
                    birdVel = (birdVel * 0.8f + reflectedVel * 0.2f) * speedLoss
                }
            }

            // Collision with Targets (circles)
            for (target in targets) {
                if (target.isDestroyed) continue
                
                val dist = birdPos.distance(target.pos)
                if (dist < birdRadius + target.radius) {
                    target.isDestroyed = true
                    score += 200
                    screenShake += 16f
                    
                    spawnExplosion(target.pos, NeonPink, count = 25)
                    
                    val normal = (birdPos - target.pos).normalize()
                    birdVel = normal * (birdVel.length() * 0.8f)
                }
            }
        }

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
            gameStateMessage = if (currentLevel < maxLevels) {
                "VICTORY! All targets defeated in Level $currentLevel!"
            } else {
                "CONGRATULATIONS! Game completed! Score: $score"
            }
            isFlying = false
        } else if (shotsLeft <= 0 && !isFlying) {
            gameStateMessage = "GAME OVER! Tap Reset to retry!"
        }
    }

    private fun circleCollidesWithRect(circle: Vector2D, radius: Float, rect: BlockObstacle): Boolean {
        val blockLeft = rect.left + rect.xOffset
        val closestX = Math.max(blockLeft, Math.min(circle.x, blockLeft + rect.width))
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
        var tempVel = dragOffset * 0.85f
        
        for (i in 0 until 120) {
            tempVel = tempVel + gravity
            tempPos = tempPos + tempVel
            
            // Ceiling boundary check
            if (tempPos.y - birdRadius < 0f) {
                tempPos = Vector2D(tempPos.x, birdRadius)
                tempVel = Vector2D(tempVel.x, -tempVel.y * bounceFactor)
            }
            
            // Ground boundary check
            val groundY = 560f
            if (tempPos.y + birdRadius > groundY) {
                tempPos = Vector2D(tempPos.x, groundY - birdRadius)
                points.add(Offset(tempPos.x, tempPos.y))
                break
            }
            
            // Left/Right boundaries check
            if (tempPos.x + birdRadius > 1280f || tempPos.x - birdRadius < 0f) {
                points.add(Offset(tempPos.x, tempPos.y))
                break
            }
            
            points.add(Offset(tempPos.x, tempPos.y))
        }
        return points
    }
}
