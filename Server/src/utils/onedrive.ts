// backend/src/utils/onedrive.ts
import axios from 'axios';
import * as fs from 'fs';
import * as path from 'path';
import { v2 as cloudinary } from 'cloudinary';
import 'dotenv/config';

// ==================== CẤU HÌNH CLOUDINARY ====================
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Helper: upload 1 file lên Cloudinary và trả về URL + public_id
const uploadToCloudinary = async (
    filePath: string,
    options: any = {}
): Promise<{ url: string; public_id: string }> => {
    const defaultOptions = {
        overwrite: true,
        invalidate: true,
    };

    const finalOptions = { ...defaultOptions, ...options };

    const result = await cloudinary.uploader.upload(filePath, finalOptions);
    return {
        url: result.secure_url,
        public_id: result.public_id,
    };
};

// ==================== GIỮ NGUYÊN CÁC HÀM EXPORT ====================

// Upload 1 file đơn lẻ (dùng trong MaroMart cũ)
export const uploadToMaroMart = async (filePath: string, fileName: string): Promise<string> => {
    try {
        const ext = path.extname(filePath).toLowerCase();
        const resource_type = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.ogg', '.mp3', '.wav'].includes(ext)
            ? 'video'
            : 'image';

        const { url } = await uploadToCloudinary(filePath, {
            folder: 'MaroMart',
            public_id: path.basename(fileName, ext), // giữ tên file gốc (không random)
            resource_type,
        });

        return url; // Cloudinary trả luôn direct link vĩnh viễn
    } catch (error: any) {
        console.error('Cloudinary upload error (uploadToMaroMart):', error);
        throw error;
    }
};

// Upload nhiều file (images + videos) theo cấu trúc userId/productId
export const uploadMultipleToOneDrive = async (
    files: Express.Multer.File[],
    userId: string,
    productId: string
): Promise<{ images: string[]; videos: string[] }> => {
    if (!files || files.length === 0) return { images: [], videos: [] };

    const result = { images: [] as string[], videos: [] as string[] };

    for (const file of files) {
        const ext = path.extname(file.originalname).toLowerCase();
        const isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'].includes(ext);

        const resource_type = isVideo ? 'video' : 'image';
        const folder = `MaroMart/${userId}/products/${productId}/${isVideo ? 'videos' : 'images'}`;

        const safeName = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}${ext}`;

        try {
            const { url } = await uploadToCloudinary(file.path, {
                folder,
                public_id: path.basename(safeName, ext),
                resource_type,
            });

            const prefixedUrl = isVideo ? `video:${url}` : `image:${url}`;

            if (isVideo) {
                result.videos.push(prefixedUrl);
            } else {
                result.images.push(prefixedUrl);
            }

            // Xóa file tạm
            fs.unlinkSync(file.path);
        } catch (error: any) {
            console.error('Cloudinary upload error:', error);
            // Không ném lỗi để không làm hỏng toàn bộ batch
            continue;
        }
    }

    return result;
};

// (Tùy chọn) Upload media chat – giữ nguyên tên hàm cũ nếu FE vẫn gọi
// export const uploadChatMediaToOneDrive = async (
//     files: Express.Multer.File[],
//     conId: string,
//     messageId: string
// ): Promise<{ type: string; url: string }[]> => {
//     if (!files || files.length === 0) return [];

//     const mediaResult: { type: string; url: string }[] = [];

//     for (const file of files) {
//         const ext = path.extname(file.originalname).toLowerCase();
//         const isVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'].includes(ext);
//         const isAudio = ['.mp3', '.wav', '.ogg', '.m4a'].includes(ext);

//         const resource_type = isVideo || isAudio ? 'video' : 'image';
//         const folder = `Conversation/${conId}/${messageId}/${isVideo || isAudio ? 'videos' : 'images'}`;
//         const safeName = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}${ext}`;

//         const { url } = await uploadToCloudinary(file.path, {
//             folder,
//             public_id: path.basename(safeName, ext),
//             resource_type,
//         });

//         const type = isVideo ? 'video' : isAudio ? 'audio' : 'image';
//         mediaResult.push({
//             type,
//             url: `${type}:${url}`,
//         });

//         fs.unlinkSync(file.path);
//     }

//     return mediaResult;
// };

// Các hàm cũ không còn dùng nữa (để lại để tránh lỗi import nếu có nơi gọi nhầm)
export const ensureFolder = async () => { /* không cần nữa */ };
export const ensureFolderByPath = async () => { /* không cần nữa */ };

// Export cloudinary instance nếu cần dùng trực tiếp ở nơi khác
export { cloudinary };