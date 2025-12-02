// src/modules/admin/admin.controller.ts
import { Request, Response } from "express";
import Product from "@/modules/product/product.model";
import User from "@/modules/user/user.model";
import Category from "@/modules/category/category.model";

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
      await user.save();

      res.json({ userId, newRole: user.role });
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  // 4. Xóa user (hard delete)
  static async deleteUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      await User.deleteOne({ userId });
      res.json({ message: "User deleted" });
    } catch (error: any) {
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