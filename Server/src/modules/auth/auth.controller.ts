import admin from 'firebase-admin';
import bcrypt from 'bcrypt';

import { UserService } from '../user/user.service';
import { Request, Response } from 'express';
import { Security } from '@/middlewares/security';
import { generateToken } from '@/middlewares/jwt';

const userService = new UserService()
const sec = new Security()


export class AuthController { 
  static async googleLogin(req: Request, res: Response) {
    try {
      const { idToken } = req.body;
      if (!idToken) {
        return res.status(400).json({ success: false, message: "Missing idToken" });
      }

      const decoded = await admin.auth().verifyIdToken(idToken);
      const { email, name: fullName } = decoded;

      if (!email) {
        return res.status(400).json({ success: false, message: "No email from Google" });
      }
      if (!fullName) {
        return res.status(400).json({ success: false, message: "fullName is required from Google" });
      }

      const user = await userService.googleLogin({ email, fullName });
      return res.status(200).json({ success: true, message: "Đăng nhập Google thành công!", user });

    } catch (error: any) {
      console.error("Google Login Error:", error);
      return res.status(500).json({
        success: false,
        message: "Lỗi server",
        error: error.message || "Unknown error"
      });
    }
  }

    static async register(req: Request, res: Response) {
    try {
      const { fullName, email, phoneNumber, password } = req.body;

      if (!fullName) return res.status(400).json({ error: "fullName is required" });
      if (!email) return res.status(400).json({ error: "email is required" });

      const hashedPassword = await sec.HashedPassword(password);

      const user = await userService.registerWithForm({
        fullName,
        email,
        phoneNumber,
        password: hashedPassword
      });

      res.status(201).json({ success: true, message: "Đăng ký thành công!", user });

    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

   static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      if (!email) return res.status(400).json({ error: "email is required" });
      if (!password) return res.status(400).json({ error: "password is required" });

      const user = await userService.login(email, password);
      
      const token = generateToken(JSON.stringify({
        userId: user.userId,
        role: user.role
      }));

      return res.json({
        message: "Đăng nhập thành công",
        token,
        // user: {
        //   email: user.email,
        //   fullName: user.fullName,
        //   role: user.role,
        // },
      });

    } catch (err: any) {
      return res.status(401).json({ message: err.message });
    }
  }



}
