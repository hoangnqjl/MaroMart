import { useState, useCallback } from 'react';

export interface Toast {
    id: string;
    title: string;
    description?: string;
    type: 'success' | 'error' | 'warning' | 'info';
}

let toastIdCounter = 0;

const listeners: Set<(toasts: Toast[]) => void> = new Set();
let toastsState: Toast[] = [];

function emitChange() {
    listeners.forEach((listener) => listener(toastsState));
}

export function addToast(toast: Omit<Toast, 'id'>) {
    const id = String(++toastIdCounter);
    const newToast = { ...toast, id };
    toastsState = [...toastsState, newToast];
    emitChange();

    // Auto-remove after 5 seconds
    setTimeout(() => {
        removeToast(id);
    }, 5000);

    return id;
}

export function removeToast(id: string) {
    toastsState = toastsState.filter((t) => t.id !== id);
    emitChange();
}

export function useToast() {
    const [toasts, setToasts] = useState<Toast[]>(toastsState);

    useState(() => {
        listeners.add(setToasts);
        return () => {
            listeners.delete(setToasts);
        };
    });

    const toast = useCallback((toast: Omit<Toast, 'id'>) => {
        return addToast(toast);
    }, []);

    return { toasts, toast, removeToast };
}
