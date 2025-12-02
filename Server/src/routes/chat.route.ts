import { Router } from 'express';
import { ChatController } from '../modules/conversation/chat.controller';

const router = Router();

// [GET] Lấy danh sách cuộc trò chuyện + tin nhắn mới nhất
router.get('/private-conversations', ChatController.getConversationsWithLatestMessage);

// [GET] Lấy tin nhắn theo cuộc trò chuyện
router.get('/conversations/:con_id/messages', ChatController.getMessagesByConversation);

// [POST] Gửi tin nhắn (text + image/video/audio)
router.post('/send', ChatController.sendMessage);

// [DELETE] Xóa cuộc trò chuyện (soft delete cho user)
router.delete('/delete-conversations/:con_id', ChatController.deleteConversationForUser);

export default router;