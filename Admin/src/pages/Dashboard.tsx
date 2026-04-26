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
    ArrowUpRight,
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

const statColors = [
    { bg: 'from-orange-500 to-amber-400', light: 'bg-orange-50' },
    { bg: 'from-blue-500 to-cyan-400', light: 'bg-blue-50' },
    { bg: 'from-emerald-500 to-teal-400', light: 'bg-emerald-50' },
    { bg: 'from-violet-500 to-purple-400', light: 'bg-violet-50' },
];

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
                        title: 'Tổng Danh mục',
                        value: data.totalCategories?.toString() || '0',
                        icon: Grid3x3,
                        trend: data.trends?.categories || '+0%',
                        isPositive: data.trends?.categories?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Tổng Sản phẩm',
                        value: data.totalProducts?.toString() || '0',
                        icon: Package,
                        trend: data.trends?.products || '+0%',
                        isPositive: data.trends?.products?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Tổng Người dùng',
                        value: data.totalUsers?.toString() || '0',
                        icon: Users,
                        trend: data.trends?.users || '+0%',
                        isPositive: data.trends?.users?.startsWith('+') ?? true,
                    },
                    {
                        title: 'Bài đăng Hôm nay',
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

                const transformedProductsData = (productsData || []).map((item: any) => ({
                    name: item.categoryName,
                    value: item.count,
                }));

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
        <div className="space-y-8 animate-fade-in">
            {/* Welcome Section */}
            <div>
                <h1 className="text-2xl font-extrabold text-gray-900">Dashboard</h1>
                <p className="text-gray-400 mt-1 text-sm">Tổng quan hoạt động hệ thống MaroMart</p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
                {isLoadingStats ? (
                    <>
                        {[1, 2, 3, 4].map((i) => (
                            <StatCardSkeleton key={i} />
                        ))}
                    </>
                ) : (
                    stats.map((stat, index) => (
                        <div key={stat.title} className="glass-card p-5 relative overflow-hidden group animate-slide-up" style={{ animationDelay: `${index * 80}ms` }}>
                            <div className="flex items-start justify-between relative z-10">
                                <div>
                                    <p className="text-sm font-medium text-gray-400">{stat.title}</p>
                                    <p className="text-3xl font-extrabold text-gray-900 mt-1.5">
                                        {stat.value}
                                    </p>
                                    <div className="flex items-center gap-1.5 mt-2.5">
                                        <div className={`flex items-center gap-0.5 px-2 py-0.5 rounded-full text-xs font-semibold ${
                                            stat.isPositive 
                                                ? 'bg-emerald-50 text-emerald-600' 
                                                : 'bg-red-50 text-red-500'
                                        }`}>
                                            {stat.isPositive ? (
                                                <TrendingUp className="h-3 w-3" />
                                            ) : (
                                                <TrendingDown className="h-3 w-3" />
                                            )}
                                            {stat.trend}
                                        </div>
                                        <span className="text-xs text-gray-400">so với tháng trước</span>
                                    </div>
                                </div>
                                <div className={`rounded-2xl bg-gradient-to-br ${statColors[index].bg} p-3 shadow-lg shadow-${statColors[index].bg}/20`}>
                                    <stat.icon className="h-5 w-5 text-white" />
                                </div>
                            </div>
                            {/* Bottom accent */}
                            <div className={`absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r ${statColors[index].bg} opacity-60`} />
                        </div>
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
                                title="Sản phẩm theo Danh mục"
                            />
                        )}
                        {dailyPosts.length > 0 && (
                            <LineChart data={dailyPosts} title="Bài đăng trong tuần" />
                        )}
                    </>
                )}
            </div>

            {/* Latest Products Table */}
            <div className="glass-card p-6">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h2 className="text-lg font-bold text-gray-900">
                            Sản phẩm Mới nhất
                        </h2>
                        <p className="text-sm text-gray-400 mt-0.5">5 sản phẩm vừa được đăng tải</p>
                    </div>
                    <a href="/products" className="text-sm text-primary font-semibold flex items-center gap-1 hover:text-primary-hover transition-colors">
                        Xem tất cả
                        <ArrowUpRight className="h-4 w-4" />
                    </a>
                </div>

                {isLoadingProducts ? (
                    <TableSkeleton rows={5} />
                ) : latestProducts.length === 0 ? (
                    <div className="text-center py-16">
                        <div className="h-16 w-16 bg-orange-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                            <Package className="h-8 w-8 text-primary" />
                        </div>
                        <p className="text-gray-600 font-medium">Chưa có sản phẩm nào</p>
                        <p className="text-gray-400 text-sm mt-1">Sản phẩm sẽ hiển thị ở đây khi được tải lên</p>
                    </div>
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Sản phẩm</TableHead>
                                <TableHead>Giá</TableHead>
                                <TableHead>Người bán</TableHead>
                                <TableHead>Danh mục</TableHead>
                                <TableHead>Ngày đăng</TableHead>
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
                                                            <div className="h-12 w-12 bg-orange-50 rounded-xl flex items-center justify-center">
                                                                <Package className="h-5 w-5 text-primary/40" />
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
                                                                className="h-12 w-12 rounded-xl object-cover ring-1 ring-gray-100"
                                                                onError={(e) => {
                                                                    e.currentTarget.src = "https://via.placeholder.com/48/FB9A40/FFFFFF?text=IMG";
                                                                }}
                                                            />
                                                            {firstMedia.startsWith('video:') && (
                                                                <div className="absolute inset-0 flex items-center justify-center bg-black/40 rounded-xl pointer-events-none">
                                                                    <svg className="w-5 h-5 text-white drop-shadow-lg" fill="currentColor" viewBox="0 0 24 24">
                                                                        <path d="M8 5v14l11-7z" />
                                                                    </svg>
                                                                </div>
                                                            )}
                                                        </div>
                                                    );
                                                })()}
                                                <span className="font-medium text-gray-800 text-sm">{product.productName}</span>
                                            </div>
                                        </TableCell>
                                        <TableCell className="font-bold text-primary">
                                            {formatPrice(product.productPrice)}
                                        </TableCell>
                                        <TableCell>
                                            <div className="flex items-center gap-2">
                                                <img
                                                    src={product.userInfo.avatarUrl}
                                                    alt={product.userInfo.fullName}
                                                    className="h-7 w-7 rounded-lg object-cover ring-1 ring-gray-100"
                                                />
                                                <span className="text-sm text-gray-600">{product.userInfo.fullName}</span>
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant="warning">
                                                {category?.categoryName || 'Unknown'}
                                            </Badge>
                                        </TableCell>
                                        <TableCell className="text-gray-400 text-sm">
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
