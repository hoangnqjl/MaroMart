import { Request, Response, NextFunction } from 'express';
import { verifyToken, TokenPayload } from './jwt';
import { UserService } from '../modules/user/user.service'; // giả sử bạn có model User

const userService = new UserService()

export const checkRole = (allowedRoles: Array<'user' | 'admin'>) => {
    return async (req: Request, res: Response, next: NextFunction) => {
        const token = req.headers.authorization?.split(" ")[1];

        if (!token) {
            return res.status(401).json({ message: "Missing token" });
        }

        const payload = verifyToken(token);
        if (!payload) {
            return res.status(401).json({ message: "Invalid token" });
        }

        try {
            // Tra cứu role trong DB bằng user_id
            const user = await userService.getUserById(payload.userId);
            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }

            if (!allowedRoles.includes(user.role)) {
                return res.status(403).json({ message: "Access denied" });
            }

            // Gắn user vào request
            (req as any).user = user;
            next();
        } catch (err) {
            console.error(err);
            return res.status(500).json({ message: "Internal server error" });
        }
    };
};

export async function getUserIdFromToken (token: string): Promise<string | null> {
    try {
        const payload = verifyToken(token);
        if (!payload) {
            return null;
        }
        console.log(payload.userId)
        return payload.userId;
    } catch (err) {
        console.error('Invalid token:', err);
        return null;
    }
};