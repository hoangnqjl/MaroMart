import type { ReactNode } from 'react';
import { cn } from '../../lib/utils';

interface BadgeProps {
    children: ReactNode;
    variant?: 'default' | 'success' | 'danger' | 'warning' | 'info' | 'primary';
    className?: string;
}

export function Badge({ children, variant = 'default', className }: BadgeProps) {
    return (
        <span
            className={cn(
                'inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold tracking-wide',
                {
                    'bg-gray-100 text-gray-600': variant === 'default',
                    'bg-emerald-50 text-emerald-600': variant === 'success',
                    'bg-red-50 text-red-600': variant === 'danger',
                    'bg-orange-50 text-orange-600': variant === 'warning',
                    'bg-blue-50 text-blue-600': variant === 'info',
                    'bg-primary-100 text-primary-700': variant === 'primary',
                },
                className
            )}
        >
            {children}
        </span>
    );
}
