"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FaceCropService = void 0;
const sharp = require("sharp");

class FaceCropService {
    /**
     * Crop a face from any image using AI-provided coordinates.
     * Works for ALL platforms (Instagram, Tinder, Bumble, etc.)
     *
     * @param imageBase64 - The original image as base64
     * @param facePosition - AI-detected face coordinates {centerX, centerY, size} as 0-100 percentages
     * @returns {success, croppedFaceBase64, method}
     */
    static async cropFace(imageBase64, facePosition) {
        try {
            const buffer = Buffer.from(imageBase64, "base64");
            const metadata = await sharp(buffer).metadata();
            if (!metadata.width || !metadata.height) {
                return { success: false, error: "Invalid image metadata", method: "failed" };
            }

            const w = metadata.width;
            const h = metadata.height;

            // Validate facePosition
            if (!facePosition ||
                typeof facePosition.centerX !== 'number' ||
                typeof facePosition.centerY !== 'number' ||
                typeof facePosition.size !== 'number') {
                return { success: false, error: "No face position provided", method: "no_position" };
            }

            const { centerX, centerY, size } = facePosition;

            // Sanity checks (coordinates should be 0-100)
            if (centerX < 0 || centerX > 100 || centerY < 0 || centerY > 100 || size <= 0 || size > 100) {
                console.warn(`FaceCropService: invalid coordinates cx=${centerX} cy=${centerY} size=${size}`);
                return { success: false, error: "Invalid face coordinates", method: "invalid_coords" };
            }

            // Convert percentages to pixels
            const faceCenterX = Math.round(w * centerX / 100);
            const faceCenterY = Math.round(h * centerY / 100);
            const faceWidth = Math.round(w * size / 100);

            // Add padding around the face (40% on each side for head/hair/chin)
            // This gives a natural portrait crop, not too tight
            const paddingFactor = 0.4;
            const cropSize = Math.round(faceWidth * (1 + paddingFactor * 2));

            // Ensure crop doesn't exceed image bounds
            const finalCropSize = Math.min(cropSize, w, h);
            let cropX = faceCenterX - Math.round(finalCropSize / 2);
            let cropY = faceCenterY - Math.round(finalCropSize / 2);

            // Clamp to image bounds
            cropX = Math.max(0, Math.min(cropX, w - finalCropSize));
            cropY = Math.max(0, Math.min(cropY, h - finalCropSize));

            // Final safety: ensure dimensions are valid
            const safeWidth = Math.min(finalCropSize, w - cropX);
            const safeHeight = Math.min(finalCropSize, h - cropY);
            const safeCropSize = Math.max(1, Math.min(safeWidth, safeHeight));

            console.log(`FaceCropService: crop at (${cropX},${cropY}) size=${safeCropSize} ` +
                `from ${w}x${h} image (face at ${centerX}%,${centerY}% size=${size}%)`);

            const croppedBuffer = await sharp(buffer)
                .extract({
                    left: cropX,
                    top: cropY,
                    width: safeCropSize,
                    height: safeCropSize,
                })
                .resize(200, 200, { fit: "cover" })
                .jpeg({ quality: 90 })
                .toBuffer();

            return {
                success: true,
                croppedFaceBase64: croppedBuffer.toString("base64"),
                method: "ai_vision",
            };
        } catch (error) {
            console.error("FaceCropService error:", error.message);
            return { success: false, error: error.message, method: "failed" };
        }
    }
}

exports.FaceCropService = FaceCropService;
