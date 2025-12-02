import { Router } from "express";
import { ProductController } from "../modules/product/product.controller";
import { checkRole } from "../middlewares/check.user";
import { upload } from "../middlewares/upload";   // THÊM DÒNG NÀY!!!

const router = Router();

// ==========================
//       PRODUCT ROUTES
// ==========================
router.get("/filter-product", ProductController.filter);

router.get("/search", ProductController.search)

router.get("/", ProductController.getAll);
router.get("/:id", ProductController.getById);

// TẠO SẢN PHẨM – BẮT BUỘC PHẢI CÓ UPLOAD TRƯỚC CONTROLLER
router.post(
  "/",
  checkRole(['admin', 'user']),
  upload.array('productMedia', 20),   // THÊM DÒNG NÀY – QUAN TRỌNG NHẤT!!!
  ProductController.create
);

// CẬP NHẬT SẢN PHẨM (nếu muốn cho phép thêm/sửa ảnh)
router.put(
  "/:id",
  checkRole(['admin', 'user']),
  upload.array('productMedia', 20),   // thêm nếu muốn update ảnh
  ProductController.update
);

router.delete("/:id", checkRole(['admin', 'user']), ProductController.delete);

export default router;