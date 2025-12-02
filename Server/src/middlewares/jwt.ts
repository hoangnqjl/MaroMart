import jwt from 'jsonwebtoken';
import {JWT_EXPIRES_IN, privateKey, publicKey} from "@/utils/jwt.utils";

export interface TokenPayload {
    userId: string;
    role: 'user' | 'admin';
}


export const generateToken = (userId: string): string => {
    return jwt.sign({ userId }, privateKey, {
        algorithm: 'ES256',
        expiresIn: JWT_EXPIRES_IN});
}


export const verifyToken = (token: string): TokenPayload | null => {
    try {
        const decoded = jwt.verify(token, publicKey, {
            algorithms: ['ES256'],
        }) as { userId: string }

        const parsed = JSON.parse(decoded.userId)

        return {
            userId: parsed.userId,
            role: parsed.role
        }
    } catch (err) {
        console.error("Invalid token", err)
        return null
    }
}
