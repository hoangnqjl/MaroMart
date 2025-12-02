import { Request, Response } from "express";
import { CategoryService } from "./category.service"; 
import { canAccessAdmin, canAccessUser } from "@/utils/authorization";

const categoryService = new CategoryService();

export class CategoryController {
    

    // GET /categories
    static async getAll(req: Request, res: Response) {
        try {
            const categories = await categoryService.getAll();
            return res.status(200).json(categories);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    // GET /categories/:id
    static async getById(req: Request, res: Response) {
        try {
            const categoryId = req.params.id;
            const category = await categoryService.getById(categoryId);

            if (!category) {
                return res.status(404).json({ message: "Category not found" });
            }

            return res.status(200).json(category);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    // POST /categories
    static async create(req: Request, res: Response) {
        try {
            if (!(await canAccessAdmin(req, res))) return;

            const { categoryId, categoryName, categorySpec } = req.body;

            const newCategory = await categoryService.create({
                categoryId,
                categoryName,
                categorySpec,
            });

            return res.status(201).json(newCategory);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    // PUT /categories/:id
    static async update(req: Request, res: Response) {
        try {
            if (!(await canAccessAdmin(req, res))) return;

            const categoryId = req.params.id;

            const updated = await categoryService.updateById(categoryId, req.body);

            if (!updated) {
                return res.status(404).json({ message: "Category not found" });
            }

            return res.status(200).json(updated);
        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }

    // DELETE /categories/:id
    static async delete(req: Request, res: Response) {
        try {
            if (!(await canAccessAdmin(req, res))) return;

            const categoryId = req.params.id;

            const deleted = await categoryService.deleteById(categoryId);

            if (!deleted) {
                return res.status(404).json({ message: "Category not found" });
            }

            return res.status(200).json({ message: "Category deleted successfully" });

        } catch (error: any) {
            return res.status(500).json({ message: error.message });
        }
    }
}
