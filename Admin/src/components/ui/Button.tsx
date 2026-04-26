import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { cn } from '../../lib/utils';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
    size?: 'sm' | 'md' | 'lg';
    children: ReactNode;
}

export function Button({
    variant = 'primary',
    size = 'md',
    className,
    children,
    ...props
}: ButtonProps) {
    return (
        <button
            className={cn(
                'inline-flex items-center justify-center rounded-button font-semibold transition-all duration-200',
                'active:scale-[0.97]',
                'disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 disabled:hover:shadow-none',
                {
                    'bg-gradient-to-r from-primary to-primary-hover text-white hover:shadow-glow hover:brightness-105': variant === 'primary',
                    'bg-gray-100 text-gray-700 hover:bg-gray-200': variant === 'secondary',
                    'bg-red-500 text-white hover:bg-red-600 hover:shadow-lg hover:shadow-red-500/20': variant === 'danger',
                    'bg-transparent text-gray-600 hover:bg-gray-100': variant === 'ghost',
                },
                {
                    'px-3 py-1.5 text-sm': size === 'sm',
                    'px-4 py-2.5 text-sm': size === 'md',
                    'px-6 py-3 text-base': size === 'lg',
                },
                className
            )}
            {...props}
        >
            {children}
        </button>
    );
}
