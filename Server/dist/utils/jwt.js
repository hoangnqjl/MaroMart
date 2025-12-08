import dotenv from "dotenv";
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
export const privateKey = fs.readFileSync('./keys/ec_private.key', 'utf8');
export const publicKey = fs.readFileSync('./keys/ec_private.key', 'utf8');
dotenv.config();
export const SECRET_KEY = `${process.env.SECRET_KEY}`;
export const JWT_EXPIRES_IN = '365d';
//# sourceMappingURL=jwt.js.map