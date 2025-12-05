import { forwardRef } from 'react';
import type { SelectHTMLAttributes } from 'react';
import { cn } from '../../lib/utils';
import type { Category } from '../../services/api';

interface CategoryFilterProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, 'onChange'> {
    categories: Category[];
    selectedCategory: string;
    onCategoryChange: (categoryId: string) => void;
    className?: string;
}

/**
 * Category Filter Component
 * Renders a styled select dropdown for filtering by category
 */
export const CategoryFilter = forwardRef<HTMLSelectElement, CategoryFilterProps>(
    ({ categories, selectedCategory, onCategoryChange, className, ...props }, ref) => {

        const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
            const value = e.target.value;
            console.log('📂 [CategoryFilter] Category changed:', value);
            onCategoryChange(value);
        };

        return (
            <div className="relative">
                <select
                    ref={ref}
                    value={selectedCategory}
                    onChange={handleChange}
                    className={cn(
                        'appearance-none',
                        'w-full md:w-48 px-4 py-3 pr-8',
                        'rounded-xl border border-gray-200',
                        'bg-white/70 backdrop-blur-sm',
                        'text-sm font-medium text-gray-700',
                        'focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary',
                        'transition-all duration-200',
                        'cursor-pointer',
                        'bg-[url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'12\' height=\'12\' viewBox=\'0 0 12 12\'%3E%3Cpath fill=\'%236B7280\' d=\'M6 8L1 3h10z\'/%3E%3C/svg%3E")] bg-no-repeat bg-[right_1rem_center]',
                        className
                    )}
                    {...props}
                >
                    <option value="">All Categories</option>
                    {categories.map((category) => (
                        <option key={category.categoryId} value={category.categoryId}>
                            {category.categoryName}
                        </option>
                    ))}
                </select>
            </div>
        );
    }
);

CategoryFilter.displayName = 'CategoryFilter';

export default CategoryFilter;
