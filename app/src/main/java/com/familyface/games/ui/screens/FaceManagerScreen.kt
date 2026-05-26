package com.familyface.games.ui.screens

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.familyface.games.data.FaceStorage
import com.familyface.games.model.FaceProfile
import com.familyface.games.ui.theme.CardSlate
import com.familyface.games.ui.theme.CyberPurple
import com.familyface.games.ui.theme.ElectricCyan
import com.familyface.games.ui.theme.IcyWhite
import com.familyface.games.ui.theme.NeonPink
import com.familyface.games.ui.theme.SoftGrey
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FaceManagerScreen(
    onPhotoSelected: (Uri) -> Unit,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    var profiles by remember { mutableStateOf(faceStorage.getProfiles()) }
    
    // Refresh profiles whenever this screen is displayed
    LaunchedEffect(Unit) {
        profiles = faceStorage.getProfiles()
    }

    // Photo picker launcher
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia(),
        onResult = { uri ->
            if (uri != null) {
                onPhotoSelected(uri)
            }
        }
    )

    BackHandler {
        onBackClick()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Family Face Manager", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = IcyWhite)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = IcyWhite
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = {
                    photoPickerLauncher.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                    )
                },
                containerColor = NeonPink,
                contentColor = Color.White,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.padding(8.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add", modifier = Modifier.size(24.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Add Photo", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(MaterialTheme.colorScheme.background)
                .padding(horizontal = 16.dp)
        ) {
            Text(
                "Add faces of family members to replace default game characters. Circular cropping happens automatically!",
                style = MaterialTheme.typography.bodyMedium,
                color = SoftGrey,
                modifier = Modifier.padding(vertical = 12.dp),
                textAlign = TextAlign.Start
            )
            
            if (profiles.isEmpty()) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "No face profiles found.\nTap 'Add Photo' to create one!",
                        color = SoftGrey,
                        textAlign = TextAlign.Center,
                        lineHeight = 24.sp
                    )
                }
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(bottom = 80.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(profiles) { profile ->
                        FaceProfileCard(
                            profile = profile,
                            onDeleteClick = {
                                faceStorage.deleteProfile(profile.id)
                                profiles = faceStorage.getProfiles() // refresh
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun FaceProfileCard(
    profile: FaceProfile,
    onDeleteClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    colors = if (profile.isDefault) {
                        listOf(CyberPurple.copy(alpha = 0.4f), Color.Transparent)
                    } else {
                        listOf(ElectricCyan.copy(alpha = 0.6f), CyberPurple.copy(alpha = 0.2f))
                    }
                ),
                shape = RoundedCornerShape(16.dp)
            ),
        colors = CardDefaults.cardColors(containerColor = CardSlate),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Face circular image
            val imgFile = File(profile.imagePath)
            
            Box(
                modifier = Modifier
                    .size(90.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF0F1424))
                    .border(
                        width = 2.dp,
                        color = if (profile.isDefault) CyberPurple else ElectricCyan,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (imgFile.exists()) {
                    // Load using basic AsyncImage wrapper or simple custom painter since Coil is standard
                    // We can use painterResource or load it via custom painter for safety, 
                    // but we will use the local absolute file image loading in Compose.
                    // A simple local bitmap painter works perfectly in Compose!
                    val bitmap = remember(profile.imagePath) {
                        try {
                            android.graphics.BitmapFactory.decodeFile(profile.imagePath)
                        } catch (e: Exception) {
                            null
                        }
                    }
                    if (bitmap != null) {
                        Image(
                            bitmap = bitmap.asImageBitmap(),
                            contentDescription = profile.name,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(CyberPurple),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                profile.name.take(1).uppercase(),
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 32.sp
                            )
                        }
                    }
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(CyberPurple),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            profile.name.take(1).uppercase(),
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 32.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = profile.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = IcyWhite,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (profile.isDefault) {
                    Text(
                        text = "Default",
                        color = CyberPurple,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .background(CyberPurple.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                    // Visual placeholder for symmetrical layout
                    Spacer(modifier = Modifier.width(1.dp))
                } else {
                    Text(
                        text = "Custom",
                        color = ElectricCyan,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .background(ElectricCyan.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                    
                    IconButton(
                        onClick = onDeleteClick,
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Delete Face",
                            tint = NeonPink.copy(alpha = 0.8f),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }
        }
    }
}
