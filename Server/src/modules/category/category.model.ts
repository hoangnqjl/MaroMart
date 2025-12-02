import mongoose, { Schema, Document } from 'mongoose';

// Interface cho TypeScript
export interface ICategory extends Document {
    categoryId: string;        // ← ID do bạn tự định nghĩa (có thể là uuid, slug, hoặc số)
    categoryName: string;      // ← Tên hiển thị: "Điện tử", "Thời trang",...
    categorySpec?: string;     // ← Đặc điểm riêng (RAM, CPU, kích thước, v.v.)
    createdAt?: Date;
    updatedAt?: Date;
}

// Schema
const categorySchema = new Schema<ICategory>(
    {
        categoryId: {
            type: String,
            required: true,
            unique: true,          // ← Không trùng categoryId
            trim: true
        },
        categoryName: {
            type: String,
            required: true,
            trim: true
        },
        categorySpec: {
            type: String,
            trim: true,
            default: null
        }
    },
    {
        timestamps: true,          // ← tự động thêm createdAt, updatedAt
        toJSON: { virtuals: true },
        toObject: { virtuals: true }
    }
);

// Tùy chọn: Tạo index tìm kiếm nhanh theo tên (nếu cần tìm gần đúng)
categorySchema.index({ categoryName: 'text' });

// Virtual để frontend vẫn lấy được "id" nếu cần (tương thích với chuẩn REST)
categorySchema.virtual('id').get(function () {
    return this.categoryId;
});

// Đảm bảo virtual được trả về khi toJSON
categorySchema.set('toJSON', { virtuals: true });

// Export model
const Category = mongoose.model<ICategory>('Category', categorySchema);

export default Category;