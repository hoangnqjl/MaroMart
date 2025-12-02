import { Request, Response } from "express";
import { UserService } from "../modules/user/user.service"; // chỉnh đường dẫn theo project
// hàm verifyToken trả về payload
import {  getUserIdFromToken } from "../middlewares/check.user"

const userService = new UserService();

/**
 * Kiểm tra quyền admin hoặc chính user dựa vào JWT token
 * @param req - Request object, chứa token trong headers.authorization
 * @param targetUserId - id user mà muốn thao tác
 * @param res - Response object, trả về 403 nếu không có quyền
 * @returns true nếu được phép, false nếu bị chặn
 */
export async function canAccessUser(req: Request, targetUserId: string, res: Response): Promise<boolean> {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
        res.status(401).json({ message: "Token not provided" });
        return false;
    }

    const userId =  await getUserIdFromToken(token)
    
    if (!userId) {
        res.status(401).json({ message: "Invalid token" });
        return false;
    }
    
    const user = await userService.getUserById(userId);

    if (!user) {
        res.status(404).json({ message: "User not found" });
        return false;
    }

    if (user.role === "admin" || userId === targetUserId) {
        return true;
    }

    res.status(403).json({ message: "Access denied" });
    return false;
}


export async function canAccessAdmin(req: Request, res: Response): Promise<boolean> {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
        res.status(401).json({ message: "Token not provided" });
        return false;
    }

    const userId =  await getUserIdFromToken(token)
    
    if (!userId) {
        res.status(401).json({ message: "Invalid token" });
        return false;
    }
    
    const user = await userService.getUserById(userId);

    if (!user) {
        res.status(404).json({ message: "User not found" });
        return false;
    }

    if (user.role === "admin") {
        return true;
    }

    res.status(403).json({ message: "Access denied" });
    return false;
}


export async function getUserId(req: Request, res: Response): Promise<string | boolean> {
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
        res.status(401).json({ message: "Token not provided" });
        return false;
    }

    const userId =  await getUserIdFromToken(token)
    
    if (!userId) {
        res.status(401).json({ message: "Invalid token" });
        return false;
    }
    
    return userId;
}