import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Loader2, Eye, EyeOff } from 'lucide-react';
import axiosInstance from '../lib/axios';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { useAuthStore } from '../stores/authStore';
import { useToast } from '../hooks/useToast';

export function Login() {
    const navigate = useNavigate();
    const { toast } = useToast();
    const login = useAuthStore((state) => state.login);

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [rememberMe, setRememberMe] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        try {
            const response = await axiosInstance.post('/auth/v1/login', {
                email,
                password,
            });

            const { token, message } = response.data;
            login(token);

            toast({
                type: 'success',
                title: 'Đăng nhập thành công',
                description: message || 'Chào mừng bạn trở lại!',
            });

            navigate('/');
        } catch (error: any) {
            toast({
                type: 'error',
                title: 'Đăng nhập thất bại',
                description: error.response?.data?.message || 'Email hoặc mật khẩu không đúng.',
            });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-orange-50 via-amber-50/30 to-white flex items-center justify-center p-4 relative overflow-hidden">
            {/* Decorative background elements */}
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-gradient-to-bl from-primary-200/30 to-transparent rounded-full blur-3xl -translate-y-1/3 translate-x-1/4" />
            <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-gradient-to-tr from-accent/10 to-transparent rounded-full blur-3xl translate-y-1/4 -translate-x-1/4" />
            
            <div className="w-full max-w-md relative z-10 animate-fade-in">
                {/* Logo & Title */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center h-16 w-16 rounded-3xl bg-gradient-to-br from-primary to-accent shadow-glow mb-5 animate-float">
                        <Sparkles className="h-8 w-8 text-white" />
                    </div>
                    <h1 className="text-3xl font-extrabold text-gray-900 mb-2">Chào mừng trở lại</h1>
                    <p className="text-gray-500">Đăng nhập vào bảng điều khiển MaroMart</p>
                </div>

                {/* Login Card */}
                <div className="bg-white/90 backdrop-blur-2xl border border-white/50 rounded-3xl shadow-2xl shadow-orange-900/5 p-8">
                    <form onSubmit={handleSubmit} className="space-y-5">
                        <Input
                            label="Email"
                            type="email"
                            required
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="admin@maromart.com"
                            className="rounded-2xl"
                        />

                        <div className="relative">
                            <Input
                                label="Mật khẩu"
                                type={showPassword ? 'text' : 'password'}
                                required
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="Nhập mật khẩu"
                                className="rounded-2xl pr-12"
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-4 top-[38px] text-gray-400 hover:text-gray-600 transition-colors"
                            >
                                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>

                        {/* Remember me & Forgot password */}
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    id="remember"
                                    checked={rememberMe}
                                    onChange={(e) => setRememberMe(e.target.checked)}
                                    className="rounded-md border-gray-300 text-primary focus:ring-primary/50 transition-colors"
                                />
                                <label htmlFor="remember" className="text-sm text-gray-600">
                                    Ghi nhớ đăng nhập
                                </label>
                            </div>
                            <a
                                href="#"
                                className="text-sm text-primary font-medium hover:text-primary-hover transition-colors"
                            >
                                Quên mật khẩu?
                            </a>
                        </div>

                        {/* Submit Button */}
                        <Button
                            type="submit"
                            className="w-full h-12 text-base rounded-2xl shadow-glow"
                            disabled={isLoading}
                        >
                            {isLoading ? (
                                <>
                                    <Loader2 className="h-5 w-5 animate-spin mr-2" />
                                    Đang đăng nhập...
                                </>
                            ) : (
                                'Đăng nhập'
                            )}
                        </Button>
                    </form>
                </div>

                {/* Footer */}
                <p className="text-center text-xs text-gray-400 mt-8">
                    © 2025 MaroMart. All rights reserved.
                </p>
            </div>
        </div>
    );
}
