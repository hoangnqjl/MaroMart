import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2 } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Modal, ConfirmModal } from '../components/ui/Modal';
import { CardSkeleton } from '../components/skeletons/Skeletons';
import type { Category } from '../services/api';
import { categoriesAPI } from '../services/api';
import { useToast } from '../hooks/useToast';

export function Categories() {
    const [categories, setCategories] = useState<Category[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState<Category | null>(null);
    const [hoveredCard, setHoveredCard] = useState<string | null>(null);
    const [deleteModal, setDeleteModal] = useState<{
        isOpen: boolean;
        categoryId: string | null;
    }>({ isOpen: false, categoryId: null });
    const { toast } = useToast();

    const [formData, setFormData] = useState({
        categoryId: '',
        categoryName: '',
        categorySpec: '',
    });

    // Fetch categories
    const fetchCategories = async () => {
        try {
            setIsLoading(true);
            setError(null);
            const data = await categoriesAPI.getCategories();
            setCategories(data);
        } catch (err: any) {
            setError(err.response?.data?.message || 'Failed to fetch categories');
            toast({
                type: 'error',
                title: 'Error',
                description: 'Failed to load categories. Please try again.',
            });
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchCategories();
    }, []);

    const handleOpenAddModal = () => {
        setEditingCategory(null);
        setFormData({
            categoryId: '',
            categoryName: '',
            categorySpec: '',
        });
        setIsModalOpen(true);
    };

    const handleOpenEditModal = (category: Category) => {
        setEditingCategory(category);
        setFormData({
            categoryId: category.categoryId,
            categoryName: category.categoryName,
            categorySpec: category.categorySpec,
        });
        setIsModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            if (editingCategory) {
                await categoriesAPI.updateCategory(editingCategory.categoryId, formData);
                toast({
                    type: 'success',
                    title: 'Category updated',
                    description: 'The category has been successfully updated.',
                });
            } else {
                await categoriesAPI.createCategory(formData as Category);
                toast({
                    type: 'success',
                    title: 'Category created',
                    description: 'The new category has been successfully created.',
                });
            }
            setIsModalOpen(false);
            fetchCategories(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to save category.',
            });
        }
    };

    const handleDelete = async (categoryId: string) => {
        try {
            await categoriesAPI.deleteCategory(categoryId);
            toast({
                type: 'success',
                title: 'Category deleted',
                description: 'The category has been successfully deleted.',
            });
            fetchCategories(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to delete category.',
            });
        }
    };

    // Loading state
    if (isLoading) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Categories</h1>
                        <p className="text-gray-500 mt-1">Organize products with custom categories</p>
                    </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    {[1, 2, 3, 4].map((i) => (
                        <CardSkeleton key={i} />
                    ))}
                </div>
            </div>
        );
    }

    // Error state
    if (error && categories.length === 0) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Categories</h1>
                        <p className="text-gray-500 mt-1">Organize products with custom categories</p>
                    </div>
                </div>
                <div className="glass-card p-12 text-center">
                    <p className="text-red-600 text-lg font-medium">{error}</p>
                    <Button onClick={fetchCategories} className="mt-4">Retry</Button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900">Categories</h1>
                    <p className="text-gray-500 mt-1">Organize products with custom categories</p>
                </div>
                <Button onClick={handleOpenAddModal} className="gap-2" size="lg">
                    <Plus className="h-5 w-5" />
                    Add New Category
                </Button>
            </div>

            {/* Categories Grid */}
            {categories.length === 0 ? (
                <div className="glass-card p-12 text-center">
                    <p className="text-gray-500 text-lg">No categories yet</p>
                    <p className="text-gray-400 text-sm mt-2">Create your first category to get started</p>
                    <Button onClick={handleOpenAddModal} className="mt-4">
                        Add Category
                    </Button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    {categories.map((category) => (
                        <div
                            key={category.categoryId}
                            className="glass-card p-6 transition-all duration-300 hover:shadow-xl hover:shadow-black/10 hover:-translate-y-1 relative group"
                            onMouseEnter={() => setHoveredCard(category.categoryId)}
                            onMouseLeave={() => setHoveredCard(null)}
                        >
                            {/* Edit/Delete Icons */}
                            {hoveredCard === category.categoryId && (
                                <div className="absolute top-4 right-4 flex gap-2">
                                    <button
                                        onClick={() => handleOpenEditModal(category)}
                                        className="p-2 rounded-lg bg-white shadow-md hover:bg-gray-50 transition-colors"
                                    >
                                        <Edit className="h-4 w-4 text-primary" />
                                    </button>
                                    <button
                                        onClick={() =>
                                            setDeleteModal({
                                                isOpen: true,
                                                categoryId: category.categoryId,
                                            })
                                        }
                                        className="p-2 rounded-lg bg-white shadow-md hover:bg-red-50 transition-colors"
                                    >
                                        <Trash2 className="h-4 w-4 text-red-500" />
                                    </button>
                                </div>
                            )}

                            {/* Category Content */}
                            <div className="space-y-3">
                                <div className="flex items-center gap-3">
                                    <div className="h-12 w-12 rounded-xl bg-gradient-to-br from-primary to-primary-hover flex items-center justify-center">
                                        <span className="text-2xl font-bold text-white">
                                            {category.categoryName.charAt(0)}
                                        </span>
                                    </div>
                                    <h3 className="text-xl font-bold text-gray-900 flex-1">
                                        {category.categoryName}
                                    </h3>
                                </div>
                                <p className="text-sm text-gray-600 leading-relaxed">
                                    {category.categorySpec}
                                </p>
                                <div className="pt-3 border-t border-gray-200/50">
                                    <p className="text-xs text-gray-500">
                                        ID: {category.categoryId}
                                    </p>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Add/Edit Category Modal */}
            <Modal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                title={editingCategory ? 'Edit Category' : 'Add New Category'}
                size="md"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setIsModalOpen(false)}>
                            Cancel
                        </Button>
                        <Button onClick={handleSubmit}>
                            {editingCategory ? 'Update' : 'Create'}
                        </Button>
                    </>
                }
            >
                <form onSubmit={handleSubmit} className="space-y-4">
                    <Input
                        label="Category Name"
                        type="text"
                        required
                        value={formData.categoryName}
                        onChange={(e) =>
                            setFormData({ ...formData, categoryName: e.target.value })
                        }
                        placeholder="e.g., Electronics"
                    />
                    <Input
                        label="Category ID"
                        type="text"
                        required
                        disabled={!!editingCategory} // Disable when editing
                        value={formData.categoryId}
                        onChange={(e) =>
                            setFormData({ ...formData, categoryId: e.target.value })
                        }
                        placeholder="e.g., CAT001"
                    />
                    <div>
                        <label className="text-sm font-medium text-gray-700 mb-1.5 block">
                            Category Specification
                        </label>
                        <textarea
                            required
                            value={formData.categorySpec}
                            onChange={(e) =>
                                setFormData({ ...formData, categorySpec: e.target.value })
                            }
                            placeholder="Describe the category..."
                            rows={4}
                            className="w-full rounded-button px-4 py-2 border border-gray-200 bg-white/70 backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none"
                        />
                    </div>
                </form>
            </Modal>

            {/* Delete Confirmation Modal */}
            <ConfirmModal
                isOpen={deleteModal.isOpen}
                onClose={() => setDeleteModal({ isOpen: false, categoryId: null })}
                onConfirm={() => {
                    if (deleteModal.categoryId) {
                        handleDelete(deleteModal.categoryId);
                    }
                }}
                title="Delete Category"
                message="Are you sure you want to delete this category? This action cannot be undone."
                confirmText="Delete"
                cancelText="Cancel"
                variant="danger"
            />
        </div>
    );
}
