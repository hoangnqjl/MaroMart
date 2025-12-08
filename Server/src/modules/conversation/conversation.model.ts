// conversation.model.ts
import mongoose, { Schema, Document } from 'mongoose';

export interface IMessageMedia {
    type: 'image' | 'video' | 'audio';
    url: string;
}

export interface IMessage extends Document {
    messageId: string;
    conId: string;
    sender: string;
    receiver: string;
    content?: string;
    media: IMessageMedia[];
    createdAt: Date;
    updatedAt?: Date;
}

export interface IConversation extends Document {
    conId: string;
    userId1: string | null;
    userId2: string | null;
    userDelete?: string | null;
    createdAt: Date;
    updatedAt: Date;
}

const messageSchema = new Schema<IMessage>({
    messageId: { type: String, required: true, unique: true },
   conId: { type: String, required: true },
    sender: { type: String, required: true },
    receiver: { type: String, required: true },
    content: { type: String },
    media: [{
        type: { type: String, enum: ['image', 'video', 'audio'], required: true },
        url: { type: String, required: true }
    }]
}, { timestamps: true });

const conversationSchema = new Schema<IConversation>({
    conId: { type: String, required: true, unique: true },
    userId1: { type: String, default: null },
    userId2: { type: String, default: null },
    userDelete: { type: String, default: null }
}, { timestamps: true });

// Virtual để lấy tin nhắn mới nhất
conversationSchema.virtual('latestMessage', {
    ref: 'Message',
    localField: 'conId',
    foreignField: 'conId',
    justOne: true,
    options: { sort: { createdAt: -1 } }
});

conversationSchema.set('toJSON', { virtuals: true });
conversationSchema.set('toObject', { virtuals: true });

export const Message = mongoose.model<IMessage>('Message', messageSchema);
export const Conversation = mongoose.model<IConversation>('Conversation', conversationSchema);