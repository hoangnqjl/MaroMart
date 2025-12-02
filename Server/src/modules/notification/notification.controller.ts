import { Request, Response } from 'express';
import Notification from './notification.model';
import { verifyUser } from '@/services/verifyUser';
import { userSocketMap } from '@/services/socketManagement';
import Product from '../product/product.model';

let io: any = null;

function getIO(IOSocket: any) {
  io = IOSocket;
  return io;
}

// Interface cho data truyền khi tạo thông báo
interface NotificationData {
  productId?: string;
  user_from?: string;
  username?: string;
  product?: string;
  reason?: string;
  post_id?: string;
  productName?: string;
  userId?: string;
  conId?: string;
  senderId?: string;
  senderName?: string;
}

class NotificationController {

  // [GET] Lấy 50 thông báo của user hiện tại
  static async getByUserId(req: Request, res: Response) {
    try {
      const userId = await verifyUser(req);
      if (!userId) return res.status(401).json({ message: 'Unauthorized' });

      const notifications = await Notification.find({ userId })
        .sort({ createdAt: -1 })
        .limit(50)
        .lean();

      return res.json({ notifications });
    } catch (error: any) {
      console.error('Error getByUserId:', error);
      return res.status(500).json({ message: error.message });
    }
  }

  // [GET] Admin: lấy tất cả thông báo
  static async getAll(req: Request, res: Response) {
    try {
      const userId = await verifyUser(req);
      if (!userId) return res.status(401).json({ message: 'Unauthorized' });

      const notifications = await Notification.find()
        .sort({ createdAt: -1 })
        .lean();

      return res.json({ notifications });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // [GET] Lấy thông báo theo ID
  static async getById(req: Request, res: Response) {
    try {
      const userId = await verifyUser(req);
      if (!userId) return res.status(401).json({ message: 'Unauthorized' });

      const { id } = req.params;
      const notification = await Notification.findById(id);

      if (!notification) {
        return res.status(404).json({ message: 'Notification not found' });
      }

      return res.json({ notification });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  static async create(
    notificationType: string,
    userId: string,
    data: NotificationData = {}
  ): Promise<any> {
    try {
      if (!userId) throw new Error('User ID is required');

      let title = '';
      let content = '';
      let type = 'info';
      let relatedUrl: string | undefined = undefined;

      switch (notificationType) {
        case 'product_refusal': {
          title = 'Product upload failed';
          content = `Hi, your product "${data.product}" was rejected because: ${data.reason}. Please try again!`;
          type = 'warning';
          break;
        }

        case 'successful_upload': {
          title = `${data.productName} uploaded`;
          content = `Hi, your product "${data.productName}" was uploaded`;
          type = 'success';
          break;
        }

        // case 'adjust_product': {

        // }

        case 'new_message': {
          title = `New message from ${data.senderName}`;
          content = `${data.senderName} sent you a message`;
          type = 'new';
          relatedUrl = `/chat/${data.conId}`;
          break;
        }

        
        default:
          throw new Error(`Invalid notification type: ${notificationType}`);
      }

      // Tạo thông báo
      const notification = await Notification.create({
        userId,
        title,
        content,
        type,
        relatedUrl,
        data,
      });

      // Real-time qua socket
      const socketId = userSocketMap.get(userId);
      if (socketId && io) {
        io.to(socketId).emit('new_notification', { notification });
      }

      return notification;
    } catch (error: any) {
      console.error('Failed to create notification:', error);
      throw new Error(`Create notification failed: ${error.message}`);
    }
  }

  // [PATCH] Đánh dấu đọc
  static async markAsRead(req: Request, res: Response) {
    try {
      const userId = await verifyUser(req);
      if (!userId) return res.status(401).json({ message: 'Unauthorized' });

      const { id } = req.params;

      const notification = await Notification.findOneAndUpdate(
        { _id: id, userId },
        { isRead: true },
        { new: true }
      );

      if (!notification) {
        return res.status(404).json({ message: 'Notification not found' });
      }

      return res.json({ message: 'Marked as read', notification });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // [DELETE] Xóa thông báo
  static async delete(req: Request, res: Response) {
    try {
      const userId = await verifyUser(req);
      if (!userId) return res.status(401).json({ message: 'Unauthorized' });

      const { id } = req.params;

      const result = await Notification.deleteOne({ _id: id, userId });

      if (result.deletedCount === 0) {
        return res.status(404).json({ message: 'Notification not found' });
      }

      return res.json({ message: 'Notification deleted' });
    } catch (error: any) {
      return res.status(500).json({ message: error.message });
    }
  }

  // API cũ của bạn → sửa đúng field
  static async getnoti(req: Request, res: Response): Promise<void> {
    try {
      const userId = await verifyUser(req);

      const notifications = await Notification.find({ userId });

      res.json({ notifications });
    } catch (err: any) {
      res.status(500).json({
        message: err?.message || "Server error",
      });
    }
  }

}

export { NotificationController, getIO };
