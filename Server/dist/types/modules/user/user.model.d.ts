export interface User {
    userid: string;
    fullname: string;
    username: string;
    password: string;
    email: string;
    phonenumber: string;
    gender: string;
    dob: Date;
    address: string;
    avatarurl: string;
    updatedAt: Date;
    createdAt: Date;
}
export interface UserResponse {
    userid: string;
    fullname: string;
    username: string;
    email: string;
    phonenumber: string;
    gender: string;
    dob: Date;
    address: string;
    avatarurl: string;
    updatedAt: Date;
    createdAt: Date;
}
export interface CreateUser {
    userid: string;
    fullname: string;
    password: string;
    email: string;
    phonenumber: string;
    gender: string;
    dob: Date;
    createdAt: Date;
}
export interface UpdateUser {
    fullname?: string;
    username?: string;
    password?: string;
    phonenumber?: string;
    gender?: string;
    dob?: Date;
    address?: string;
    avatarurl?: string;
    updatedAt: Date;
}
//# sourceMappingURL=user.model.d.ts.map