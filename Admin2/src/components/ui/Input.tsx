import { InputHTMLAttributes, forwardRef } from 'react';
import { cn } from '../../lib/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
    label?: string;
    error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
    ({ label, error, className, ...props }, ref) => {
        return (
            <div className="flex flex-col gap-1.5">
                {label && (
                    <label className="text-sm font-medium text-gray-700">
                        {label}
                    </label>
                )}
                <input
                    ref={ref}
                    className={cn(
                        'rounded-button px-4 py-2 border border-gray-200',
                        'bg-white/70 backdrop-blur-sm',
                        'focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary',
                        'transition-all duration-200',
                        'placeholder:text-gray-400',
                        error && 'border-red-500 focus:ring-red-500/50',
                        className
                    )}
                    {...props}
                />
                {error && (
                    <span className="text-sm text-red-500">{error}</span>
                )}
            </div>
        );
    }
);

Input.displayName = 'Input';
