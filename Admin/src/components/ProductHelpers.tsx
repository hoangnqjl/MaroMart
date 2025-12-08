import { Play } from 'lucide-react';


interface ProductImageProps {
    productMedia: string[];
    productName: string;
    className?: string;
}

/**
 * Helper to parse and display the first image/video from productMedia
 * Handles "image:URL" and "video:URL" prefixes
 */
export function ProductImage({ productMedia, productName, className = 'h-14 w-14' }: ProductImageProps) {
    if (!productMedia || productMedia.length === 0) {
        return (
            <div className={`${className} rounded-lg bg-gray-200 flex items-center justify-center`}>
                <span className="text-gray-400 text-xs">No image</span>
            </div>
        );
    }

    const firstMedia = productMedia[0];
    const isVideo = firstMedia.startsWith('video:');
    const url = firstMedia.startsWith('image:') || firstMedia.startsWith('video:')
        ? firstMedia.substring(6)
        : firstMedia;

    return (
        <div className={`${className} rounded-lg overflow-hidden relative group`}>
            <img
                src={url}
                alt={productName}
                className="w-full h-full object-cover"
            />
            {isVideo && (
                <div className="absolute inset-0 bg-black/30 flex items-center justify-center">
                    <Play className="h-6 w-6 text-white" fill="white" />
                </div>
            )}
        </div>
    );
}

/**
 * Parse stringified productAttribute JSON and return preview string
 * e.g. "Asus K34E • Intel i3 • 8GB RAM"
 */
export function getAttributePreview(productAttribute: any, maxItems: number = 3): string {
    let attributes: Record<string, any> = {};

    try {
        if (typeof productAttribute === 'string') {
            attributes = JSON.parse(productAttribute);
        } else if (typeof productAttribute === 'object') {
            attributes = productAttribute;
        }
    } catch {
        return '';
    }

    const priority = ['brand', 'model', 'cpu', 'ram', 'storage', 'color', 'size'];
    const preview: string[] = [];

    priority.forEach((key) => {
        if (preview.length < maxItems && attributes[key]) {
            preview.push(attributes[key].toString());
        }
    });

    // Fill remaining with other attributes
    if (preview.length < maxItems) {
        Object.entries(attributes).forEach(([key, value]) => {
            if (preview.length < maxItems && !priority.includes(key) && value) {
                preview.push(value.toString());
            }
        });
    }

    return preview.join(' • ');
}

/**
 * Parse and format location from stringified JSON
 * Returns short format: "Phường An Khê, Đà Nẵng"
 */
export function getLocationPreview(productAddress: any): string {
    let location: any = {};

    try {
        if (typeof productAddress === 'string') {
            location = JSON.parse(productAddress);
        } else if (typeof productAddress === 'object') {
            location = productAddress;
        }
    } catch {
        return '';
    }

    const parts: string[] = [];
    if (location.commune) parts.push(location.commune);
    if (location.province) {
        // Shorten province name
        const province = location.province.replace('Thành phố ', '').replace('Tỉnh ', '');
        parts.push(province);
    }

    return parts.filter(Boolean).join(', ');
}

/**
 * Example usage in table:
 * 
 * <TableCell>
 *   <div className="flex items-center gap-3">
 *     <ProductImage productMedia={product.productMedia} productName={product.productName} />
 *     <div>
 *       <p className="font-medium">{product.productName}</p>
 *       <p className="text-sm text-gray-500">{getAttributePreview(product.productAttribute)}</p>
 *     </div>
 *   </div>
 * </TableCell>
 * 
 * <TableCell className="text-gray-600">
 *   {getLocationPreview(product.productAddress) || 'N/A'}
 * </TableCell>
 */
