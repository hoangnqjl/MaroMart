// src/routes/auth.ts
import express from 'express';
import admin from 'firebase-admin';
import serviceAccount from '../modules/auth/serviceAccountKey.json';
import { AuthController } from '@/modules/auth/auth.controller';

const router = express.Router();

// Khởi tạo Firebase Admin (chỉ 1 lần)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount as admin.ServiceAccount)
  });
}

router.post('/login/google', AuthController.googleLogin);
router.post('/register', AuthController.register)
router.post('/login', AuthController.login)

export default router;