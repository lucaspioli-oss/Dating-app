import * as admin from 'firebase-admin';
import sharp from 'sharp';
import imghash from 'imghash';
import { randomUUID } from 'crypto';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

const getStorage = () => admin.storage().bucket();
const getDb = () => admin.firestore();

export interface FaceData {
  faceHashes: string[];      // Hashes perceptuais das imagens faciais
  faceUrls: string[];        // URLs das imagens no Firebase Storage
  faceDescription: string;   // Descrição textual do rosto
}

export interface FaceUploadResult {
  success: boolean;
  faceUrl?: string;
  faceHash?: string;
  error?: string;
}

export interface FaceMatchResult {
  isMatch: boolean;
  similarity: number;       // 0-100
  matchedAvatarId?: string;
  matchedFaceUrl?: string;
}

// ═══════════════════════════════════════════════════════════════════
// 📸 FACE STORAGE SERVICE
// ═══════════════════════════════════════════════════════════════════

export class FaceStorageService {
  private static readonly HASH_SIZE = 16;          // Tamanho do hash (16x16)
  private static readonly SIMILARITY_THRESHOLD = 85; // % mínimo para considerar match
  private static readonly FACE_SIZE = 200;         // Tamanho em pixels para salvar

  /**
   * Gerar hash perceptual de uma imagem base64
   */
  static async generatePerceptualHash(imageBase64: string): Promise<string> {
    const tempFile = path.join(os.tmpdir(), `face_${randomUUID()}.jpg`);

    try {
      // Converter base64 para buffer
      const imageBuffer = Buffer.from(imageBase64, 'base64');

      // Processar imagem: converter para grayscale e redimensionar
      const processedBuffer = await sharp(imageBuffer)
        .resize(this.HASH_SIZE, this.HASH_SIZE, { fit: 'fill' })
        .grayscale()
        .toBuffer();

      // Salvar temporariamente para o imghash
      await fs.promises.writeFile(tempFile, processedBuffer);

      // Gerar hash perceptual
      const hash = await imghash.hash(tempFile, this.HASH_SIZE, 'hex');

      return hash;
    } finally {
      // Limpar arquivo temporário
      try {
        await fs.promises.unlink(tempFile);
      } catch {
        // Ignorar erro de limpeza
      }
    }
  }

  /**
   * Calcular similaridade entre dois hashes (Hamming distance)
   */
  static calculateHashSimilarity(hash1: string, hash2: string): number {
    if (hash1.length !== hash2.length) return 0;

    // Converter hex para binário
    const bin1 = this.hexToBinary(hash1);
    const bin2 = this.hexToBinary(hash2);

    // Calcular distância de Hamming
    let distance = 0;
    for (let i = 0; i < bin1.length; i++) {
      if (bin1[i] !== bin2[i]) distance++;
    }

    // Converter para similaridade percentual
    const similarity = ((bin1.length - distance) / bin1.length) * 100;
    return Math.round(similarity * 100) / 100;
  }

  private static hexToBinary(hex: string): string {
    return hex
      .split('')
      .map(char => parseInt(char, 16).toString(2).padStart(4, '0'))
      .join('');
  }

  /**
   * Fazer upload de imagem de face para Firebase Storage
   */
  static async uploadFaceImage(
    avatarId: string,
    imageBase64: string
  ): Promise<FaceUploadResult> {
    try {
      const bucket = getStorage();
      const imageBuffer = Buffer.from(imageBase64, 'base64');

      // Processar imagem: redimensionar para tamanho padrão
      const processedBuffer = await sharp(imageBuffer)
        .resize(this.FACE_SIZE, this.FACE_SIZE, {
          fit: 'cover',
          position: 'center'
        })
        .jpeg({ quality: 85 })
        .toBuffer();

      // Gerar nome único para o arquivo
      const fileName = `faces/${avatarId}/${randomUUID()}.jpg`;
      const file = bucket.file(fileName);

      // Upload para Firebase Storage
      await file.save(processedBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // Cache de 1 ano
        },
      });

      // Tornar arquivo público
      await file.makePublic();

      // Obter URL pública
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      // Gerar hash perceptual
      const faceHash = await this.generatePerceptualHash(imageBase64);

      return {
        success: true,
        faceUrl: publicUrl,
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

  /**
   * Buscar avatares candidatos para comparação de face
   */
  static async findCandidateAvatars(
    name: string,
    age: string | undefined,
    platform: string
  ): Promise<Array<{ id: string; faceData: FaceData }>> {
    const normalizedName = name
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]/g, '')
      .trim();

    const db = getDb();

    // Buscar avatares com mesmo nome normalizado e plataforma
    const snapshot = await db
      .collection('collectiveAvatars')
      .where('normalizedName', '==', normalizedName)
      .where('platform', '==', platform.toLowerCase())
      .get();

    const candidates: Array<{ id: string; faceData: FaceData }> = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();

      // Verificar se tem dados de face
      if (!data.faceData?.faceHashes?.length) continue;

      // Verificar idade (se fornecida)
      if (age) {
        const ageNum = parseInt(age);
        const possibleAges = data.profileData?.possibleAges || [];

        // Aceitar idade exata ou +1 (aniversário)
        const ageMatch = possibleAges.some((possibleAge: string) => {
          const possibleAgeNum = parseInt(possibleAge);
          return possibleAgeNum === ageNum || possibleAgeNum === ageNum - 1;
        });

        if (!ageMatch && possibleAges.length > 0) continue;
      }

