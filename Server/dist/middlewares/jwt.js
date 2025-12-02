import jwt from 'jsonwebtoken';
import { JWT_EXPIRES_IN, privateKey, publicKey } from "@/utils/jwt";
export const generateToken = (userId) => {
    return jwt.sign({ userId }, privateKey, {
        algorithm: 'ES256',
        expiresIn: JWT_EXPIRES_IN
    });
};
export const verifyToken = (token) => {
    try {
        const decoded = jwt.verify(token, publicKey, { algorithms: ['ES256'] });
        return decoded.userId;
    }
    catch (err) {
        console.error('Unvalid token', err);
        return null;
    }
};
//# sourceMappingURL=jwt.js.map