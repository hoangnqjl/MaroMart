import { CategoryRepository } from "./category.repository";

export class CategoryService {
    private catRepo = new CategoryRepository();

    async getAll() {
        return await this.catRepo.getAll();
    }

    async getById(categoryId: string) {
        return await this.catRepo.findById(categoryId);
    }

    async getByName(categoryName: string) {
        return await this.catRepo.findByName(categoryName);
    }

    async create(data: { 
    categoryId: string;
    categoryName: string; 
    categorySpec?: string;
    }) {
        return await this.catRepo.create(data);
    }


    async updateById(
        categoryId: string,
        data: Partial<{
            categoryName: string;
            categorySpec: string;
        }>
    ) {
        return await this.catRepo.updateById(categoryId, data);
    }

    async deleteById(categoryId: string) {
        return await this.catRepo.deleteById(categoryId);
    }
}
