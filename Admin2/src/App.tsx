import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { Sidebar } from './components/layout/Sidebar';
import { Header } from './components/layout/Header';
import { ToastContainer } from './components/ui/Toast';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Products } from './pages/Products';
import { Users } from './pages/Users';
import { Categories } from './pages/Categories';
import { useAuthStore } from './stores/authStore';

function AdminLayout() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#F8FAFC] to-white">
      <Sidebar />
      <div className="ml-64">
        <div className="max-w-[1440px] mx-auto px-8 py-6">
          <Header />
          <main>
            <Outlet />
          </main>
        </div>
      </div>
    </div>
  );
}

function App() {
  const initAuth = useAuthStore((state) => state.initAuth);

  // Initialize auth on app load
  useEffect(() => {
    initAuth();
  }, [initAuth]);

  return (
    <BrowserRouter>
      <Routes>
        {/* Public Login Route */}
        <Route path="/login" element={<Login />} />

        {/* Protected Admin Routes */}
        <Route element={<ProtectedRoute />}>
          <Route element={<AdminLayout />}>
            <Route path="/" element={<Dashboard />} />
            <Route path="/products" element={<Products />} />
            <Route path="/users" element={<Users />} />
            <Route path="/categories" element={<Categories />} />
          </Route>
        </Route>

        {/* Catch all redirect */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>

      <ToastContainer />
    </BrowserRouter>
  );
}

export default App;
