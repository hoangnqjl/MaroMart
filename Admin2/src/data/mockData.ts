// Mock data types
export interface User {
    userId: string;
    fullName: string;
    email: string;
    phoneNumber: string;
    avatarUrl: string;
    role: 'admin' | 'user';
    isActive: boolean;
}

export interface Category {
    categoryId: string;
    categoryName: string;
    categorySpec: string;
}

export interface Product {
    productId: string;
    productName: string;
    productPrice: number;
    productMedia: string[];
    categoryId: string;
    createdAt: string;
    userInfo: {
        fullName: string;
        avatarUrl: string;
        phoneNumber?: string;
    };
}

// Mock Users
export const mockUsers: User[] = [
    {
        userId: '1',
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+84 123 456 789',
        avatarUrl: 'https://ui-avatars.com/api/?name=John+Doe&background=random',
        role: 'admin',
        isActive: true,
    },
    {
        userId: '2',
        fullName: 'Jane Smith',
        email: 'jane.smith@example.com',
        phoneNumber: '+84 987 654 321',
        avatarUrl: 'https://ui-avatars.com/api/?name=Jane+Smith&background=random',
        role: 'user',
        isActive: true,
    },
    {
        userId: '3',
        fullName: 'Robert Johnson',
        email: 'robert.j@example.com',
        phoneNumber: '+84 111 222 333',
        avatarUrl: 'https://ui-avatars.com/api/?name=Robert+Johnson&background=random',
        role: 'user',
        isActive: false,
    },
    {
        userId: '4',
        fullName: 'Emily Davis',
        email: 'emily.d@example.com',
        phoneNumber: '+84 444 555 666',
        avatarUrl: 'https://ui-avatars.com/api/?name=Emily+Davis&background=random',
        role: 'user',
        isActive: true,
    },
    {
        userId: '5',
        fullName: 'Michael Wilson',
        email: 'michael.w@example.com',
        phoneNumber: '+84 777 888 999',
        avatarUrl: 'https://ui-avatars.com/api/?name=Michael+Wilson&background=random',
        role: 'admin',
        isActive: true,
    },
];

// Mock Categories
export const mockCategories: Category[] = [
    {
        categoryId: '1',
        categoryName: 'Electronics',
        categorySpec: 'Smartphones, laptops, tablets, and electronic accessories',
    },
    {
        categoryId: '2',
        categoryName: 'Fashion',
        categorySpec: 'Clothing, shoes, bags, and fashion accessories',
    },
    {
        categoryId: '3',
        categoryName: 'Home & Living',
        categorySpec: 'Furniture, decor, kitchen appliances, and home essentials',
    },
    {
        categoryId: '4',
        categoryName: 'Sports & Outdoors',
        categorySpec: 'Sports equipment, outdoor gear, and fitness products',
    },
    {
        categoryId: '5',
        categoryName: 'Books & Media',
        categorySpec: 'Books, movies, music, and digital media',
    },
];

// Mock Products
export const mockProducts: Product[] = [
    {
        productId: '1',
        productName: 'iPhone 15 Pro Max',
        productPrice: 29990000,
        productMedia: ['https://via.placeholder.com/60?text=iPhone'],
        categoryId: '1',
        createdAt: '2024-12-01T10:30:00Z',
        userInfo: {
            fullName: 'John Doe',
            avatarUrl: 'https://ui-avatars.com/api/?name=John+Doe&background=random',
        },
    },
    {
        productId: '2',
        productName: 'Samsung Galaxy S24 Ultra',
        productPrice: 27990000,
        productMedia: ['https://via.placeholder.com/60?text=Samsung'],
        categoryId: '1',
        createdAt: '2024-12-01T11:00:00Z',
        userInfo: {
            fullName: 'Jane Smith',
            avatarUrl: 'https://ui-avatars.com/api/?name=Jane+Smith&background=random',
        },
    },
    {
        productId: '3',
        productName: 'Nike Air Max 2024',
        productPrice: 3500000,
        productMedia: ['https://via.placeholder.com/60?text=Nike'],
        categoryId: '2',
        createdAt: '2024-12-01T12:15:00Z',
        userInfo: {
            fullName: 'Robert Johnson',
            avatarUrl: 'https://ui-avatars.com/api/?name=Robert+Johnson&background=random',
        },
    },
    {
        productId: '4',
        productName: 'MacBook Pro M3',
        productPrice: 45990000,
        productMedia: ['https://via.placeholder.com/60?text=MacBook'],
        categoryId: '1',
        createdAt: '2024-12-01T13:20:00Z',
        userInfo: {
            fullName: 'Emily Davis',
            avatarUrl: 'https://ui-avatars.com/api/?name=Emily+Davis&background=random',
        },
    },
    {
        productId: '5',
        productName: 'Modern Sofa Set',
        productPrice: 12500000,
        productMedia: ['https://via.placeholder.com/60?text=Sofa'],
        categoryId: '3',
        createdAt: '2024-12-01T14:45:00Z',
        userInfo: {
            fullName: 'Michael Wilson',
            avatarUrl: 'https://ui-avatars.com/api/?name=Michael+Wilson&background=random',
        },
    },
    {
        productId: '6',
        productName: 'Sony WH-1000XM5',
        productPrice: 8990000,
        productMedia: ['https://via.placeholder.com/60?text=Sony'],
        categoryId: '1',
        createdAt: '2024-12-02T08:00:00Z',
        userInfo: {
            fullName: 'John Doe',
            avatarUrl: 'https://ui-avatars.com/api/?name=John+Doe&background=random',
        },
    },
    {
        productId: '7',
        productName: 'Adidas Running Shoes',
        productPrice: 2800000,
        productMedia: ['https://via.placeholder.com/60?text=Adidas'],
        categoryId: '4',
        createdAt: '2024-12-02T09:30:00Z',
        userInfo: {
            fullName: 'Jane Smith',
            avatarUrl: 'https://ui-avatars.com/api/?name=Jane+Smith&background=random',
        },
    },
    {
        productId: '8',
        productName: 'The Great Gatsby - Book',
        productPrice: 250000,
        productMedia: ['https://via.placeholder.com/60?text=Book'],
        categoryId: '5',
        createdAt: '2024-12-02T10:00:00Z',
        userInfo: {
            fullName: 'Emily Davis',
            avatarUrl: 'https://ui-avatars.com/api/?name=Emily+Davis&background=random',
        },
    },
];

// Chart data
export const productsPerCategoryData = [
    { name: 'Electronics', value: 4 },
    { name: 'Fashion', value: 1 },
    { name: 'Home', value: 1 },
    { name: 'Sports', value: 1 },
    { name: 'Books', value: 1 },
];

export const dailyPostsData = [
    { name: 'Mon', value: 3 },
    { name: 'Tue', value: 5 },
    { name: 'Wed', value: 2 },
    { name: 'Thu', value: 7 },
    { name: 'Fri', value: 4 },
    { name: 'Sat', value: 6 },
    { name: 'Sun', value: 8 },
];
