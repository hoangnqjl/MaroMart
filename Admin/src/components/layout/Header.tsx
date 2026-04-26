import { Bell, Search } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { Menu } from 'lucide-react';

interface HeaderProps {
    onToggleSidebar: () => void;
}

export function Header({ onToggleSidebar }: HeaderProps) {
    const user = useAuthStore((state) => state.user);

    const getAvatarUrl = () => {
        if (user?.avatarUrl) return user.avatarUrl;
        return `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.fullName || 'Admin User')}&background=FB9A40&color=fff&bold=true&format=svg`;
    };

    return (
        <header className="sticky top-4 z-[60] flex items-center justify-center w-full pointer-events-none mb-6">
            <div className="flex items-center gap-2.5 w-full max-w-5xl justify-center pointer-events-none">
                {/* Mobile hamburger */}
                <button
                    onClick={onToggleSidebar}
                    className="md:hidden w-12 h-12 bg-white/90 backdrop-blur-2xl border border-gray-100 rounded-full shadow-lg flex items-center justify-center pointer-events-auto"
                >
                    <Menu className="h-5 w-5 text-gray-500" />
                </button>

                {/* Search Pill — LanguageCore style */}
                <div className="w-full max-w-xl flex items-center bg-white/90 backdrop-blur-2xl border border-gray-200/60 rounded-full shadow-lg h-12 pointer-events-auto px-5 relative group focus-within:ring-4 focus-within:ring-orange-500/10 focus-within:border-orange-300/60 transition-all">
                    <Search className="h-4 w-4 text-gray-400 shrink-0" />
                    <input
                        type="text"
                        placeholder="Tìm kiếm nhanh..."
                        className="w-full bg-transparent border-none outline-none text-sm px-3 text-gray-700 placeholder:text-gray-400 h-full font-medium"
                    />
                </div>

                {/* Notification Circle */}
                <div className="relative w-12 h-12 bg-white/90 backdrop-blur-2xl border border-gray-200/60 rounded-full shadow-lg flex items-center justify-center pointer-events-auto shrink-0">
                    <button className="p-2.5 text-gray-400 hover:text-gray-600 transition-colors relative">
                        <Bell className="h-5 w-5" />
                        <span className="absolute top-2 right-2 h-2 w-2 bg-[#FB9A40] rounded-full border-2 border-white animate-pulse"></span>
                    </button>
                </div>

                {/* Profile Circle */}
                <div className="relative w-12 h-12 bg-white/90 backdrop-blur-2xl border border-gray-200/60 rounded-full shadow-lg flex items-center justify-center pointer-events-auto shrink-0 group">
                    <img
                        src={getAvatarUrl()}
                        alt={user?.fullName || 'Admin'}
                        className="h-9 w-9 rounded-full object-cover cursor-pointer transition-transform hover:scale-110"
                        onError={(e) => {
                            e.currentTarget.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user?.fullName || 'Admin User')}&background=FB9A40&color=fff&bold=true&format=svg`;
                        }}
                    />
                    {/* Online dot */}
                    <div className="absolute bottom-0 right-0 h-3 w-3 bg-emerald-400 rounded-full ring-2 ring-white" />

                    {/* Tooltip */}
                    <div className="absolute bottom-full right-0 mb-3 px-3 py-2 bg-gray-900 text-white text-xs font-bold rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 whitespace-nowrap pointer-events-none z-50">
                        {user?.fullName || 'Admin User'}
                        <div className="absolute top-full right-4 w-2 h-2 bg-gray-900 transform rotate-45 -translate-y-1"></div>
                    </div>
                </div>
            </div>
        </header>
    );
}
