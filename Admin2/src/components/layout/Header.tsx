import { Bell, Search } from 'lucide-react';

export function Header() {
    return (
        <header className="glass-card sticky top-0 z-30 px-8 py-4 mb-8">
            <div className="flex items-center justify-between">
                <div className="flex-1 max-w-xl">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search..."
                            className="w-full pl-10 pr-4 py-2 rounded-button border border-gray-200 bg-white/70 backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
                        />
                    </div>
                </div>

                <div className="flex items-center gap-4">
                    <button className="relative p-2 rounded-button hover:bg-gray-100 transition-colors">
                        <Bell className="h-6 w-6 text-gray-600" />
                        <span className="absolute top-1 right-1 h-2 w-2 bg-red-500 rounded-full"></span>
                    </button>

                    <div className="flex items-center gap-3 pl-4 border-l border-gray-200">
                        <div className="text-right">
                            <p className="text-sm font-medium text-gray-900">Admin User</p>
                            <p className="text-xs text-gray-500">admin@maromart.com</p>
                        </div>
                        <img
                            src="https://ui-avatars.com/api/?name=Admin+User&background=6366F1&color=fff"
                            alt="Admin"
                            className="h-10 w-10 rounded-full"
                        />
                    </div>
                </div>
            </div>
        </header>
    );
}
