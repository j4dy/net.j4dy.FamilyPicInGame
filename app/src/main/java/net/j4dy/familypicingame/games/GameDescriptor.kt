package net.j4dy.familypicingame.games

data class GameDescriptor(
    val id: String,
    val title: String,
    val description: String,
    val route: String,
    val tags: List<String> = emptyList()
)
