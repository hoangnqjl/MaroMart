import { Router } from "express"; 
import {UserController} from "../modules/user/user.controller"
import { checkRole } from "../middlewares/check.user";

const router = Router(); 

router.get("/", checkRole(['admin']), UserController.getAllUsers);
router.get("/:userId", UserController.getUserById)
router.put("/:userId", checkRole(['admin', 'user']), UserController.updateUser)

export default router;