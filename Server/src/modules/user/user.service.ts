// src/services/user.service.ts
import { UserRepository } from '../user/user.repository';
import bcrypt from "bcrypt";

export class UserService {
  private userRepo = new UserRepository();
  private userId : string = `MM${Date.now()}${Math.floor(Math.random() * 1000)}`;

  async getAllUsers() {
    return await this.userRepo.getAll();
  }

  async getUserById(userId: string) {
    return await this.userRepo.findById(userId);
  }

  async updateUser(userId: string, data: any) {
    return await this.userRepo.updateById(userId, data);
  }

  async findNameById(userId: string): Promise<string | null> {
    return await this.userRepo.findNameById(userId)
  }

  async deleteUser(userId: string) {
    return await this.userRepo.deleteById(userId);
  }

  async updateAvatar(userId: string, avatarUrl: string) {
    const updatedUser = await this.userRepo.updateById(userId, {
      avatarUrl,
      
    });

    if (!updatedUser) {
      throw new Error('User not found!');
    }

    return {
      userId: updatedUser.userId,
      avatarUrl: updatedUser.avatarUrl
    };
  }


  async googleLogin(googleData: { email: string; fullName: string }) {
    const { email, fullName } = googleData;

    let user = await this.userRepo.findByEmail(email);

    if (!user) {
      const userId = this.userId;
      user = await this.userRepo.create({
        userId,
        email,
        fullName, 
        role: 'user',
        isActive: true
      });
    } else {
      await this.userRepo.updateById(user.userId, { fullName, updatedAt: new Date() });
    }

    return this.formatUserResponse(user);
  }

  async login(email: string, password: string) {
    const user = await this.userRepo.findByEmail(email);
    if (!user) {
      throw new Error("Email không tồn tại");
    }

    console.log(user)

    if (!user.password) {
      throw new Error("Tài khoản này không có mật khẩu");
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new Error("Sai mật khẩu");
    }

    return user; // hoặc tạo JWT token
  }

  async registerWithForm(data: {
    fullName: string;
    email: string;
    phoneNumber: number;
    password: string;
  }) {
    const { fullName, email, phoneNumber, password } = data;

    const existing = await this.userRepo.findByEmail(email);
    if (existing) throw new Error('Email is existed!');

    const userId = this.userId;
    const user = await this.userRepo.create({
      userId,
      fullName, 
      email,
      phoneNumber,
      password,
      role: 'user',
      isActive: true
    });

    return this.formatUserResponse(user);
  }

  private formatUserResponse(user: any) {
    return {
      userId: user.userId,
      email: user.email,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      role: user.role,
      isActive: user.isActive
    };
  }
}

