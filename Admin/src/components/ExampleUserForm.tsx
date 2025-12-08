import { useState } from 'react';
import { User, Mail, Phone } from 'lucide-react';
import { InputField, SelectField, CheckboxField } from '../components/ui/FormField';
import { Button } from '../components/ui/Button';
import { Modal } from '../components/ui/Modal';

interface UserFormData {
    fullName: string;
    email: string;
    phoneNumber: string;
    role: 'admin' | 'user';
    isActive: boolean;
}

interface ExampleUserFormProps {
    isOpen: boolean;
    onClose: () => void;
    initialData?: Partial<UserFormData>;
    onSubmit: (data: UserFormData) => Promise<void>;
}

/**
 * Example form using the new FormField components
 * Demonstrates Material You styling with:
 * - Rounded-2xl inputs
 * - Focus ring glow
 * - Error states
 * - Icon support
 */
export function ExampleUserForm({ isOpen, onClose, initialData, onSubmit }: ExampleUserFormProps) {
    const [formData, setFormData] = useState<UserFormData>({
        fullName: initialData?.fullName || '',
        email: initialData?.email || '',
        phoneNumber: initialData?.phoneNumber || '',
        role: initialData?.role || 'user',
        isActive: initialData?.isActive ?? true,
    });

    const [errors, setErrors] = useState<Partial<Record<keyof UserFormData, string>>>({});
    const [isSubmitting, setIsSubmitting] = useState(false);

    const validate = (): boolean => {
        const newErrors: Partial<Record<keyof UserFormData, string>> = {};

        if (!formData.fullName.trim()) {
            newErrors.fullName = 'Full name is required';
        }

        if (!formData.email.trim()) {
            newErrors.email = 'Email is required';
        } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
            newErrors.email = 'Please enter a valid email address';
        }

        if (!formData.phoneNumber.trim()) {
            newErrors.phoneNumber = 'Phone number is required';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!validate()) return;

        setIsSubmitting(true);
        try {
            await onSubmit(formData);
            onClose();
        } catch (error) {
            console.error('Form submission failed:', error);
        } finally {
            setIsSubmitting(false);
        }
    };

    const updateField = <K extends keyof UserFormData>(key: K, value: UserFormData[K]) => {
        setFormData(prev => ({ ...prev, [key]: value }));
        // Clear error when field is modified
        if (errors[key]) {
            setErrors(prev => ({ ...prev, [key]: undefined }));
        }
    };

    return (
        <Modal
            isOpen={isOpen}
            onClose={onClose}
            title={initialData ? 'Edit User' : 'Add New User'}
            size="md"
            footer={
                <>
                    <Button variant="secondary" onClick={onClose} disabled={isSubmitting}>
                        Cancel
                    </Button>
                    <Button onClick={handleSubmit} disabled={isSubmitting}>
                        {isSubmitting ? 'Saving...' : initialData ? 'Update' : 'Create'}
                    </Button>
                </>
            }
        >
            <form onSubmit={handleSubmit} className="space-y-5">
                <InputField
                    label="Full Name"
                    placeholder="Enter full name"
                    value={formData.fullName}
                    onChange={(e) => updateField('fullName', e.target.value)}
                    error={errors.fullName}
                    leftIcon={<User className="h-5 w-5" />}
                    required
                />

                <InputField
                    label="Email"
                    type="email"
                    placeholder="Enter email address"
                    value={formData.email}
                    onChange={(e) => updateField('email', e.target.value)}
                    error={errors.email}
                    leftIcon={<Mail className="h-5 w-5" />}
                    required
                />

                <InputField
                    label="Phone Number"
                    type="tel"
                    placeholder="Enter phone number"
                    value={formData.phoneNumber}
                    onChange={(e) => updateField('phoneNumber', e.target.value)}
                    error={errors.phoneNumber}
                    leftIcon={<Phone className="h-5 w-5" />}
                    required
                />

                <SelectField
                    label="Role"
                    value={formData.role}
                    onChange={(e) => updateField('role', e.target.value as 'admin' | 'user')}
                    options={[
                        { value: 'user', label: 'User' },
                        { value: 'admin', label: 'Admin' },
                    ]}
                    required
                />

                <CheckboxField
                    label="Active User"
                    checked={formData.isActive}
                    onChange={(e) => updateField('isActive', e.target.checked)}
                />
            </form>
        </Modal>
    );
}

export default ExampleUserForm;
