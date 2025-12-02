// src/server.ts
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import http from 'http';
import { Server } from 'socket.io';
import path from 'path'
import { fileURLToPath } from 'url';

import connectDB from './config/db';

import uploadRouter from './routes/upload.route';
import authRouter from './routes/authencation.route';
import userRouter from './routes/user.route';
import categoryRouter from './routes/category.route';
import productRouter from './routes/product.route';
import conversationRouter from './routes/chat.route';
import notificationRouter from './routes/notification.route';
import adminRouter from './routes/admin.route'
import { setupSocket } from './services/socketManagement';
import { getIO2 } from './modules/conversation/chat.controller';
import { getIO } from './modules/notification/notification.controller'

const app = express();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// app.use(bodyParser.json());
// app.use(bodyParser.urlencoded({ extended: true }));
// app.use("/data_user", express.static(path.join(__dirname, "public/data_user")));
// app.use("/groups", express.static(path.join(__dirname, "public/groups")));
// app.use("/avatar", express.static(path.join(__dirname, "public/avatar_auto")));
app.use('/conversation', express.static(path.join(process.cwd(), 'public', 'conversation')));

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

app.use('/upload', uploadRouter);
app.use('/auth/v1', authRouter);
app.use('/users', userRouter);
app.use('/categories', categoryRouter);
app.use('/products', productRouter);
app.use('/chat', conversationRouter);
app.use('/notifications', notificationRouter); 
app.use('/admin', adminRouter)
app.get('/', (req, res) => {
  res.send('MaroMart Server Running on port 14678');
});

// === KHỞI ĐỘNG SERVER + SOCKET.IO ===
// const PORT = 14678; // ← ĐỔI THÀNH PORT 14678

export const startServer = async (PORT: number) => {
  try {
    await connectDB();
    console.log('MongoDB Connected');

    const server = http.createServer(app);

    const io = new Server(server, {
      cors: {
        origin: '*',
      },
    });

    setupSocket(io)
    getIO2(io)
    getIO(io)

    server.listen(PORT, () => {
      console.log(`Server đang chạy tại: http://localhost:${PORT}`);
      console.log(`Socket.IO cũng đang chạy chung trên port ${PORT}`);
    });

    // Bonus: tự động đổi port nếu bị chiếm
    server.on('error', (err: any) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`Port ${PORT} bị chiếm → thử port ${PORT + 1}`);
        server.listen(PORT + 1);
      }
    });

  } catch (error) {
    console.error('Lỗi khởi động server:', error);
    process.exit(1);
  }
};

// startServer();

export default app;