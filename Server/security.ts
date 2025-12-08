import bcrypt from "bcrypt";

export class Security {
    async HashedPassword(password: string): Promise<string> {
        const hashedPassword = await bcrypt.hash(password, 10);
        return hashedPassword;
    }

    async run(): Promise<void> {
        const password = "123456"; 
        const hashed = await this.HashedPassword(password);
        console.log("Hashed password:", hashed);
    }
}

// Chạy trực tiếp khi dùng terminal:
const sec = new Security();
sec.run();
