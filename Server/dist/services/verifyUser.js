import { verifyToken } from "@/middlewares/jwt";
export const verifyUser = (req) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('No token provided or invalid format');
    }
    const token = authHeader.split(' ')[1];
    const userId = verifyToken(token);
    return userId ? userId : 'Unauthorized';
};
//# sourceMappingURL=verifyUser.js.map