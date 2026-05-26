package com.familyface.games.model

data class FaceProfile(
    val id: String,
    val name: String,
    val imagePath: String,
    val isDefault: Boolean = false
)
