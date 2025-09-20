import {verifyToken} from "@/middlewares/jwt";
import { Request } from 'express';


export const verifyUser = (req: Request): string => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('No token provided or invalid format');
    }

    const token = authHeader.split(' ')[1];
    const userId = verifyToken(token);

    return userId ? userId : 'Unauthorized';
}