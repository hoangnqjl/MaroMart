import mongoose, { Schema, Document } from "mongoose";
import { v4 as uuidv4 } from "uuid";

delete (mongoose as any).models.Product;

interface IProduct extends Document {
    productId: string;
    categoryId: string;
    userId: string

    productName: string;
    productPrice: number;
    productDescription: string;

    // detailed information
    productCondition: string;
    productBrand: string;
    productWP: string;  // Warranty Policy
    productOrigin: string;
    productCategory: string;

    // product's attributes
    productAttribute: any;

    productAddress: any;

    // product's medias
    productMedia: string[];
}

const productSchema = new Schema<IProduct>(
    {
        productId: {
            type: String,
            default: () => uuidv4(),
            unique: true,
        },

        categoryId: {
            type: String,
            required: true,
        },

        userId: {
            type: String,
            required: true, 
        },

        productName: {
            type: String,
            required: true,
        },

        productPrice: {
            type: Number,
            required: true,
        },

        productDescription: {
            type: String,
            required: true,
        },

        // detailed information
        productCondition: {
            type: String,
            required: true,
        },

        productBrand: {
            type: String,
            required: true,
        },

        productWP: {
            type: String,
            required: true,
        },

        productOrigin: {
            type: String,
            required: true,
        },

        productCategory: {
            type: String,
            required: true,
        },

        // product attributes
        productAttribute: {
            type: Schema.Types.Mixed,
            required: true,
        },

        productAddress: {
            type: Schema.Types.Mixed,
            require: true
        },

        // product media
        productMedia: {
            type: [String],     // ← MẢNG CÁC STRING
            default: [],        // ← mặc định là mảng rỗng
            required: false
        },
    },
    {
        timestamps: true,
        versionKey: false,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);
productSchema.virtual('userInfo', {
    ref: 'User',           
    localField: 'userId',  
    foreignField: 'userId',
    justOne: true          
});


const Product =  mongoose.model<IProduct>("Product", productSchema);

export default Product;
export { IProduct };
