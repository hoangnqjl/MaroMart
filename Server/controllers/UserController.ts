import { Request, Response, NextFunction } from 'express';
import User from '../models/User'
import createError from 'http-errors';
import * as console from "node:console";
import user from "../models/User";
import {generateToken, verifyToken} from "@/middlewares/jwt";
import {verifyUser} from "@/services/verifyUser";



interface ErrorResponse {
    status: number;
    message: string;
}

class UserController {
    //for signup
    async addUser(req: Request, res: Response, next: NextFunction): Promise <void> {
        try {
            const {fullName, email, phoneNumber, password} = req.body;

            const existingUser = await User.findOne({email});
            if(existingUser) {
                throw createError(400, 'Email already exists');
            }

            const user = await User.create({
                fullName,
                email,
                phoneNumber,
                password,
            });

            res.status(201).json({
                status: 'success',
                data: user.toJSON(),
            });
        }

        catch(e) {
            next(e);
        }
    }


    //for login
    async checkUser(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const {email, password} = req.body
            const checking = await User.findOne({email: email, password: password});


            if (checking) {
                const userId = checking.userId.toString();
                const jwtTokenPublic = generateToken(userId)

                res.status(200).json({
                    status: 'success',
                    message: 'successfully login',
                    data: jwtTokenPublic
                })
            }

            else {
                res.status(401).json({
                    status: 'failed',
                    message: 'fail login',
                })
            }
        } catch (e) {
            next(e)
        }
    }


    async getAllUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
        const userId = verifyUser(req);
        if (userId) {
            const users = await User.find().select('-__v');
            res.status(200).json({
                status: 'success',
                results: users.length,
                data: users,
            });
        }
        else {
            res.status(404)
        }
        } catch (e) {
            next(e);
        }

    }

    static errorHandler(err: any, req: Request, res: Response, next: NextFunction): void {
    const status = err.status || 500;
    const message = err.message || 'Something went wrong';
    res.status(status).json({
      status: 'error',
      error: {
        message,
        status,
      },
    });
  }
}

export default UserController;