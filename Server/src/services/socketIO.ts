// src/socket/socketManager.ts
import { Server, Socket } from 'socket.io';
import { verifyUser as verifyUserFromRequest } from '../services/verifyUser';
import { OnlineUserManager } from './onlineUser';

// Wrapper function to verify token string
const verifyUser = async (token: string): Promise<string | null> => {
  try {
    // Extract token from Authorization header format if needed
    const cleanToken = token.startsWith('Bearer ') ? token.slice(7) : token;
    // Call the actual verification logic here
    // You may need to decode JWT directly instead of using verifyUserFromRequest
    const decoded = await verifyUserFromRequest(cleanToken as any);
    return decoded;
  } catch {
    return null;
  }
};

// Map: user_id (string) → socket.id (string)
export const userSocketMap = new Map<string, string>();

let io: Server;

// Hàm khởi tạo socket
export const setupSocket = (socketIO: Server) => {
  io = socketIO;

  io.on('connection', (socket: Socket) => {
    console.log(`[Socket] Client connected: ${socket.id}`);

    // ──────────────────────────────────────
    // 1. Đăng ký user bằng JWT token
    // ──────────────────────────────────────
    socket.on('register', async (token: string) => {
      try {
        // Validate token đầu vào
        if (!token || typeof token !== 'string') {
          return socket.emit('register_fail', { message: 'Token không hợp lệ!' });
        }

        const user_id = await verifyUser(token);

        if (!user_id) {
          return socket.emit('register_fail', { message: 'Token không hợp lệ hoặc đã hết hạn!' });
        }

        // Ghi đè nếu user đăng nhập lại từ thiết bị khác
        const oldSocketId = userSocketMap.get(user_id);
        if (oldSocketId && oldSocketId !== socket.id) {
          io.to(oldSocketId).emit('force_disconnect', { message: 'Tài khoản được đăng nhập từ thiết bị khác' });
          io.sockets.sockets.get(oldSocketId)?.disconnect();
        }

        // Lưu mapping
        userSocketMap.set(user_id, socket.id);
        OnlineUserManager.addUser(user_id, socket.id);

        console.log(`[Socket] User ${user_id} registered → ${socket.id}`);

        socket.emit('register_success', {
          message: 'Kết nối socket thành công!',
          user_id,
        });
      } catch (err) {
        console.error('[Socket] Lỗi verify token:', err);
        socket.emit('register_fail', { message: 'Xác thực thất bại!' });
      }
    });

    // ──────────────────────────────────────
    // 2. Ngắt kết nối
    // ──────────────────────────────────────
    socket.on('disconnect', (reason) => {
      console.log(`[Socket] Client disconnected: ${socket.id} | Reason: ${reason}`);

      for (const [userId, sockId] of userSocketMap.entries()) {
        if (sockId === socket.id) {
          userSocketMap.delete(userId);
          OnlineUserManager.removeUser(userId);
          console.log(`[Socket] User ${userId} removed from map`);
          break;
        }
      }
    });

    // ──────────────────────────────────────
    // 3. Xử lý lỗi (tùy chọn)
    // ──────────────────────────────────────
    socket.on('error', (err) => {
      console.error('[Socket] Error:', err);
    });
  });
};

// ──────────────────────────────────────
// Helper functions (rất tiện khi dùng ở controller)
// ──────────────────────────────────────

// Lấy socket id của user
export const getSocketId = (user_id: string): string | undefined => {
  return userSocketMap.get(user_id);
};

// Gửi event tới một user cụ thể
export const emitToUser = (user_id: string, event: string, data: any): void => {
  const socketId = getSocketId(user_id);
  if (socketId && io) {
    io.to(socketId).emit(event, data);
  }
};

// Gửi tới nhiều user cùng lúc
export const emitToUsers = (user_ids: string[], event: string, data: any): void => {
  user_ids.forEach((uid) => emitToUser(uid, event, data));
};

// Lấy danh sách user đang online
export const getOnlineUsers = (): string[] => {
  return Array.from(userSocketMap.keys());
};

// Kiểm tra user có online không
export const isUserOnline = (user_id: string): boolean => {
  return userSocketMap.has(user_id);
};