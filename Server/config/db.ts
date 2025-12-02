import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config()

const connectDB = async () => {
    try{
        const dbConnection = process.env.DB_CONNECTION
        const dbHost = process.env.DB_HOST
        const dbPort = process.env.DB_PORT
        const dbName = process.env.DB_NAME

        const uri = `${dbConnection}://${dbHost}:${dbPort}/${dbName}`
        if (!uri) throw new Error('Mongo uri is not defined in .env');

        const conn = await mongoose.connect(uri)
        console.log(`Successfull connected to mongodb: ${conn.connection.host}`)
    }

    catch(e) {
        console.error(`Failed to connect: ${e}`)
        process.exit(1)
    }
}

export default connectDB;
