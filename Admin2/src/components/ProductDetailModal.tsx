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
    Phone,
} from 'lucide-react';
import type { Product } from '../services/api';
import { formatPrice, formatDate } from '../lib/utils';
import { Badge } from './ui/Badge';
import { useToast } from '../hooks/useToast';

interface ProductDetailModalProps {
    isOpen: boolean;
    onClose: () => void;
    product?: Product;
}

interface LocationData {
    province?: string;
    commune?: string;
    district?: string;
    detail?: string;
}

interface MediaItem {
    type: 'image' | 'video';
    url: string;
}

// Extend Product type to include phoneNumber in userInfo
interface ExtendedProduct extends Product {
    userInfo: {
        fullName: string;
        avatarUrl: string;
        phoneNumber?: string;
    };
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

const categoryNameMap: Record<string, string> = {
    'điện thoại': 'technology',
    'laptop': 'technology',
    'máy tính': 'technology',
    'technology': 'technology',
    'tech': 'technology',
    'ô tô': 'auto',
    'xe máy': 'auto',
    'auto': 'auto',
    'nội thất': 'furniture',
    'furniture': 'furniture',
    'văn phòng': 'office',
    'office': 'office',
    'thời trang': 'style',
    'fashion': 'style',
    'style': 'style',
    'dịch vụ': 'service',
    'service': 'service',
    'sở thích': 'hobby',
    'hobby': 'hobby',
    'trẻ em': 'kids',
    'kids': 'kids',
};

export function ProductDetailModal({
    isOpen,
    onClose,
    product,
}: ProductDetailModalProps) {
    const [activeMediaIndex, setActiveMediaIndex] = useState(0);
    const [isFullscreen, setIsFullscreen] = useState(false);
    const [copiedAddress, setCopiedAddress] = useState(false);
    const [copiedPhone, setCopiedPhone] = useState(false);
    const [isLoading, setIsLoading] = useState(true);
    const { toast } = useToast();

    useEffect(() => {
        if (!isOpen) {
            setActiveMediaIndex(0);
            setIsFullscreen(false);
            setIsLoading(true);
        } else {
            // Simulate loading for smooth skeleton transition
            setTimeout(() => setIsLoading(false), 300);
        }
    }, [isOpen]);

    // Parse media with "image:" or "video:" prefix
    const parseMedia = (mediaArray: string[]): MediaItem[] => {
        if (!mediaArray || !Array.isArray(mediaArray)) return [];

        return mediaArray.map((item) => {
            if (item.startsWith('image:')) {
                return { type: 'image', url: item.substring(6) };
            } else if (item.startsWith('video:')) {
                return { type: 'video', url: item.substring(6) };
            } else {
                // Fallback: detect by extension
                const isVideo = /\.(mp4|mov|webm)$/i.test(item);
                return { type: isVideo ? 'video' : 'image', url: item };
            }
        });
    };

    // Parse productAttribute (STRINGIFIED JSON or Object)
    const parseAttributes = (attrData: any): Record<string, any> => {
        if (!attrData) return {};

        try {
            if (typeof attrData === 'object' && !Array.isArray(attrData)) {
                return attrData;
            }
            if (typeof attrData === 'string') {
                return JSON.parse(attrData);
            }
        } catch (err) {
            console.error('Failed to parse productAttribute:', err);
        }

        return {};
    };

    // Parse productAddress (STRINGIFIED JSON or Object)
    const parseLocation = (address: any): LocationData => {
        let location: LocationData = {};

        if (!address) return location;

        try {
            if (typeof address === 'object' && !Array.isArray(address)) {
                location = address;
            } else if (typeof address === 'string') {
                location = JSON.parse(address);
            }
        } catch (err) {
            console.error('Failed to parse location:', err);
        }

        return location;
    };

    const formatLocation = (location: LocationData): string => {
        const parts = [];
        if (location.detail) parts.push(location.detail);
        if (location.commune) parts.push(location.commune);
        if (location.district) parts.push(location.district);
        if (location.province) parts.push(location.province);
        return parts.filter(Boolean).join(', ');
    };

    const handleCopyAddress = (address: string) => {
        navigator.clipboard.writeText(address);
        setCopiedAddress(true);
        toast({
            type: 'success',
            title: 'Copied!',
            description: 'Address copied to clipboard.',
        });
        setTimeout(() => setCopiedAddress(false), 2000);
    };

    const handleCopyPhone = (phone: string) => {
        navigator.clipboard.writeText(phone);
        setCopiedPhone(true);
        toast({
            type: 'success',
            title: 'Copied!',
            description: 'Phone number copied to clipboard.',
        });
        setTimeout(() => setCopiedPhone(false), 2000);
    };

    const handleCallPhone = (phone: string) => {
        window.location.href = `tel:${phone}`;
    };

    const formatAttributeKey = (key: string): string => {
        return key
            .split('_')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    };

    const getCategoryKey = (categoryId: string): string => {
        const lowerCategoryId = categoryId.toLowerCase();

        if (attributeTemplates[lowerCategoryId]) {
            return lowerCategoryId;
        }

        for (const [name, key] of Object.entries(categoryNameMap)) {
            if (lowerCategoryId.includes(name) || name.includes(lowerCategoryId)) {
                return key;
            }
        }

        return 'technology';
    };

    const getRelevantAttributes = (attributes: Record<string, any>, categoryId: string) => {
        const categoryKey = getCategoryKey(categoryId);
        const template = attributeTemplates[categoryKey] || [];

        const relevantAttrs: Record<string, any> = {};

        template.forEach((attrKey) => {
            const value = attributes[attrKey];
            if (value !== undefined && value !== null && value !== '') {
                relevantAttrs[attrKey] = value;
            }
        });

        return relevantAttrs;
    };

    if (!product) return null;

    const extendedProduct = product as ExtendedProduct;
    const mediaItems = parseMedia(product.productMedia || []);
    const parsedAttributes = parseAttributes(product.productAttribute);
    const location = parseLocation(product.productAddress);
    const formattedAddress = formatLocation(location);
    const relevantAttributes = getRelevantAttributes(parsedAttributes, product.categoryId);
    const phoneNumber = extendedProduct.userInfo?.phoneNumber;

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
                                <Dialog.Panel className="w-full max-w-7xl transform overflow-hidden rounded-3xl bg-white/95 backdrop-blur-xl border border-white/40 shadow-2xl transition-all">
                                    <button
                                        onClick={onClose}
                                        className="absolute top-6 right-6 z-10 p-2.5 rounded-xl bg-white/90 hover:bg-white transition-all shadow-lg group"
                                    >
                                        <X className="h-5 w-5 text-gray-600 group-hover:text-gray-900 group-hover:rotate-90 transition-transform duration-300" />
                                    </button>

                                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 p-8 max-h-[90vh] overflow-y-auto">
                                        {/* Left: Media Gallery */}
                                        <div className="space-y-4">
                                            <div className="relative aspect-square rounded-2xl overflow-hidden bg-gradient-to-br from-gray-100 to-gray-200 group">
                                                {isLoading ? (
                                                    <div className="w-full h-full flex items-center justify-center">
                                                        <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-primary" />
                                                    </div>
                                                ) : mediaItems.length > 0 ? (
                                                    <>
                                                        {mediaItems[activeMediaIndex].type === 'video' ? (
                                                            <video
                                                                key={mediaItems[activeMediaIndex].url}
                                                                src={mediaItems[activeMediaIndex].url}
                                                                controls
                                                                autoPlay
                                                                loop
                                                                muted
                                                                className="w-full h-full object-cover"
                                                            />
                                                        ) : (
                                                            <img
                                                                src={mediaItems[activeMediaIndex].url}
                                                                alt={product.productName}
                                                                className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-500"
                                                            />
                                                        )}

                                                        <button
                                                            onClick={() => setIsFullscreen(true)}
                                                            className="absolute top-4 right-4 p-2.5 rounded-lg bg-white/80 backdrop-blur-sm opacity-0 group-hover:opacity-100 transition-all shadow-lg hover:bg-white hover:scale-110"
                                                        >
                                                            <Maximize2 className="h-5 w-5 text-gray-700" />
                                                        </button>

                                                        {mediaItems.length > 1 && (
                                                            <>
                                                                <button
                                                                    onClick={() => setActiveMediaIndex((prev) => prev === 0 ? mediaItems.length - 1 : prev - 1)}
                                                                    className="absolute left-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-white/90 backdrop-blur-sm shadow-xl hover:bg-white transition-all hover:scale-110"
                                                                >
                                                                    <ChevronLeft className="h-6 w-6 text-gray-700" />
                                                                </button>
                                                                <button
                                                                    onClick={() => setActiveMediaIndex((prev) => prev === mediaItems.length - 1 ? 0 : prev + 1)}
                                                                    className="absolute right-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-white/90 backdrop-blur-sm shadow-xl hover:bg-white transition-all hover:scale-110"
                                                                >
                                                                    <ChevronRight className="h-6 w-6 text-gray-700" />
                                                                </button>
                                                            </>
                                                        )}
                                                    </>
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center text-gray-400">
                                                        <div className="text-center">
                                                            <svg
                                                                className="mx-auto h-24 w-24 mb-4"
                                                                fill="none"
                                                                stroke="currentColor"
                                                                viewBox="0 0 24 24"
                                                            >
                                                                <path
                                                                    strokeLinecap="round"
                                                                    strokeLinejoin="round"
                                                                    strokeWidth={1.5}
                                                                    d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                                                                />
                                                            </svg>
                                                            <p className="text-lg font-medium">No media available</p>
                                                        </div>
                                                    </div>
                                                )}
                                            </div>

                                            {mediaItems.length > 1 && (
                                                <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100">
                                                    {mediaItems.map((media, index) => (
                                                        <button
                                                            key={index}
                                                            onClick={() => setActiveMediaIndex(index)}
                                                            className={`relative flex-shrink-0 w-24 h-24 rounded-xl overflow-hidden transition-all ${activeMediaIndex === index
                                                                ? 'ring-4 ring-primary scale-105 shadow-lg'
                                                                : 'hover:scale-105 hover:ring-2 hover:ring-gray-300 opacity-70 hover:opacity-100'
                                                                }`}
                                                        >
                                                            {media.type === 'video' ? (
                                                                <>
                                                                    <video src={media.url} className="w-full h-full object-cover" muted />
                                                                    <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                                                                        <div className="p-2 bg-white/80 rounded-full">
                                                                            <svg className="h-4 w-4 text-gray-900" fill="currentColor" viewBox="0 0 24 24">
                                                                                <path d="M8 5v14l11-7z" />
                                                                            </svg>
                                                                        </div>
                                                                    </div>
                                                                </>
                                                            ) : (
                                                                <img src={media.url} alt={`Thumb ${index + 1}`} className="w-full h-full object-cover" />
                                                            )}
                                                        </button>
                                                    ))}
                                                </div>
                                            )}
                                        </div>

                                        {/* Right: Product Info */}
                                        <div className="space-y-6 lg:sticky lg:top-0 lg:h-fit">
                                            <div>
                                                <h1 className="text-4xl font-bold text-gray-900 mb-3 leading-tight">
                                                    {product.productName}
                                                </h1>
                                                <Badge variant="info" className="text-sm px-4 py-1.5">
                                                    {product.categoryId}
                                                </Badge>
                                            </div>

                                            <div className="py-6 border-t border-b border-gray-200">
                                                <p className="text-5xl font-bold bg-gradient-to-r from-primary to-blue-600 bg-clip-text text-transparent">
                                                    {formatPrice(product.productPrice)}
                                                </p>
                                            </div>

                                            {product.userInfo && (
                                                <div className="flex items-center gap-4 p-5 rounded-2xl bg-gradient-to-r from-gray-50 to-gray-100/50 border border-gray-200 shadow-sm">
                                                    <img
                                                        src={product.userInfo.avatarUrl}
                                                        alt={product.userInfo.fullName}
                                                        className="h-16 w-16 rounded-full ring-4 ring-white shadow-lg"
                                                    />
                                                    <div className="flex-1">
                                                        <div className="flex items-center gap-2">
                                                            <User className="h-4 w-4 text-gray-500" />
                                                            <p className="font-semibold text-gray-900 text-lg">
                                                                {product.userInfo.fullName}
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
                                            )}

                                            {/* Location Card */}
                                            {formattedAddress && (
                                                <div className="flex items-start gap-3 p-5 rounded-2xl bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 shadow-sm">
                                                    <MapPin className="h-5 w-5 text-blue-600 mt-0.5 flex-shrink-0" />
                                                    <div className="flex-1">
                                                        <p className="text-sm font-semibold text-blue-900 mb-1">Location</p>
                                                        <p className="text-sm text-blue-700 leading-relaxed">{formattedAddress}</p>
                                                    </div>
                                                    <button
                                                        onClick={() => handleCopyAddress(formattedAddress)}
                                                        className="p-2.5 rounded-lg hover:bg-blue-200 transition-colors"
                                                        title="Copy address"
                                                    >
                                                        {copiedAddress ? (
                                                            <Check className="h-4 w-4 text-green-600" />
                                                        ) : (
                                                            <Copy className="h-4 w-4 text-blue-600" />
                                                        )}
                                                    </button>
                                                </div>
                                            )}

                                            {/* Contact/Phone Card */}
                                            {phoneNumber && (
                                                <div className="flex items-start gap-3 p-5 rounded-2xl bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 shadow-sm">
                                                    <Phone className="h-5 w-5 text-green-600 mt-0.5 flex-shrink-0" />
                                                    <div className="flex-1">
                                                        <p className="text-sm font-semibold text-green-900 mb-1">Contact</p>
                                                        <button
                                                            onClick={() => handleCallPhone(phoneNumber)}
                                                            className="text-sm text-green-700 font-medium hover:text-green-900 transition-colors hover:underline"
                                                        >
                                                            Phone: {phoneNumber}
                                                        </button>
                                                    </div>
                                                    <button
                                                        onClick={() => handleCopyPhone(phoneNumber)}
                                                        className="p-2.5 rounded-lg hover:bg-green-200 transition-colors"
                                                        title="Copy phone number"
                                                    >
                                                        {copiedPhone ? (
                                                            <Check className="h-4 w-4 text-green-600" />
                                                        ) : (
                                                            <Copy className="h-4 w-4 text-green-600" />
                                                        )}
                                                    </button>
                                                </div>
                                            )}

                                            {product.productDescription && (
                                                <div className="space-y-2">
                                                    <h3 className="text-lg font-semibold text-gray-900">Description</h3>
                                                    <p className="text-gray-700 leading-relaxed whitespace-pre-wrap bg-gray-50 p-4 rounded-xl border border-gray-200">
                                                        {product.productDescription}
                                                    </p>
                                                </div>
                                            )}

                                            {Object.keys(relevantAttributes).length > 0 && (
                                                <div className="space-y-3">
                                                    <h3 className="text-lg font-semibold text-gray-900">Specifications</h3>
                                                    <div className="grid grid-cols-2 gap-x-6 gap-y-5 p-5 rounded-2xl bg-gradient-to-br from-gray-50 via-white to-gray-50 border border-gray-200 shadow-sm">
                                                        {Object.entries(relevantAttributes).map(([key, value]) => (
                                                            <div key={key} className="flex flex-col space-y-1.5">
                                                                <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                                                                    {formatAttributeKey(key)}
                                                                </span>
                                                                <span className="text-sm font-bold text-gray-900">
                                                                    {value?.toString() || 'N/A'}
                                                                </span>
                                                            </div>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </Dialog.Panel>
                            </Transition.Child>
                        </div>
                    </div>
                </Dialog>
            </Transition>

            {/* Fullscreen Viewer */}
            <Transition appear show={isFullscreen} as={Fragment}>
                <Dialog as="div" className="relative z-[60]" onClose={() => setIsFullscreen(false)}>
                    <Transition.Child
                        as={Fragment}
                        enter="ease-out duration-300"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="ease-in duration-200"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div className="fixed inset-0 bg-black/95 backdrop-blur-sm" />
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
                                        className="absolute top-4 right-4 z-10 p-3 rounded-full bg-white/10 hover:bg-white/20 transition-all backdrop-blur-sm"
                                    >
                                        <X className="h-6 w-6 text-white" />
                                    </button>

                                    {mediaItems[activeMediaIndex] && (
                                        <div className="relative">
                                            {mediaItems[activeMediaIndex].type === 'video' ? (
                                                <video
                                                    src={mediaItems[activeMediaIndex].url}
                                                    controls
                                                    autoPlay
                                                    loop
                                                    className="w-full max-h-[90vh] object-contain rounded-2xl"
                                                />
                                            ) : (
                                                <img
                                                    src={mediaItems[activeMediaIndex].url}
                                                    alt={product.productName}
                                                    className="w-full max-h-[90vh] object-contain rounded-2xl"
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
