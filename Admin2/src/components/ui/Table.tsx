import type { ReactNode } from 'react';
import { cn } from '../../lib/utils';

interface TableProps {
    children: ReactNode;
    className?: string;
}

export function Table({ children, className }: TableProps) {
    return (
        <div className="w-full overflow-x-auto rounded-card border border-gray-200/50">
            <table className={cn('w-full border-collapse', className)}>
                {children}
            </table>
        </div>
    );
}

interface TableHeaderProps {
    children: ReactNode;
}

export function TableHeader({ children }: TableHeaderProps) {
    return (
        <thead className="bg-gray-50/50 backdrop-blur-sm">
            {children}
        </thead>
    );
}

interface TableBodyProps {
    children: ReactNode;
}

export function TableBody({ children }: TableBodyProps) {
    return <tbody className="divide-y divide-gray-200/50">{children}</tbody>;
}

interface TableRowProps {
    children: ReactNode;
    className?: string;
}

export function TableRow({ children, className }: TableRowProps) {
    return (
        <tr className={cn('transition-colors hover:bg-gray-50/50', className)}>
            {children}
        </tr>
    );
}

interface TableHeadProps {
    children: ReactNode;
    className?: string;
}

export function TableHead({ children, className }: TableHeadProps) {
    return (
        <th
            className={cn(
                'px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider',
                className
            )}
        >
            {children}
        </th>
    );
}

interface TableCellProps {
    children: ReactNode;
    className?: string;
}

export function TableCell({ children, className }: TableCellProps) {
    return (
        <td className={cn('px-6 py-4 text-sm text-gray-900', className)}>
            {children}
        </td>
    );
}
