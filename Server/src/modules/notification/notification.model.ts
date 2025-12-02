import mongoose, { Schema, Document } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';

export interface INotification extends Document {
  _id: string;
  notificationId: string;
  userId: string;           // người nhận thông báo
  title: string;
  content: string;
  type: 'like' | 'comment' | 'follow' | 'report' | 'system' | 'message' | 'order';
  isRead: boolean;
  relatedUrl?: string;      // link khi click vào thông báo (ví dụ: /post/123)
  relatedId?: string;       // ID của post, comment, user,...
  data?: Record<string, any>; // dữ liệu bổ sung (tùy chọn)
  createdAt: Date;
  updatedAt: Date;
}

const notificationSchema = new Schema<INotification>(
  {
    _id: {
      type: String,
      default: () => uuidv4(),
    },
    notificationId: {
      type: String,
      required: true,
      unique: true,
      default: () => `NOTI_${Date.now().toString(36).toUpperCase()}`,
      // Ví dụ: NOTI_K9P4X2Q
    },
    userId: {
      type: String,
      required: true,
      index: true, // rất quan trọng để query nhanh theo user
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    content: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      required: true,
      // enum: ['like', 'comment', 'follow', 'report', 'system', 'message', 'order'],
      default: 'system',
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    relatedUrl: {
      type: String,
      trim: true,
    },
    relatedId: {
      type: String,
    },
    data: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret) => {
        return ret;
      },
    },
    toObject: { virtuals: true },
  }
);

// Index tối ưu
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ isRead: 1 });
notificationSchema.index({ type: 1 });

const Notification = mongoose.model<INotification>('Notification', notificationSchema);

export default Notification;