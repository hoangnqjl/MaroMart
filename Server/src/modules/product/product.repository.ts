import Product, { IProduct } from "../product/product.model";
import Category from "../category/category.model";

export interface IProductRepository {
    createProduct(data: Partial<IProduct>): Promise<IProduct>;
    getAllProducts(): Promise<IProduct[]>;
    getProductById(productId: string): Promise<IProduct | null>;
    updateProduct(productId: string, data: Partial<IProduct>): Promise<IProduct | null>;
    deleteProduct(productId: string): Promise<boolean>;

    // thêm
    getProductsByUserId(userId: string): Promise<IProduct[]>;
    getProductsByCategoryId(categoryId: string): Promise<IProduct[]>;
    getProductsByCategoryAndUser(categoryId: string, userId: string): Promise<IProduct[]>;
    filterProducts(filters: any): Promise<IProduct[]>;
}

class ProductRepository implements IProductRepository {

    async createProduct(data: Partial<IProduct>): Promise<IProduct> {
        if (data.categoryId) {
            const categoryExists = await Category.findOne({ categoryId: data.categoryId });
            if (!categoryExists) {
                throw new Error("Category is not existed");
            }
        }

        const newProduct = new Product(data);
        return await newProduct.save();
    }

    async getAllProducts(page: number = 1, limit: number = 5) { 
        const skip = (page - 1) * limit;

        return await Product.find()
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .populate({
                path: 'userInfo',
                select: 'fullName avatarUrl email phoneNumber'
            })
            .exec();
    }

   async getProductById(productId: string): Promise<IProduct | null> {
        return await Product.findOne({ productId })
            .populate({
                path: 'userInfo',
                select: 'fullName avatarUrl email phoneNumber' 
            })
            .exec();
    }

    async updateProduct(productId: string, data: Partial<IProduct>): Promise<IProduct | null> {
        return await Product.findOneAndUpdate(
            { productId },
            { $set: data },
            { new: true }
        ).exec();
    }

    async deleteProduct(productId: string): Promise<boolean> { 
        const result = await Product.deleteOne({ productId }).exec();
        return result.deletedCount > 0;
    }


    async getProductsByUserId(userId: string): Promise<IProduct[]> {
        return await Product.find({ userId }).exec();
    }

    async getProductsByCategoryId(categoryId: string): Promise<IProduct[]> {
        return await Product.find({ categoryId }).exec();
    }

    async getProductsByCategoryAndUser(categoryId: string, userId: string): Promise<IProduct[]> {
        return await Product.find({
            categoryId,
            userId
        }).exec();
    }

    async filterProducts(filters: { 
        categoryId?: string, 
        userId?: string, 
        province?: string, 
        ward?: string 
    }): Promise<IProduct[]> {
        
        const query: any = {};

        if (filters.categoryId) query.categoryId = filters.categoryId;
        if (filters.userId) query.userId = filters.userId;

        if (filters.province) {
            query.productAddress = { $regex: new RegExp(`"province":"[^"]*${filters.province}[^"]*"`, 'i') };
        }

        if (filters.ward) {
            const wardRegex = { $regex: new RegExp(`"(commune|ward)":"[^"]*${filters.ward}[^"]*"`, 'i') };
            
            if (query.productAddress) {
                query.$and = [
                    { productAddress: query.productAddress },
                    { productAddress: wardRegex }
                ];
                delete query.productAddress; 
            } else {
                query.productAddress = wardRegex;
            }
        }

        return await Product.find(query)
            .sort({ createdAt: -1 })
            .populate('userInfo', 'fullName avatarUrl phoneNumber email')
            .exec();
    }

    // Thêm vào cuối class ProductRepository
    async searchProductByName(keyword: string): Promise<IProduct[]> {
        if (!keyword || keyword.trim().length < 2) return [];

        const tokens = keyword.trim().split(/\s+/); 

        const regexConditions = tokens.map(token => ({
            $or: [
                { productName: new RegExp(token, 'i') },
                { productBrand: new RegExp(token, 'i') },
                { productDescription: new RegExp(token, 'i') },
                { productCondition: new RegExp(token, 'i') },
                { productAddress: new RegExp(token, 'i') },
                { productAttribute: new RegExp(token, 'i') }
            ]
        }));

        return await Product.find({ $and: regexConditions })
            .sort({ createdAt: -1 })
            .populate('userInfo', 'fullName avatarUrl phoneNumber email')
            .limit(50)
            .exec();
    }
}

export default new ProductRepository();
