import { Bell } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';

import { Menu } from 'lucide-react';

interface HeaderProps {
    onToggleSidebar: () => void;
}

export function Header({ onToggleSidebar }: HeaderProps) {
    const user = useAuthStore((state) => state.user);

    const getAvatarUrl = () => {
        if (user?.avatarUrl) return user.avatarUrl;
        return `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.fullName || 'Admin User')}&background=6366F1&color=fff`;
    };

    return (
        <header className="glass-card sticky top-0 z-30 px-8 py-4 mb-8">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <button
                        onClick={onToggleSidebar}
                        className="p-2 -ml-2 rounded-lg hover:bg-gray-100 md:hidden"
                    >
                        <Menu className="h-6 w-6 text-gray-600" />
                    </button>

                    <div className="flex-1 max-w-xl">
                        {/* Placeholder for global search if needed in future */}
                    </div>
                </div>{/* Close wrapper for Hamburger + Search */}

                <div className="flex items-center gap-4">
                    <button className="relative p-2 rounded-button hover:bg-gray-100 transition-colors">
                        <Bell className="h-6 w-6 text-gray-600" />
                        <span className="absolute top-1 right-1 h-2 w-2 bg-red-500 rounded-full"></span>
                    </button>

                    <div className="flex items-center gap-3 pl-4 border-l border-gray-200 group relative">
                        <div className="text-right hidden sm:block">
                            <p className="text-sm font-medium text-gray-900">{user?.fullName || 'Admin User'}</p>
                            <p className="text-xs text-gray-500">{user?.email || 'admin@maromart.com'}</p>
                        </div>

                        <div className="relative">
                            <img
                                src={getAvatarUrl()}
                                alt={user?.fullName || 'Admin'}
                                className="h-10 w-10 rounded-full ring-2 ring-white shadow-sm object-cover cursor-pointer transition-transform hover:scale-105"
                                onError={(e) => {
                                    e.currentTarget.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.fullName || 'Admin User')}&background=6366F1&color=fff`;
                                }}
                            />
                            {/* Tooltip */}
                            <div className="absolute bottom-full right-0 mb-2 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 whitespace-nowrap pointer-events-none z-50">
                                {user?.fullName || 'Admin User'}
                                <div className="absolute top-full right-4 w-2 h-2 bg-gray-900 transform rotate-45 -translate-y-1"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </header>
    );
}
