import productRepository from "../product/product.repository";
import { IProduct } from "../product/product.model";

class ProductService {
    // Tạo sản phẩm mới
    async createProduct(data: Partial<IProduct>): Promise<IProduct> {
        return await productRepository.createProduct(data);
    }

    // Lấy tất cả sản phẩm
    async getAllProducts(page: number, limit: number): Promise<IProduct[]> {
        return await productRepository.getAllProducts(page, limit);
    }

    // Lấy sản phẩm theo productId
    async getProductById(productId: string): Promise<IProduct | null> {
        return await productRepository.getProductById(productId);
    }

    // Cập nhật sản phẩm
    async updateProduct(productId: string, data: Partial<IProduct>): Promise<IProduct | null> {
        return await productRepository.updateProduct(productId, data);
    }

    // Xóa sản phẩm
    async deleteProduct(productId: string): Promise<boolean> {
        return await productRepository.deleteProduct(productId);
    }

    // ===============================
    //      Lọc sản phẩm nâng cao
    // ===============================

    // Lấy sản phẩm theo userId
    async getProductsByUserId(userId: string): Promise<IProduct[]> {
        return await productRepository.getProductsByUserId(userId);
    }

    // Lấy sản phẩm theo categoryId
    async getProductsByCategoryId(categoryId: string): Promise<IProduct[]> {
        return await productRepository.getProductsByCategoryId(categoryId);
    }

    // Lấy sản phẩm theo categoryId + userId
    async getProductsByCategoryAndUser(categoryId: string, userId: string): Promise<IProduct[]> {
        return await productRepository.getProductsByCategoryAndUser(categoryId, userId);
    }

    // Thêm vào cuối class ProductService

    async searchProductByName(q: string): Promise<IProduct[]> {
        return await productRepository.searchProductByName(q);
    }
}

export default new ProductService();
