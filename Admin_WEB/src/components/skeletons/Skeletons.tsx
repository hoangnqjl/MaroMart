import { cn } from '../../lib/utils';

export function TableSkeleton({ rows = 5 }: { rows?: number }) {
    return (
        <div className="w-full overflow-hidden rounded-card border border-gray-200/50">
            <div className="bg-gray-50/50 px-6 py-3">
                <div className="flex gap-4">
                    {[1, 2, 3, 4, 5].map((i) => (
                        <div key={i} className="h-4 bg-gray-200 rounded animate-shimmer flex-1" />
                    ))}
                </div>
            </div>
            <div className="divide-y divide-gray-200/50">
                {Array.from({ length: rows }).map((_, i) => (
                    <div key={i} className="px-6 py-4">
                        <div className="flex gap-4 items-center">
                            <div className="h-12 w-12 bg-gray-200 rounded animate-shimmer" />
                            {[1, 2, 3, 4].map((j) => (
                                <div
                                    key={j}
                                    className="h-4 bg-gray-200 rounded animate-shimmer flex-1"
                                />
                            ))}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

export function CardSkeleton({ className }: { className?: string }) {
    return (
        <div className={cn('glass-card p-6 space-y-4', className)}>
            <div className="h-6 bg-gray-200 rounded animate-shimmer w-1/3" />
            <div className="h-10 bg-gray-200 rounded animate-shimmer w-1/2" />
            <div className="h-4 bg-gray-200 rounded animate-shimmer w-full" />
        </div>
    );
}

export function StatCardSkeleton() {
    return (
        <div className="glass-card p-6">
            <div className="flex items-center justify-between">
                <div className="space-y-2 flex-1">
                    <div className="h-4 bg-gray-200 rounded animate-shimmer w-24" />
                    <div className="h-8 bg-gray-200 rounded animate-shimmer w-32" />
                </div>
                <div className="h-12 w-12 bg-gray-200 rounded-xl animate-shimmer" />
            </div>
        </div>
    );
}
