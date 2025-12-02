import { useState, useEffect } from 'react';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Badge } from '../components/ui/Badge';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '../components/ui/Table';
import { Modal, ConfirmModal } from '../components/ui/Modal';
import { TableSkeleton } from '../components/skeletons/Skeletons';
import type { User } from '../services/api';
import { usersAPI } from '../services/api';
import { useToast } from '../hooks/useToast';
import { useDebounce } from '../hooks/useDebounce';

export function Users() {
    const [users, setUsers] = useState<User[]>([]);
    const [searchQuery, setSearchQuery] = useState('');
    const debouncedSearch = useDebounce(searchQuery, 500);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [deleteModal, setDeleteModal] = useState<{
        isOpen: boolean;
        userId: string | null;
    }>({ isOpen: false, userId: null });
    const { toast } = useToast();

    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        phoneNumber: '',
        role: 'user' as 'admin' | 'user',
        isActive: true,
    });

    // Fetch users
    const fetchUsers = async () => {
        try {
            setIsLoading(true);
            setError(null);
            // Backend returns plain array
            const data = await usersAPI.getUsers(1, 100, debouncedSearch);
            setUsers(Array.isArray(data) ? data : []);
        } catch (err: any) {
            setError(err.response?.data?.message || 'Failed to fetch users');
            toast({
                type: 'error',
                title: 'Error',
                description: 'Failed to load users. Please try again.',
            });
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, [debouncedSearch]);

    const handleOpenAddModal = () => {
        setEditingUser(null);
        setFormData({
            fullName: '',
            email: '',
            phoneNumber: '',
            role: 'user',
            isActive: true,
        });
        setIsModalOpen(true);
    };

    const handleOpenEditModal = (user: User) => {
        setEditingUser(user);
        setFormData({
            fullName: user.fullName,
            email: user.email,
            phoneNumber: user.phoneNumber,
            role: user.role,
            isActive: user.isActive,
        });
        setIsModalOpen(true);
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // For demo - just close modal and show toast
        toast({
            type: 'success',
            title: editingUser ? 'User updated' : 'User created',
            description: editingUser
                ? 'The user has been successfully updated.'
                : 'The new user has been successfully created.',
        });
        setIsModalOpen(false);
        fetchUsers(); // Refresh list
    };

    const handleDelete = async (userId: string) => {
        try {
            await usersAPI.deleteUser(userId);
            toast({
                type: 'success',
                title: 'User deleted',
                description: 'The user has been successfully deleted.',
            });
            fetchUsers(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to delete user.',
            });
        }
    };

    const toggleRole = async (userId: string, currentRole: 'admin' | 'user') => {
        const newRole = currentRole === 'admin' ? 'user' : 'admin';
        try {
            await usersAPI.updateUserRole(userId, newRole);
            toast({
                type: 'success',
                title: 'Role updated',
                description: `User role changed to ${newRole}.`,
            });
            fetchUsers(); // Refresh list
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to update role.',
            });
        }
    };

    // Loading state
    if (isLoading && users.length === 0) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Users</h1>
                        <p className="text-gray-500 mt-1">Manage user accounts and permissions</p>
                    </div>
                </div>
                <TableSkeleton rows={8} />
            </div>
        );
    }

    // Error state
    if (error && users.length === 0) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">Users</h1>
                        <p className="text-gray-500 mt-1">Manage user accounts and permissions</p>
                    </div>
                </div>
                <div className="glass-card p-12 text-center">
                    <p className="text-red-600 text-lg font-medium">{error}</p>
                    <Button onClick={fetchUsers} className="mt-4">Retry</Button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900">Users</h1>
                    <p className="text-gray-500 mt-1">Manage user accounts and permissions</p>
                </div>
                <Button onClick={handleOpenAddModal} className="gap-2">
                    <Plus className="h-5 w-5" />
                    Add New User
                </Button>
            </div>

            {/* Search */}
            <div className="glass-card p-6">
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                    <Input
                        type="text"
                        placeholder="Search users by name or email..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="pl-10"
                    />
                </div>
            </div>

            {/* Table */}
            <div className="glass-card p-6">
                {users.length === 0 ? (
                    <div className="text-center py-12">
                        <p className="text-gray-500 text-lg">No users found</p>
                        <p className="text-gray-400 text-sm mt-2">Try adjusting your search</p>
                    </div>
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>User</TableHead>
                                <TableHead>Email</TableHead>
                                <TableHead>Phone</TableHead>
                                <TableHead>Role</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {users.map((user) => (
                                <TableRow key={user.userId}>
                                    <TableCell>
                                        <div className="flex items-center gap-3">
                                            <img
                                                src={user.avatarUrl}
                                                alt={user.fullName}
                                                className="h-10 w-10 rounded-full"
                                            />
                                            <span className="font-medium">{user.fullName}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell className="text-gray-600">{user.email}</TableCell>
                                    <TableCell className="text-gray-600">{user.phoneNumber}</TableCell>
                                    <TableCell>
                                        <Badge
                                            variant={user.role === 'admin' ? 'danger' : 'default'}
                                            className="cursor-pointer hover:opacity-80 transition-opacity"
                                            onClick={() => toggleRole(user.userId, user.role)}
                                        >
                                            {user.role.toUpperCase()}
                                        </Badge>
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant={user.isActive ? 'success' : 'default'}>
                                            {user.isActive ? 'Active' : 'Inactive'}
                                        </Badge>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex items-center justify-end gap-2">
                                            <button
                                                onClick={() => handleOpenEditModal(user)}
                                                className="p-2 rounded-lg hover:bg-gray-100 transition-colors group"
                                            >
                                                <Edit className="h-4 w-4 text-gray-600 group-hover:text-primary" />
                                            </button>
                                            <button
                                                onClick={() =>
                                                    setDeleteModal({ isOpen: true, userId: user.userId })
                                                }
                                                className="p-2 rounded-lg hover:bg-red-50 transition-colors group"
                                            >
                                                <Trash2 className="h-4 w-4 text-gray-600 group-hover:text-red-500" />
                                            </button>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </div>

            {/* Add/Edit User Modal */}
            <Modal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                title={editingUser ? 'Edit User' : 'Add New User'}
                size="md"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setIsModalOpen(false)}>
                            Cancel
                        </Button>
                        <Button onClick={handleSubmit}>
                            {editingUser ? 'Update' : 'Create'}
                        </Button>
                    </>
                }
            >
                <form onSubmit={handleSubmit} className="space-y-4">
                    <Input
                        label="Full Name"
                        type="text"
                        required
                        value={formData.fullName}
                        onChange={(e) =>
                            setFormData({ ...formData, fullName: e.target.value })
                        }
                    />
                    <Input
                        label="Email"
                        type="email"
                        required
                        value={formData.email}
                        onChange={(e) =>
                            setFormData({ ...formData, email: e.target.value })
                        }
                    />
                    <Input
                        label="Phone Number"
                        type="text"
                        required
                        value={formData.phoneNumber}
                        onChange={(e) =>
                            setFormData({ ...formData, phoneNumber: e.target.value })
                        }
                    />
                    <div>
                        <label className="text-sm font-medium text-gray-700 mb-1.5 block">
                            Role
                        </label>
                        <select
                            value={formData.role}
                            onChange={(e) =>
                                setFormData({
                                    ...formData,
                                    role: e.target.value as 'admin' | 'user',
                                })
                            }
                            className="w-full rounded-button px-4 py-2 border border-gray-200 bg-white/70 backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary"
                        >
                            <option value="user">User</option>
                            <option value="admin">Admin</option>
                        </select>
                    </div>
                    <div className="flex items-center gap-2">
                        <input
                            type="checkbox"
                            id="isActive"
                            checked={formData.isActive}
                            onChange={(e) =>
                                setFormData({ ...formData, isActive: e.target.checked })
                            }
                            className="rounded border-gray-300"
                        />
                        <label htmlFor="isActive" className="text-sm text-gray-700">
                            Active user
                        </label>
                    </div>
                </form>
            </Modal>

            {/* Delete Confirmation Modal */}
            <ConfirmModal
                isOpen={deleteModal.isOpen}
                onClose={() => setDeleteModal({ isOpen: false, userId: null })}
                onConfirm={() => {
                    if (deleteModal.userId) {
                        handleDelete(deleteModal.userId);
                    }
                }}
                title="Delete User"
                message="Are you sure you want to delete this user? This action cannot be undone."
                confirmText="Delete"
                cancelText="Cancel"
                variant="danger"
            />
        </div>
    );
}
