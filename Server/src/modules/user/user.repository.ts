import User from '../user/user.model';
import bcrypt from "bcrypt";

export class UserRepository{
  async findByEmail(email: string) {
    return await User.findOne({ email });
  }

  async findById(userId: string) { 
    return await User.findOne({ userId });
  }

async findNameById(userId: string): Promise<string> {
    try {
      const user = await User.findOne({ userId }, { fullName: 1, _id: 0 });
      return user?.fullName || 'Unknown User';
    } catch (error) {
      return 'Unknown User';
    }
  }

  
async comparePassword(email: string, password: string): Promise<boolean> {
  const user = await User.findOne({ email });
  if (!user || !user.password) return false;

  return await bcrypt.compare(password, user.password);
}

  async create(data: {
    userId: string;
    email: string;
    fullName: string;
    phoneNumber?: number | undefined;
    country?: string | undefined;
    address?: string | undefined;
    role?: 'user' | 'admin' | undefined;
    avatarUrl?: string | undefined;
    isActive?: boolean | undefined;
    password?: string | undefined;
  }) {
    const user = new User({
      userId: data.userId,
      email: data.email,
      fullName: data.fullName,    
      phoneNumber: data.phoneNumber,
      country: data.country,
      address: data.address,
      role: data.role ?? 'user',
      avatarUrl: data.avatarUrl,
      isActive: data.isActive ?? true,
      password: data.password 
    });
    return await user.save();
  }

  async updateById(userId: string, data: Partial<{
    fullName: string;
    phoneNumber: string;
    country: string;
    address: string;
    role: 'user' | 'admin';
    avatarUrl: string;
    isActive: boolean;
    password: string;
    updatedAt: Date;
  }>) {
    return await User.findOneAndUpdate({ userId }, data, { new: true });
  }

  async deleteById(userId: string) {
    return await User.findOneAndDelete({ userId });
  }

  async getAll() {
    return await User.find();
  }
}