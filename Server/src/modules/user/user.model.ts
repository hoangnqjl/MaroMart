import mongoose, { Schema, Document } from "mongoose";
import { v4 as uuidv4 } from "uuid";
import validator from "validator";

interface IUser extends Document {
  _id: string; 
  userId: string;
  fullName: string;
  email: string;
  phoneNumber?: number;
  country?: string;
  address?: string;
  role: "user" | "admin";
  createdAt: Date;
  updatedAt: Date;
  avatarUrl?: string;
  isActive: boolean;
  password?: string;
}


const userSchema = new Schema<IUser>(
  {
    _id: {
      type: String,
      default: () => uuidv4(),
    },
    userId: {
      type: String,
      required: true,
      unique: true,
      default: () => "MM" + randomString(10) + Date.now()
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 50,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      validate: [validator.isEmail, "Please provide a valid email"],
    },
    phoneNumber: {
      type: Number,
      sparse: true,
      minlength: 9,
      maxlength: 15,
    },
    password: {
      type: String,
      minlength: 8,
      maxlength: 200,
      select: true,
    },
    country: String,
    address: String,
    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
    },
    avatarUrl: String,
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform: (_, ret) => {
        delete ret.password;
        return ret;
      },
    },
    toObject: { virtuals: true },
  }
);

// userSchema.virtual("id").get(function () {
//   return this.userId;
// });

const User = mongoose.model<IUser>("User", userSchema);

export default User;
export { IUser };
