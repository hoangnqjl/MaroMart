import { forwardRef } from 'react';
import type { InputHTMLAttributes, SelectHTMLAttributes, TextareaHTMLAttributes, ReactNode } from 'react';
import { cn } from '../../lib/utils';

// ============== Base Styles ==============

const baseInputStyles = cn(
    'w-full px-4 py-3',
    'rounded-2xl border border-gray-200',
    'bg-white/70 backdrop-blur-sm',
    'shadow-sm shadow-black/5',
    'focus:outline-none focus:ring-2 focus:ring-primary/40 focus:border-primary focus:shadow-md focus:shadow-primary/10',
    'transition-all duration-200 ease-out',
    'placeholder:text-gray-400',
    'text-gray-900'
);

const labelStyles = 'block text-sm font-medium text-gray-700 mb-2';

const errorStyles = 'mt-1.5 text-sm font-medium';
const errorColor = '#ff6b6b';

// ============== FormField Base Props ==============

interface FormFieldBaseProps {
    /** Label text above the field */
    label?: string;
    /** Error message to display */
    error?: string;
    /** Hint text below the field */
    hint?: string;
    /** Required indicator */
    required?: boolean;
    /** Container class name */
    containerClassName?: string;
    /** Left icon/addon */
    leftIcon?: ReactNode;
    /** Right icon/addon */
    rightIcon?: ReactNode;
}

// ============== Input Field ==============

interface InputFieldProps extends FormFieldBaseProps, InputHTMLAttributes<HTMLInputElement> { }

export const InputField = forwardRef<HTMLInputElement, InputFieldProps>(
    ({ label, error, hint, required, containerClassName, leftIcon, rightIcon, className, ...props }, ref) => {
        return (
            <div className={cn('flex flex-col', containerClassName)}>
                {label && (
                    <label className={labelStyles}>
                        {label}
                        {required && <span className="text-red-500 ml-1">*</span>}
                    </label>
                )}
                <div className="relative">
                    {leftIcon && (
                        <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                            {leftIcon}
                        </div>
                    )}
                    <input
                        ref={ref}
                        className={cn(
                            baseInputStyles,
                            leftIcon && 'pl-10',
                            rightIcon && 'pr-10',
                            error && 'border-red-400 focus:ring-red-400/40 focus:border-red-400',
                            className
                        )}
                        {...props}
                    />
                    {rightIcon && (
                        <div className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
                            {rightIcon}
                        </div>
                    )}
                </div>
                {hint && !error && (
                    <span className="mt-1.5 text-sm text-gray-500">{hint}</span>
                )}
                {error && (
                    <span className={errorStyles} style={{ color: errorColor }}>
                        {error}
                    </span>
                )}
            </div>
        );
    }
);

InputField.displayName = 'InputField';

// ============== Select Field ==============

interface SelectFieldProps extends FormFieldBaseProps, SelectHTMLAttributes<HTMLSelectElement> {
    options: Array<{ value: string; label: string }>;
}

export const SelectField = forwardRef<HTMLSelectElement, SelectFieldProps>(
    ({ label, error, hint, required, containerClassName, options, className, ...props }, ref) => {
        return (
            <div className={cn('flex flex-col', containerClassName)}>
                {label && (
                    <label className={labelStyles}>
                        {label}
                        {required && <span className="text-red-500 ml-1">*</span>}
                    </label>
                )}
                <select
                    ref={ref}
                    className={cn(
                        baseInputStyles,
                        'cursor-pointer appearance-none',
                        'bg-[url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'12\' height=\'12\' viewBox=\'0 0 12 12\'%3E%3Cpath fill=\'%236B7280\' d=\'M6 8L1 3h10z\'/%3E%3C/svg%3E")] bg-no-repeat bg-[right_1rem_center]',
                        error && 'border-red-400 focus:ring-red-400/40 focus:border-red-400',
                        className
                    )}
                    {...props}
                >
                    {options.map((option) => (
                        <option key={option.value} value={option.value}>
                            {option.label}
                        </option>
                    ))}
                </select>
                {hint && !error && (
                    <span className="mt-1.5 text-sm text-gray-500">{hint}</span>
                )}
                {error && (
                    <span className={errorStyles} style={{ color: errorColor }}>
                        {error}
                    </span>
                )}
            </div>
        );
    }
);

SelectField.displayName = 'SelectField';

// ============== Textarea Field ==============

interface TextareaFieldProps extends FormFieldBaseProps, TextareaHTMLAttributes<HTMLTextAreaElement> { }

export const TextareaField = forwardRef<HTMLTextAreaElement, TextareaFieldProps>(
    ({ label, error, hint, required, containerClassName, className, ...props }, ref) => {
        return (
            <div className={cn('flex flex-col', containerClassName)}>
                {label && (
                    <label className={labelStyles}>
                        {label}
                        {required && <span className="text-red-500 ml-1">*</span>}
                    </label>
                )}
                <textarea
                    ref={ref}
                    className={cn(
                        baseInputStyles,
                        'min-h-[100px] resize-y',
                        error && 'border-red-400 focus:ring-red-400/40 focus:border-red-400',
                        className
                    )}
                    {...props}
                />
                {hint && !error && (
                    <span className="mt-1.5 text-sm text-gray-500">{hint}</span>
                )}
                {error && (
                    <span className={errorStyles} style={{ color: errorColor }}>
                        {error}
                    </span>
                )}
            </div>
        );
    }
);

TextareaField.displayName = 'TextareaField';

// ============== Checkbox Field ==============

interface CheckboxFieldProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
    label: string;
    error?: string;
    containerClassName?: string;
}

export const CheckboxField = forwardRef<HTMLInputElement, CheckboxFieldProps>(
    ({ label, error, containerClassName, className, ...props }, ref) => {
        return (
            <div className={cn('flex flex-col', containerClassName)}>
                <label className="flex items-center gap-3 cursor-pointer group">
                    <input
                        ref={ref}
                        type="checkbox"
                        className={cn(
                            'w-5 h-5 rounded-lg border-2 border-gray-300',
                            'text-primary focus:ring-2 focus:ring-primary/40',
                            'transition-all duration-200',
                            'cursor-pointer',
                            error && 'border-red-400',
                            className
                        )}
                        {...props}
                    />
                    <span className="text-sm font-medium text-gray-700 group-hover:text-gray-900 transition-colors">
                        {label}
                    </span>
                </label>
                {error && (
                    <span className={cn(errorStyles, 'ml-8')} style={{ color: errorColor }}>
                        {error}
                    </span>
                )}
            </div>
        );
    }
);

CheckboxField.displayName = 'CheckboxField';

// ============== Legacy FormField (Backward Compatible) ==============

interface FormFieldProps extends InputFieldProps { }

/**
 * Legacy FormField component - wraps InputField for backward compatibility
 * @deprecated Use InputField, SelectField, TextareaField, or CheckboxField instead
 */
export const FormField = forwardRef<HTMLInputElement, FormFieldProps>((props, ref) => {
    return <InputField ref={ref} {...props} />;
});

FormField.displayName = 'FormField';

export default FormField;
