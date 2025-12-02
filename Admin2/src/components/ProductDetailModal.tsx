import { useState, useEffect, Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import {
    X,
    ChevronLeft,
    ChevronRight,
    Maximize2,
    MapPin,
    Calendar,
    User,
    Copy,
    Check,
} from 'lucide-react';
import type { Product } from '../services/api';
import { productsAPI } from '../services/api';
import { formatPrice, formatDate } from '../lib/utils';
import { Badge } from './ui/Badge';
import { useToast } from '../hooks/useToast';

interface ProductDetailModalProps {
    isOpen: boolean;
    onClose: () => void;
    product?: Product;
    productId?: string;
}

const attributeTemplates: Record<string, string[]> = {
    auto: ['brand', 'model', 'year', 'fuel_type', 'transmission', 'mileage', 'condition', 'color', 'accessories_type', 'warranty'],
    furniture: ['material', 'color', 'dimensions', 'style', 'room_type', 'weight', 'brand', 'warranty', 'assembly_required'],
    technology: ['brand', 'model', 'cpu', 'ram', 'storage', 'screen_size', 'battery_capacity', 'os', 'connectivity', 'warranty'],
    office: ['material', 'dimensions', 'color', 'brand', 'quantity', 'type', 'weight'],
    style: ['size', 'color', 'material', 'gender', 'brand', 'season', 'pattern', 'style', 'origin'],
    service: ['service_type', 'duration', 'price_type', 'provider', 'area', 'availability', 'warranty'],
    hobby: ['category', 'skill_level', 'material', 'brand', 'age_range', 'weight', 'size'],
    kids: ['age_range', 'material', 'size', 'color', 'brand', 'education_type', 'certification', 'weight'],
};

export function ProductDetailModal({
    isOpen,
    onClose,
    product: initialProduct,
    productId,
}: ProductDetailModalProps) {
    const [product, setProduct] = useState<Product | null>(initialProduct || null);
    const [isLoading, setIsLoading] = useState(false);
    const [activeMediaIndex, setActiveMediaIndex] = useState(0);
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [copiedAddress, setCopiedAddress] = useState(false);
    const { toast } = useToast();

    // Fetch product if only ID is provided
    useEffect(() => {
        if (isOpen && productId && !initialProduct) {
            const fetchProduct = async () => {
                setIsLoading(true);
                try {
                    // You'll need to add this endpoint to your API
                    const response = await productsAPI.getProducts(1, 1, productId);
                    if (response.products && response.products.length > 0) {
                        setProduct(response.products[0]);
                    }
                } catch (err) {
                    console.error('Failed to fetch product:', err);
                    toast({
                        type: 'error',
                        title: 'Error',
                        description: 'Failed to load product details.',
                    });
                } finally {
                    setIsLoading(false);
                }
            };
            fetchProduct();
        } else if (initialProduct) {
            setProduct(initialProduct);
        }
    }, [isOpen, productId, initialProduct]);

    // Reset state when modal closes
    useEffect(() => {
        if (!isOpen) {
            setActiveMediaIndex(0);
            setIsFullscreen(false);
        }
    }, [isOpen]);

    const handleCopyAddress = () => {
        if (product?.productAddress) {
            navigator.clipboard.writeText(product.productAddress);
            setCopiedAddress(true);
            toast({
                type: 'success',
                title: 'Copied!',
                description: 'Address copied to clipboard.',
            });
            setTimeout(() => setCopiedAddress(false), 2000);
        }
    };

    const isVideo = (url: string) => {
        return /\.(mp4|mov|webm)$/i.test(url);
    };

    const formatAttributeKey = (key: string): string => {
        return key
            .split('_')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    };

    const getCategoryKey = (categoryId: string): string => {
        // You can customize this mapping based on your actual category IDs
        const categoryMap: Record<string, string> = {
            'auto': 'auto',
            'furniture': 'furniture',
            'technology': 'technology',
            'tech': 'technology',
            'office': 'office',
            'fashion': 'style',
            'style': 'style',
            'service': 'service',
            'hobby': 'hobby',
            'kids': 'kids',
            'children': 'kids',
        };

        const lowerCategoryId = categoryId.toLowerCase();
        return categoryMap[lowerCategoryId] || 'technology';
    };

    const getRelevantAttributes = () => {
        if (!product?.productAttribute || !product.categoryId) return {};

        const categoryKey = getCategoryKey(product.categoryId);
        const template = attributeTemplates[categoryKey] || [];

        const relevantAttrs: Record<string, any> = {};
        template.forEach((attrKey) => {
            if (product.productAttribute && product.productAttribute[attrKey] !== undefined) {
                relevantAttrs[attrKey] = product.productAttribute[attrKey];
            }
        });

        return relevantAttrs;
    };

    if (!product && !isLoading) return null;

    return (
        <>
            <Transition appear show={isOpen} as={Fragment}>
                <Dialog as="div" className="relative z-50" onClose={onClose}>
                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="ease-in duration-200"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm" />
                    </Transition.Child>

                    <div className="fixed inset-0 overflow-y-auto">
                        <div className="flex min-h-full items-center justify-center p-4">
                            <Transition.Child
                                as={Fragment}
                                enter="ease-out duration-300"
                                enterFrom="opacity-0 scale-95"
                                enterTo="opacity-100 scale-100"
                                leave="ease-in duration-200"
                                leaveFrom="opacity-100 scale-100"
                                leaveTo="opacity-0 scale-95"
                            >
                                <Dialog.Panel className="w-full max-w-7xl transform overflow-hidden rounded-3xl bg-white/90 backdrop-blur-xl border border-white/30 shadow-2xl transition-all">
                                    {/* Close Button */}
                                    <button
                                        onClick={onClose}
                                        className="absolute top-6 right-6 z-10 p-2 rounded-xl bg-white/80 hover:bg-white transition-all shadow-lg group"
                                    >
                                        <X className="h-5 w-5 text-gray-600 group-hover:text-gray-900" />
                                    </button>

                                    {isLoading ? (
                                        <div className="p-12 text-center">
                                            <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
                                            <p className="mt-4 text-gray-600">Loading product details...</p>
                                        </div>
                                    ) : product ? (
                                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 p-8 max-h-[90vh] overflow-y-auto">
                                            {/* Left Side - Media Gallery */}
                                            <div className="space-y-4">
                                                {/* Main Media View */}
                                                <div className="relative aspect-square rounded-2xl overflow-hidden bg-gray-100 group">
                                                    {product.productMedia && product.productMedia.length > 0 ? (
                                                        <>
                                                            {isVideo(product.productMedia[activeMediaIndex]) ? (
                                                                <video
                                                                    src={product.productMedia[activeMediaIndex]}
                                                                    controls
                                                                    autoPlay
                                                                    loop
                                                                    muted
                                                                    className="w-full h-full object-cover"
                                                                />
                                                            ) : (
                                                                <img
                                                                    src={product.productMedia[activeMediaIndex]}
                                                                    alt={product.productName}
                                                                    className="w-full h-full object-cover"
                                                                />
                                                            )}

                                                            {/* Fullscreen Button */}
                                                            <button
                                                                onClick={() => setIsFullscreen(true)}
                                                                className="absolute top-4 right-4 p-2 rounded-lg bg-white/80 backdrop-blur-sm opacity-0 group-hover:opacity-100 transition-all shadow-lg hover:bg-white"
                                                            >
                                                                <Maximize2 className="h-5 w-5 text-gray-700" />
                                                            </button>

                                                            {/* Navigation Arrows */}
                                                            {product.productMedia.length > 1 && (
                                                                <>
                                                                    <button
                                                                        onClick={() =>
                                                                            setActiveMediaIndex((prev) =>
                                                                                prev === 0 ? product.productMedia.length - 1 : prev - 1
                                                                            )
                                                                        }
                                                                        className="absolute left-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/80 backdrop-blur-sm shadow-lg hover:bg-white transition-all"
                                                                    >
                                                                        <ChevronLeft className="h-5 w-5 text-gray-700" />
                                                                    </button>
                                                                    <button
                                                                        onClick={() =>
                                                                            setActiveMediaIndex((prev) =>
                                                                                prev === product.productMedia.length - 1 ? 0 : prev + 1
                                                                            )
                                                                        }
                                                                        className="absolute right-4 top-1/2 -translate-y-1/2 p-2 rounded-full bg-white/80 backdrop-blur-sm shadow-lg hover:bg-white transition-all"
                                                                    >
                                                                        <ChevronRight className="h-5 w-5 text-gray-700" />
                                                                    </button>
                                                                </>
                                                            )}
                                                        </>
                                                    ) : (
                                                        <div className="w-full h-full flex items-center justify-center text-gray-400">
                                                            No media available
                                                        </div>
                                                    )}
                                                </div>

                                                {/* Thumbnails Strip */}
                                                {product.productMedia && product.productMedia.length > 1 && (
                                                    <div className="flex gap-3 overflow-x-auto pb-2">
                                                        {product.productMedia.map((media, index) => (
                                                            <button
                                                                key={index}
                                                                onClick={() => setActiveMediaIndex(index)}
                                                                className={`relative flex-shrink-0 w-20 h-20 rounded-xl overflow-hidden transition-all ${activeMediaIndex === index
                                                                        ? 'ring-4 ring-primary scale-105'
                                                                        : 'hover:scale-105 hover:ring-2 hover:ring-gray-300'
                                                                    }`}
                                                            >
                                                                {isVideo(media) ? (
                                                                    <video
                                                                        src={media}
                                                                        className="w-full h-full object-cover"
                                                                        muted
                                                                    />
                                                                ) : (
                                                                    <img
                                                                        src={media}
                                                                        alt={`Thumbnail ${index + 1}`}
                                                                        className="w-full h-full object-cover"
                                                                    />
                                                                )}
                                                            </button>
                                                        ))}
                                                    </div>
                                                )}
                                            </div>

                                            {/* Right Side - Product Information */}
                                            <div className="space-y-6 lg:sticky lg:top-0 lg:h-fit">
                                                {/* Product Name */}
                                                <div>
                                                    <h1 className="text-4xl font-bold text-gray-900 mb-3">
                                                        {product.productName}
                                                    </h1>
                                                    <Badge variant="info" className="text-sm">
                                                        {product.categoryId}
                                                    </Badge>
                                                </div>

                                                {/* Price */}
                                                <div className="py-4 border-t border-b border-gray-200">
                                                    <p className="text-5xl font-bold text-primary">
                                                        {formatPrice(product.productPrice)}
                                                    </p>
                                                </div>

                                                {/* Owner Info */}
                                                <div className="flex items-center gap-4 p-4 rounded-xl bg-gradient-to-r from-gray-50 to-gray-100/50">
                                                    <img
                                                        src={product.userInfo?.avatarUrl}
                                                        alt={product.userInfo?.fullName}
                                                        className="h-14 w-14 rounded-full ring-4 ring-white shadow-lg"
                                                    />
                                                    <div className="flex-1">
                                                        <div className="flex items-center gap-2">
                                                            <User className="h-4 w-4 text-gray-500" />
                                                            <p className="font-semibold text-gray-900">
                                                                {product.userInfo?.fullName}
                                                            </p>
                                                        </div>
                                                        <div className="flex items-center gap-2 mt-1">
                                                            <Calendar className="h-4 w-4 text-gray-400" />
                                                            <p className="text-sm text-gray-600">
                                                                Posted on {formatDate(product.createdAt)}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>

                                                {/* Address (if exists) */}
                                                {product.productAddress && (
                                                    <div className="flex items-start gap-3 p-4 rounded-xl bg-blue-50 border border-blue-100">
                                                        <MapPin className="h-5 w-5 text-blue-600 mt-0.5 flex-shrink-0" />
                                                        <div className="flex-1">
                                                            <p className="text-sm font-medium text-blue-900">Location</p>
                                                            <p className="text-sm text-blue-700 mt-1">
                                                                {product.productAddress}
                                                            </p>
                                                        </div>
                                                        <button
                                                            onClick={handleCopyAddress}
                                                            className="p-2 rounded-lg hover:bg-blue-100 transition-colors"
                                                        >
                                                            {copiedAddress ? (
                                                                <Check className="h-4 w-4 text-green-600" />
                                                            ) : (
                                                                <Copy className="h-4 w-4 text-blue-600" />
                                                            )}
                                                        </button>
                                                    </div>
                                                )}

                                                {/* Description */}
                                                {product.productDescription && (
                                                    <div className="space-y-2">
                                                        <h3 className="text-lg font-semibold text-gray-900">
                                                            Description
                                                        </h3>
                                                        <p className="text-gray-700 leading-relaxed whitespace-pre-wrap">
                                                            {product.productDescription}
                                                        </p>
                                                    </div>
                                                )}

                                                {/* Dynamic Attributes */}
                                                {Object.keys(getRelevantAttributes()).length > 0 && (
                                                    <div className="space-y-3">
                                                        <h3 className="text-lg font-semibold text-gray-900">
                                                            Specifications
                                                        </h3>
                                                        <div className="grid grid-cols-2 gap-x-6 gap-y-3 p-4 rounded-xl bg-gradient-to-br from-gray-50 to-white border border-gray-200">
                                                            {Object.entries(getRelevantAttributes()).map(
                                                                ([key, value]) => (
                                                                    <div
                                                                        key={key}
                                                                        className="flex flex-col space-y-1"
                                                                    >
                                                                        <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                                                                            {formatAttributeKey(key)}
                                                                        </span>
                                                                        <span className="text-sm font-semibold text-gray-900">
                                                                            {value?.toString() || 'N/A'}
                                                                        </span>
                                                                    </div>
                                                                )
                                                            )}
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    ) : null}
                                </Dialog.Panel>
                            </Transition.Child>
                        </div>
                    </div>
                </Dialog>
            </Transition>

            {/* Fullscreen Media Viewer */}
            <Transition appear show={isFullscreen} as={Fragment}>
                <Dialog
                    as="div"
                    className="relative z-[60]"
                    onClose={() => setIsFullscreen(false)}
                >
                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="ease-in duration-200"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div className="fixed inset-0 bg-black/95" />
                    </Transition.Child>

                    <div className="fixed inset-0 overflow-y-auto">
                        <div className="flex min-h-full items-center justify-center p-4">
                            <Transition.Child
                                as={Fragment}
                                enter="ease-out duration-300"
                                enterFrom="opacity-0 scale-95"
                                enterTo="opacity-100 scale-100"
                                leave="ease-in duration-200"
                                leaveFrom="opacity-100 scale-100"
                                leaveTo="opacity-0 scale-95"
                            >
                                <Dialog.Panel className="relative max-w-7xl w-full">
                                    <button
                                        onClick={() => setIsFullscreen(false)}
                                        className="absolute top-4 right-4 z-10 p-3 rounded-full bg-white/10 hover:bg-white/20 transition-all"
                                    >
                                        <X className="h-6 w-6 text-white" />
                                    </button>

                                    {product?.productMedia &&
                                        product.productMedia[activeMediaIndex] && (
                                            <div className="relative">
                                                {isVideo(product.productMedia[activeMediaIndex]) ? (
                                                    <video
                                                        src={product.productMedia[activeMediaIndex]}
                                                        controls
                                                        autoPlay
                                                        loop
                                                        className="w-full max-h-[90vh] object-contain"
                                                    />
                                                ) : (
                                                    <img
                                                        src={product.productMedia[activeMediaIndex]}
                                                        alt={product.productName}
                                                        className="w-full max-h-[90vh] object-contain"
                                                    />
                                                )}
                                            </div>
                                        )}
                                </Dialog.Panel>
                            </Transition.Child>
                        </div>
                    </div>
                </Dialog>
            </Transition>
        </>
    );
}
