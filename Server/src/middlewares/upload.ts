import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Tạo thư mục tạm nếu chưa có
const tempDir = 'uploads/temp';
if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, tempDir);
    },
    filename: (req, file, cb) => {
        const unique = Date.now() + '-' + Math.random().toString(36).substring(2, 8);
        cb(null, `temp-${unique}${path.extname(file.originalname)}`);
    }
});

export const upload = multer({
    storage,
    limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
    fileFilter: (req, file, cb) => {
        const allowed = /jpeg|jpg|png|gif|webp|mp4|mov|avi|mkv/;
        const ext = path.extname(file.originalname).toLowerCase();
        if (allowed.test(ext) || allowed.test(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Chỉ cho phép ảnh và video!'));
        }
    }
});