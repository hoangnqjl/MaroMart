// src/services/socketManagement.ts
import { Server, Socket } from 'socket.io';
import { getUserIdFromToken } from './verifyUser';
import { OnlineUserManager } from './onlineUser';

let io: Server | null = null;

export const userSocketMap = new Map<string, string>();

let user_id

export function setupSocket(io) {
    io.on('connection', (socket) => {
        socket.on('register', async (token) => { 
            try {
                console.log('dang chay dong ni')
                
                user_id = await getUserIdFromToken(token);
                console.log(user_id);
                
                
                if (!user_id) {
                    return socket.emit('register_fail', { message: 'Token không hợp lệ hoặc đã hết hạn!' });
                }
                
                userSocketMap.set(user_id, socket.id);
                OnlineUserManager.addUser(user_id, socket.id)
                socket.emit('register_success', { message: 'Đã kết nối socket thành công!', user_id });
                
            } catch (error) {
                console.error('Lỗi xác thực token:', error);
                socket.emit('register_fail', { message: 'Token không hợp lệ!' });
            }
        });

        socket.on('disconnect', () => {
            for (let [userId, sockId] of userSocketMap.entries()) {
                if (sockId === socket.id) {
                    userSocketMap.delete(userId);
                    OnlineUserManager.removeUser(userId)
                    break;
                }
            }
        });
    });
}
