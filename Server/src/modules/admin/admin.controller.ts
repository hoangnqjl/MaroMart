// src/modules/admin/admin.controller.ts
import { Request, Response } from "express";
import Product from "@/modules/product/product.model";
import User from "@/modules/user/user.model";
import Category from "@/modules/category/category.model";
import { Message, Conversation } from "@/modules/conversation/conversation.model";
import Notification from "@/modules/notification/notification.model";

export class AdminController {

  // 1. Lấy tất cả sản phẩm (có phân trang + populate đầy đủ)
  static async getAllProducts(req: Request, res: Response) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;
      const skip = (page - 1) * limit;

      const products = await Product.find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate({
          path: 'userInfo',
          select: 'fullName avatarUrl email phoneNumber'
        })
        .lean();

      const total = await Product.countDocuments();

      res.json({ products, total, page, limit });
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  // 2. Admin xóa sản phẩm của bất kỳ ai
  static async deleteAnyProduct(req: Request, res: Response) {
    try {
      const { productId } = req.params;
      const result = await Product.deleteOne({ productId });
      if (result.deletedCount === 0) return res.status(404).json({ message: "Product not found" });
      res.json({ message: "Product deleted successfully" });
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  // 3. Toggle role user (admin → user và ngược lại)
  static async toggleUserRole(req: Request, res: Response) {


    try {
      const { userId } = req.params;

      const user = await User.findOne({ userId });
      if (!user) return res.status(404).json({ message: "User not found" });

      user.role = user.role === "admin" ? "user" : "admin";


      console.log(userId)
      console.log(user.role)

      await user.save();

      res.json({ userId, newRole: user.role });
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  static async updateUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const {
        fullName,
        email,
        phoneNumber,
        avatarUrl,
        isLocked,   // khóa tài khoản (true = bị khóa)
        role        // admin có thể đổi role (admin ↔ user)
      } = req.body;

      // Tìm user
      const user = await User.findOne({ userId });
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }

      // Danh sách các trường được phép cập nhật
      if (fullName !== undefined) user.fullName = fullName;
      if (email !== undefined) {
        // Kiểm tra email đã tồn tại chưa (trừ chính user này)
        const existingEmail = await User.findOne({ email, userId: { $ne: userId } });
        if (existingEmail) {
          return res.status(400).json({ message: "Email đã được sử dụng bởi tài khoản khác" });
        }
        user.email = email;
      }
      if (phoneNumber !== undefined) user.phoneNumber = phoneNumber || null;
      if (avatarUrl !== undefined) user.avatarUrl = avatarUrl || null;
      if (role !== undefined) {
        if (!["user", "admin"].includes(role)) {
          return res.status(400).json({ message: "Role không hợp lệ. Chỉ chấp nhận 'user' hoặc 'admin'" });
        }
        user.role = role;
      }

      await user.save();

      // Trả về thông tin đã cập nhật (không trả password)
      const updatedUser = await User.findOne({ userId })
        .select('userId fullName email phoneNumber avatarUrl isLocked role createdAt')
        .lean();

      res.json({
        message: "Cập nhật thông tin người dùng thành công",
        user: updatedUser
      });
    } catch (error: any) {
      console.error("Admin update user error:", error);
      res.status(500).json({ message: error.message || "Lỗi server" });
    }
  }

  // 4. Xóa user (hard delete)
  // 4. Xóa user (hard delete)
  static async deleteUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;

      const user = await User.findOne({ userId });
      if (!user) {
        return res.status(404).json({ message: "User not found" });
      }

      // 1. Xóa sản phẩm của user
      await Product.deleteMany({ userId });

      // 2. Tìm các cuộc trò chuyện liên quan
      const conversations = await Conversation.find({
        $or: [{ userId1: userId }, { userId2: userId }]
      });

      const conIds = conversations.map(c => c.conId);

      // 3. Xóa tin nhắn và cuộc trò chuyện
      if (conIds.length > 0) {
        await Message.deleteMany({ conId: { $in: conIds } });
        await Conversation.deleteMany({ conId: { $in: conIds } });
      }

      // 4. Xóa thông báo (nhận hoặc gửi)
      await Notification.deleteMany({
        $or: [
          { userId: userId },             // Thông báo user này nhận
          { "data.senderId": userId }     // Thông báo user này gửi (ví dụ tin nhắn mới)
        ]
      });

      // 5. Xóa user
      await User.deleteOne({ userId });

      res.json({ message: "User and all related data deleted successfully" });
    } catch (error: any) {
      console.error("Delete user error:", error);
      res.status(500).json({ message: error.message });
    }
  }

  // 5. Thống kê tổng quan
  static async getDashboardStats(req: Request, res: Response) {
    const totalProducts = await Product.countDocuments();
    const totalUsers = await User.countDocuments();
    const totalCategories = await Category.countDocuments();

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const postsToday = await Product.countDocuments({ createdAt: { $gte: todayStart } });

    res.json({
      totalProducts,
      totalUsers,
      totalCategories,
      postsToday
    });
  }

  // 6. Số bài đăng 7 ngày gần nhất
  static async getDailyPostStats(req: Request, res: Response) {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const stats = await Product.aggregate([
      { $match: { createdAt: { $gte: sevenDaysAgo } } },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    res.json(stats);
  }

  // 7. Top 10 sản phẩm xem nhiều nhất (hoặc mới nhất)
  static async getTopProducts(req: Request, res: Response) {
    const top = await Product.find()
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('userInfo', 'fullName')
      .select('productName productPrice productMedia createdAt')
      .lean();

    res.json(top);
  }

  // 8. Số sản phẩm theo từng category
  static async getProductsPerCategory(req: Request, res: Response) {
    const stats = await Product.aggregate([
      {
        $group: {
          _id: "$categoryId",
          count: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: "categories",
          localField: "_id",
          foreignField: "categoryId",
          as: "category"
        }
      },
      { $unwind: "$category" },
      {
        $project: {
          categoryName: "$category.categoryName",
          count: 1
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json(stats);
  }
}