import { useState, useEffect } from 'react';
import { Search, Plus, Eye, Trash2 } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Badge } from '../components/ui/Badge';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '../components/ui/Table';
import { ConfirmModal } from '../components/ui/Modal';
import { TableSkeleton } from '../components/skeletons/Skeletons';
import { ProductDetailModal } from '../components/ProductDetailModal';
import type { Product, Category } from '../services/api';
import { productsAPI, categoriesAPI } from '../services/api';
import { formatPrice, formatDate } from '../lib/utils';
import { useToast } from '../hooks/useToast';
import { useDebounce } from '../hooks/useDebounce';


export function Products() {
    const [products, setProducts] = useState<Product[]>([]);
    const [categories, setCategories] = useState<Category[]>([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [limit] = useState(10);
    const [searchQuery, setSearchQuery] = useState('');
    const debouncedSearch = useDebounce(searchQuery, 500);
    const [categoryFilter, setCategoryFilter] = useState('');
    const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
    const [deleteModal, setDeleteModal] = useState<{
        isOpen: boolean;
        productId: string | null;
    }>({ isOpen: false, productId: null });
    const [bulkDeleteModal, setBulkDeleteModal] = useState(false);
    const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const { toast } = useToast();

    // Fetch categories
    useEffect(() => {
        const fetchCategories = async () => {
            try {
                const data = await categoriesAPI.getCategories();
                setCategories(data);
            } catch (err) {
                console.error('Failed to fetch categories:', err);
            }
        };
        fetchCategories();
    }, []);

    // Fetch products
    const fetchProducts = async () => {
        try {
            setIsLoading(true);
            setError(null);
            // Backend returns { products[], total, page, limit }
            const response = await productsAPI.getProducts(
                page,
                limit,
                debouncedSearch,
                categoryFilter
            );
            setProducts(response.products || []);
            setTotal(response.total || 0);
        } catch (err: any) {
            setError(err.response?.data?.message || 'Failed to fetch products');
            toast({
                type: 'error',
                title: 'Error',
                description: 'Failed to load products. Please try again.',
            });
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchProducts();
    }, [page, debouncedSearch, categoryFilter]);

    const handleDelete = async (productId: string) => {
        try {
            await productsAPI.deleteProduct(productId);
            toast({
                type: 'success',
                title: 'Product deleted',
                description: 'The product has been successfully deleted.',
            });
            setSelectedProducts((prev) => prev.filter((id) => id !== productId));
            fetchProducts();
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to delete product.',
            });
        }
    };

    const handleBulkDelete = async () => {
        try {
            await productsAPI.deleteProducts(selectedProducts);
            toast({
                type: 'success',
                title: 'Products deleted',
                description: `${selectedProducts.length} products have been deleted.`,
            });
            setSelectedProducts([]);
            fetchProducts();
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to delete products.',
            });
        }
        setBulkDeleteModal(false);
    };

    const toggleSelectAll = () => {
        if (selectedProducts.length === products.length) {
            setSelectedProducts([]);
        } else {
            setSelectedProducts(products.map((p) => p.productId));
        }
    };

    const toggleSelect = (productId: string) => {
        setSelectedProducts((prev) =>
            prev.includes(productId)
                ? prev.filter((id) => id !== productId)
                : [...prev, productId]
        );
    };

    const totalPages = Math.ceil(total / limit);

    // Loading state
    if (isLoading && products.length === 0) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Products</h1>
                        <p className="text-gray-500 mt-1">Manage your product inventory and listings</p>
                    </div>
                </div>
                <TableSkeleton rows={8} />
            </div>
        );
    }

    // Error state
    if (error && products.length === 0) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Products</h1>
                        <p className="text-gray-500 mt-1">Manage your product inventory and listings</p>
                    </div>
                </div>
                <div className="glass-card p-12 text-center">
                    <p className="text-red-600 text-lg font-medium">{error}</p>
                    <Button onClick={fetchProducts} className="mt-4">Retry</Button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900">Products</h1>
                    <p className="text-gray-500 mt-1">Manage your product inventory and listings</p>
                </div>
                <Button className="gap-2">
                    <Plus className="h-5 w-5" />
                    Add Product
                </Button>
            </div>

            {/* Filters */}
            <div className="glass-card p-6">
                <div className="flex items-center gap-4">
                    <div className="flex-1">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                            <Input
                                type="text"
                                placeholder="Search products..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="pl-10"
                            />
                        </div>
                    </div>
                    <select
                        value={categoryFilter}
                        onChange={(e) => setCategoryFilter(e.target.value)}
                        className="rounded-button px-4 py-2 border border-gray-200 bg-white/70 backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary"
                    >
                        <option value="">All Categories</option>
                        {categories.map((category) => (
                            <option key={category.categoryId} value={category.categoryId}>
                                {category.categoryName}
                            </option>
                        ))}
                    </select>
                    {selectedProducts.length > 0 && (
                        <Button
                            variant="danger"
                            onClick={() => setBulkDeleteModal(true)}
                            className="gap-2"
                        >
                            <Trash2 className="h-4 w-4" />
                            Delete Selected ({selectedProducts.length})
                        </Button>
                    )}
                </div>
            </div>

            {/* Table */}
            <div className="glass-card p-6">
                {products.length === 0 ? (
                    <div className="text-center py-12">
                        <p className="text-gray-500 text-lg">No products found</p>
                        <p className="text-gray-400 text-sm mt-2">Try adjusting your filters</p>
                    </div>
                ) : (
                    <>
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="w-12">
                                        <input
                                            type="checkbox"
                                            checked={
                                                selectedProducts.length === products.length &&
                                                products.length > 0
                                            }
                                            onChange={toggleSelectAll}
                                            className="rounded border-gray-300"
                                        />
                                    </TableHead>
                                    <TableHead>Product</TableHead>
                                    <TableHead>Price</TableHead>
                                    <TableHead>Owner</TableHead>
                                    <TableHead>Category</TableHead>
                                    <TableHead>Created</TableHead>
                                    <TableHead className="text-right">Actions</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {products.map((product) => {
                                    const category = categories.find(
                                        (c) => c.categoryId === product.categoryId
                                    );
                                    return (
                                        <TableRow key={product.productId}>
                                            <TableCell>
                                                <input
                                                    type="checkbox"
                                                    checked={selectedProducts.includes(product.productId)}
                                                    onChange={() => toggleSelect(product.productId)}
                                                    className="rounded border-gray-300"
                                                />
                                            </TableCell>
                                            <TableCell>
                                                <div className="flex items-center gap-3">
                                                    {(() => {
                                                        const firstMedia = product.productMedia?.[0];
                                                        if (!firstMedia) {
                                                            return (
                                                                <div className="h-14 w-14 bg-gray-200 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300">
                                                                    <span className="text-xs text-gray-400">No image</span>
                                                                </div>
                                                            );
                                                        }

                                                        const url = firstMedia.startsWith('image:')
                                                            ? firstMedia.slice(6)
                                                            : firstMedia.startsWith('video:')
                                                                ? firstMedia.slice(6)
                                                                : firstMedia;

                                                        return (
                                                            <div className="relative">
                                                                <img
                                                                    src={url}
                                                                    alt={product.productName}
                                                                    className="h-14 w-14 rounded-lg object-cover"
                                                                    onError={(e) => {
                                                                        e.currentTarget.src = "https://via.placeholder.com/56/6366F1/FFFFFF?text=IMG";
                                                                    }}
                                                                />
                                                                {firstMedia.startsWith('video:') && (
                                                                    <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-lg pointer-events-none">
                                                                        <svg className="w-7 h-7 text-white drop-shadow-lg" fill="currentColor" viewBox="0 0 24 24">
                                                                            <path d="M8 5v14l11-7z" />
                                                                        </svg>
                                                                    </div>
                                                                )}
                                                            </div>
                                                        );
                                                    })()}
                                                    <span className="font-medium text-gray-900">{product.productName}</span>
                                                </div>
                                            </TableCell>
                                            <TableCell className="font-semibold text-primary">
                                                {formatPrice(product.productPrice)}
                                            </TableCell>
                                            <TableCell>
                                                <div className="flex items-center gap-2">
                                                    <img
                                                        src={product.userInfo.avatarUrl}
                                                        alt={product.userInfo.fullName}
                                                        className="h-8 w-8 rounded-full"
                                                    />
                                                    <span className="text-sm">
                                                        {product.userInfo.fullName}
                                                    </span>
                                                </div>
                                            </TableCell>
                                            <TableCell>
                                                <Badge variant="info">
                                                    {category?.categoryName || 'Unknown'}
                                                </Badge>
                                            </TableCell>
                                            <TableCell className="text-gray-500">
                                                {formatDate(product.createdAt)}
                                            </TableCell>
                                            <TableCell>
                                                <div className="flex items-center justify-end gap-2">
                                                    <button
                                                        onClick={() => setSelectedProduct(product)}
                                                        className="p-2 rounded-lg hover:bg-gray-100 transition-colors group"
                                                    >
                                                        <Eye className="h-4 w-4 text-gray-600 group-hover:text-primary" />
                                                    </button>
                                                    <button
                                                        onClick={() =>
                                                            setDeleteModal({
                                                                isOpen: true,
                                                                productId: product.productId,
                                                            })
                                                        }
                                                        className="p-2 rounded-lg hover:bg-red-50 transition-colors group"
                                                    >
                                                        <Trash2 className="h-4 w-4 text-gray-600 group-hover:text-red-500" />
                                                    </button>
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    );
                                })}
                            </TableBody>
                        </Table>

                        {/* Pagination */}
                        <div className="flex items-center justify-between mt-6 pt-6 border-t border-gray-200/50">
                            <p className="text-sm text-gray-600">
                                Showing {((page - 1) * limit) + 1} to {Math.min(page * limit, total)} of {total} products
                            </p>
                            <div className="flex gap-2">
                                <Button
                                    variant="secondary"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                                    disabled={page === 1}
                                >
                                    Previous
                                </Button>
                                <Button
                                    variant="secondary"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                                    disabled={page === totalPages}
                                >
                                    Next
                                </Button>
                            </div>
                        </div>
                    </>
                )}
            </div>

            {/* Delete Single Confirmation Modal */}
            <ConfirmModal
                isOpen={deleteModal.isOpen}
                onClose={() => setDeleteModal({ isOpen: false, productId: null })}
                onConfirm={() => {
                    if (deleteModal.productId) {
                        handleDelete(deleteModal.productId);
                    }
                }}
                title="Delete Product"
                message="Are you sure you want to delete this product? This action cannot be undone."
                confirmText="Delete"
                cancelText="Cancel"
                variant="danger"
            />

            {/* Bulk Delete Confirmation Modal */}
            <ConfirmModal
                isOpen={bulkDeleteModal}
                onClose={() => setBulkDeleteModal(false)}
                onConfirm={handleBulkDelete}
                title="Delete Multiple Products"
                message={`Are you sure you want to delete ${selectedProducts.length} products? This action cannot be undone.`}
                confirmText="Delete All"
                cancelText="Cancel"
                variant="danger"
            />

            {/* Product Detail Modal */}
            <ProductDetailModal
                isOpen={!!selectedProduct}
                onClose={() => setSelectedProduct(null)}
                product={selectedProduct || undefined}
            />
        </div>
    );
}
