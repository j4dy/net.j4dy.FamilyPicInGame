package net.j4dy.familypicingame.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import net.j4dy.familypicingame.model.FaceProfile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class FaceStorage(private val context: Context) {

    private val sharedPrefs = context.getSharedPreferences("family_face_prefs", Context.MODE_PRIVATE)
    private val facesDir = File(context.filesDir, "faces").apply { if (!exists()) mkdirs() }

    init {
        // Initialize default characters if none exist
        if (getProfiles().isEmpty()) {
            createDefaultProfiles()
        }
    }

    /**
     * Retrieves all saved face profiles.
     */
    fun getProfiles(): List<FaceProfile> {
        val jsonStr = sharedPrefs.getString("profiles", "[]") ?: "[]"
        val list = mutableListOf<FaceProfile>()
        try {
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                list.add(
                    FaceProfile(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        imagePath = obj.getString("imagePath"),
                        isDefault = obj.optBoolean("isDefault", false)
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return list
    }

    /**
     * Saves a list of profiles.
     */
    private fun saveProfiles(profiles: List<FaceProfile>) {
        val jsonArray = JSONArray()
        for (profile in profiles) {
            val obj = JSONObject().apply {
                put("id", profile.id)
                put("name", profile.name)
                put("imagePath", profile.imagePath)
                put("isDefault", profile.isDefault)
            }
            jsonArray.put(obj)
        }
        sharedPrefs.edit().putString("profiles", jsonArray.toString()).apply()
    }

    /**
     * Adds a new custom face profile by saving its bitmap as a circular PNG.
     */
    fun addProfile(name: String, sourceBitmap: Bitmap): FaceProfile {
        val id = UUID.randomUUID().toString()
        val circleBitmap = getCircularBitmap(sourceBitmap)
        val file = File(facesDir, "$id.png")
        
        var fos: FileOutputStream? = null
        try {
            fos = FileOutputStream(file)
            circleBitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            fos?.close()
        }

        val newProfile = FaceProfile(
            id = id,
            name = name,
            imagePath = file.absolutePath,
            isDefault = false
        )

        val updatedList = getProfiles().toMutableList().apply { add(newProfile) }
        saveProfiles(updatedList)
        return newProfile
    }

    /**
     * Deletes a profile.
     */
    fun deleteProfile(id: String) {
        val currentProfiles = getProfiles()
        val target = currentProfiles.find { it.id == id }
        if (target != null) {
            // Delete actual image file if not a default profile (defaults are handled in assets/files)
            if (!target.isDefault) {
                val file = File(target.imagePath)
                if (file.exists()) {
                    file.delete()
                }
            }
            val updatedList = currentProfiles.filter { it.id != id }
            saveProfiles(updatedList)
        }
    }

    /**
     * Generates a circular masked Bitmap from a source square/rectangle Bitmap.
     */
    private fun getCircularBitmap(src: Bitmap): Bitmap {
        val size = Math.min(src.width, src.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)

        val paint = Paint().apply {
            isAntiAlias = true
        }
        
        val radius = size / 2f
        canvas.drawCircle(radius, radius, radius, paint)
        
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val srcRect = Rect(
            (src.width - size) / 2,
            (src.height - size) / 2,
            (src.width + size) / 2,
            (src.height + size) / 2
        )
        val destRect = Rect(0, 0, size, size)
        canvas.drawBitmap(src, srcRect, destRect, paint)
        
        return output
    }

    /**
     * Generates beautiful pre-loaded cute cartoon faces on an Android Canvas
     * so that the application has vibrant assets immediately playable out-of-the-box.
     */
    private fun createDefaultProfiles() {
        val defaults = listOf(
            Triple("Hero Red", Color.parseColor("#FF4C4C"), "angry_bird"),
            Triple("Chubby Blue", Color.parseColor("#4C8DFF"), "blue_bird"),
            Triple("Piggy Green", Color.parseColor("#5CD65C"), "green_pig"),
            Triple("Cookie Yellow", Color.parseColor("#FFD633"), "cookie_monster")
        )

        val list = mutableListOf<FaceProfile>()

        for ((name, color, type) in defaults) {
            val id = UUID.randomUUID().toString()
            val bitmap = createCartoonFace(color, type)
            val file = File(facesDir, "$id.png")
            
            var fos: FileOutputStream? = null
            try {
                fos = FileOutputStream(file)
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                fos?.close()
            }

            list.add(
                FaceProfile(
                    id = id,
                    name = name,
                    imagePath = file.absolutePath,
                    isDefault = true
                )
            )
        }
        saveProfiles(list)
    }

    /**
     * Draws cute round cartoon characters programmatically.
     */
    private fun createCartoonFace(bgColor: Int, type: String): Bitmap {
        val size = 256
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint().apply { isAntiAlias = true }

        val radius = size / 2f
        
        // 1. Draw main body circle
        paint.color = bgColor
        canvas.drawCircle(radius, radius, radius, paint)

        // 2. Draw face features depending on type
        when (type) {
            "angry_bird" -> {
                // Angry eyebrows (black)
                paint.color = Color.BLACK
                paint.strokeWidth = 12f
                // Left eyebrow
                canvas.drawLine(50f, 90f, 120f, 115f, paint)
                // Right eyebrow
                canvas.drawLine(206f, 90f, 136f, 115f, paint)

                // Large white eyes
                paint.color = Color.WHITE
                canvas.drawCircle(90f, 130f, 25f, paint)
                canvas.drawCircle(166f, 130f, 25f, paint)

                // Black pupils looking inwards
                paint.color = Color.BLACK
                canvas.drawCircle(100f, 130f, 10f, paint)
                canvas.drawCircle(156f, 130f, 10f, paint)

                // Orange triangle beak
                paint.color = Color.parseColor("#FFA500")
                val path = android.graphics.Path().apply {
                    moveTo(128f, 125f)
                    lineTo(100f, 165f)
                    lineTo(156f, 165f)
                    close()
                }
                canvas.drawPath(path, paint)
            }
            "blue_bird" -> {
                // Cute happy eyes
                paint.color = Color.WHITE
                canvas.drawCircle(85f, 120f, 22f, paint)
                canvas.drawCircle(171f, 120f, 22f, paint)

                paint.color = Color.parseColor("#1A1A1A")
                canvas.drawCircle(85f, 120f, 8f, paint)
                canvas.drawCircle(171f, 120f, 8f, paint)

                // Cheeks (blush pink)
                paint.color = Color.parseColor("#FF9999")
                canvas.drawCircle(55f, 155f, 15f, paint)
                canvas.drawCircle(201f, 155f, 15f, paint)

                // Small yellow bill
                paint.color = Color.parseColor("#FFCC00")
                val path = android.graphics.Path().apply {
                    moveTo(128f, 120f)
                    lineTo(113f, 150f)
                    lineTo(143f, 150f)
                    close()
                }
                canvas.drawPath(path, paint)
            }
            "green_pig" -> {
                // Pig eyes (black dots with white circles)
                paint.color = Color.WHITE
                canvas.drawCircle(80f, 110f, 16f, paint)
                canvas.drawCircle(176f, 110f, 16f, paint)
                paint.color = Color.BLACK
                canvas.drawCircle(80f, 110f, 6f, paint)
                canvas.drawCircle(176f, 110f, 6f, paint)

                // Huge pig snout (lighter green)
                paint.color = Color.parseColor("#8AE68A")
                canvas.drawRoundRect(88f, 125f, 168f, 175f, 20f, 20f, paint)

                // Snout nostrils
                paint.color = Color.parseColor("#336633")
                canvas.drawCircle(108f, 150f, 8f, paint)
                canvas.drawCircle(148f, 150f, 8f, paint)
            }
            else -> {
                // "cookie_monster" / happy face
                // Giant goofy eyes
                paint.color = Color.WHITE
                canvas.drawCircle(100f, 95f, 28f, paint)
                canvas.drawCircle(156f, 95f, 28f, paint)

                paint.color = Color.BLACK
                canvas.drawCircle(95f, 95f, 10f, paint)
                canvas.drawCircle(151f, 90f, 10f, paint) // silly misaligned pupil

                // Wide open black mouth
                paint.color = Color.BLACK
                canvas.drawArc(64f, 110f, 192f, 210f, 0f, 180f, true, paint)
            }
        }

        return bitmap
    }
}