      candidates.push({
        id: doc.id,
        faceData: data.faceData as FaceData,
      });
    }

    return candidates;
  }

  /**
   * Comparar face com avatares existentes
   */
  static async compareFaceWithAvatars(
    imageBase64: string,
    candidates: Array<{ id: string; faceData: FaceData }>
  ): Promise<FaceMatchResult> {
    if (candidates.length === 0) {
      return { isMatch: false, similarity: 0 };
    }

    try {
      // Gerar hash da nova imagem
      const newHash = await this.generatePerceptualHash(imageBase64);

      let bestMatch: FaceMatchResult = { isMatch: false, similarity: 0 };

      // Comparar com cada candidato
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

  /**
   * Atualizar dados de face de um avatar coletivo
   */
  static async updateAvatarFaceData(
    avatarId: string,
    faceUrl: string,
    faceHash: string,
    faceDescription: string
  ): Promise<void> {
    const db = getDb();
    const docRef = db.collection('collectiveAvatars').doc(avatarId);

    await docRef.update({
      'faceData.faceUrls': admin.firestore.FieldValue.arrayUnion(faceUrl),
      'faceData.faceHashes': admin.firestore.FieldValue.arrayUnion(faceHash),
      'faceData.faceDescription': faceDescription,
      lastUpdated: admin.firestore.Timestamp.fromDate(new Date()),
    });
  }

  /**
   * Inicializar dados de face para novo avatar
   */
  static async initializeAvatarFaceData(
    avatarId: string,
    faceUrl: string,
    faceHash: string,
    faceDescription: string
  ): Promise<void> {
    const db = getDb();
    const docRef = db.collection('collectiveAvatars').doc(avatarId);

    await docRef.update({
      faceData: {
        faceUrls: [faceUrl],
        faceHashes: [faceHash],
        faceDescription,
      },
      lastUpdated: admin.firestore.Timestamp.fromDate(new Date()),
    });
  }

  /**
   * Fluxo completo: detectar duplicata ou criar novo avatar com face
   */
  static async processProfileFace(params: {
    name: string;
    age?: string;
    platform: string;
    imageBase64: string;
    faceDescription: string;
    username?: string;  // Para Instagram
  }): Promise<{
    avatarId: string;
    isExistingMatch: boolean;
    faceUrl: string;
    similarity?: number;
  }> {
    const { name, age, platform, imageBase64, faceDescription, username } = params;

    // Para Instagram, usar username como identificador único
    if (platform.toLowerCase() === 'instagram' && username) {
      const avatarId = `${username.toLowerCase()}_instagram`;

      // Verificar se avatar já existe
      const db = getDb();
      const existingDoc = await db.collection('collectiveAvatars').doc(avatarId).get();

      // Upload da face de qualquer forma (para exibir na conversa)
      const uploadResult = await this.uploadFaceImage(avatarId, imageBase64);

      if (!uploadResult.success || !uploadResult.faceUrl || !uploadResult.faceHash) {
        throw new Error('Falha ao fazer upload da imagem');
      }

      if (existingDoc.exists) {
        // Atualizar com nova face (pode ser foto diferente)
        await this.updateAvatarFaceData(
          avatarId,
          uploadResult.faceUrl,
          uploadResult.faceHash,
          faceDescription
        );

        return {
          avatarId,
          isExistingMatch: true,
          faceUrl: uploadResult.faceUrl,
        };
      } else {
        // Novo avatar - será criado pelo collective-avatar-manager
        return {
          avatarId,
          isExistingMatch: false,
          faceUrl: uploadResult.faceUrl,
        };
      }
    }

    // Para Tinder/Bumble/Hinge: usar nome + idade + face
    // 1. Buscar candidatos
    const candidates = await this.findCandidateAvatars(name, age, platform);

    // 2. Comparar faces
    const matchResult = await this.compareFaceWithAvatars(imageBase64, candidates);

    if (matchResult.isMatch && matchResult.matchedAvatarId) {
      // Match encontrado - usar avatar existente
      const uploadResult = await this.uploadFaceImage(
        matchResult.matchedAvatarId,
        imageBase64
      );

      if (uploadResult.success && uploadResult.faceUrl && uploadResult.faceHash) {
        await this.updateAvatarFaceData(
          matchResult.matchedAvatarId,
          uploadResult.faceUrl,
          uploadResult.faceHash,
          faceDescription
        );
      }

      return {
        avatarId: matchResult.matchedAvatarId,
        isExistingMatch: true,
        faceUrl: matchResult.matchedFaceUrl || uploadResult.faceUrl || '',
        similarity: matchResult.similarity,
      };
    }

    // Nenhum match - criar novo avatar
    const normalizedName = name
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]/g, '')
      .trim();

    // Gerar ID único incluindo idade para diferenciar
    const avatarId = age
      ? `${normalizedName}_${age}_${platform.toLowerCase()}`
      : `${normalizedName}_${platform.toLowerCase()}`;

    const uploadResult = await this.uploadFaceImage(avatarId, imageBase64);

    if (!uploadResult.success || !uploadResult.faceUrl) {
      throw new Error('Falha ao fazer upload da imagem');
    }

    return {
      avatarId,
      isExistingMatch: false,
      faceUrl: uploadResult.faceUrl,
    };
  }
}
