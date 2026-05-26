package net.j4dy.familypicingame.games.common

data class Vector2D(val x: Float = 0f, val y: Float = 0f) {
    operator fun plus(other: Vector2D) = Vector2D(x + other.x, y + other.y)
    operator fun minus(other: Vector2D) = Vector2D(x - other.x, y - other.y)
    operator fun times(scalar: Float) = Vector2D(x * scalar, y * scalar)
    operator fun div(scalar: Float) = if (scalar != 0f) Vector2D(x / scalar, y / scalar) else Vector2D(0f, 0f)
    
    fun length() = Math.sqrt((x * x + y * y).toDouble()).toFloat()
    
    fun normalize(): Vector2D {
        val len = length()
        return if (len > 0f) this / len else Vector2D(0f, 0f)
    }
    
    fun dot(other: Vector2D) = x * other.x + y * other.y
    
    fun distance(other: Vector2D) = (this - other).length()
    
    fun limit(max: Float): Vector2D {
        val len = length()
        return if (len > max) this.normalize() * max else this
    }
}
