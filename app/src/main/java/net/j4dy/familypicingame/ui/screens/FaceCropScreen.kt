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
import androidx.compose.ui.layout.onSizeChanged
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
    var canvasSize by remember { mutableStateOf(Size.Zero) }

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
                        .onSizeChanged { intSize ->
                            canvasSize = Size(intSize.width.toFloat(), intSize.height.toFloat())
                        }
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
                                val cropped = cropBitmapNatively(b, scale, offset, canvasSize.width, canvasSize.height)
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
    canvasWidth: Float,
    canvasHeight: Float
): Bitmap? {
    try {
        // A standard crop dimension (e.g. 256x256 makes a perfect avatar)
        val size = 256
        val croppedOutput = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(croppedOutput)
        
        // Paint setup with anti-aliasing and bitmap filtering for smooth crops
        val paint = android.graphics.Paint().apply { 
            isAntiAlias = true 
            isFilterBitmap = true
        }

        val widthVal = if (canvasWidth > 0f) canvasWidth else 800f
        val heightVal = if (canvasHeight > 0f) canvasHeight else 800f

        val circleRadius = Math.min(widthVal, heightVal) * 0.35f
        val centerX = widthVal / 2f
        val centerY = heightVal / 2f

        val imgWidth = src.width.toFloat()
        val imgHeight = src.height.toFloat()

        // Replicate base scale and final scale from preview
        val baseScale = Math.min(widthVal / imgWidth, heightVal / imgHeight)
        val finalScale = baseScale * gestureScale

        val drawWidth = imgWidth * finalScale
        val drawHeight = imgHeight * finalScale

        // Replicate initial centering start coords
        val startX = (widthVal - drawWidth) / 2f + gestureOffset.x
        val startY = (heightVal - drawHeight) / 2f + gestureOffset.y

        val transform = Matrix()
        // 1. Position and scale image exactly as visually laid out on physical screen
        transform.postScale(finalScale, finalScale)
        transform.postTranslate(startX, startY)

        // 2. Shift center of physical screen's crop circle to (0, 0)
        transform.postTranslate(-centerX, -centerY)

        // 3. Scale crop circle radius to output bitmap's radius (128f)
        val cropScale = 128f / circleRadius
        transform.postScale(cropScale, cropScale)

        // 4. Translate center (0, 0) to output bitmap's center (128f, 128f)
        transform.postTranslate(128f, 128f)

        // Clean slate and clear
        canvas.drawColor(android.graphics.Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR)
        
        // Clip to circular crop path so everything outside the 128px radius circle is transparent
        val clipPath = android.graphics.Path().apply {
            addCircle(128f, 128f, 128f, android.graphics.Path.Direction.CW)
        }
        canvas.clipPath(clipPath)
        
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
