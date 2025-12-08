// src/controllers/user.controller.ts
import { Request, Response } from "express";
import { UserService }   from "./user.service";
import { canAccessUser } from "@/utils/authorization";
import { moderateUserInputFields } from "@/services/moderateText";


const userService = new UserService();

export class UserController {

  static async getAllUsers(req: Request, res: Response) {
    try {
      const users = await userService.getAllUsers();
      res.status(200).json(users);
    } catch (error) {
      res.status(500).json({ message: "Failed to get users", error });
    }
  }

  
  static async getUserById(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const user = await userService.getUserById(userId);
      // if (!(await canAccessUser(req, userId, res))) return;

      if (!user) return res.status(404).json({ message: "User not found" });
      res.status(200).json(user);
    } catch (error) {
      res.status(500).json({ message: "Failed to get user", error });
    }
  }


  // Cập nhật user
  static async updateUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const data = req.body;

      console.log(data)
      // Kiểm quyền truy cập user
      if (!(await canAccessUser(req, userId, res))) return;

      // Lọc ra các field text cần kiểm duyệt
      const textFields: Record<string, string> = {};
      ["fullName", "country", "address"].forEach((field) => {
        if (data[field]) textFields[field] = data[field];
      });

      

      // Nếu có field text, kiểm duyệt
      if (Object.keys(textFields).length > 0) {
        const check = await moderateUserInputFields(textFields);

        for (const [field, result] of Object.entries(check)) {
          if (!result.isSafe) {
            return res.status(400).json({ error: `${field} is invalid: ${result.reason}` });
          }
        }
      }

      // Nếu tất cả field an toàn, tiến hành update
      const user = await userService.updateUser(userId, data);
      if (!user) return res.status(404).json({ message: "User not found" });

      res.status(200).json(user);
    } catch (error: any) {
      res.status(400).json({ message: error.message || "Failed to update user" });
    }
  }


  // Xóa user
  static async deleteUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;

      if (!(await canAccessUser(req, userId, res))) return;

      const user = await userService.deleteUser(userId);
      if (!user) return res.status(404).json({ message: "User not found" });
      res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
      res.status(500).json({ message: "Failed to delete user", error });
    }
  }
}
