import { Request, Response } from 'express';
import mongoose from 'mongoose';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import fs from 'fs';

import { Message, Conversation } from './conversation.model';
import { verifyUser } from '@/services/verifyUser';
import { userSocketMap } from '@/services/socketManagement';
import { NotificationController } from '../notification/notification.controller';
import { UserService } from '../user/user.service';

const userService = new UserService();
let io: any;

export function getIO2(IOSocket: any) {
  io = IOSocket;
}

const PUBLIC_DIR = path.join(process.cwd(), 'public');
const CONVERSATION_DIR = path.join(PUBLIC_DIR, 'conversation');

if (!fs.existsSync(PUBLIC_DIR)) fs.mkdirSync(PUBLIC_DIR, { recursive: true });
if (!fs.existsSync(CONVERSATION_DIR)) fs.mkdirSync(CONVERSATION_DIR, { recursive: true });

const TEMP_DIR = path.join(process.cwd(), 'temp');
if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, TEMP_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  },
});

const fileFilter = (req: any, file: any, cb: any) => {
  if (/^image\//.test(file.mimetype) || /^video\//.test(file.mimetype) || /^audio\//.test(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ chấp nhận image, video hoặc audio'), false);
  }
};

const upload = multer({ storage, fileFilter }).fields([
  { name: 'images', maxCount: 50 },
  { name: 'videos', maxCount: 50 },
  { name: 'audios', maxCount: 1 },
]);

export class ChatController {
  // [GET] Danh sách cuộc trò chuyện + tin nhắn mới nhất
  static async getConversationsWithLatestMessage(req: Request, res: Response) {
    try {
      const user_id = await verifyUser(req);
      if (!user_id) return res.status(401).json({ message: 'Unauthorized' });

      const conversations = await Conversation.aggregate([
        { $match: { $or: [{ userId1: user_id }, { userId2: user_id }] } },
        {
          $lookup: {
            from: 'messages',
            localField: 'conId',
            foreignField: 'conId',
            as: 'all_messages',
          },
        },
        {
          $addFields: {
            latest_message: {
              $arrayElemAt: [
                { $sortArray: { input: '$all_messages', sortBy: { createdAt: -1 } } },
                0,
              ],
            },
          },
        },
        {
          $project: {
            conId: 1,
            userId1: 1,
            userId2: 1,
            createdAt: 1,
            updatedAt: 1,
            latest_message: {
              sender: '$latest_message.sender',
              receiver: '$latest_message.receiver',
              content: '$latest_message.content',
              media: '$latest_message.media',
              createdAt: '$latest_message.createdAt',
            },
          },
        },
      ]);

      return res.json({ conversations });
    } catch (error) {
      console.error('Error getConversationsWithLatestMessage:', error);
      return res.status(500).json({ message: 'Server Error' });
    }
  }

 // [GET] Lấy tin nhắn theo cuộc trò chuyện
static async getMessagesByConversation(req: Request, res: Response) {
  try {
    const user_id = await verifyUser(req);
    if (!user_id) return res.status(401).json({ message: 'Unauthorized' });

    const { con_id } = req.params;

    const conversation = await Conversation.findOne({
      conId: con_id,
      $or: [{ userId1: user_id }, { userId2: user_id }],
    });

    if (!conversation) return res.status(403).json({ message: 'Access denied' });

    const messages = await Message.find({ conId: con_id })
      .sort({ createdAt: 1 })
      .lean();

    const response = messages.map((msg: any) => ({
      messageId: msg.messageId, 
      conId: msg.conId,         
      sender: msg.sender,
      receiver: msg.receiver,
      content: msg.content,
      createdAt: msg.createdAt, 
      updatedAt: msg.updatedAt, 
      media: (msg.media || []).map((m: any) => ({ type: m.type, url: m.url })),
    }));

    return res.json({ messages: response });
  } catch (error) {
    console.error('Error getMessagesByConversation:', error);
    return res.status(500).json({ message: 'Server Error' });
  }
}

