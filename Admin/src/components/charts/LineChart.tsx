import {
    LineChart as RechartsLineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    Area,
    AreaChart,
} from 'recharts';

interface LineChartProps {
    data: Array<{ name: string; value: number }>;
    title: string;
}

export function LineChart({ data, title }: LineChartProps) {
    return (
        <div className="glass-card p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-6">{title}</h3>
            <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={data}>
                    <defs>
                        <linearGradient id="lineGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stopColor="#FB9A40" stopOpacity={0.3} />
                            <stop offset="100%" stopColor="#FB9A40" stopOpacity={0} />
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
                    />
                    <Area
                        type="monotone"
                        dataKey="value"
                        stroke="#FB9A40"
                        strokeWidth={2.5}
                        fill="url(#lineGrad)"
                        dot={{ fill: '#FB9A40', r: 4, strokeWidth: 2, stroke: '#fff' }}
                        activeDot={{ r: 6, fill: '#FF6B35', stroke: '#fff', strokeWidth: 2 }}
                    />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
}
