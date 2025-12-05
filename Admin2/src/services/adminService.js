/**
 * Admin Service - Centralized API calls with detailed logging
 * This is a JavaScript wrapper around the TypeScript api.ts for easier debugging
 */

import { usersAPI, productsAPI, categoriesAPI, statsAPI } from './api';

console.log('📦 [AdminService] Module loaded');

// ==================== USER MANAGEMENT ====================

/**
 * Get all users with pagination
 */
export const getUsers = async (page = 1, limit = 10, search = '') => {
    console.log('🔄 [AdminService] getUsers called');
    console.log('📝 [AdminService] Parameters:', { page, limit, search });

    try {
        const users = await usersAPI.getUsers(page, limit, search);
        console.log('✅ [AdminService] getUsers success');
        console.log('📊 [AdminService] Users count:', users.length);
        return users;
    } catch (error) {
        console.error('❌ [AdminService] getUsers failed:', error);
        throw error;
    }
};

/**
 * Toggle user role between admin and user
 * @param {string} userId - User ID
 * @param {'admin' | 'user'} newRole - New role to set
 */
export const toggleUserRole = async (userId, newRole) => {
    console.log('🔄 [AdminService] toggleUserRole called');
    console.log('👤 [AdminService] User ID:', userId);
    console.log('🎭 [AdminService] New Role:', newRole);
    console.log('⏳ [AdminService] Calling API...');

    try {
        const result = await usersAPI.toggleUserRole(userId, newRole);
        console.log('✅ [AdminService] toggleUserRole success');
        console.log('📦 [AdminService] Result:', result);
        return result;
    } catch (error) {
        console.error('❌ [AdminService] toggleUserRole failed');
        console.error('📄 [AdminService] Error:', error);
        throw error;
    }
};

/**
 * Update user information
 * @param {string} userId - User ID
 * @param {object} data - User data to update
 */
export const updateUser = async (userId, data) => {
    console.log('🔄 [AdminService] updateUser called');
    console.log('👤 [AdminService] User ID:', userId);
    console.log('📝 [AdminService] Data:', data);

    try {
        const result = await usersAPI.updateUser(userId, data);
        console.log('✅ [AdminService] updateUser success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] updateUser failed:', error);
        throw error;
    }
};

/**
 * Delete a user
 */
export const deleteUser = async (userId) => {
    console.log('🔄 [AdminService] deleteUser called');
    console.log('👤 [AdminService] User ID:', userId);

    try {
        const result = await usersAPI.deleteUser(userId);
        console.log('✅ [AdminService] deleteUser success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] deleteUser failed:', error);
        throw error;
    }
};

// ==================== PRODUCT MANAGEMENT ====================

/**
 * Get products with pagination and filters
 */
export const getProducts = async (page = 1, limit = 10, search = '', categoryId = '') => {
    console.log('🔄 [AdminService] getProducts called');
    console.log('📝 [AdminService] Parameters:', { page, limit, search, categoryId });

    try {
        const response = await productsAPI.getProducts(page, limit, search, categoryId);
        console.log('✅ [AdminService] getProducts success');
        console.log('📊 [AdminService] Products count:', response.products?.length);
        console.log('📊 [AdminService] Total:', response.total);
        return response;
    } catch (error) {
        console.error('❌ [AdminService] getProducts failed:', error);
        throw error;
    }
};

/**
 * Delete a product
 */
export const deleteProduct = async (productId) => {
    console.log('🔄 [AdminService] deleteProduct called');
    console.log('📦 [AdminService] Product ID:', productId);

    try {
        const result = await productsAPI.deleteProduct(productId);
        console.log('✅ [AdminService] deleteProduct success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] deleteProduct failed:', error);
        throw error;
    }
};

/**
 * Delete multiple products
 */
