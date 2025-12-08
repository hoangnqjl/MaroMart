import axiosInstance from '../lib/axios';

// Types
export interface User {
    userId: string;
    fullName: string;
    email: string;
    phoneNumber: string;
    avatarUrl: string;
    role: 'admin' | 'user';
    isActive: boolean;
}

export interface Product {
    productId: string;
    productName: string;
    productPrice: number;
    productMedia: string[];
    categoryId: string;
    createdAt: string;
    productDescription?: string;
    productAddress?: string;
    productAttribute?: Record<string, any>;
    userInfo: {
        fullName: string;
        avatarUrl: string;
        phoneNumber?: string;
    };
}

export interface Category {
    categoryId: string;
    categoryName: string;
    categorySpec: string;
}

export interface ProductsResponse {
    products: Product[];
    total: number;
    page: number;
    limit: number;
}

export interface StatsOverview {
    totalCategories: number;
    totalProducts: number;
    totalUsers: number;
    postsToday: number;
    trends?: {
        categories: string;
        products: string;
        users: string;
        posts: string;
    };
}

export interface DailyPost {
    _id: string;
    count: number;
}

export interface ProductPerCategory {
    categoryName: string;
    count: number;
}

// Auth API
export const authAPI = {
    login: async (email: string, password: string) => {
        const response = await axiosInstance.post('/auth/v1/login', { email, password });
        return response.data;
    },
};

// Users API
export const usersAPI = {
    getUsers: async (page = 1, limit = 10, search = '') => {
        // Backend returns plain array, not paginated
        const response = await axiosInstance.get<User[]>('/admin/users', {
            params: { page, limit, search },
        });
        return response.data;
    },

    /**
     * Toggle user role between 'admin' and 'user'
     * Backend expects: { userId, newRole }
     * @param userId - User ID to toggle
     * @param newRole - New role to set ('admin' or 'user')
     * @returns { userId: string, newRole: 'admin' | 'user' }
     */
    toggleUserRole: async (userId: string, newRole: 'admin' | 'user'): Promise<{ userId: string; newRole: 'admin' | 'user' }> => {
        console.log('🔄 [API] toggleUserRole called');
        console.log('📝 [API] Parameters:', { userId, newRole });

        const url = `/admin/users/${userId}/role`;
        const payload = { userId, newRole };

        console.log('🌐 [API] Request URL:', url);
        console.log('📦 [API] Request payload:', JSON.stringify(payload, null, 2));
        console.log('⏳ [API] Sending PATCH request...');

        try {
            const response = await axiosInstance.patch(url, payload);
            console.log('✅ [API] Response received:', response.data);
            console.log('📊 [API] Response status:', response.status);
            return response.data;
        } catch (error: any) {
            console.error('❌ [API] Error occurred:', error);
            console.error('📄 [API] Error response:', error.response?.data);
            console.error('🔢 [API] Error status:', error.response?.status);
            console.error('📋 [API] Full error object:', JSON.stringify(error, null, 2));
            throw error;
        }
    },

    deleteUser: async (userId: string) => {
        const response = await axiosInstance.delete(`/admin/users/${userId}`);
        return response.data;
    },

    /**
     * Update user information
     * Route: PUT /admin/users/:userId
     */
    updateUser: async (userId: string, data: Partial<User>) => {
        console.log('🔄 [API] updateUser called');
        console.log('📝 [API] Parameters:', { userId, data });

        const url = `/admin/users/${userId}`;
        console.log('🌐 [API] Request URL:', url);
        console.log('📦 [API] Request payload:', JSON.stringify(data, null, 2));

        try {
            const response = await axiosInstance.put(url, data);
            console.log('✅ [API] Response received:', response.data);
            return response.data;
        } catch (error: any) {
            console.error('❌ [API] Error occurred:', error);
            console.error('📄 [API] Error response:', error.response?.data);
            throw error;
        }
    },
};

// Products API
export const productsAPI = {
    getProducts: async (page = 1, limit = 10, search = '', categoryId = '') => {
        const response = await axiosInstance.get<ProductsResponse>('/admin/products', {
            params: { page, limit, search, categoryId },
        });
        return response.data;
    },

    deleteProduct: async (productId: string) => {
        const response = await axiosInstance.delete(`/admin/products/${productId}`);
        return response.data;
    },

    deleteProducts: async (productIds: string[]) => {
        const response = await axiosInstance.post('/admin/products/bulk-delete', { productIds });
        return response.data;
    },
};

// Categories API
export const categoriesAPI = {
    getCategories: async () => {
        const response = await axiosInstance.get<Category[]>('/categories');
        return response.data;
    },

    createCategory: async (data: Category) => {
        const response = await axiosInstance.post('/categories', data);
        return response.data;
    },

    updateCategory: async (id: string, data: Omit<Category, 'categoryId'>) => {
        const response = await axiosInstance.patch(`/categories/${id}`, data);
        return response.data;
    },

    deleteCategory: async (id: string) => {
        const response = await axiosInstance.delete(`/categories/${id}`);
        return response.data;
    },
};

// Dashboard Stats API
export const statsAPI = {
    getOverview: async () => {
        const response = await axiosInstance.get<StatsOverview>('/admin/stats/overview');
        return response.data;
    },

    getDailyPosts: async () => {
        const response = await axiosInstance.get<DailyPost[]>('/admin/stats/daily-posts');
        return response.data;
    },

    getProductsPerCategory: async () => {
        const response = await axiosInstance.get<ProductPerCategory[]>('/admin/stats/products-per-category');
        return response.data;
    },
};
