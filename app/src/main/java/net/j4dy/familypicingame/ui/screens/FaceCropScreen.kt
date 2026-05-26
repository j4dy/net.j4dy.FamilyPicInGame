package net.j4dy.familypicingame.ui.screens

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import net.j4dy.familypicingame.data.FaceStorage
import net.j4dy.familypicingame.ui.theme.CyberPurple
import net.j4dy.familypicingame.ui.theme.ElectricCyan
import net.j4dy.familypicingame.ui.theme.IcyWhite
import net.j4dy.familypicingame.ui.theme.NeonPink
import net.j4dy.familypicingame.ui.theme.SoftGrey
import java.io.InputStream

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FaceCropScreen(
    imageUri: Uri,
    onCropSuccess: () -> Unit,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    val faceStorage = remember { FaceStorage(context) }
    
    // Load bitmap in background safely
    var bitmap by remember { mutableStateOf<Bitmap?>(null) }
    var loadingError by remember { mutableStateOf(false) }
    
    LaunchedEffect(imageUri) {
        try {
            bitmap = loadDownsampledBitmap(context, imageUri, 1024)
        } catch (e: Exception) {
            e.printStackTrace()
            loadingError = true
        }
    }
    
    var nameText by remember { mutableStateOf("") }
    var showError by remember { mutableStateOf(false) }
    
    // Transform states for cropping
    var scale by remember { mutableStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }

    BackHandler {
        onBackClick()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Crop Character Head", fontWeight = FontWeight.Bold) },
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
        }
    ) { padding ->
        if (loadingError) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(MaterialTheme.colorScheme.background),
                contentAlignment = Alignment.Center
            ) {
                Text("Failed to load image. Please try another.", color = NeonPink, textAlign = TextAlign.Center)
            }
        } else if (bitmap == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(MaterialTheme.colorScheme.background),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = NeonPink)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .background(MaterialTheme.colorScheme.background)
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "Pinch to zoom and drag to position family member's head inside the circle.",
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 12.dp)
                )

                // The Crop Canvas
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color(0xFF0F1424))
                        .pointerInput(Unit) {
                            detectTransformGestures { _, panDrag, zoomMultiplier, _ ->
                                scale = (scale * zoomMultiplier).coerceIn(0.5f, 5.0f)
                                offset = offset + panDrag
                            }
                        },
                    contentAlignment = Alignment.Center
                ) {
                    val imageBitmap = remember(bitmap) { bitmap?.asImageBitmap() }
                    
                    if (imageBitmap != null) {
                        Canvas(modifier = Modifier.fillMaxSize()) {
                            val canvasWidth = size.width
                            val canvasHeight = size.height
                            val circleRadius = Math.min(canvasWidth, canvasHeight) * 0.35f
                            val center = Offset(canvasWidth / 2f, canvasHeight / 2f)

                            // 1. Draw image with scale and offset centered
                            val imgWidth = imageBitmap.width.toFloat()
                            val imgHeight = imageBitmap.height.toFloat()
                            
                            val baseScale = Math.min(canvasWidth / imgWidth, canvasHeight / imgHeight)
                            val finalScale = baseScale * scale
                            
                            val drawWidth = imgWidth * finalScale
                            val drawHeight = imgHeight * finalScale
                            
                            val startX = (canvasWidth - drawWidth) / 2f + offset.x
                            val startY = (canvasHeight - drawHeight) / 2f + offset.y

                            // Draw image
                            drawImage(
                                image = imageBitmap,
                                dstOffset = IntOffset(startX.toInt(), startY.toInt()),
                                dstSize = IntSize(drawWidth.toInt(), drawHeight.toInt())
                            )

                            // 2. Draw glass overlay with circular hole
                            val path = Path().apply {
                                addRect(Rect(0f, 0f, canvasWidth, canvasHeight))
                            }
                            val circlePath = Path().apply {
                                addOval(Rect(center.x - circleRadius, center.y - circleRadius, center.x + circleRadius, center.y + circleRadius))
                            }
                            
                            // Subtract circle from rect
                            val differencePath = Path.combine(
                                PathOperation.Difference,
                                path,
                                circlePath
                            )
                            
                            drawPath(
                                path = differencePath,
                                color = Color(0xAA0A0E17)
                            )
                            
                            // Draw neon border circle helper
                            drawCircle(
                                color = ElectricCyan,
                                radius = circleRadius,
                                center = center,
                                style = androidx.compose.ui.graphics.drawscope.Stroke(width = 3.dp.toPx())
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Name Input field
                OutlinedTextField(
                    value = nameText,
                    onValueChange = {
                        nameText = it
                        showError = false
                    },
                    label = { Text("Family Member Name (e.g., Dad, Mom)") },
                    singleLine = true,
                    isError = showError,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ElectricCyan,
                        unfocusedBorderColor = CyberPurple,
                        focusedLabelColor = ElectricCyan,
                        unfocusedLabelColor = SoftGrey,
                        focusedTextColor = IcyWhite,
                        unfocusedTextColor = IcyWhite
                    ),
                    shape = RoundedCornerShape(12.dp)
                )

                if (showError) {
                    Text(
                        "Please enter a valid name.",
                        color = NeonPink,
                        style = MaterialTheme.typography.bodySmall,
                        modifier = Modifier.align(Alignment.Start).padding(start = 8.dp, top = 4.dp)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Save button
                Button(
                    onClick = {
                        if (nameText.trim().isEmpty()) {
                            showError = true
                        } else {
                            // Extract crop and save
                            val b = bitmap
                            if (b != null) {
                                val cropped = cropBitmapNatively(b, scale, offset, nameText, context)
                                if (cropped != null) {
                                    faceStorage.addProfile(nameText.trim(), cropped)
                                    onCropSuccess()
                                }
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = NeonPink,
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Save Character Face", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

/**
 * Perform actual crop using Matrix transformations to extract precisely what the user aligned.
 */
private fun cropBitmapNatively(
    src: Bitmap,
    gestureScale: Float,
    gestureOffset: Offset,
    name: String,
    context: Context
): Bitmap? {
    try {
        // A standard crop dimension (e.g. 256x256 makes a perfect avatar)
        val size = 256
        val croppedOutput = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(croppedOutput)
        val paint = android.graphics.Paint().apply { isAntiAlias = true }

        // We need to replicate what was rendered in the Compose Canvas.
        // Let's assume the Canvas was, say, 800x800 or whatever aspect ratio.
        // To make it fully stable without relying on Canvas dimensions:
        // We will project the center crop:
        val srcWidth = src.width.toFloat()
        val srcHeight = src.height.toFloat()
        
        // Compute base scale as if viewport was 800px square
        val viewportSize = 800f
        val baseScale = Math.min(viewportSize / srcWidth, viewportSize / srcHeight)
        val finalScale = baseScale * gestureScale
        
        // Offset mapping to source coordinates
        // Under viewportSize, crop window is a circle at center (400, 400) of radius 280 (0.35f * 800)
        // Center offset relative to source
        val scaleMatrix = Matrix()
        
        // We translate source so it's centered, then scale it, then apply user offsets
        val baseTranslateX = (viewportSize - srcWidth * finalScale) / 2f + gestureOffset.x
        val baseTranslateY = (viewportSize - srcHeight * finalScale) / 2f + gestureOffset.y
        
        // We want to extract a 280px radius circle centered at 400,400.
        // Let's draw it onto our 256x256 canvas:
        // We maps (400, 400) of viewport to (128, 128) of cropped output.
        // Scaling factor from viewport to crop size: 256f / (viewportSize * 0.70f) -> 256 / 560
        val cropRadius = viewportSize * 0.35f // 280
        val cropToOutputScale = size.toFloat() / (cropRadius * 2f) // 256 / 560
        
        val transform = Matrix()
        // 1. Center photo relative to viewport center
        transform.postTranslate(-srcWidth / 2f, -srcHeight / 2f)
        // 2. Scale by gesture zoom
        transform.postScale(finalScale, finalScale)
        // 3. Translate by gesture offset
        transform.postTranslate(gestureOffset.x, gestureOffset.y)
        // 4. Align viewport center (0,0 now) to crop center
        // 5. Scale down to output 256px size
        transform.postScale(cropToOutputScale, cropToOutputScale)
        // 6. Center in the output bitmap
        transform.postTranslate(size / 2f, size / 2f)

        canvas.drawColor(android.graphics.Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR)
        canvas.drawBitmap(src, transform, paint)
        
        return croppedOutput
    } catch (e: Exception) {
        e.printStackTrace()
    }
    return null
}

/**
 * Loads and downsamples a bitmap from a Uri to prevent memory crashes.
 */
private fun loadDownsampledBitmap(context: Context, uri: Uri, maxDim: Int): Bitmap? {
    var inputStream: InputStream? = null
    try {
        inputStream = context.contentResolver.openInputStream(uri)
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeStream(inputStream, null, options)
        inputStream?.close()

        var width = options.outWidth
        var height = options.outHeight
        var sampleSize = 1

        while (width > maxDim || height > maxDim) {
            width /= 2
            height /= 2
            sampleSize *= 2
        }

        val decodeOptions = BitmapFactory.Options().apply {
            inSampleSize = sampleSize
        }
        inputStream = context.contentResolver.openInputStream(uri)
        val result = BitmapFactory.decodeStream(inputStream, null, decodeOptions)
        
        // Handle rotation if needed (panned images are sometimes rotated in EXIF)
        return result
    } catch (e: Exception) {
        e.printStackTrace()
    } finally {
        inputStream?.close()
    }
    return null
}
