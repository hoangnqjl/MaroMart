import { NavLink, useNavigate } from 'react-router-dom';
import { Home, Package, Users, Grid3x3, LogOut } from 'lucide-react';
import { cn } from '../../lib/utils';
import { useAuthStore } from '../../stores/authStore';
import { useToast } from '../../hooks/useToast';

const navigation = [
    { name: 'Dashboard', href: '/', icon: Home },
    { name: 'Products', href: '/products', icon: Package },
    { name: 'Users', href: '/users', icon: Users },
    { name: 'Categories', href: '/categories', icon: Grid3x3 },
];

export function Sidebar() {
    const navigate = useNavigate();
    const logout = useAuthStore((state) => state.logout);
    const { toast } = useToast();

    const handleLogout = () => {
        logout();
        toast({
            type: 'success',
            title: 'Đã đăng xuất',
            description: 'Hẹn gặp lại bạn!',
        });
        navigate('/login');
    };

    return (
        <aside className="fixed left-0 top-0 h-screen w-64 glass border-r border-white/20 shadow-lg z-40">
            <div className="flex flex-col h-full">
                {/* Logo */}
                <div className="flex items-center gap-3 px-6 py-6 border-b border-gray-200/50">
                    <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-primary to-primary-hover flex items-center justify-center">
                        <Package className="h-6 w-6 text-white" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold text-gray-900">MaroMart</h1>
                        <p className="text-xs text-gray-500">Admin Dashboard</p>
                    </div>
                </div>

                {/* Navigation */}
                <nav className="flex-1 px-4 py-6 space-y-2">
                    {navigation.map((item) => (
                        <NavLink
                            key={item.name}
                            to={item.href}
                            className={({ isActive }) =>
                                cn(
                                    'flex items-center gap-3 px-4 py-3 rounded-button font-medium transition-all duration-200',
                                    'hover:bg-gray-50',
                                    isActive
                                        ? 'bg-indigo-50 text-primary border-l-4 border-primary'
                                        : 'text-gray-700'
                                )
                            }
                        >
                            {({ isActive }) => (
                                <>
                                    <item.icon
                                        className={cn(
                                            'h-5 w-5',
                                            isActive ? 'text-primary' : 'text-gray-500'
                                        )}
                                    />
                                    <span>{item.name}</span>
                                </>
                            )}
                        </NavLink>
                    ))}
                </nav>

                {/* Logout */}
                <div className="px-4 py-6 border-t border-gray-200/50">
                    <button
                        onClick={handleLogout}
                        className="flex items-center gap-3 px-4 py-3 w-full rounded-button font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                    >
                        <LogOut className="h-5 w-5 text-gray-500" />
                        <span>Logout</span>
                    </button>
                </div>
            </div>
        </aside>
    );
}
