import { checkRole } from "@/middlewares/check.user";
import { CategoryController } from "../modules/category/category.controller";
import { Router } from "express"; 

const router = Router()


router.get("/", CategoryController.getAll)
router.get("/:id", CategoryController.getById)

router.post("/", checkRole(['admin']), CategoryController.create)
router.patch("/:id", checkRole(['admin']), CategoryController.update)

router.delete("/:id",checkRole(['admin']) ,CategoryController.delete)


export default router;