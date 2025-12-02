import { useEffect } from 'react';
import { Transition } from '@headlessui/react';
import { X, CheckCircle, AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { useToast, removeToast } from '../../hooks/useToast';

const toastIcons = {
    success: CheckCircle,
    error: AlertCircle,
    warning: AlertTriangle,
    info: Info,
};

const toastColors = {
    success: 'bg-green-50 border-green-200 text-green-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800',
};

const iconColors = {
    success: 'text-green-500',
    error: 'text-red-500',
    warning: 'text-yellow-500',
    info: 'text-blue-500',
};

export function ToastContainer() {
    const { toasts } = useToast();

    return (
        <div className="fixed top-4 right-4 z-50 flex flex-col gap-2 w-96">
            {toasts.map((toast) => {
                const Icon = toastIcons[toast.type];
                return (
                    <Transition
                        key={toast.id}
                        show={true}
                        appear
                        enter="transform transition duration-300"
                        enterFrom="translate-x-full opacity-0"
                        enterTo="translate-x-0 opacity-100"
                        leave="transform transition duration-200"
                        leaveFrom="translate-x-0 opacity-100"
                        leaveTo="translate-x-full opacity-0"
                    >
                        <div
                            className={`rounded-button border p-4 shadow-lg backdrop-blur-sm ${toastColors[toast.type]}`}
                        >
                            <div className="flex items-start gap-3">
                                <Icon className={`h-5 w-5 flex-shrink-0 mt-0.5 ${iconColors[toast.type]}`} />
                                <div className="flex-1 min-w-0">
                                    <p className="font-medium text-sm">{toast.title}</p>
                                    {toast.description && (
                                        <p className="text-sm opacity-90 mt-1">{toast.description}</p>
                                    )}
                                </div>
                                <button
                                    onClick={() => removeToast(toast.id)}
                                    className="flex-shrink-0 rounded-lg p-1 hover:bg-black/5 transition-colors"
                                >
                                    <X className="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    </Transition>
                );
            })}
        </div>
    );
}
