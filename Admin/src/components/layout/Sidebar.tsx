import { NavLink, useNavigate } from 'react-router-dom';
import { Home, Package, Users, Grid3x3, LogOut, Sparkles } from 'lucide-react';
import { cn } from '../../lib/utils';
import { useAuthStore } from '../../stores/authStore';
import { useToast } from '../../hooks/useToast';

const navigation = [
    { name: 'Dashboard', href: '/', icon: Home },
    { name: 'Products', href: '/products', icon: Package },
    { name: 'Users', href: '/users', icon: Users },
    { name: 'Categories', href: '/categories', icon: Grid3x3 },
];

interface SidebarProps {
    isOpen: boolean;
    onClose: () => void;
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
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
        <>
            {/* Mobile Backdrop */}
            {isOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/20 backdrop-blur-sm md:hidden transition-opacity duration-300"
                    onClick={onClose}
                />
            )}

            {/* Desktop: Floating capsule sidebar — LanguageCore style */}
            <aside
                className={cn(
                    'fixed z-50 transition-all duration-500',
                    // Desktop: centered vertical floating pill
                    'hidden md:flex flex-col w-[78px] bg-white/90 backdrop-blur-2xl',
                    'border border-gray-200/50 left-5 top-1/2 -translate-y-1/2',
                    'rounded-[2.5rem] shadow-[0_8px_32px_rgba(0,0,0,0.12)] h-fit py-3'
                )}
            >
                {/* Logo */}
                <div className="flex items-center justify-center px-3 pb-3 mb-1">
                    <div className="h-11 w-11 rounded-2xl bg-gradient-to-br from-[#FB9A40] to-[#FF6B35] flex items-center justify-center shadow-[0_4px_16px_rgba(251,154,64,0.35)]">
                        <Sparkles className="h-5 w-5 text-white" />
                    </div>
                </div>

                {/* Divider */}
                <div className="mx-5 h-px bg-gray-200/60" />

                {/* Nav Items */}
                <nav className="flex flex-col items-center gap-2 px-3 py-3">
                    {navigation.map((item) => (
                        <NavLink
                            key={item.name}
                            to={item.href}
                            className={({ isActive }) =>
                                cn(
                                    'relative group/nav-item flex items-center justify-center',
                                    'w-[48px] h-[48px] rounded-full transition-all duration-300',
                                    isActive
                                        ? 'bg-[#FB9A40] text-white shadow-lg shadow-[#FB9A40]/40 scale-110'
                                        : 'text-gray-400 hover:bg-gray-100 hover:text-gray-600'
                                )
                            }
                        >
                            {({ isActive }) => (
                                <>
                                    <item.icon className={cn('w-[22px] h-[22px]', isActive ? 'stroke-[2.5px]' : 'stroke-[1.8px]')} />
                                    {/* Active indicator dot */}
                                    {isActive && (
                                        <div className="absolute top-0.5 right-0.5 w-2 h-2 bg-orange-200 rounded-full border-2 border-[#FB9A40] ring-2 ring-[#FB9A40]/10" />
                                    )}
                                    {/* Floating Tooltip */}
                                    <div className="absolute left-[calc(100%+12px)] top-1/2 -translate-y-1/2 px-3 py-1.5 bg-gray-900 text-white text-xs font-bold rounded-xl opacity-0 pointer-events-none group-hover/nav-item:opacity-100 scale-90 group-hover/nav-item:scale-100 transition-all duration-200 z-50 whitespace-nowrap">
                                        {item.name}
                                        <div className="absolute right-full top-1/2 -translate-y-1/2 border-[5px] border-transparent border-r-gray-900" />
                                    </div>
                                </>
                            )}
                        </NavLink>
                    ))}
                </nav>

                {/* Divider */}
                <div className="mx-5 h-px bg-gray-200/60" />

                {/* Logout */}
                <div className="flex items-center justify-center px-3 pt-3">
                    <button
                        onClick={handleLogout}
                        className="relative group/nav-item w-[48px] h-[48px] rounded-full flex items-center justify-center text-gray-400 hover:bg-red-50 hover:text-red-500 transition-all duration-300"
                    >
                        <LogOut className="w-[22px] h-[22px] stroke-[1.8px]" />
                        {/* Floating Tooltip */}
                        <div className="absolute left-[calc(100%+12px)] top-1/2 -translate-y-1/2 px-3 py-1.5 bg-gray-900 text-white text-xs font-bold rounded-xl opacity-0 pointer-events-none group-hover/nav-item:opacity-100 scale-90 group-hover/nav-item:scale-100 transition-all duration-200 z-50 whitespace-nowrap">
                            Đăng xuất
                            <div className="absolute right-full top-1/2 -translate-y-1/2 border-[5px] border-transparent border-r-gray-900" />
                        </div>
                    </button>
                </div>
            </aside>

            {/* Mobile: Full sidebar panel */}
            <aside
                className={cn(
                    'fixed top-0 left-0 z-50 h-screen w-72 bg-white/95 backdrop-blur-2xl border-r border-gray-100 shadow-2xl transition-transform duration-300 ease-in-out md:hidden',
                    isOpen ? 'translate-x-0' : '-translate-x-full'
                )}
            >
                <div className="flex flex-col h-full">
                    {/* Mobile Logo */}
                    <div className="flex items-center gap-3 px-6 py-6">
                        <div className="h-11 w-11 rounded-2xl bg-gradient-to-br from-[#FB9A40] to-[#FF6B35] flex items-center justify-center shadow-[0_4px_16px_rgba(251,154,64,0.35)]">
                            <Sparkles className="h-5 w-5 text-white" />
                        </div>
                        <div>
                            <h1 className="text-xl brand-bold text-gradient">MaroMart</h1>
                            <p className="text-[11px] text-gray-400 font-medium tracking-wider uppercase">Admin Panel</p>
                        </div>
                    </div>

                    <div className="mx-5 h-px bg-gray-200/60" />

                    {/* Mobile Nav */}
                    <nav className="flex-1 px-4 py-5 space-y-1.5 overflow-y-auto">
                        {navigation.map((item) => (
                            <NavLink
                                key={item.name}
                                to={item.href}
                                onClick={() => onClose()}
                                className={({ isActive }) =>
                                    cn(
                                        'flex items-center gap-3 px-4 py-3 rounded-2xl font-medium transition-all duration-200',
                                        isActive
                                            ? 'bg-orange-50 text-[#E8861F]'
                                            : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                                    )
                                }
                            >
                                {({ isActive }) => (
                                    <>
                                        <item.icon className={cn('h-5 w-5', isActive ? 'text-[#FB9A40]' : 'text-gray-400')} />
                                        <span className="text-sm">{item.name}</span>
                                    </>
                                )}
                            </NavLink>
                        ))}
                    </nav>

                    {/* Mobile Logout */}
                    <div className="px-4 py-5">
                        <div className="mx-1 mb-4 h-px bg-gray-200/60" />
                        <button
                            onClick={handleLogout}
                            className="flex items-center gap-3 px-4 py-3 w-full rounded-2xl font-medium text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all duration-200"
                        >
                            <LogOut className="h-5 w-5" />
                            <span className="text-sm">Đăng xuất</span>
                        </button>
                    </div>
                </div>
            </aside>
        </>
    );
}
