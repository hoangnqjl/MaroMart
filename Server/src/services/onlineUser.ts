// src/socket/onlineUser.ts
class OnlineUserManagerClass {
  private users = new Map<string, string>(); // user_id → socket_id

  addUser(user_id: string, socket_id: string) {
    this.users.set(user_id, socket_id);
  }

  removeUser(user_id: string) {
    this.users.delete(user_id);
  }

  getSocketId(user_id: string): string | undefined {
    return this.users.get(user_id);
  }

  getAll(): string[] {
    return Array.from(this.users.keys());
  }

  has(user_id: string): boolean {
    return this.users.has(user_id);
  }
}

// Export instance (singleton)
export const OnlineUserManager = new OnlineUserManagerClass();