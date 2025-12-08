import { Router } from "express";
import { ProductController } from "../modules/product/product.controller";
import { checkRole } from "../middlewares/check.user";
import { upload } from "../middlewares/upload";   // THÊM DÒNG NÀY!!!

const router = Router();


router.get("/filter-product", ProductController.filter);

router.get("/search", ProductController.search)

router.get("/", ProductController.getAll);
router.get("/:id", ProductController.getById);

router.post(
  "/",
  checkRole(['admin', 'user']),
  upload.array('productMedia', 20),   
  ProductController.create
);

router.put(
  "/:id",
  checkRole(['admin', 'user']),
  upload.array('productMedia', 20),   
  ProductController.update
);

router.delete("/:id", checkRole(['admin', 'user']), ProductController.delete);

export default router;