// src/controllers/user.controller.ts
import { Request, Response } from "express";
import { UserService }   from "./user.service";
import { canAccessUser } from "@/utils/authorization";


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

      if (!(await canAccessUser(req, userId, res))) return;

      console.log(data)

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
