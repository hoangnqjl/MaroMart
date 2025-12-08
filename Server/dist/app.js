import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
// import userRouters from './routes/user.router'
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));
app.use('/hello', (req, res) => {
    res.json({ message: 'Hello from Express + TypeScript' });
});
// app.use("/users", userRouters)
export default app;
//# sourceMappingURL=app.js.map