import app, { startServer } from './app.js';
import dotenv from 'dotenv';
import connectDB from './config/db.js';


dotenv.config();

const PORT = parseInt(process.env.PORT || '3000', 10);


startServer(PORT)