import Category from "./category.model";

export class CategoryRepository {
    async findById(categoryId: string) {
        return await Category.findOne({categoryId});
    }

    async findByName(categoryName: string) {
        return await Category.findOne({categoryName})
    }

    async create(data: {
        categoryId: string;
        categoryName: string;
        categorySpec?: string;
        }) {
        const category = new Category({
            categoryId: data.categoryId,
            categoryName: data.categoryName,
            categorySpec: data.categorySpec,
        });

        return await category.save();
        }



    async updateById(
        categoryId: string, 
        data: Partial<{
            categoryName: string;
            categorySpec: string
        }>
    )

    {
        return await Category.findOneAndUpdate({categoryId}, data, {new: true});
    }

    async deleteById(categoryId: string) {
    return await Category.findOneAndDelete({ categoryId });
  }

    async getAll() {
    return await Category.find();
  }

}