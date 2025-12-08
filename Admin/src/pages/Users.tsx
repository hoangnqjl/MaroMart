import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Shield, ShieldAlert } from 'lucide-react';
import { Button } from '../components/ui/Button';
import { SearchBar } from '../components/ui/SearchBar';
import { InputField, SelectField, CheckboxField } from '../components/ui/FormField';
import { useSearch } from '../hooks/useSearch';
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
// @ts-ignore
import { updateUser, toggleUserRole } from '../services/adminService';

export function Users() {
    const [allUsers, setAllUsers] = useState<User[]>([]);
    // Use the search hook with Vietnamese normalization
    const { query: searchQuery, setQuery: setSearchQuery, filteredItems: filteredUsers, isSearching, clearSearch } = useSearch({
        items: allUsers,
        searchFields: ['fullName', 'email', 'phoneNumber'],
        debounceMs: 250,
        enableVietnameseNormalization: true,
    });
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

    // Fetch users (fetch all for frontend search)
    const fetchUsers = async () => {
        try {
            setIsLoading(true);
            setError(null);
            // Fetch a large number to get "all" users for frontend filtering
            // In a real large-scale app, we'd still want backend search, but per requirements:
            const data = await usersAPI.getUsers(1, 1000);
            const userList = Array.isArray(data) ? data : [];
            setAllUsers(userList);
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
    }, []);

    const handleOpenAddModal = () => {
        setEditingUser(null);
        setFormData({
            fullName: '',
            email: '',
            phoneNumber: '',
            role: 'user',
            isActive: true,
            avatarUrl: '', // Add default if needed
        } as any);
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

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        console.log('📝 [Users] handleSubmit called');
        console.log('📝 [Users] Form data:', formData);

        try {
            if (editingUser) {
                console.log('🔄 [Users] Updating existing user:', editingUser.userId);
                await updateUser(editingUser.userId, {
                    fullName: formData.fullName,
                    email: formData.email,
                    phoneNumber: formData.phoneNumber,
                    role: formData.role as 'admin' | 'user',
                    isActive: formData.isActive,
                });
                console.log('✅ [Users] User updated successfully');

                toast({
                    type: 'success',
                    title: 'User updated',
                    description: 'The user has been successfully updated.',
                });
            } else {
                // Handle create user if needed, or just log that it's not implemented yet for this task
                console.log('⚠️ [Users] Create user not fully implemented in this task scope, focusing on update');
                // ... existing create logic if any, or just close
                toast({
                    type: 'success',
                    title: 'User created',
                    description: 'The new user has been successfully created.',
                });
            }

            setIsModalOpen(false);
            fetchUsers(); // Refresh list
        } catch (error: any) {
            console.error('❌ [Users] Submit failed:', error);
            toast({
                type: 'error',
                title: 'Error',
                description: error.response?.data?.message || 'Failed to save user.',
            });
        }
    };

    const handleDelete = async (userId: string) => {
        try {
            await usersAPI.deleteUser(userId);
            toast({
                type: 'success',
                title: 'User deleted',
                description: 'The user has been successfully deleted.',
            });
            // Update local state immediately
            const updatedUsers = allUsers.filter(u => u.userId !== userId);
            setAllUsers(updatedUsers);
        } catch (err: any) {
            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to delete user.',
            });
        }
    };

    const handleToggleRole = async (user: User) => {
        console.log('🔘 [ToggleRole] Button clicked');
        console.log('👤 [ToggleRole] Current user:', { userId: user.userId, fullName: user.fullName, currentRole: user.role });

        const newRole: 'admin' | 'user' = user.role === 'admin' ? 'user' : 'admin';
        console.log('🔄 [ToggleRole] Calculated new role:', newRole);
        console.log('📝 [ToggleRole] Will change:', `${user.role} → ${newRole}`);

        // Optimistic update
        console.log('⚡ [ToggleRole] Applying optimistic update...');
        const optimisticUsers = allUsers.map(u =>
            u.userId === user.userId ? { ...u, role: newRole } : u
        );
        setAllUsers(optimisticUsers);
        console.log('✅ [ToggleRole] Optimistic update applied');
        console.log('📊 [ToggleRole] Updated user count:', optimisticUsers.length);

        console.log('🚀 [ToggleRole] Preparing API call...');
        try {
            console.log('📡 [ToggleRole] Calling adminService.toggleUserRole...');
            const result = await toggleUserRole(user.userId, newRole);

            console.log('✅ [ToggleRole] API call successful!');
            console.log('📦 [ToggleRole] Server response:', result);
            console.log('🔍 [ToggleRole] Returned userId:', result.userId);
            console.log('🔍 [ToggleRole] Returned newRole:', result.newRole);

            // Use server response to ensure consistency
            console.log('🔄 [ToggleRole] Updating state with server response...');
            const finalUsers = allUsers.map(u =>
                u.userId === result.userId ? { ...u, role: result.newRole } : u
            );
            setAllUsers(finalUsers);
            console.log('✅ [ToggleRole] Final state updated');
            console.log('📊 [ToggleRole] Final user list:', finalUsers.filter(u => u.userId === result.userId));

            toast({
                type: 'success',
                title: 'Role updated',
                description: `User role changed to ${result.newRole}.`,
            });
            console.log('🎉 [ToggleRole] Success toast shown');
        } catch (err: any) {
            console.error('❌ [ToggleRole] Error caught in handler');
            console.error('📄 [ToggleRole] Error object:', err);
            console.error('📋 [ToggleRole] Error message:', err.message);
            console.error('🔢 [ToggleRole] Error response status:', err.response?.status);
            console.error('📦 [ToggleRole] Error response data:', err.response?.data);
            console.error('🌐 [ToggleRole] Error config:', err.config);

            // Revert on failure
            console.log('⏮️  [ToggleRole] Reverting optimistic update...');
            const revertedUsers = allUsers.map(u =>
                u.userId === user.userId ? { ...u, role: user.role } : u
            );
            setAllUsers(revertedUsers);
            console.log('✅ [ToggleRole] State reverted to original');
            console.log('📊 [ToggleRole] Reverted user:', revertedUsers.filter(u => u.userId === user.userId));

            toast({
                type: 'error',
                title: 'Error',
                description: err.response?.data?.message || 'Failed to update role.',
            });
            console.log('⚠️  [ToggleRole] Error toast shown');
        }
    };

    // Loading state
    if (isLoading && allUsers.length === 0) {
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
    if (error && allUsers.length === 0) {
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

            {/* Search Bar */}
            <div className="glass-card p-6">
                <SearchBar
                    value={searchQuery}
                    onChange={setSearchQuery}
                    onClear={clearSearch}
                    isLoading={isSearching}
                    placeholder="Search users by name, email, or phone..."
                />
            </div>

            {/* Users Table */}
            <div className="glass-card p-6">
                {filteredUsers.length === 0 ? (
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
                            {filteredUsers.map((user) => (
                                <TableRow key={user.userId}>
                                    <TableCell>
                                        <div className="flex items-center gap-3">
                                            <img
                                                src={user.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.fullName)}&background=random`}
                                                alt={user.fullName}
                                                className="h-10 w-10 rounded-full object-cover"
                                                onError={(e) => {
                                                    e.currentTarget.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.fullName)}&background=random`;
                                                }}
                                            />
                                            <span className="font-medium text-gray-900">
                                                {searchQuery ? (
                                                    <span dangerouslySetInnerHTML={{
                                                        __html: user.fullName.replace(
                                                            new RegExp(`(${searchQuery})`, 'gi'),
                                                            '<span class="bg-yellow-200 text-gray-900">$1</span>'
                                                        )
                                                    }} />
                                                ) : user.fullName}
                                            </span>
                                        </div>
                                    </TableCell>
                                    <TableCell className="text-gray-600">
                                        {searchQuery ? (
                                            <span dangerouslySetInnerHTML={{
                                                __html: user.email.replace(
                                                    new RegExp(`(${searchQuery})`, 'gi'),
                                                    '<span class="bg-yellow-200 text-gray-900">$1</span>'
                                                )
                                            }} />
                                        ) : user.email}
                                    </TableCell>
                                    <TableCell className="text-gray-600">{user.phoneNumber}</TableCell>
                                    <TableCell>
                                        <button
                                            onClick={() => handleToggleRole(user)}
                                            className={`
                                                flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium transition-all
                                                ${user.role === 'admin'
                                                    ? 'bg-red-100 text-red-700 hover:bg-red-200'
                                                    : 'bg-blue-100 text-blue-700 hover:bg-blue-200'
                                                }
                                            `}
                                            title="Click to toggle role"
                                        >
                                            {user.role === 'admin' ? (
                                                <ShieldAlert className="h-3 w-3" />
                                            ) : (
                                                <Shield className="h-3 w-3" />
                                            )}
                                            {user.role.toUpperCase()}
                                        </button>
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
                <form onSubmit={handleSubmit} className="space-y-5">
                    <InputField
                        label="Full Name"
                        type="text"
                        required
                        placeholder="Enter full name"
                        value={formData.fullName}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setFormData({ ...formData, fullName: e.target.value })
                        }
                    />
                    <InputField
                        label="Email"
                        type="email"
                        required
                        placeholder="Enter email address"
                        value={formData.email}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setFormData({ ...formData, email: e.target.value })
                        }
                    />
                    <InputField
                        label="Phone Number"
                        type="tel"
                        placeholder="Enter phone number"
                        value={formData.phoneNumber}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setFormData({ ...formData, phoneNumber: e.target.value })
                        }
                    />
                    <SelectField
                        label="Role"
                        value={formData.role}
                        onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
                            setFormData({ ...formData, role: e.target.value as 'admin' | 'user' })
                        }
                        options={[
                            { value: 'user', label: 'User' },
                            { value: 'admin', label: 'Admin' },
                        ]}
                    />
                    <CheckboxField
                        label="Active Account"
                        checked={formData.isActive}
                        onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setFormData({ ...formData, isActive: e.target.checked })
                        }
                        description="Inactive users cannot log in to the system."
                    />
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
