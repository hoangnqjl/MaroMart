import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
    email: string;
    fullName: string;
    role: 'admin' | 'user';
}

interface AuthState {
    isAuthenticated: boolean;
    user: User | null;
    token: string | null;
    login: (token: string, user?: User) => void;
    logout: () => void;
    initAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
    persist(
        (set, get) => ({
            isAuthenticated: false,
            user: null,
            token: null,

            login: (token: string, user?: User) => {
                localStorage.setItem('token', token);
                set({
                    isAuthenticated: true,
                    token,
                    user: user || null
                });
            },

            logout: () => {
                localStorage.removeItem('token');
                set({ isAuthenticated: false, user: null, token: null });
            },

            initAuth: () => {
                const token = localStorage.getItem('token');
                if (token) {
                    set({ isAuthenticated: true, token });
                } else {
                    set({ isAuthenticated: false, user: null, token: null });
                }
            },
        }),
        {
            name: 'auth-storage',
        }
    )
);
