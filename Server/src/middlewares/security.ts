import bcrypt from 'bcrypt';


let hashedPassword;

export class Security {
    async HashedPassword(password: string): Promise<string> {
        hashedPassword = await bcrypt.hash(password, 10);
        return hashedPassword
    }
}