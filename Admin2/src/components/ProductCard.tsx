import { Play } from 'lucide-react';
import type { Product } from '../services/api';
import { formatPrice } from '../lib/utils';

interface ProductCardProps {
    product: Product;
    onClick?: () => void;
}

export function ProductCard({ product, onClick }: ProductCardProps) {
    // Parse media - split "image:" or "video:" prefix
    const getFirstImage = (): string | null => {
        if (!product.productMedia || product.productMedia.length === 0) {
            return null;
        }

        const firstMedia = product.productMedia[0];

        // Check if it has "image:" prefix
        if (firstMedia.startsWith('image:')) {
            return firstMedia.substring(6); // Remove "image:" prefix
        }

        // Check if it has "video:" prefix (not an image)
        if (firstMedia.startsWith('video:')) {
            return null;
        }

        // Check if it's a video file by extension
        const isVideo = /\.(mp4|mov|webm)$/i.test(firstMedia);
        if (isVideo) {
            return null;
        }

        return firstMedia;
    };

    const hasVideo = (): boolean => {
        if (!product.productMedia || product.productMedia.length === 0) {
            return false;
        }

        return product.productMedia.some((media) => {
            if (media.startsWith('video:')) return true;
            return /\.(mp4|mov|webm)$/i.test(media);
        });
    };

    const firstImage = getFirstImage();
    const showVideoIcon = hasVideo();

    // Parse location for short display
    const getShortLocation = (): string => {
        if (!product.productAddress) return '';

        try {
            let location: any;
            if (typeof product.productAddress === 'string') {
                location = JSON.parse(product.productAddress);
            } else {
                location = product.productAddress;
            }

            // Show city/province only
            return location.province || location.district || '';
        } catch (err) {
            return '';
        }
    };

    const shortLocation = getShortLocation();

    return (
        <div
            onClick={onClick}
            className="group relative bg-white/80 backdrop-blur-md rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 overflow-hidden cursor-pointer hover:-translate-y-2 border border-white/50"
        >
            {/* Image Container */}
            <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-gray-100 to-gray-200">
                {firstImage ? (
                    <img
                        src={firstImage}
                        alt={product.productName}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                    />
                ) : (
                    <div className="w-full h-full flex items-center justify-center">
                        <div className="text-center text-gray-400">
                            <svg
                                className="mx-auto h-16 w-16 mb-2"
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
                            <p className="text-sm font-medium">No Image</p>
                        </div>
                    </div>
                )}

                {/* Video Icon Overlay */}
                {showVideoIcon && (
                    <div className="absolute top-3 right-3 p-2 bg-black/60 backdrop-blur-sm rounded-lg">
                        <Play className="h-4 w-4 text-white fill-white" />
                    </div>
                )}

                {/* Gradient Overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            </div>

            {/* Content */}
            <div className="p-4 space-y-3">
                {/* Product Name */}
                <h3 className="font-semibold text-gray-900 text-lg line-clamp-2 group-hover:text-primary transition-colors">
                    {product.productName}
                </h3>

                {/* Price */}
                <p className="text-2xl font-bold text-primary">
                    {formatPrice(product.productPrice)}
                </p>

                {/* Location & Owner */}
                <div className="flex items-center justify-between pt-3 border-t border-gray-200">
                    {shortLocation && (
                        <div className="flex items-center gap-1.5 text-sm text-gray-600">
                            <svg
                                className="h-4 w-4 flex-shrink-0"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                                />
                                <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                                />
                            </svg>
                            <span className="truncate">{shortLocation}</span>
                        </div>
                    )}

                    {product.userInfo && (
                        <div className="flex items-center gap-2">
                            <img
                                src={product.userInfo.avatarUrl}
                                alt={product.userInfo.fullName}
                                className="h-6 w-6 rounded-full ring-2 ring-white shadow-sm"
                            />
                            <span className="text-sm font-medium text-gray-700 truncate max-w-[100px]">
                                {product.userInfo.fullName}
                            </span>
                        </div>
                    )}
                </div>
            </div>

            {/* Glassmorphism shine effect */}
            <div className="absolute inset-0 bg-gradient-to-br from-white/20 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none" />
        </div>
    );
}
