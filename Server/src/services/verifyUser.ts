import {verifyToken} from "@/middlewares/jwt";
import { Request } from 'express';


export const verifyUser = (req: Request): string => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('No token provided or invalid format');
    }

    const token = authHeader.split(' ')[1];
    const userId = verifyToken(token);

    if (!userId || !userId.userId) {
        throw new Error('Invalid token payload');
    }

    return userId.userId;
}

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