  // [POST] Gửi tin nhắn
  static async sendMessage(req: Request, res: Response) {
    upload(req, res, async (err: any) => {
      if (err) return res.status(400).json({ message: err.message });

      try {
        const user_id = await verifyUser(req);
        if (!user_id) return res.status(401).json({ message: 'Unauthorized' });

        const { receiver_id, content } = req.body;
        const files: any = req.files;

        if (!receiver_id) {
          return res.status(400).json({ message: 'Thiếu receiver_id' });
        }

        if (user_id === receiver_id) {
          return res.status(400).json({ message: 'Không thể gửi tin nhắn cho chính mình' });
        }

        // Tìm hoặc tạo conversation
        let conversation = await Conversation.findOne({
          $or: [
            { userId1: user_id, userId2: receiver_id },
            { userId1: receiver_id, userId2: user_id },
          ],
        });

        if (!conversation) {
          conversation = new Conversation({
            conId: `con_${Date.now()}_${uuidv4().slice(0, 8)}`,
            userId1: user_id,
            userId2: receiver_id,
          });
          await conversation.save();
        }

        // Khôi phục nếu bị soft-delete
        if (conversation.userDelete) {
          if (!conversation.userId1) conversation.userId1 = conversation.userDelete;
          if (!conversation.userId2) conversation.userId2 = conversation.userDelete;
          conversation.userDelete = null;
          await conversation.save();
        }

        // Xác định receiver
        let realReceiver: string;
        
        if (conversation.userId1 === user_id) {
          realReceiver = conversation.userId2 || receiver_id;
        } else if (conversation.userId2 === user_id) {
          realReceiver = conversation.userId1 || receiver_id;
        } else {
          realReceiver = receiver_id;
        }

        const messageId = new mongoose.Types.ObjectId().toString();
        const media: { type: string; url: string }[] = [];

        // Xử lý upload file
        if (files) {
          const folderPath = path.join(PUBLIC_DIR, 'conversation', conversation.conId, user_id, messageId);
          fs.mkdirSync(folderPath, { recursive: true });

          const processFile = (field: string, type: 'image' | 'video' | 'audio') => {
            if (files[field]) {
              files[field].forEach((file: any) => {
                const newPath = path.join(folderPath, file.filename);
                fs.renameSync(file.path, newPath);
                media.push({
                  type,
                  url: `/conversation/${conversation!.conId}/${user_id}/${messageId}/${file.filename}`,
                });
              });
            }
          };

          processFile('images', 'image');
          processFile('videos', 'video');
          processFile('audios', 'audio');
        }

        // Tạo tin nhắn
        const newMessage = await Message.create({
          messageId,
          conId: conversation.conId,
          sender: user_id,
          receiver: realReceiver,
          content: content || '',
          media,
        });

        
        try {
          const senderName = await userService.findNameById(user_id);
          
          await NotificationController.create('new_message', realReceiver, {
            userId: realReceiver,
            senderId: user_id,
            senderName: senderName || 'Unknown User',
            conId: conversation.conId,
          });
        } catch (notifError) {
          console.error('Error sending notification:', notifError);
        }

        // Cập nhật thời gian conversation
        conversation.updatedAt = new Date();
        await conversation.save();

        const msgRes = {
          messageId: newMessage.messageId,
          conId: newMessage.conId,
          sender: newMessage.sender,
          receiver: newMessage.receiver,
          content: newMessage.content,
          media: newMessage.media,
          createdAt: newMessage.createdAt,
          updatedAt: newMessage.updatedAt,
        };

        // Emit socket
        const senderSocket = userSocketMap.get(user_id);
        const receiverSocket = userSocketMap.get(realReceiver);

        if (senderSocket && io) {
          io.to(senderSocket).emit('put_new_message', { new_message: msgRes });
        }
        
        if (receiverSocket && io) {
          io.to(receiverSocket).emit('get_new_message', { new_message: msgRes });
        }

        return res.json({ 
          message: 'Gửi tin nhắn thành công', 
          new_message: msgRes 
        });
        
      } catch (error: any) {
        console.error('Error sendMessage:', error);
        return res.status(500).json({ 
          message: 'Server Error', 
          error: error.message 
        });
      }
    });
  }

  // [DELETE] Xóa cuộc trò chuyện (soft delete)
  static async deleteConversationForUser(req: Request, res: Response) {
    try {
      const user_id = await verifyUser(req);
      if (!user_id) return res.status(401).json({ message: 'Unauthorized' });

      const { con_id } = req.params;

      const conversation = await Conversation.findOne({ conId: con_id });
      if (!conversation) {
        return res.status(404).json({ message: 'Không tìm thấy cuộc trò chuyện' });
      }

      const isUser1 = conversation.userId1 === user_id;
      const isUser2 = conversation.userId2 === user_id;
      
      if (!isUser1 && !isUser2) {
        return res.status(403).json({ message: 'Không có quyền' });
      }

      // Soft delete
      if (isUser1) conversation.userId1 = null;
      if (isUser2) conversation.userId2 = null;
      conversation.userDelete = user_id;

      // Nếu cả hai đều xóa → xóa thật
      if (!conversation.userId1 && !conversation.userId2) {
        await Conversation.deleteOne({ conId: con_id });
        await Message.deleteMany({ conId: con_id });
        return res.json({ message: 'Đã xóa cuộc trò chuyện vĩnh viễn' });
      } else {
        await conversation.save();
        return res.json({ message: 'Đã ẩn cuộc trò chuyện' });
      }
      
    } catch (error) {
      console.error('Error deleteConversationForUser:', error);
      return res.status(500).json({ message: 'Server Error' });
    }
  }
}