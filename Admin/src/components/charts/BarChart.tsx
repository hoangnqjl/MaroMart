import {
    BarChart as RechartsBarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
} from 'recharts';

interface BarChartProps {
    data: Array<{ name: string; value: number }>;
    title: string;
}

export function BarChart({ data, title }: BarChartProps) {
    return (
        <div className="glass-card p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-6">{title}</h3>
            <ResponsiveContainer width="100%" height={300}>
                <RechartsBarChart data={data} barCategoryGap="20%">
                    <defs>
                        <linearGradient id="barGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stopColor="#FB9A40" stopOpacity={1} />
                            <stop offset="100%" stopColor="#FF6B35" stopOpacity={0.8} />
                        </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                    <XAxis
                        dataKey="name"
                        tick={{ fill: '#9ca3af', fontSize: 12, fontWeight: 500 }}
                        axisLine={false}
                        tickLine={false}
                    />
                    <YAxis
                        tick={{ fill: '#9ca3af', fontSize: 12 }}
                        axisLine={false}
                        tickLine={false}
                    />
                    <Tooltip
                        contentStyle={{
                            backgroundColor: 'rgba(255, 255, 255, 0.98)',
                            border: 'none',
                            borderRadius: '16px',
                            boxShadow: '0 8px 30px rgba(0, 0, 0, 0.08)',
                            padding: '12px 16px',
                        }}
                        cursor={{ fill: 'rgba(251, 154, 64, 0.06)' }}
                    />
                    <Bar dataKey="value" fill="url(#barGrad)" radius={[10, 10, 0, 0]} />
                </RechartsBarChart>
            </ResponsiveContainer>
        </div>
    );
}
