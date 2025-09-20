import jwt from 'jsonwebtoken';
import {JWT_EXPIRES_IN, privateKey, publicKey} from "@/utils/jwt";

export const generateToken = (userId: string): string => {
    return jwt.sign({ userId }, privateKey, {
        algorithm: 'ES256',
        expiresIn: JWT_EXPIRES_IN});
}

export const verifyToken = (token: string): string | null => {
    try {
        const decoded = jwt.verify(token, publicKey, { algorithms: ['ES256'] }) as { userId: string }
        return decoded.userId
    } catch (err) {
        console.error('Unvalid token', err)
        return null
    }
}

