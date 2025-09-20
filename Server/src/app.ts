import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import connectDB from './config/db';


const app = express()

app.use(express.json());
app.use(express.urlencoded({extended: true}));

connectDB()

app.use(cors())
app.use(express.json())
app.use(morgan('dev'));


app.use('/hello', (req, res) => {
    res.json({message : 'Hello from Express + TypeScript'})
});

export default app;