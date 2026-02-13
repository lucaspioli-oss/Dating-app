"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InstagramCropService = void 0;
const sharp = require("sharp");

class InstagramCropService {
    /**
     * Crop Instagram profile photo from screenshot.
     * Uses sharp edge-detection to find the circular profile picture,
     * falls back to fixed coordinates for standard Instagram layout.
     */
    static async cropProfilePhoto(imageBase64) {
        try {
            const buffer = Buffer.from(imageBase64, "base64");
            const metadata = await sharp(buffer).metadata();
            if (!metadata.width || !metadata.height) {
                return { success: false, error: "Invalid image metadata", method: "failed" };
            }

            // Try smart detection first
            const smartResult = await this.cropWithEdgeDetection(buffer, metadata);
            if (smartResult.success) return smartResult;

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
     * Smart crop: analyze the expected profile picture region using sharp.
     * Instagram profile pic is always a circle in the top-left area.
     * We crop that region and use contrast analysis to validate it contains a face.
     */
    static async cropWithEdgeDetection(buffer, metadata) {
        try {
            // Instagram profile circle is in the top-left quadrant
            // Typical position: center ~12-15% from left, ~6-10% from top
            // Size: ~18-22% of screen width
            const w = metadata.width;
            const h = metadata.height;

            // Define search region (top-left area where profile pic lives)
            const searchW = Math.round(w * 0.35);
            const searchH = Math.round(h * 0.20);

            // Extract the search region and analyze it
            const regionBuffer = await sharp(buffer)
                .extract({ left: 0, top: 0, width: searchW, height: searchH })
                .grayscale()
                .raw()
                .toBuffer({ resolveWithObject: true });

            const pixels = regionBuffer.data;
            const rW = regionBuffer.info.width;
            const rH = regionBuffer.info.height;

            // Scan for the circular profile picture using brightness variance
            // The profile pic typically has higher variance (face/content) compared
            // to the uniform background around it
            let bestRegion = null;
            let bestVariance = 0;

            // Try multiple candidate positions based on known Instagram layouts
            const candidates = [
                { cx: 0.13, cy: 0.38, r: 0.28 },  // Standard layout
                { cx: 0.15, cy: 0.40, r: 0.30 },  // Slightly shifted
                { cx: 0.12, cy: 0.35, r: 0.25 },  // Compact layout
                { cx: 0.14, cy: 0.42, r: 0.32 },  // Larger profile pic
            ];

            for (const cand of candidates) {
                const cx = Math.round(rW * cand.cx);
                const cy = Math.round(rH * cand.cy);
                const radius = Math.round(rW * cand.r);

                // Calculate variance of pixels in this circular region
                let sum = 0, sumSq = 0, count = 0;
                const startY = Math.max(0, cy - radius);
                const endY = Math.min(rH, cy + radius);
                const startX = Math.max(0, cx - radius);
                const endX = Math.min(rW, cx + radius);

                for (let y = startY; y < endY; y++) {
                    for (let x = startX; x < endX; x++) {
                        // Check if pixel is within the circle
                        const dx = x - cx;
                        const dy = y - cy;
                        if (dx * dx + dy * dy <= radius * radius) {
                            const val = pixels[y * rW + x];
                            sum += val;
                            sumSq += val * val;
                            count++;
                        }
                    }
                }

                if (count > 0) {
                    const mean = sum / count;
                    const variance = (sumSq / count) - (mean * mean);

                    // Profile pics have moderate-to-high variance (faces, colors)
                    // Blank/uniform areas have low variance
                    if (variance > bestVariance && variance > 200) {
                        bestVariance = variance;
                        bestRegion = {
                            cx: Math.round(w * cand.cx),
                            cy: Math.round(h * (cand.cy * 0.20)),  // Scale back to full image coords
                            r: Math.round(w * cand.r / 2),
                        };
                    }
                }
            }

            if (!bestRegion) {
                return { success: false, method: "edge_no_region" };
            }

            console.log(`Smart crop: region at (${bestRegion.cx}, ${bestRegion.cy}) r=${bestRegion.r} variance=${bestVariance.toFixed(0)}`);

            // Crop square around the detected region
            const padding = Math.round(bestRegion.r * 0.10);
            const cropSize = (bestRegion.r + padding) * 2;
            const cropX = Math.max(0, bestRegion.cx - Math.round(cropSize / 2));
            const cropY = Math.max(0, bestRegion.cy - Math.round(cropSize / 2));
            const finalSize = Math.max(1, Math.min(cropSize, w - cropX, h - cropY));

            const croppedBuffer = await sharp(buffer)
                .extract({ left: cropX, top: cropY, width: finalSize, height: finalSize })
                .resize(200, 200, { fit: "cover" })
                .jpeg({ quality: 90 })
                .toBuffer();

            return {
                success: true,
                croppedFaceBase64: croppedBuffer.toString("base64"),
                method: "smart_variance",
            };
        } catch (error) {
            console.warn("Smart crop failed:", error.message);
            return { success: false, method: "edge_error" };
        }
    }

    /**
     * Fallback: crop using fixed coordinates for standard Instagram layout.
     * Instagram profile pic is a circle at ~12% from left, ~7% from top,
     * approximately 20% of screen width in diameter.
     */
    static async cropWithFallback(buffer, metadata) {
        const w = metadata.width;
        const h = metadata.height;

        // Instagram profile circle center and size (as % of screen)
        const centerX = Math.round(w * 0.13);
        const centerY = Math.round(h * 0.075);
        const circleRadius = Math.round(w * 0.10);

        const padding = Math.round(circleRadius * 0.10);
        const cropSize = (circleRadius + padding) * 2;
        const cropX = Math.max(0, centerX - Math.round(cropSize / 2));
        const cropY = Math.max(0, centerY - Math.round(cropSize / 2));
        const finalSize = Math.max(1, Math.min(cropSize, w - cropX, h - cropY));

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
