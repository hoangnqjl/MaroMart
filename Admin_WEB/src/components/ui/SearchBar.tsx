import { forwardRef, useRef } from 'react';
import type { InputHTMLAttributes } from 'react';
import { Search, X, Loader2 } from 'lucide-react';
import { cn } from '../../lib/utils';

interface SearchBarProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
    /** Current search value */
    value: string;
    /** Called when search value changes */
    onChange: (value: string) => void;
    /** Called when clear button is clicked */
    onClear?: () => void;
    /** Show loading spinner */
    isLoading?: boolean;
    /** Placeholder text */
    placeholder?: string;
    /** Additional container class */
    containerClassName?: string;
}

/**
 * SearchBar component with icon, clear button, and loading state
 * 
 * @example
 * <SearchBar
 *   value={query}
 *   onChange={setQuery}
 *   onClear={clearSearch}
 *   isLoading={isSearching}
 *   placeholder="Search products..."
 * />
 */
export const SearchBar = forwardRef<HTMLInputElement, SearchBarProps>(
    (
        {
            value,
            onChange,
            onClear,
            isLoading = false,
            placeholder = 'Search...',
            containerClassName,
            className,
            ...props
        },
        ref
    ) => {
        const localRef = useRef<HTMLInputElement>(null);
        const inputRef = (ref as React.RefObject<HTMLInputElement>) || localRef;

        const handleClear = () => {
            onClear?.();
            onChange('');
            inputRef.current?.focus();
        };

        return (
            <div className={cn('relative', containerClassName)}>
                {/* Search Icon */}
                <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none">
                    {isLoading ? (
                        <Loader2 className="h-5 w-5 text-gray-400 animate-spin" />
                    ) : (
                        <Search className="h-5 w-5 text-gray-400" />
                    )}
                </div>

                {/* Input */}
                <input
                    ref={inputRef}
                    type="text"
                    value={value}
                    onChange={(e) => onChange(e.target.value)}
                    placeholder={placeholder}
                    className={cn(
                        'w-full pl-10 pr-10 py-3',
                        'rounded-xl border border-gray-200',
                        'bg-white/70 backdrop-blur-sm',
                        'focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary',
                        'transition-all duration-200',
                        'placeholder:text-gray-400',
                        'text-gray-900',
                        className
                    )}
                    {...props}
                />

                {/* Clear Button */}
                {value && (
                    <button
                        type="button"
                        onClick={handleClear}
                        className={cn(
                            'absolute right-3 top-1/2 -translate-y-1/2',
                            'p-1 rounded-full',
                            'hover:bg-gray-100 active:bg-gray-200',
                            'transition-colors duration-150',
                            'focus:outline-none focus:ring-2 focus:ring-primary/50'
                        )}
                        aria-label="Clear search"
                    >
                        <X className="h-4 w-4 text-gray-500" />
                    </button>
                )}
            </div>
        );
    }
);

SearchBar.displayName = 'SearchBar';

export default SearchBar;
