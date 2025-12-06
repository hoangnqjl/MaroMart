import type { ReactNode } from 'react';
import { cn } from '../../lib/utils';

interface CardProps {
    children: ReactNode;
    className?: string;
    hover?: boolean;
}

export function Card({ children, className, hover = false }: CardProps) {
    return (
        <div
            className={cn(
                'glass-card p-6 transition-all duration-300',
                hover && 'hover:shadow-xl hover:shadow-black/10 hover:-translate-y-1',
                className
            )}
        >
            {children}
        </div>
    );
}
