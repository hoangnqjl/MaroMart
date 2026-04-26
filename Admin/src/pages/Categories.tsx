import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Settings, FileText, Search, Grid, List, ChevronDown, ChevronUp } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Modal, ConfirmModal } from '../components/ui/Modal';
import { CardSkeleton, TableSkeleton } from '../components/skeletons/Skeletons';
import { Badge } from '../components/ui/Badge';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '../components/ui/Table';
import type { Category } from '../services/api';
import { categoriesAPI } from '../services/api';
import { useToast } from '../hooks/useToast';

export function Categories() {
    const [categories, setCategories] = useState<Category[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState<Category | null>(null);
    const [viewMode, setViewMode] = useState<'grid' | 'table'>('table');
    const [searchQuery, setSearchQuery] = useState('');
    const [expandedRow, setExpandedRow] = useState<string | null>(null);
    const [deleteModal, setDeleteModal] = useState<{
        isOpen: boolean;
        categoryId: string | null;
    }>({ isOpen: false, categoryId: null });
    const { toast } = useToast();

    const [formData, setFormData] = useState({
        categoryId: '',
        categoryName: '',
        categorySpec: '',
        categoryIcon: '',
    });

    const [selectedCategoryForDetails, setSelectedCategoryForDetails] = useState<Category | null>(null);
    const [selectedProductTypeForFilter, setSelectedProductTypeForFilter] = useState<string | null>(null);
    const [selectedTypeInRow, setSelectedTypeInRow] = useState<Record<string, string | null>>({});
    const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
    const [newTypeName, setNewTypeName] = useState('');
    const [attrFormData, setAttrFormData] = useState({
        name: '',
        displayName: '',
        isRequired: false,
        isCommon: true,
        fieldType: 'TEXT' as 'TEXT' | 'NUMBER' | 'DROPDOWN',
        options: '',
        productTypeId: '',
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
                description: 'Failed to load categories.',
            });
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchCategories();
    }, []);

    const filteredCategories = categories.filter((category) =>
        category.categoryName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        category.categoryId.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const handleOpenAddModal = () => {
        setEditingCategory(null);
        setFormData({
            categoryId: '',
            categoryName: '',
            categorySpec: '',
            categoryIcon: '',
        });
        setIsModalOpen(true);
    };

    const handleOpenEditModal = (category: Category) => {
        setEditingCategory(category);
        setFormData({
            categoryId: category.categoryId,
            categoryName: category.categoryName,
            categorySpec: category.categorySpec,
            categoryIcon: category.categoryIcon || '',
        });
        setIsModalOpen(true);
    };

    const handleOpenDetailsModal = async (category: Category) => {
        try {
            // Re-fetch or use full category with includes if needed
            // Assuming categoriesAPI.getCategories returns deep relationships based on backend inspection
            setSelectedCategoryForDetails(category);
            setSelectedProductTypeForFilter(null);
            setIsDetailsModalOpen(true);
        } catch (err) {
            console.error(err);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            if (editingCategory) {
                await categoriesAPI.updateCategory(editingCategory.categoryId, formData);
                toast({
                    type: 'success',
                    title: 'Đã cập nhật danh mục',
                    description: 'Danh mục đã được chỉnh sửa thành công.',
                });
            } else {
                await categoriesAPI.createCategory(formData);
                toast({
                    type: 'success',
                    title: 'Đã thêm danh mục',
                    description: 'Danh mục mới đã được khởi tạo.',
                });
            }
            setIsModalOpen(false);
            fetchCategories(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Lỗi',
                description: err.response?.data?.message || 'Không thể lưu danh mục.',
            });
        }
    };

    const handleDelete = async (categoryId: string) => {
        try {
            await categoriesAPI.deleteCategory(categoryId);
            toast({
                type: 'success',
                title: 'Đã xóa danh mục',
                description: 'Xóa danh mục thành công.',
            });
            fetchCategories(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Lỗi',
                description: err.response?.data?.message || 'Không thể xóa danh mục.',
            });
        }
    };

    const handleAddProductType = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newTypeName.trim() || !selectedCategoryForDetails) return;

        try {
            await categoriesAPI.addProductType({
                categoryId: selectedCategoryForDetails.categoryId,
                typeName: newTypeName.trim(),
            });
            toast({
                type: 'success',
                title: 'Thành công',
                description: 'Đã thêm loại sản phẩm.',
            });
            setNewTypeName('');
            // Refresh details
            const updated = await categoriesAPI.getCategories();
            setCategories(updated);
            const current = updated.find(c => c.categoryId === selectedCategoryForDetails.categoryId);
            if (current) setSelectedCategoryForDetails(current);
        } catch (err: any) {
            toast({ type: 'error', title: 'Lỗi', description: err.response?.data?.message || 'Không thể thêm.' });
        }
    };

    const handleDeleteProductType = async (productTypeId: string) => {
        if (!selectedCategoryForDetails) return;
        try {
            await categoriesAPI.deleteProductType(productTypeId);
            toast({ type: 'success', title: 'Đã xóa', description: 'Xóa loại sản phẩm thành công.' });
            const updated = await categoriesAPI.getCategories();
            setCategories(updated);
            const current = updated.find(c => c.categoryId === selectedCategoryForDetails.categoryId);
            if (current) setSelectedCategoryForDetails(current);
        } catch (err: any) {
            toast({ type: 'error', title: 'Lỗi', description: err.response?.data?.message || 'Không thể xóa.' });
        }
    };

    const handleAddAttribute = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedCategoryForDetails) return;

        try {
            const payload = {
                categoryId: selectedCategoryForDetails.categoryId,
                name: attrFormData.name,
                displayName: attrFormData.displayName,
                isRequired: attrFormData.isRequired,
                isCommon: attrFormData.isCommon,
                fieldType: attrFormData.fieldType,
                options: attrFormData.fieldType === 'DROPDOWN' ? attrFormData.options : undefined,
                productTypeId: !attrFormData.isCommon ? attrFormData.productTypeId : undefined
            };

            await categoriesAPI.addAttribute(payload);
            toast({ type: 'success', title: 'Thành công', description: 'Đã thêm thuộc tính.' });
            
            // Reset form
            setAttrFormData({
                name: '',
                displayName: '',
                isRequired: false,
                isCommon: true,
                fieldType: 'TEXT',
                options: '',
                productTypeId: '',
            });

            // Refresh details
            const updated = await categoriesAPI.getCategories();
            setCategories(updated);
            const current = updated.find(c => c.categoryId === selectedCategoryForDetails.categoryId);
            if (current) setSelectedCategoryForDetails(current);
        } catch (err: any) {
            toast({ type: 'error', title: 'Lỗi', description: err.response?.data?.message || 'Không thể thêm.' });
        }
    };

    const handleDeleteAttribute = async (attributeId: string) => {
        if (!selectedCategoryForDetails) return;
        try {
            await categoriesAPI.deleteAttribute(attributeId);
            toast({ type: 'success', title: 'Đã xóa', description: 'Xóa thuộc tính thành công.' });
            const updated = await categoriesAPI.getCategories();
            setCategories(updated);
            const current = updated.find(c => c.categoryId === selectedCategoryForDetails.categoryId);
            if (current) setSelectedCategoryForDetails(current);
        } catch (err: any) {
            toast({ type: 'error', title: 'Lỗi', description: err.response?.data?.message || 'Không thể xóa.' });
        }
    };

    if (isLoading) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-900">Quản lý Danh mục</h1>
                        <p className="text-gray-500 mt-1">Quản lý dữ liệu hệ thống</p>
                    </div>
                </div>
                <TableSkeleton rows={8} />
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fade-in">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Quản lý Danh mục</h1>
                    <p className="text-gray-500 mt-1">Cấu hình danh mục, loại sản phẩm và thuộc tính template.</p>
                </div>
                <Button onClick={handleOpenAddModal} className="gap-2 self-start sm:self-auto rounded-xl">
                    <Plus className="h-4 w-4" />
                    Thêm Danh mục Mới
                </Button>
            </div>

            {/* Controls Bar */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between bg-white/50 backdrop-blur-sm p-4 rounded-[1.5rem] border border-gray-100 shadow-sm">
                <div className="relative w-full md:max-w-md flex items-center bg-white border border-gray-200/80 rounded-full px-4 py-2 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/10 transition-all">
                    <Search className="h-4 w-4 text-gray-400 shrink-0" />
                    <input
                        type="text"
                        placeholder="Tìm kiếm danh mục theo tên hoặc ID..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full bg-transparent border-none outline-none text-sm px-3 text-gray-700 placeholder:text-gray-400 h-full font-medium"
                    />
                </div>

                <div className="flex items-center gap-2 bg-gray-100 p-1 rounded-xl shrink-0">
                    <button
                        onClick={() => setViewMode('table')}
                        className={`p-2 rounded-lg transition-all ${viewMode === 'table' ? 'bg-white text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
                        title="Dạng bảng"
                    >
                        <List className="h-4 w-4" />
                    </button>
                    <button
                        onClick={() => setViewMode('grid')}
                        className={`p-2 rounded-lg transition-all ${viewMode === 'grid' ? 'bg-white text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
                        title="Dạng lưới"
                    >
                        <Grid className="h-4 w-4" />
                    </button>
                </div>
            </div>

            {/* Categories Table View (Classic UX for Admins) */}
            {viewMode === 'table' && (
                <div className="glass-card overflow-hidden">
                    <Table>
                        <TableHeader>
                            <TableRow className="bg-gray-50/50">
                                <TableHead className="w-[50px]"></TableHead>
                                <TableHead className="w-[80px]">Icon</TableHead>
                                <TableHead>Tên Danh mục</TableHead>
                                <TableHead>ID</TableHead>
                                <TableHead className="hidden md:table-cell">Mô tả</TableHead>
                                <TableHead className="hidden lg:table-cell">Loại Sản phẩm</TableHead>
                                <TableHead className="text-right">Thao tác</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {filteredCategories.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={7} className="text-center py-12 text-gray-400">
                                        Không tìm thấy danh mục nào phù hợp.
                                    </TableCell>
                                </TableRow>
                            ) : (
                                filteredCategories.map((category) => {
                                    const isExpanded = expandedRow === category.categoryId;
                                    return (
                                        <React.Fragment key={category.categoryId}>
                                            <TableRow className="hover:bg-orange-50/10 transition-colors border-b border-gray-100">
                                                <TableCell>
                                                    <button
                                                        onClick={() => setExpandedRow(isExpanded ? null : category.categoryId)}
                                                        className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
                                                    >
                                                        {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                                                    </button>
                                                </TableCell>
                                                <TableCell>
                                                    <div className="h-10 w-10 rounded-xl bg-orange-100 flex items-center justify-center overflow-hidden border border-orange-200/40 shadow-sm">
                                                        {category.categoryIcon ? (
                                                            <img
                                                                src={category.categoryIcon}
                                                                alt={category.categoryName}
                                                                className="h-full w-full object-cover"
                                                                onError={(e) => {
                                                                    e.currentTarget.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(category.categoryName)}&background=FB9A40&color=fff&bold=true`;
                                                                }}
                                                            />
                                                        ) : (
                                                            <span className="text-base font-bold text-primary">
                                                                {category.categoryName.charAt(0)}
                                                            </span>
                                                        )}
                                                    </div>
                                                </TableCell>
                                                <TableCell className="font-semibold text-gray-800">
                                                    {category.categoryName}
                                                </TableCell>
                                                <TableCell className="text-xs font-mono text-gray-400">
                                                    {category.categoryId}
                                                </TableCell>
                                                <TableCell className="hidden md:table-cell text-sm text-gray-500 max-w-xs truncate">
                                                    {category.categorySpec || 'N/A'}
                                                </TableCell>
                                                <TableCell className="hidden lg:table-cell">
                                                    <Badge variant="primary">
                                                        {category.productTypes?.length || 0} loại
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="text-right">
                                                    <div className="flex items-center justify-end gap-2">
                                                        <Button
                                                            variant="ghost"
                                                            size="sm"
                                                            className="rounded-xl hover:bg-orange-50 text-orange-600"
                                                            onClick={() => handleOpenDetailsModal(category)}
                                                        >
                                                            <Settings className="h-4 w-4 mr-1.5" />
                                                            Cấu hình
                                                        </Button>
                                                        <Button
                                                            variant="ghost"
                                                            size="sm"
                                                            className="rounded-xl hover:bg-gray-100 text-gray-600"
                                                            onClick={() => handleOpenEditModal(category)}
                                                        >
                                                            <Edit className="h-4 w-4" />
                                                        </Button>
                                                        <Button
                                                            variant="ghost"
                                                            size="sm"
                                                            className="rounded-xl hover:bg-red-50 text-red-500"
                                                            onClick={() =>
                                                                setDeleteModal({
                                                                    isOpen: true,
                                                                    categoryId: category.categoryId,
                                                                })
                                                            }
                                                        >
                                                            <Trash2 className="h-4 w-4" />
                                                        </Button>
                                                    </div>
                                                </TableCell>
                                            </TableRow>

                                            {/* Expandable nested info */}
                                            {isExpanded && (
                                                <TableRow className="bg-gray-50/40 border-b border-gray-100">
                                                    <TableCell colSpan={7} className="p-6">
                                                        <div className="flex flex-col md:flex-row gap-6 animate-slide-up w-full">
                                                            {/* Left column: Product Types */}
                                                            <div className="w-full md:w-[220px] border-r border-gray-100 pr-4 space-y-2 flex-shrink-0">
                                                                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                                                                    Các loại sản phẩm:
                                                                </p>
                                                                <div 
                                                                    onClick={() => setSelectedTypeInRow({ ...selectedTypeInRow, [category.categoryId]: null })}
                                                                    className={`px-3 py-2 rounded-xl text-xs font-medium cursor-pointer transition-all border ${
                                                                        selectedTypeInRow[category.categoryId] === null || selectedTypeInRow[category.categoryId] === undefined
                                                                        ? 'bg-orange-50 border-primary text-primary font-bold shadow-sm'
                                                                        : 'bg-white border-gray-200 text-gray-600 hover:bg-orange-50/20'
                                                                    }`}
                                                                >
                                                                    Tất cả
                                                                </div>

                                                                {category.productTypes?.map((type) => (
                                                                    <div 
                                                                        key={type.id} 
                                                                        onClick={() => setSelectedTypeInRow({ ...selectedTypeInRow, [category.categoryId]: type.id })}
                                                                        className={`px-3 py-2 rounded-xl text-xs font-medium cursor-pointer transition-all border flex items-center justify-between ${
                                                                            selectedTypeInRow[category.categoryId] === type.id
                                                                            ? 'bg-orange-50 border-primary text-primary font-bold shadow-sm'
                                                                            : 'bg-white border-gray-200 text-gray-600 hover:bg-orange-50/20'
                                                                        }`}
                                                                    >
                                                                        <span>{type.typeName}</span>
                                                                        <span className="text-[10px] bg-gray-100 text-gray-400 px-1 rounded-md font-normal">
                                                                            {(type.attributes?.length || 0)} thuộc tính
                                                                        </span>
                                                                    </div>
                                                                ))}

                                                                {(!category.productTypes || category.productTypes.length === 0) && (
                                                                    <p className="text-xs text-gray-400 italic">Chưa có loại sản phẩm nào.</p>
                                                                )}
                                                            </div>

                                                            {/* Right column: Attributes list matching the selection */}
                                                            <div className="flex-1 pl-2">
                                                                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">
                                                                    Thuộc tính Template liên quan:
                                                                </p>

                                                                <div className="space-y-4 max-h-[350px] overflow-y-auto hide-scrollbar">
                                                                    {/* Common attributes (always show) */}
                                                                    {(selectedTypeInRow[category.categoryId] === null || selectedTypeInRow[category.categoryId] === undefined) && (
                                                                        <div>
                                                                            <p className="text-xs font-bold text-primary mb-1.5 flex items-center gap-1.5">
                                                                                <FileText className="h-3 w-3" /> Thuộc tính CHUNG
                                                                            </p>
                                                                            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
                                                                                {category.attributes?.filter(a => a.isCommon).map((attr) => (
                                                                                    <div key={attr.id} className="bg-orange-50/30 border border-orange-200/30 text-gray-700 px-3 py-2 rounded-xl text-xs font-medium flex items-center gap-2">
                                                                                        <span>{attr.displayName}</span>
                                                                                        <code className="text-gray-400 font-mono text-[10px]">({attr.name})</code>
                                                                                        {attr.isRequired && <span className="text-red-500 font-bold">*</span>}
                                                                                    </div>
                                                                                ))}
                                                                                {(!category.attributes || category.attributes.filter(a => a.isCommon).length === 0) && (
                                                                                    <span className="text-xs text-gray-400 italic">Không có thuộc tính chung.</span>
                                                                                )}
                                                                            </div>
                                                                        </div>
                                                                    )}

                                                                    {/* Specific attributes */}
                                                                    <div className="space-y-3 mt-1">
                                                                        {category.productTypes
                                                                            ?.filter(type => selectedTypeInRow[category.categoryId] === null || selectedTypeInRow[category.categoryId] === undefined || type.id === selectedTypeInRow[category.categoryId])
                                                                            .map((type) => {
                                                                                const typeAttrs = type.attributes || [];
                                                                                if (typeAttrs.length === 0 && selectedTypeInRow[category.categoryId] === type.id) {
                                                                                    return (
                                                                                        <p key={type.id} className="text-xs text-gray-400 italic">Loại sản phẩm này chưa có thuộc tính riêng.</p>
                                                                                    );
                                                                                }
                                                                                if (typeAttrs.length === 0) return null;

                                                                                return (
                                                                                    <div key={type.id} className="bg-gray-50/50 border border-gray-100 rounded-xl p-3">
                                                                                        <p className="text-xs font-bold text-gray-700 mb-2 flex items-center gap-1">
                                                                                            <Settings className="h-3 w-3 text-gray-500" /> Thuộc tính riêng của: {type.typeName}
                                                                                        </p>
                                                                                        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
                                                                                            {typeAttrs.map((attr) => (
                                                                                                <div key={attr.id} className="bg-white border border-gray-200 text-gray-700 px-3 py-2 rounded-xl text-xs font-medium flex items-center gap-2 shadow-none hover:shadow-sm transition-all">
                                                                                                    <span>{attr.displayName}</span>
                                                                                                    <code className="text-gray-400 font-mono text-[10px]">({attr.name})</code>
                                                                                                    {attr.isRequired && <span className="text-red-500 font-bold">*</span>}
                                                                                                </div>
                                                                                            ))}
                                                                                        </div>
                                                                                    </div>
                                                                                );
                                                                            })}
                                                                    </div>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </TableCell>
                                                </TableRow>
                                            )}
                                        </React.Fragment>
                                    );
                                })
                            )}
                        </TableBody>
                    </Table>
                </div>
            )}

            {/* Categories Grid View */}
            {viewMode === 'grid' && (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                    {filteredCategories.map((category) => (
                        <div
                            key={category.categoryId}
                            className="glass-card p-5 relative overflow-hidden group hover-neon flex flex-col justify-between"
                        >
                            <div>
                                <div className="flex items-start justify-between mb-4">
                                    <div className="h-12 w-12 rounded-2xl bg-orange-100 flex items-center justify-center overflow-hidden border border-orange-200/40">
                                        {category.categoryIcon ? (
                                            <img
                                                src={category.categoryIcon}
                                                alt={category.categoryName}
                                                className="h-full w-full object-cover"
                                                onError={(e) => {
                                                    e.currentTarget.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(category.categoryName)}&background=FB9A40&color=fff&bold=true`;
                                                }}
                                            />
                                        ) : (
                                            <span className="text-2xl font-bold text-primary">
                                                {category.categoryName.charAt(0)}
                                            </span>
                                        )}
                                    </div>

                                    {/* Visible actions */}
                                    <div className="flex items-center gap-1.5">
                                        <button
                                            onClick={() => handleOpenDetailsModal(category)}
                                            className="p-2 rounded-xl hover:bg-orange-50 text-orange-500 transition-colors"
                                            title="Quản lý chi tiết"
                                        >
                                            <Settings className="h-4 w-4" />
                                        </button>
                                        <button
                                            onClick={() => handleOpenEditModal(category)}
                                            className="p-2 rounded-xl hover:bg-gray-100 text-gray-500 transition-colors"
                                        >
                                            <Edit className="h-4 w-4" />
                                        </button>
                                        <button
                                            onClick={() =>
                                                setDeleteModal({
                                                    isOpen: true,
                                                    categoryId: category.categoryId,
                                                })
                                            }
                                            className="p-2 rounded-xl hover:bg-red-50 text-red-500 transition-colors"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>

                                <h3 className="text-lg font-bold text-gray-900 mb-1">
                                    {category.categoryName}
                                </h3>
                                <p className="text-xs font-mono text-gray-400 mb-2 block">
                                    ID: {category.categoryId}
                                </p>
                                <p className="text-sm text-gray-500 leading-relaxed line-clamp-2 mb-4">
                                    {category.categorySpec || 'Không có mô tả.'}
                                </p>
                            </div>

                            {/* Tags for product types */}
                            <div className="border-t border-gray-100 pt-3 mt-auto">
                                <p className="text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-2">
                                    Loại sản phẩm ({category.productTypes?.length || 0}):
                                </p>
                                <div className="flex flex-wrap gap-1">
                                    {category.productTypes?.slice(0, 3).map((type) => (
                                        <span
                                            key={type.id}
                                            className="text-xs bg-gray-50 text-gray-600 px-2.5 py-1 rounded-lg font-medium border border-gray-200/50"
                                        >
                                            {type.typeName}
                                        </span>
                                    ))}
                                    {(category.productTypes?.length || 0) > 3 && (
                                        <span className="text-xs text-gray-400 px-2 py-1 font-semibold">
                                            +{(category.productTypes?.length || 0) - 3}
                                        </span>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Empty State */}
            {!isLoading && filteredCategories.length === 0 && categories.length > 0 && (
                <div className="text-center py-12">
                    <p className="text-gray-500 font-medium">Không tìm thấy kết quả.</p>
                </div>
            )}

            {/* Add/Edit Category Modal */}
            <Modal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                title={editingCategory ? 'Chỉnh sửa Danh mục' : 'Thêm Danh mục Mới'}
                size="md"
                footer={
                    <>
                        <Button variant="secondary" className="rounded-xl" onClick={() => setIsModalOpen(false)}>
                            Hủy
                        </Button>
                        <Button onClick={handleSubmit} className="rounded-xl shadow-glow">
                            {editingCategory ? 'Cập nhật' : 'Tạo mới'}
                        </Button>
                    </>
                }
            >
                <form onSubmit={handleSubmit} className="space-y-4 pt-2">
                    <Input
                        label="Tên Danh mục"
                        type="text"
                        required
                        value={formData.categoryName}
                        onChange={(e) =>
                            setFormData({ ...formData, categoryName: e.target.value })
                        }
                        placeholder="Ví dụ: Thiết bị Điện tử"
                        className="rounded-xl"
                    />
                    <Input
                        label="Mã Danh mục (ID)"
                        type="text"
                        required
                        disabled={!!editingCategory}
                        value={formData.categoryId}
                        onChange={(e) =>
                            setFormData({ ...formData, categoryId: e.target.value })
                        }
                        placeholder="Ví dụ: electronics"
                        className="rounded-xl font-mono"
                    />
                    <Input
                        label="Icon URL (Tùy chọn)"
                        type="text"
                        value={formData.categoryIcon}
                        onChange={(e) =>
                            setFormData({ ...formData, categoryIcon: e.target.value })
                        }
                        placeholder="https://example.com/icon.png"
                        className="rounded-xl"
                    />
                    <div>
                        <label className="text-sm font-medium text-gray-700 mb-1.5 block">
                            Tải lên Icon (Lưu dưới dạng {formData.categoryId || 'id'}.png)
                        </label>
                        <input
                            type="file"
                            accept="image/*"
                            onChange={async (e) => {
                                const file = e.target.files?.[0];
                                if (file && editingCategory) {
                                    try {
                                        toast({
                                            type: 'info',
                                            title: 'Đang tải lên...',
                                            description: 'Đang xử lý ảnh icon.',
                                        });
                                        const res = await categoriesAPI.uploadCategoryIcon(editingCategory.categoryId, file);
                                        setFormData({ ...formData, categoryIcon: res.categoryIcon });
                                        toast({
                                            type: 'success',
                                            title: 'Thành công',
                                            description: 'Đã tải lên icon danh mục.',
                                        });
                                    } catch (err) {
                                        toast({
                                            type: 'error',
                                            title: 'Lỗi',
                                            description: 'Không thể tải lên icon.',
                                        });
                                    }
                                } else if (file && !editingCategory) {
                                    toast({
                                        type: 'warning',
                                        title: 'Lưu ý',
                                        description: 'Hãy tạo danh mục trước rồi upload icon sau.',
                                    });
                                }
                            }}
                            className="w-full rounded-xl px-4 py-2 border border-gray-200 bg-white text-sm"
                        />
                    </div>
                    <div>
                        <label className="text-sm font-medium text-gray-700 mb-1.5 block">
                            Mô tả danh mục
                        </label>
                        <textarea
                            required
                            value={formData.categorySpec}
                            onChange={(e) =>
                                setFormData({ ...formData, categorySpec: e.target.value })
                            }
                            placeholder="Mô tả thông tin danh mục này..."
                            rows={4}
                            className="w-full rounded-xl px-4 py-2.5 border border-gray-200 bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all resize-none font-medium text-sm text-gray-700"
                        />
                    </div>
                </form>
            </Modal>

            {/* Manage Types & Attributes Modal */}
            <Modal
                isOpen={isDetailsModalOpen}
                onClose={() => setIsDetailsModalOpen(false)}
                title={`Quản lý Cấu hình: ${selectedCategoryForDetails?.categoryName}`}
                size="4xl"
            >
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-h-[70vh] overflow-y-auto pr-2 pt-2">
                    {/* PRODUCT TYPES SECTION */}
                    <div className="space-y-4 border-r border-gray-100 pr-4">
                        <h4 className="text-sm font-bold text-gray-400 uppercase tracking-wider flex items-center gap-2">
                            <Settings className="h-4 w-4 text-primary" />
                            Loại sản phẩm (Product Types)
                        </h4>

                        <form onSubmit={handleAddProductType} className="flex gap-2">
                            <input
                                type="text"
                                placeholder="VD: Laptop, Áo thun..."
                                value={newTypeName}
                                onChange={(e) => setNewTypeName(e.target.value)}
                                className="flex-1 rounded-xl px-3.5 py-2 border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium"
                            />
                            <Button type="submit" size="sm" className="rounded-xl">Thêm</Button>
                        </form>

                        <div className="space-y-2 mt-4 max-h-[300px] overflow-y-auto hide-scrollbar">
                            {/* "Tất cả" Filter Option */}
                            <div 
                                onClick={() => setSelectedProductTypeForFilter(null)}
                                className={`flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all border ${
                                    selectedProductTypeForFilter === null 
                                    ? 'bg-orange-50/80 border-primary text-primary font-bold shadow-sm' 
                                    : 'bg-gray-50 border-gray-200/50 hover:bg-orange-50/20 text-gray-700 font-semibold'
                                }`}
                            >
                                <span className="text-sm">Tất cả (Hiển thị toàn bộ)</span>
                            </div>

                            {selectedCategoryForDetails?.productTypes?.map((type) => (
                                <div 
                                    key={type.id} 
                                    onClick={() => setSelectedProductTypeForFilter(type.id)}
                                    className={`flex items-center justify-between p-3 rounded-xl cursor-pointer transition-all border ${
                                        selectedProductTypeForFilter === type.id 
                                        ? 'bg-orange-50/80 border-primary text-primary font-bold shadow-sm' 
                                        : 'bg-gray-50 border-gray-200/50 hover:bg-orange-50/20 text-gray-700 font-semibold'
                                    }`}
                                >
                                    <span className="text-sm">{type.typeName}</span>
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation(); // Prevent setting filter when deleting
                                            handleDeleteProductType(type.id);
                                        }}
                                        className="text-gray-400 hover:text-red-500 p-1.5 rounded-lg hover:bg-white shadow-none hover:shadow-sm transition-all"
                                    >
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            ))}
                            {(!selectedCategoryForDetails?.productTypes || selectedCategoryForDetails.productTypes.length === 0) && (
                                <p className="text-xs text-gray-400 italic py-4 text-center">Chưa có loại sản phẩm nào.</p>
                            )}
                        </div>
                    </div>

                    {/* ATTRIBUTES SECTION */}
                    <div className="space-y-4">
                        <h4 className="text-sm font-bold text-gray-400 uppercase tracking-wider flex items-center gap-2">
                            <FileText className="h-4 w-4 text-primary" />
                            Thuộc tính Template (Attributes)
                        </h4>

                        <form onSubmit={handleAddAttribute} className="space-y-4 bg-white/60 p-5 rounded-2xl border border-gray-100 shadow-sm">
                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <label className="text-xs font-bold text-gray-500 block mb-1">Mã Thuộc tính (Key)</label>
                                    <input
                                        type="text"
                                        placeholder="cpu, dung_luong..."
                                        required
                                        value={attrFormData.name}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, name: e.target.value.toLowerCase().trim() })}
                                        className="w-full rounded-xl px-3.5 py-2.5 border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium text-gray-700 bg-white"
                                    />
                                </div>
                                <div>
                                    <label className="text-xs font-bold text-gray-500 block mb-1">Tên hiển thị</label>
                                    <input
                                        type="text"
                                        placeholder="CPU, Dung lượng..."
                                        required
                                        value={attrFormData.displayName}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, displayName: e.target.value })}
                                        className="w-full rounded-xl px-3.5 py-2.5 border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium text-gray-700 bg-white"
                                    />
                                </div>
                            </div>

                            <div className="flex items-center gap-4 py-1">
                                <label className="flex items-center gap-2 text-xs text-gray-600 font-semibold cursor-pointer select-none">
                                    <input
                                        type="checkbox"
                                        checked={attrFormData.isRequired}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, isRequired: e.target.checked })}
                                        className="rounded border-gray-300 text-primary focus:ring-primary/30 h-4 w-4 transition-colors cursor-pointer"
                                    />
                                    Bắt buộc nhập
                                </label>

                                <label className="flex items-center gap-2 text-xs text-gray-600 font-semibold cursor-pointer select-none">
                                    <input
                                        type="checkbox"
                                        checked={attrFormData.isCommon}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, isCommon: e.target.checked })}
                                        className="rounded border-gray-300 text-primary focus:ring-primary/30 h-4 w-4 transition-colors cursor-pointer"
                                    />
                                    Thuộc tính CHUNG
                                </label>
                            </div>

                            {!attrFormData.isCommon && (
                                <div className="animate-fade-in">
                                    <label className="text-xs font-bold text-gray-500 block mb-1">Gắn với Loại sản phẩm nào?</label>
                                    <select
                                        required={!attrFormData.isCommon}
                                        value={attrFormData.productTypeId}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, productTypeId: e.target.value })}
                                        className="w-full rounded-xl px-3 py-2.5 border border-gray-200 text-xs bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium text-gray-700"
                                    >
                                        <option value="">-- Chọn Loại sản phẩm --</option>
                                        {selectedCategoryForDetails?.productTypes?.map((t) => (
                                            <option key={t.id} value={t.id}>{t.typeName}</option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            <div>
                                <label className="text-xs font-bold text-gray-500 block mb-1">Kiểu dữ liệu</label>
                                <select
                                    value={attrFormData.fieldType}
                                    onChange={(e) => setAttrFormData({ ...attrFormData, fieldType: e.target.value as any })}
                                    className="w-full rounded-xl px-3 py-2.5 border border-gray-200 text-xs bg-white focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium text-gray-700"
                                >
                                    <option value="TEXT">TEXT (Chữ/Chuỗi)</option>
                                    <option value="NUMBER">NUMBER (Số)</option>
                                    <option value="DROPDOWN">DROPDOWN (Lựa chọn)</option>
                                </select>
                            </div>

                            {attrFormData.fieldType === 'DROPDOWN' && (
                                <div className="animate-fade-in">
                                    <label className="text-xs font-bold text-gray-500 block mb-1">Các lựa chọn (Phân cách bằng dấu phẩy)</label>
                                    <input
                                        type="text"
                                        placeholder="8GB, 16GB, 32GB"
                                        required
                                        value={attrFormData.options}
                                        onChange={(e) => setAttrFormData({ ...attrFormData, options: e.target.value })}
                                        className="w-full rounded-xl px-3.5 py-2.5 border border-gray-200 text-xs focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary font-medium text-gray-700 bg-white"
                                    />
                                </div>
                            )}

                            <button 
                                type="submit" 
                                className="w-full rounded-xl py-2.5 bg-gradient-to-r from-orange-400 to-orange-500 hover:from-orange-500 hover:to-orange-600 text-white text-xs font-bold shadow-glow transition-all active:scale-[0.98]"
                            >
                                Thêm Thuộc tính
                            </button>
                        </form>

                        {/* List Attributes */}
                        <div className="space-y-2 mt-4 max-h-[300px] overflow-y-auto pr-1 hide-scrollbar">
                            {/* Common Attrs */}
                            <p className="text-xs font-bold text-orange-500 flex items-center gap-1.5 mt-2">
                                <FileText className="h-3.5 w-3.5" /> Thuộc tính CHUNG:
                            </p>
                            <div className="space-y-1.5">
                                {selectedCategoryForDetails?.attributes?.filter(a => a.isCommon).map((attr) => (
                                    <div key={attr.id} className="flex items-center justify-between p-3 bg-gradient-to-r from-orange-50/50 to-orange-100/20 rounded-xl border border-orange-100 shadow-sm transition-all text-xs font-semibold">
                                        <div className="flex items-center gap-2">
                                            <span className="text-gray-800">{attr.displayName}</span>
                                            <code className="text-gray-400 font-mono text-[10px] bg-white px-1.5 py-0.5 rounded border border-gray-100">({attr.name})</code>
                                            <span className="text-[9px] bg-orange-100/60 text-orange-600 px-1.5 py-0.5 rounded-md font-bold">{attr.fieldType || 'TEXT'}</span>
                                            {attr.isRequired && <span className="text-red-500 font-bold" title="Bắt buộc">*</span>}
                                        </div>
                                        <button 
                                            onClick={() => handleDeleteAttribute(attr.id)} 
                                            className="text-gray-400 hover:text-red-500 p-1 rounded-lg hover:bg-white transition-all shadow-none hover:shadow-sm"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                ))}
                            </div>

                            {/* Specific Attrs */}
                            <p className="text-xs font-bold text-gray-500 flex items-center gap-1.5 mt-4">
                                <Settings className="h-3.5 w-3.5" /> Thuộc tính RIÊNG theo Loại:
                            </p>
                            <div className="space-y-3">
                                {selectedCategoryForDetails?.productTypes?.filter(type => selectedProductTypeForFilter === null || type.id === selectedProductTypeForFilter).map((type) => (
                                    <div key={type.id} className="bg-gray-50/40 border border-gray-100/80 rounded-2xl p-3.5 space-y-2 shadow-sm">
                                        <p className="text-xs font-bold text-gray-700 flex items-center gap-1">
                                            🏷️ {type.typeName}:
                                        </p>
                                        <div className="space-y-1.5">
                                            {type.attributes?.map((attr) => (
                                                <div key={attr.id} className="flex items-center justify-between p-3 bg-white border border-gray-200/60 rounded-xl shadow-none hover:shadow-sm transition-all text-xs font-semibold">
                                                    <div className="flex items-center gap-2">
                                                        <span className="text-gray-700">{attr.displayName}</span>
                                                        <code className="text-gray-400 font-mono text-[10px] bg-gray-50 px-1.5 py-0.5 rounded border border-gray-200/50">({attr.name})</code>
                                                        <span className="text-[9px] bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded-md font-bold">{attr.fieldType || 'TEXT'}</span>
                                                        {attr.isRequired && <span className="text-red-500 font-bold" title="Bắt buộc">*</span>}
                                                    </div>
                                                    <button 
                                                        onClick={() => handleDeleteAttribute(attr.id)} 
                                                        className="text-gray-400 hover:text-red-500 p-1 rounded-lg hover:bg-gray-50 transition-all"
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </button>
                                                </div>
                                            ))}
                                            {(!type.attributes || type.attributes.length === 0) && (
                                                <p className="text-[11px] text-gray-400 italic pl-1">Chưa có thuộc tính riêng.</p>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
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
                title="Xóa Danh mục"
                message="Bạn có chắc chắn muốn xóa danh mục này? Toàn bộ loại sản phẩm và thuộc tính template liên quan sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác."
                confirmText="Xóa vĩnh viễn"
                cancelText="Hủy"
                variant="danger"
            />
        </div>
    );
}