export const deleteProducts = async (productIds) => {
    console.log('🔄 [AdminService] deleteProducts called');
    console.log('📦 [AdminService] Product IDs:', productIds);
    console.log('📊 [AdminService] Count:', productIds.length);

    try {
        const result = await productsAPI.deleteProducts(productIds);
        console.log('✅ [AdminService] deleteProducts success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] deleteProducts failed:', error);
        throw error;
    }
};

// ==================== CATEGORY MANAGEMENT ====================

/**
 * Get all categories
 */
export const getCategories = async () => {
    console.log('🔄 [AdminService] getCategories called');

    try {
        const categories = await categoriesAPI.getCategories();
        console.log('✅ [AdminService] getCategories success');
        console.log('📊 [AdminService] Categories count:', categories.length);
        return categories;
    } catch (error) {
        console.error('❌ [AdminService] getCategories failed:', error);
        throw error;
    }
};

/**
 * Create a new category
 */
export const createCategory = async (data) => {
    console.log('🔄 [AdminService] createCategory called');
    console.log('📝 [AdminService] Category data:', data);

    try {
        const result = await categoriesAPI.createCategory(data);
        console.log('✅ [AdminService] createCategory success');
        console.log('📦 [AdminService] Result:', result);
        return result;
    } catch (error) {
        console.error('❌ [AdminService] createCategory failed:', error);
        throw error;
    }
};

/**
 * Update a category
 */
export const updateCategory = async (id, data) => {
    console.log('🔄 [AdminService] updateCategory called');
    console.log('🆔 [AdminService] Category ID:', id);
    console.log('📝 [AdminService] Update data:', data);

    try {
        const result = await categoriesAPI.updateCategory(id, data);
        console.log('✅ [AdminService] updateCategory success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] updateCategory failed:', error);
        throw error;
    }
};

/**
 * Delete a category
 */
export const deleteCategory = async (id) => {
    console.log('🔄 [AdminService] deleteCategory called');
    console.log('🆔 [AdminService] Category ID:', id);

    try {
        const result = await categoriesAPI.deleteCategory(id);
        console.log('✅ [AdminService] deleteCategory success');
        return result;
    } catch (error) {
        console.error('❌ [AdminService] deleteCategory failed:', error);
        throw error;
    }
};

// ==================== DASHBOARD STATS ====================

/**
 * Get dashboard overview stats
 */
export const getOverviewStats = async () => {
    console.log('🔄 [AdminService] getOverviewStats called');

    try {
        const stats = await statsAPI.getOverview();
        console.log('✅ [AdminService] getOverviewStats success');
        console.log('📊 [AdminService] Stats:', stats);
        return stats;
    } catch (error) {
        console.error('❌ [AdminService] getOverviewStats failed:', error);
        throw error;
    }
};

/**
 * Get daily posts stats
 */
export const getDailyPosts = async () => {
    console.log('🔄 [AdminService] getDailyPosts called');

    try {
        const data = await statsAPI.getDailyPosts();
        console.log('✅ [AdminService] getDailyPosts success');
        console.log('📊 [AdminService] Data points:', data.length);
        return data;
    } catch (error) {
        console.error('❌ [AdminService] getDailyPosts failed:', error);
        throw error;
    }
};

/**
 * Get products per category stats
 */
export const getProductsPerCategory = async () => {
    console.log('🔄 [AdminService] getProductsPerCategory called');

    try {
        const data = await statsAPI.getProductsPerCategory();
        console.log('✅ [AdminService] getProductsPerCategory success');
        console.log('📊 [AdminService] Categories:', data.length);
        return data;
    } catch (error) {
        console.error('❌ [AdminService] getProductsPerCategory failed:', error);
        throw error;
    }
};

console.log('✅ [AdminService] All functions exported');

export default {
    // Users
    getUsers,
    toggleUserRole,
    updateUser,
    deleteUser,

    // Products
    getProducts,
    deleteProduct,
    deleteProducts,

    // Categories
    getCategories,
    createCategory,
    updateCategory,
    deleteCategory,

    // Stats
    getOverviewStats,
    getDailyPosts,
    getProductsPerCategory,
};
