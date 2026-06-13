import 'dart:math' as math;

class Vector2D {
  final double x;
  final double y;

  const Vector2D(this.x, this.y);

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);
  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);
  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);
  Vector2D operator /(double scalar) => scalar != 0.0 ? Vector2D(x / scalar, y / scalar) : const Vector2D(0.0, 0.0);

  double length() => math.sqrt(x * x + y * y);

  Vector2D normalize() {
    final len = length();
    return len > 0.0 ? this / len : const Vector2D(0.0, 0.0);
  }

  double dot(Vector2D other) => x * other.x + y * other.y;

  double distance(Vector2D other) => (this - other).length();

  Vector2D limit(double max) {
    final len = length();
    return len > max ? normalize() * max : this;
  }
}
