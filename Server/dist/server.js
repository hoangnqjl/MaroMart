import app from './app.js';
import dotenv from 'dotenv';
import connectDB from './config/db.js';
connectDB;
dotenv.config();
const PORT = process.env.PORT;
app.listen(PORT, () => {
    console.log(`🚀 Express server is running at http://localhost:${PORT}`);
});
//# sourceMappingURL=server.js.map