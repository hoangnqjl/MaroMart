// backend/src/routes/upload.ts
import express from 'express';
import {UploadController} from '@/modules/cloud/cloud.storage'

const router = express.Router();

router.post('/avatar', UploadController.uploadAvatar)

export default router;