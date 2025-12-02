// src/routes/admin.route.ts
import { Router } from "express";
import { checkRole } from "@/middlewares/check.user";
import { AdminController } from "../modules/admin/admin.controller";
import {UserController} from "../modules/user/user.controller"

const router = Router();

// Tất cả route dưới đây chỉ admin mới vào được
router.use(checkRole(['admin']));

// === PRODUCTS MANAGEMENT ===
router.get("/products", AdminController.getAllProducts);        // phân trang + populate đầy đủ
router.delete("/products/:productId", AdminController.deleteAnyProduct);

// === USERS MANAGEMENT ===

router.get("/users", checkRole(['admin']), UserController.getAllUsers);
router.patch("/users/:userId/role", AdminController.toggleUserRole);   // đổi admin ↔ user
router.delete("/users/:userId", AdminController.deleteUser);

// === STATISTICS ===
router.get("/stats/overview", AdminController.getDashboardStats);
router.get("/stats/daily-posts", AdminController.getDailyPostStats);   // 7 ngày gần nhất
router.get("/stats/top-products", AdminController.getTopProducts);
router.get("/stats/products-per-category", AdminController.getProductsPerCategory);

export default router;