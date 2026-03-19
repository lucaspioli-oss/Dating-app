"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FaceStorageService = void 0;
const sharp_1 = __importDefault(require("sharp"));
const imghash_1 = __importDefault(require("imghash"));
const crypto_1 = require("crypto");
const path = require("path");
const os = require("os");
const fs = require("fs");
const { supabaseAdmin } = require("../config/supabase");

class FaceStorageService {
    static HASH_SIZE = 16;
    static SIMILARITY_THRESHOLD = 85;
    static FACE_SIZE = 200;

    static async generatePerceptualHash(imageBase64) {
        const tempFile = path.join(os.tmpdir(), `face_${(0, crypto_1.randomUUID)()}.jpg`);
        try {
            const imageBuffer = Buffer.from(imageBase64, 'base64');
            const processedBuffer = await (0, sharp_1.default)(imageBuffer)
                .resize(this.HASH_SIZE, this.HASH_SIZE, { fit: 'fill' })
                .grayscale()
                .toBuffer();
            await fs.promises.writeFile(tempFile, processedBuffer);
            const hash = await imghash_1.default.hash(tempFile, this.HASH_SIZE, 'hex');
            return hash;
        } finally {
            try { await fs.promises.unlink(tempFile); } catch { }
        }
    }

    static calculateHashSimilarity(hash1, hash2) {
        if (hash1.length !== hash2.length) return 0;
        const bin1 = this.hexToBinary(hash1);
        const bin2 = this.hexToBinary(hash2);
        let distance = 0;
        for (let i = 0; i < bin1.length; i++) {
            if (bin1[i] !== bin2[i]) distance++;
        }
        const similarity = ((bin1.length - distance) / bin1.length) * 100;
        return Math.round(similarity * 100) / 100;
    }

    static hexToBinary(hex) {
        return hex.split('').map(char => parseInt(char, 16).toString(2).padStart(4, '0')).join('');
    }

