"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InstagramCropService = void 0;
const sharp = require("sharp");

let cv = null;
let cvLoadFailed = false;

async function loadOpenCV() {
    if (cv) return cv;
    if (cvLoadFailed) return null;
    try {
        cv = require("opencv-wasm");
        return cv;
    } catch (error) {
        console.warn("opencv-wasm not available, using fallback crop:", error.message);
        cvLoadFailed = true;
        return null;
    }
}

class InstagramCropService {
    /**
     * Crop Instagram profile photo using OpenCV HoughCircles.
     * Fallback to fixed coordinates if OpenCV fails.
     */
    static async cropProfilePhoto(imageBase64) {
        try {
            const buffer = Buffer.from(imageBase64, "base64");
            const metadata = await sharp(buffer).metadata();
            if (!metadata.width || !metadata.height) {
                return { success: false, error: "Invalid image metadata", method: "failed" };
            }

            // Try OpenCV first
            const opencv = await loadOpenCV();
            if (opencv) {
                const result = await this.cropWithOpenCV(opencv, buffer, metadata);
                if (result.success) return result;
            }

            // Fallback to fixed coordinates
            return await this.cropWithFallback(buffer, metadata);
        } catch (error) {
            console.error("InstagramCropService error:", error.message);
            try {
                const buffer = Buffer.from(imageBase64, "base64");
                const metadata = await sharp(buffer).metadata();
                return await this.cropWithFallback(buffer, metadata);
            } catch (fallbackError) {
                return { success: false, error: error.message, method: "failed" };
            }
        }
    }

    /**
     * Detect profile circle using OpenCV HoughCircles
     */
    static async cropWithOpenCV(cv, buffer, metadata) {
        let src = null, gray = null, blurred = null, circles = null;
        try {
            // 1. Crop top 40% of the image (Instagram profile circle area)
            const cropHeight = Math.round(metadata.height * 0.40);
            const topCropRgba = await sharp(buffer)
                .extract({ left: 0, top: 0, width: metadata.width, height: cropHeight })
                .ensureAlpha()
                .raw()
                .toBuffer({ resolveWithObject: true });

            // 2. Create OpenCV Mat from RGBA pixels
            src = cv.matFromImageData({
                data: new Uint8ClampedArray(topCropRgba.data),
                width: topCropRgba.info.width,
                height: topCropRgba.info.height,
            });

            // 3. Convert to grayscale
            gray = new cv.Mat();
            cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);

            // 4. Median blur to reduce noise
            blurred = new cv.Mat();
            cv.medianBlur(gray, blurred, 5);

            // 5. Detect circles with HoughCircles
            circles = new cv.Mat();
            const minRadius = Math.round(topCropRgba.info.width * 0.04);
            const maxRadius = Math.round(topCropRgba.info.width * 0.15);

            cv.HoughCircles(
                blurred,
                circles,
                cv.HOUGH_GRADIENT,
                1,                              // dp
                topCropRgba.info.width / 8,     // minDist
                100,                             // param1 (Canny upper threshold)
                30,                              // param2 (accumulator threshold)
                minRadius,
                maxRadius
            );

            // 6. Find best circle in expected Instagram region (left side, upper area)
            let bestCircle = null;
            let bestScore = -1;

            for (let i = 0; i < circles.cols; i++) {
                const x = circles.data32F[i * 3];
                const y = circles.data32F[i * 3 + 1];
                const r = circles.data32F[i * 3 + 2];

                const xPct = x / topCropRgba.info.width;
                const yPct = y / topCropRgba.info.height;

                // Skip circles in the right half (not profile area)
                if (xPct > 0.5) continue;

                // Score: prefer larger circles closer to expected position
                const regionScore = (xPct < 0.25 ? 1.0 : 0.5) * (yPct < 0.6 ? 1.0 : 0.5);
                const score = r * regionScore;

                if (score > bestScore) {
                    bestCircle = { x: Math.round(x), y: Math.round(y), r: Math.round(r) };
                    bestScore = score;
                }
            }

            if (!bestCircle) {
                console.log("HoughCircles: no valid circle found in expected region");
                return { success: false, method: "opencv_no_circle" };
            }

            console.log(`HoughCircles: circle at (${bestCircle.x}, ${bestCircle.y}) r=${bestCircle.r}`);

            // 7. Crop square around the circle with slight padding
            const padding = Math.round(bestCircle.r * 0.15);
            const cropSize = (bestCircle.r + padding) * 2;
            const cropX = Math.max(0, bestCircle.x - Math.round(cropSize / 2));
            const cropY = Math.max(0, bestCircle.y - Math.round(cropSize / 2));
            const finalW = Math.min(Math.round(cropSize), metadata.width - cropX);
            const finalH = Math.min(Math.round(cropSize), cropHeight - cropY);
            const finalSize = Math.max(1, Math.min(finalW, finalH));

            const croppedBuffer = await sharp(buffer)
                .extract({ left: cropX, top: cropY, width: finalSize, height: finalSize })
                .resize(200, 200, { fit: "cover" })
                .jpeg({ quality: 90 })
                .toBuffer();

            return {
                success: true,
                croppedFaceBase64: croppedBuffer.toString("base64"),
                circle: bestCircle,
                method: "opencv_hough",
            };
        } finally {
            // Cleanup OpenCV Mats
            if (src) src.delete();
            if (gray) gray.delete();
            if (blurred) blurred.delete();
            if (circles) circles.delete();
        }
    }

    /**
     * Fallback: crop using fixed coordinates for standard Instagram layout
     */
    static async cropWithFallback(buffer, metadata) {
        // Instagram profile circle: ~12% from left, ~7% from top, ~20% of screen width
        const circleRadius = Math.round(metadata.width * 0.10);
        const centerX = Math.round(metadata.width * 0.12);
        const centerY = Math.round(metadata.height * 0.08);

        const padding = Math.round(circleRadius * 0.15);
        const cropSize = (circleRadius + padding) * 2;
        const cropX = Math.max(0, centerX - Math.round(cropSize / 2));
        const cropY = Math.max(0, centerY - Math.round(cropSize / 2));
        const finalSize = Math.max(1, Math.min(cropSize, metadata.width - cropX, metadata.height - cropY));

        const croppedBuffer = await sharp(buffer)
            .extract({ left: cropX, top: cropY, width: finalSize, height: finalSize })
            .resize(200, 200, { fit: "cover" })
            .jpeg({ quality: 90 })
            .toBuffer();

        return {
            success: true,
            croppedFaceBase64: croppedBuffer.toString("base64"),
            method: "fallback_fixed",
        };
    }
}

exports.InstagramCropService = InstagramCropService;
