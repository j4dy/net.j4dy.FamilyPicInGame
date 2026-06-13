# 🕹️ Game Features & Mechanics Guide

Each game inside the suite is rendered on a hardware-accelerated Flutter `CustomPaint` Canvas with separate tick loops and state models. Here are the core mechanics of each of the 5 games:

---

## ☄️ 1. Family Slingshot (Physics-Based)

Launch your family birds using an elastic slingshot to crash wood and glass fortifications and knock down target opponents:

* **Plow-Through Block Demolition**: Rather than bouncing directly backwards on impact, the bird continues forward when plowing through destroyed obstacle blocks. The physics engine contact contact normal splits velocity vector components:
  * Contact normal calculations reflect a minor portion of horizontal momentum: $v_{ref} = v - (1 + e)(v \cdot n)n$ (mixing 80% forward momentum with 20% reflected contact normal).
  * Wood blocks incur a 20% velocity decay, and Glass blocks incur a 10% velocity decay, allowing the bird to plow through multiple blocks in a single launch.
* **Falling Debris & Gravity**: Supporting obstacle blocks fall down realistically under gravity when pillars beneath them are destroyed, settling onto lower blocks. Falling debris travelling with high velocity inflicts impact damage on targets beneath them.
* **Elastic Neon Bands**: Cords connect the slingshot anchor to the bird as you pull back, drawing a dotted aim trajectory for 120 simulation frames.
* **Level Progression**: Includes 3 distinct levels ("Twin Towers", "Pyramid Arch", and "Multi-Layer Fort") with custom architectural layouts.

---

## 🐍 2. Family Nibbles (Snake Game)

Steer the snake head through a wrapping grid to collect food, accumulating family member faces in your body tail:

* **Portal Ripple Boundaries**: When the snake head touches a boundary wall, it wraps to the other side of the grid. Connector lines are hidden during wrap frames to prevent rendering cross-screen diagonals. Wraps are highlighted by dual-color ripples (Electric Cyan at exit, Neon Pink at entrance) alongside chomp particle spark bursts.
* **Alternating Family Body**: When food (representing a family member) is eaten, the tail grows and alternates its segments with the faces of all other characters saved in your Face Manager database.
* **Precision Controls**: Supports both fluid finger swipe-to-turn gestures on the Canvas grid, and a physical D-Pad dock overlay for high-precision turning.

---

## 🚀 3. Family Flappy Flight

Guide your rocket-capsule family astronaut between neon pillars in space:

* **Difficulty Gap Settings**: Features a customizable gap difficulty setting selector in the setup phase screen:
  * **Space Cadet (Easy)**: $340f$ pixel gap size.
  * **Pilot (Medium)**: $280f$ pixel gap size.
  * **Astronaut (Hard)**: $220f$ pixel gap size (the baseline hardest setting).
* **Parallax Stars**: Features drifting space stars scrolling behind neon energy pillars generated at random offsets.

---

## 👽 4. Whack-a-Monster

Test your reaction speed by whacking pop-up opponent monsters while avoiding whacking your family members:

* **Custom Speed Setting**: Customize speeds before starting: `1.0x (Slow)`, `1.5x (Normal)`, `2.0x (Fast - default)`, or `3.0x (Insane)`.
* **Teammates vs. Opponents**: Family faces assigned as Teammates pop up with Electric Cyan borders (tapping them inflicts score penalty). Opponents pop up with Neon Pink borders (tapping awards points and increments combo multipliers).

---

## 👻 5. Family Pac-Man

Munch pellets inside a retro blue neon maze while escaping family ghosts:

* **Authentic Ghost AI Pathways**: 4 ghosts navigate using their classic personalities:
  * **Blinky (Red)**: Targets Pac-Man's active tile coordinates.
  * **Pinky (Pink)**: Ambient targeting offset 4 tiles ahead of Pac-Man.
  * **Inky (Cyan)**: Vector mirror path target relative to Blinky.
  * **Clyde (Orange)**: Flees to the bottom-left corner when in close proximity.
* **CME-Safe Array Copy Iteration**: Collisions between Pac-Man and ghosts are calculated using snapshot-safe `.toList()` copy loops, preventing runtime `ConcurrentModificationException` crashes when ghosts are eaten or reset.
* **Enlarged Avatars**: Family faces inside ghost sheets are scaled to $85\%$ body size for premium clarity.