    /**
     * Upload face image to Supabase Storage
     */
    static async uploadFaceImage(avatarId, imageBase64) {
        try {
            const imageBuffer = Buffer.from(imageBase64, 'base64');
            const processedBuffer = await (0, sharp_1.default)(imageBuffer)
                .resize(this.FACE_SIZE, this.FACE_SIZE, { fit: 'cover', position: 'center' })
                .jpeg({ quality: 85 })
                .toBuffer();

            const fileName = `faces/${avatarId}/${(0, crypto_1.randomUUID)()}.jpg`;

            const { error: uploadError } = await supabaseAdmin.storage
                .from('faces')
                .upload(fileName, processedBuffer, {
                    contentType: 'image/jpeg',
                    cacheControl: '31536000',
                });

            if (uploadError) {
                // If bucket doesn't exist, try creating it
                if (uploadError.message?.includes('not found')) {
                    await supabaseAdmin.storage.createBucket('faces', { public: true });
                    await supabaseAdmin.storage
                        .from('faces')
                        .upload(fileName, processedBuffer, {
                            contentType: 'image/jpeg',
                            cacheControl: '31536000',
                        });
                } else {
                    throw uploadError;
                }
            }

            const { data: urlData } = supabaseAdmin.storage
                .from('faces')
                .getPublicUrl(fileName);

            const faceHash = await this.generatePerceptualHash(imageBase64);

            return {
                success: true,
                faceUrl: urlData.publicUrl,
                faceHash,
            };
        } catch (error) {
            console.error('Erro ao fazer upload da face:', error);
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Erro desconhecido',
            };
        }
    }

    static async findCandidateAvatars(name, age, platform) {
        const normalizedName = name
            .toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '').trim();

        const { data: rows } = await supabaseAdmin
            .from('collective_avatars')
            .select('*')
            .eq('normalized_name', normalizedName)
            .eq('platform', platform.toLowerCase());

        const candidates = [];
        for (const row of (rows || [])) {
            const faceData = row.face_data || row.profile_data?.faceData;
            if (!faceData?.faceHashes?.length) continue;

            if (age) {
                const ageNum = parseInt(age);
                const possibleAges = row.profile_data?.possibleAges || [];
                const ageMatch = possibleAges.some((possibleAge) => {
                    const possibleAgeNum = parseInt(possibleAge);
                    return possibleAgeNum === ageNum || possibleAgeNum === ageNum - 1;
                });
                if (!ageMatch && possibleAges.length > 0) continue;
            }
            candidates.push({ id: row.id, faceData });
        }
        return candidates;
    }

    static async compareFaceWithAvatars(imageBase64, candidates) {
        if (candidates.length === 0) return { isMatch: false, similarity: 0 };
        try {
            const newHash = await this.generatePerceptualHash(imageBase64);
            let bestMatch = { isMatch: false, similarity: 0 };

            for (const candidate of candidates) {
                for (let i = 0; i < candidate.faceData.faceHashes.length; i++) {
                    const existingHash = candidate.faceData.faceHashes[i];
                    const similarity = this.calculateHashSimilarity(newHash, existingHash);
                    if (similarity > bestMatch.similarity) {
                        bestMatch = {
                            isMatch: similarity >= this.SIMILARITY_THRESHOLD,
                            similarity,
                            matchedAvatarId: candidate.id,
                            matchedFaceUrl: candidate.faceData.faceUrls[i],
                        };
                    }
                }
            }
            return bestMatch;
        } catch (error) {
            console.error('Erro ao comparar faces:', error);
            return { isMatch: false, similarity: 0 };
        }
    }

    static async updateAvatarFaceData(avatarId, faceUrl, faceHash, faceDescription) {
        const { data: doc } = await supabaseAdmin
            .from('collective_avatars')
            .select('profile_data')
            .eq('id', avatarId)
            .single();

        if (!doc) return;
        const faceData = doc.profile_data?.faceData || { faceUrls: [], faceHashes: [] };
        faceData.faceUrls = [...(faceData.faceUrls || []), faceUrl];
        faceData.faceHashes = [...(faceData.faceHashes || []), faceHash];
        faceData.faceDescription = faceDescription;

        const profileData = { ...(doc.profile_data || {}), faceData };

        await supabaseAdmin
            .from('collective_avatars')
            .update({ profile_data: profileData, last_updated: new Date().toISOString() })
            .eq('id', avatarId);
    }

    static async initializeAvatarFaceData(avatarId, faceUrl, faceHash, faceDescription) {
        const { data: doc } = await supabaseAdmin
            .from('collective_avatars')
            .select('profile_data')
            .eq('id', avatarId)
            .single();

        const profileData = {
            ...(doc?.profile_data || {}),
            faceData: { faceUrls: [faceUrl], faceHashes: [faceHash], faceDescription },
        };

        await supabaseAdmin
            .from('collective_avatars')
            .update({ profile_data: profileData, last_updated: new Date().toISOString() })
            .eq('id', avatarId);
    }

    static async processProfileFace(params) {
        const { name, age, platform, imageBase64, faceDescription, username } = params;

        if (platform.toLowerCase() === 'instagram' && username) {
            const avatarId = `${username.toLowerCase()}_instagram`;
            const { data: existingDoc } = await supabaseAdmin
                .from('collective_avatars')
                .select('id')
                .eq('id', avatarId)
                .single();

            const uploadResult = await this.uploadFaceImage(avatarId, imageBase64);
            if (!uploadResult.success || !uploadResult.faceUrl || !uploadResult.faceHash) {
                throw new Error('Falha ao fazer upload da imagem');
            }

            if (existingDoc) {
                await this.updateAvatarFaceData(avatarId, uploadResult.faceUrl, uploadResult.faceHash, faceDescription);
                return { avatarId, isExistingMatch: true, faceUrl: uploadResult.faceUrl };
            }
            return { avatarId, isExistingMatch: false, faceUrl: uploadResult.faceUrl };
        }

        const candidates = await this.findCandidateAvatars(name, age, platform);
        const matchResult = await this.compareFaceWithAvatars(imageBase64, candidates);

        if (matchResult.isMatch && matchResult.matchedAvatarId) {
            const uploadResult = await this.uploadFaceImage(matchResult.matchedAvatarId, imageBase64);
            if (uploadResult.success && uploadResult.faceUrl && uploadResult.faceHash) {
                await this.updateAvatarFaceData(matchResult.matchedAvatarId, uploadResult.faceUrl, uploadResult.faceHash, faceDescription);
            }
            return {
                avatarId: matchResult.matchedAvatarId,
                isExistingMatch: true,
                faceUrl: matchResult.matchedFaceUrl || uploadResult.faceUrl || '',
                similarity: matchResult.similarity,
            };
        }

        const normalizedName = name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '').trim();
        const avatarId = age ? `${normalizedName}_${age}_${platform.toLowerCase()}` : `${normalizedName}_${platform.toLowerCase()}`;
        const uploadResult = await this.uploadFaceImage(avatarId, imageBase64);
        if (!uploadResult.success || !uploadResult.faceUrl) {
            throw new Error('Falha ao fazer upload da imagem');
        }
        return { avatarId, isExistingMatch: false, faceUrl: uploadResult.faceUrl };
    }
}
exports.FaceStorageService = FaceStorageService;
