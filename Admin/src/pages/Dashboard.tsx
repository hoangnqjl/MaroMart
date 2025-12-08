import { useState, useEffect } from 'react';
import { Card } from '../components/ui/Card';
import { BarChart } from '../components/charts/BarChart';
import { LineChart } from '../components/charts/LineChart';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '../components/ui/Table';
import { Badge } from '../components/ui/Badge';
import {
    Package,
    Users,
    Grid3x3,
    FileText,
    TrendingUp,
    TrendingDown,
} from 'lucide-react';
import { StatCardSkeleton, TableSkeleton, CardSkeleton } from '../components/skeletons/Skeletons';
import type { Product, Category } from '../services/api';
import { statsAPI, productsAPI, categoriesAPI } from '../services/api';
import { formatPrice, formatDate } from '../lib/utils';
import { useToast } from '../hooks/useToast';

interface StatCard {
    title: string;
    value: string;
    icon: typeof Package;
    trend: string;
    isPositive: boolean;
}

export function Dashboard() {
    const [stats, setStats] = useState<StatCard[]>([]);
    const [productsPerCategory, setProductsPerCategory] = useState<any[]>([]);
    const [dailyPosts, setDailyPosts] = useState<any[]>([]);
    const [latestProducts, setLatestProducts] = useState<Product[]>([]);
    const [categories, setCategories] = useState<Category[]>([]);
    const [isLoadingStats, setIsLoadingStats] = useState(true);
    const [isLoadingCharts, setIsLoadingCharts] = useState(true);
    const [isLoadingProducts, setIsLoadingProducts] = useState(true);
    const { toast } = useToast();

    // Fetch stats
    useEffect(() => {
        const fetchStats = async () => {
            try {
                setIsLoadingStats(true);
                const data = await statsAPI.getOverview();

                const statsData: StatCard[] = [
                    {
                        title: 'Total Categories',
                        value: data.totalCategories?.toString() || '0',
                        icon: Grid3x3,
                        trend: data.trends?.categories || '+0%',
                        isPositive: data.trends?.categories?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Total Products',
                        value: data.totalProducts?.toString() || '0',
                        icon: Package,
                        trend: data.trends?.products || '+0%',
                        isPositive: data.trends?.products?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Total Users',
                        value: data.totalUsers?.toString() || '0',
                        icon: Users,
                        trend: data.trends?.users || '+0%',
                        isPositive: data.trends?.users?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Posts Today',
                        value: data.postsToday?.toString() || '0',
                        icon: FileText,
                        trend: data.trends?.posts || '+0%',
                        isPositive: data.trends?.posts?.startsWith('+') ?? true,
                    },
                ];

                setStats(statsData);
            } catch (err: any) {
                console.error('Failed to fetch stats:', err);
                toast({
                    type: 'error',
                    title: 'Error',
                    description: 'Failed to load statistics.',
                });
            } finally {
                setIsLoadingStats(false);
            }
        };

        fetchStats();
    }, []);

    // Fetch chart data
    useEffect(() => {
        const fetchChartData = async () => {
            try {
                setIsLoadingCharts(true);
                const [productsData, postsData] = await Promise.all([
                    statsAPI.getProductsPerCategory(),
                    statsAPI.getDailyPosts(),
                ]);

                // Transform productsData to match BarChart format
                // API returns: [{ categoryName: "...", count: 123 }]
                // BarChart expects: [{ name: "...", value: 123 }]
                const transformedProductsData = (productsData || []).map((item: any) => ({
                    name: item.categoryName,
                    value: item.count,
                }));

                // Transform dailyPosts for LineChart
                // API returns: [{ _id: "2025-04-01", count: 25 }]
                // LineChart expects: [{ name: "...", value: 123 }]
                const transformedPostsData = (postsData || []).map((item: any) => ({
                    name: item._id,
                    value: item.count,
                }));

                setProductsPerCategory(transformedProductsData);
                setDailyPosts(transformedPostsData);
            } catch (err: any) {
                console.error('Failed to fetch chart data:', err);
                toast({
                    type: 'error',
                    title: 'Error',
                    description: 'Failed to load chart data.',
                });
            } finally {
                setIsLoadingCharts(false);
            }
        };

        fetchChartData();
    }, []);

    // Fetch latest products and categories
    useEffect(() => {
        const fetchProductsAndCategories = async () => {
            try {
                setIsLoadingProducts(true);
                const [productsResponse, categoriesData] = await Promise.all([
                    productsAPI.getProducts(1, 5),
                    categoriesAPI.getCategories(),
                ]);

                // Backend returns { products[], total, page, limit }
                setLatestProducts(productsResponse.products || []);
                setCategories(categoriesData);
            } catch (err: any) {
                console.error('Failed to fetch products:', err);
                toast({
                    type: 'error',
                    title: 'Error',
                    description: 'Failed to load latest products.',
                });
            } finally {
                setIsLoadingProducts(false);
            }
        };

        fetchProductsAndCategories();
    }, []);

    return (
        <div className="space-y-8">
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {isLoadingStats ? (
                    <>
                        {[1, 2, 3, 4].map((i) => (
                            <StatCardSkeleton key={i} />
                        ))}
                    </>
                ) : (
                    stats.map((stat) => (
                        <Card key={stat.title} hover className="relative overflow-hidden">
                            <div className="flex items-start justify-between">
                                <div>
                                    <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                                    <p className="text-3xl font-bold text-gray-900 mt-2">
                                        {stat.value}
                                    </p>
                                    <div className="flex items-center gap-1 mt-2">
                                        {stat.isPositive ? (
                                            <TrendingUp className="h-4 w-4 text-green-500" />
                                        ) : (
                                            <TrendingDown className="h-4 w-4 text-red-500" />
                                        )}
                                        <span
                                            className={`text-sm font-medium ${stat.isPositive ? 'text-green-500' : 'text-red-500'
                                                }`}
                                        >
                                            {stat.trend}
                                        </span>
                                        <span className="text-sm text-gray-500">vs last month</span>
                                    </div>
                                </div>
                                <div className="rounded-xl bg-gradient-to-br from-primary to-primary-hover p-3">
                                    <stat.icon className="h-6 w-6 text-white" />
                                </div>
                            </div>
                        </Card>
                    ))
                )}
            </div>

            {/* Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {isLoadingCharts ? (
                    <>
                        <CardSkeleton />
                        <CardSkeleton />
                    </>
                ) : (
                    <>
                        {productsPerCategory.length > 0 && (
                            <BarChart
                                data={productsPerCategory}
                                title="Products per Category"
                            />
                        )}
                        {dailyPosts.length > 0 && (
                            <LineChart data={dailyPosts} title="Daily Posts (Last 7 Days)" />
                        )}
                    </>
                )}
            </div>

            {/* Latest Products Table */}
            <div className="glass-card p-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-6">
                    Latest Products
                </h2>

                {isLoadingProducts ? (
                    <TableSkeleton rows={5} />
                ) : latestProducts.length === 0 ? (
                    <div className="text-center py-12">
                        <p className="text-gray-500 text-lg">No products yet</p>
                        <p className="text-gray-400 text-sm mt-2">Products will appear here once added</p>
                    </div>
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Product</TableHead>
                                <TableHead>Price</TableHead>
                                <TableHead>Owner</TableHead>
                                <TableHead>Category</TableHead>
                                <TableHead>Date</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {latestProducts.map((product) => {
                                const category = categories.find(
                                    (c) => c.categoryId === product.categoryId
                                );
                                return (
                                    <TableRow key={product.productId}>
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
                                                <span className="text-sm">{product.userInfo.fullName}</span>
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
                                    </TableRow>
                                );
                            })}
                        </TableBody>
                    </Table>
                )}
            </div>
        </div>
    );
}
