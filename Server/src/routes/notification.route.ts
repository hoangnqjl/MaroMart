import { Router } from "express";
import { NotificationController } from "../modules/notification/notification.controller";

const router = Router();

// [GET] /notifications (Lấy danh sách cho user hiện tại)
// Thay getnoti bằng getByUserId để có sort và limit
router.get("/", NotificationController.getByUserId); 

// [GET] /notifications/admin/all (Nếu muốn admin xem hết)
router.get("/admin/all", NotificationController.getAll);

// [GET] /notifications/:id (Xem chi tiết 1 thông báo)
router.get("/:id", NotificationController.getById);

// [PUT] /notifications/:id (Đánh dấu đã đọc)
// Flutter gọi: _apiService.put(endpoint: '/notifications/$notificationId', ...)
router.put("/:id", NotificationController.markAsRead);

// [DELETE] /notifications/:id (Xóa)
router.delete("/:id", NotificationController.delete);

export default router;