import { Request, Response } from "express";
import ProductService from "./product.service";
import { getUserId } from "@/utils/authorization";
import { uploadMultipleToOneDrive } from '@/utils/onedrive';
import { v4 as uuidv4 } from 'uuid';
import { validateProduct } from "@/services/validateProduct";
import { IProduct } from "./product.model";
import { NotificationController } from "../notification/notification.controller";
import fs from 'fs'
import { moderateMedia } from "@/services/moderateContent";

const productService = ProductService;

export class ProductController {

    static async getAll(req: Request, res: Response) {
        const page = Number(req.query.page) || 1;   // FE không gửi → default 1
        const limit = Number(req.query.limit) || 3; // FE không gửi → default 20
        try {
            const products = await productService.getAllProducts(page, limit);
            return res.status(200).json(products);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    static async getById(req: Request, res: Response) {
        try {
            const productId = req.params.id;
            const product = await productService.getProductById(productId);
            if (!product) return res.status(404).json({ message: "Product not found" });
            return res.status(200).json(product);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    static async create(req: Request, res: Response) {
        try {
            const files = req.files as Express.Multer.File[] | undefined;
            const data = { ...req.body };

            console.log(files)
            
            const userId = await getUserId(req, res);
            if (!userId || userId === true) return res.status(401).json({ message: "Unauthorized" });

            const productId = uuidv4();

            data.userId = userId;
            data.productId = productId;
            data.productMedia = [];

            // 1. Ép kiểu Giá
            if (data.productPrice) {
                data.productPrice = Number(data.productPrice);
            }

            // Lưu ý: productAttribute & productAddress giữ nguyên là STRING để lưu vào DB

            // 2. Tạo sản phẩm (Lưu String vào DB)
            const newProduct = await productService.createProduct(data);

            if (!newProduct) {
                return res.status(400).json({ success: false, message: "Không thể khởi tạo sản phẩm" });
            }

            // --- CHUẨN BỊ DỮ LIỆU ĐỂ VALIDATE ---
            const productForValidation = newProduct.toObject(); 

            try {
                // Parse Attribute
                if (typeof productForValidation.productAttribute === 'string') {
                    productForValidation.productAttribute = JSON.parse(productForValidation.productAttribute);
                }

                // --- XỬ LÝ ADDRESS: CHỈ LẤY PROVINCE, COMMUNE, DETAIL ---
                // Xóa bỏ hoàn toàn district ở đây
                if (typeof productForValidation.productAddress === 'string') {
                    const rawAddr = JSON.parse(productForValidation.productAddress);
                    
                    productForValidation.productAddress = {
                        province: rawAddr.province || "",
                        // Chấp nhận cả key 'commune' hoặc 'ward' từ frontend, chuẩn hóa về 'commune'
                        commune: rawAddr.commune || rawAddr.ward || "", 
                        detail: rawAddr.detail || ""
                    };
                }
            } catch (e) {
                console.log("Lỗi parse validate:", e);
            }

            // Fake ảnh để validate (nếu có file gửi lên)
            if (files && files.length > 0) {
                productForValidation.productMedia = ["placeholder.jpg"];
            }


            // 3. Tiến hành Validate
            const validation = await validateProduct(productForValidation as unknown as IProduct);
            
            if (!validation.isValid) {
                console.log("❌ Lỗi Validation:", validation.errors);
                await productService.deleteProduct(newProduct.productId);
                
                const safeErrors = validation.errors.filter(e => !e.includes("GoogleGenerativeAI"));

                await NotificationController.create("product_refusal", userId, {
                    product: newProduct.productName,
                    reason: safeErrors.join(", ")
                });

                return res.status(400).json({
                    success: false,
                    message: "Dữ liệu không hợp lệ",
                    errors: validation.errors
                });
            }

            // 4 validate hình ảnh 
            let mediaLinks: string[] = [];

            if (files && files.length > 0) {
            // 1. Tách riêng ảnh và video
            const imageFiles = files.filter(f => f.mimetype.startsWith('image/'));
            const videoFiles = files.filter(f => f.mimetype.startsWith('video/'));

            // 2. Nếu có ảnh → kiểm cực gắt bằng Gemini
            if (imageFiles.length > 0) {
                const base64Images = imageFiles.map(file => {
                const buffer = fs.readFileSync(file.path);
                return `data:${file.mimetype};base64,${buffer.toString('base64')}`;
                });

                const { isSafe, reason } = await moderateMedia(base64Images, newProduct.categoryId, newProduct.productName);

                if (!isSafe) {
                await productService.deleteProduct(newProduct.productId);
                return res.status(400).json({
                    success: false,
                    message: "Sản phẩm không được duyệt do ảnh vi phạm",
                    reason: reason || "Ảnh không phù hợp hoặc không đúng sản phẩm"
                });
                }
            }

            // 3. Video → KHÔNG kiểm gì hết, cho qua luôn
            // (nếu sau này muốn kiểm video nhẹ thì trích 3-5 frame rồi gọi lại moderateMedia)

            // 4. Upload toàn bộ (ảnh + video) lên OneDrive
            const uploadResult = await uploadMultipleToOneDrive(files, userId, productId);
            mediaLinks = [...uploadResult.images, ...uploadResult.videos];
            }



            newProduct.productMedia = mediaLinks;

            await NotificationController.create("successful_upload", userId, {
                productName: newProduct.productName,
                productId: newProduct.productId
            });

            await newProduct.save();

            return res.status(201).json({ success: true, data: newProduct });

        } catch (error: any) {
            console.error("Create error:", error);
            return res.status(500).json({ success: false, message: error.message });
        }
    }


    // ==========================================
    // UPDATE (ĐÃ XÓA QUẬN/HUYỆN)
    // ==========================================
    static async update(req: Request, res: Response) {
    try {
        const userId = await getUserId(req, res);
        if (!userId || userId === true) return res.status(401).json({ message: "Unauthorized" });

        const productId = req.params.id;
        const existingProduct = await productService.getProductById(productId);
        if (!existingProduct) return res.status(404).json({ message: "Product not found" });
        if (existingProduct.userId !== userId) return res.status(403).json({ message: "Forbidden" });

        const updateBody = { ...req.body };
        if (updateBody.productPrice) updateBody.productPrice = Number(updateBody.productPrice);

        const updatedData = { ...existingProduct.toObject(), ...updateBody };

        // === VALIDATE DỮ LIỆU CƠ BẢN (giống create) ===
        if (req.files && (req.files as Express.Multer.File[]).length > 0) {
        updatedData.productMedia = ["placeholder.jpg"]; // fake để validate
        }

        const dataForValidation = { ...updatedData };
        try {
        if (typeof dataForValidation.productAttribute === 'string') {
            dataForValidation.productAttribute = JSON.parse(dataForValidation.productAttribute);
        }
        if (typeof dataForValidation.productAddress === 'string') {
            const rawAddr = JSON.parse(dataForValidation.productAddress);
            dataForValidation.productAddress = {
            province: rawAddr.province || "",
            commune: rawAddr.commune || rawAddr.ward || "",
            detail: rawAddr.detail || ""
            };
        }
        } catch (e) {}

        const validation = await validateProduct(dataForValidation as unknown as IProduct);
        if (!validation.isValid) {
        return res.status(400).json({
            success: false,
            message: "Dữ liệu cập nhật không hợp lệ",
            errors: validation.errors
        });
        }

        // === KIỂM DUYỆT ẢNH MỚI (GIỐNG HỆT CREATE) ===
        const files = req.files as Express.Multer.File[] | undefined;
        let newMediaLinks: string[] = [];

        if (files && files.length > 0) {
        const imageFiles = files.filter(f => f.mimetype.startsWith('image/'));
        const videoFiles = files.filter(f => f.mimetype.startsWith('video/'));

        // Chỉ kiểm ảnh – video cho qua
        if (imageFiles.length > 0) {
            const base64Images = imageFiles.map(file => {
            const buffer = fs.readFileSync(file.path);
            return `data:${file.mimetype};base64,${buffer.toString('base64')}`;
            });

            const { isSafe, reason } = await moderateMedia(base64Images, existingProduct.categoryId, existingProduct.productName);

            if (!isSafe) {
            return res.status(400).json({
                success: false,
                message: "Cập nhật thất bại do ảnh mới vi phạm",
                reason: reason || "Ảnh không phù hợp hoặc không đúng sản phẩm"
            });
            }
        }

        // Upload toàn bộ (ảnh + video) lên OneDrive
        const uploadResult = await uploadMultipleToOneDrive(files, userId, productId);
        newMediaLinks = [...uploadResult.images, ...uploadResult.videos];
        }

        updatedData.productMedia = newMediaLinks.length > 0 
        ? newMediaLinks 
        : (existingProduct.productMedia || []); // nếu không upload file mới → giữ nguyên

        // Lưu vào DB
        const updatedProduct = await productService.updateProduct(productId, updatedData);
        if (!updatedProduct) {
        return res.status(500).json({ message: "Lỗi cập nhật sản phẩm" });
        }

        await NotificationController.create("product_updated", userId, {
        userId,
        productId: updatedProduct.productId,
        productName: updatedProduct.productName,
        });

        return res.status(200).json({ success: true, data: updatedProduct });

    } catch (error: any) {
        console.error("Update product error:", error);
        return res.status(500).json({ message: error.message || "Lỗi server" });
    }
    }

    static async delete(req: Request, res: Response) {
        try {
            const userId = await getUserId(req, res);
            if (!userId) return;

            const productId = req.params.id;
            const deleted = await productService.deleteProduct(productId);
            if (!deleted) return res.status(404).json({ message: "Product not found" });

            return res.status(200).json({ message: "Product deleted successfully" });
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    static async filter(req: Request, res: Response) {
        try {
            const { categoryId, userId } = req.query;
            let products;

            if (categoryId && userId) {
                products = await productService.getProductsByCategoryAndUser(categoryId as string, userId as string);
            } else if (categoryId) {
                products = await productService.getProductsByCategoryId(categoryId as string);
            } else if (userId) {
                products = await productService.getProductsByUserId(userId as string);
            } else {
                products = await productService.getAllProducts();
            }

            return res.status(200).json(products);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    static async search(req: Request, res: Response) {
        try {
            const { q } = req.query; 
            if (!q || typeof q !== 'string') return res.status(400).json({ message: "Search keyword is required" });
            const products = await productService.searchProductByName(q);
            return res.status(200).json(products);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }
}