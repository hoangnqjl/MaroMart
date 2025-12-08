import { Request, Response } from 'express';
import { uploadToMaroMart } from '../../utils/onedrive';
import * as fs from 'fs';
import * as path from 'path';
import multer from 'multer';
import {UserService} from '../user/user.service';

const userService = new UserService();

const allowedImageTypes = [
  'image/jpeg', 'image/png', 'image/gif',
  'image/webp', 'image/heic', 'image/heif'
];

const allowedVideoTypes = [
  'video/mp4', 'video/quicktime', 'video/hevc'
];

const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 100 * (1024 ** 4) },
  fileFilter: (req, file, cb) => {
    if (file.fieldname === 'images') {
      if (allowedImageTypes.includes(file.mimetype)) {
        cb(null, true);
      } else {
        cb(new Error('Invalid image type'), false);
      }
    } else if (file.fieldname === 'video') {
      // Cho phép tất cả video hoặc lọc theo allowedVideoTypes
      cb(null, true);
    } else if (file.fieldname === 'avatar') {
      // Cho phép tất cả avatar hoặc lọc nếu muốn
      cb(null, true);
    } else {
      cb(new Error('Unexpected field'), false);
    }
  }
}).fields([
  { name: 'avatar', maxCount: 1 },
  { name: 'images', maxCount: 10 },
  { name: 'video', maxCount: 2 }
]);


export class UploadController {

  static async uploadAvatar (req: Request, res: Response): Promise<void> {
      upload(req, res, async (err) => {
      if (err) {
        return res.status(400).json({ success: false, error: err.message });
      }
      
      const userId = req.body.userId;
      if (!userId) {
        return res.status(400).json({ success: false, error: 'userId is required' });
      }

      const avatarFile = (req.files as any)?.avatar?.[0];
      if (!avatarFile) {
        return res.status(400).json({ success: false, error: 'No avatar uploaded' });
      }

      const filePath = avatarFile.path;
      const fileName = `${userId}/avatar${path.extname(avatarFile.originalname)}`;

      try {
        // 1. UPLOAD LÊN MAROMART
        const avatarUrl = await uploadToMaroMart(filePath, fileName);

        // 2. XÓA FILE TẠM
        fs.unlinkSync(filePath);

        // 3. DÙNG UserService ĐỂ LƯU VÀO DB
        const result = await userService.updateAvatar(userId, avatarUrl);

        // 4. TRẢ KẾT QUẢ
        res.json({
          success: true,
          message: 'Avatar uploaded & saved to DB!',
          userId: result.userId,
          avatarUrl: result.avatarUrl
        });

      } catch (error: any) {
        console.error('Upload avatar error:', error);
        res.status(500).json({
          success: false,
          error: error.message || 'Upload failed'
        });
      }
    });
  }

  static async uploadProductImages(req: Request, res: Response): Promise<void> {
      upload(req, res, async (err) => {
      if (err) return res.status(400).json({ error: err.message });

      const userId = req.body.userId;
      const productId = req.body.productId || `product_${Date.now()}`;
      const imageFiles = (req.files as any)?.images;

      if (!imageFiles || imageFiles.length === 0) {
        return res.status(400).json({ error: 'No images uploaded' });
      }

      const urls: string[] = [];

      for (const file of imageFiles) {
        const filePath = file.path;
        const fileName = `${userId}/product/${productId}/${Date.now()}_${file.originalname}`;

        try {
          const url = await uploadToMaroMart(filePath, fileName);
          urls.push(url);
          fs.unlinkSync(filePath);
        } catch (error: any) {
          fs.unlinkSync(filePath);
          return res.status(500).json({ error: error.message });
        }
      }

      res.json({
        message: 'Product images uploaded!',
        userId,
        productId,
        imageUrls: urls
      });
    });
  }

  static async uploadProductVideo (req: Request, res: Response): Promise<void> {
      upload(req, res, async (err) => {
      if (err) return res.status(400).json({ error: err.message });

      const userId = req.body.userId;
      const productId = req.body.productId;
      const videoFile = (req.files as any)?.video?.[0];

      if (!videoFile || !userId || !productId) {
        return res.status(400).json({ error: 'Missing video or product info' });
      }

      const filePath = videoFile.path;
      const fileName = `${userId}/product/${productId}/video${path.extname(videoFile.originalname)}`;

      try {
        const url = await uploadToMaroMart(filePath, fileName);
        fs.unlinkSync(filePath);

        res.json({
          message: 'Video uploaded!',
          userId,
          productId,
          videoUrl: url
        });
      } catch (error: any) {
        res.status(500).json({ error: error.message });
      }
    });
  }
}
