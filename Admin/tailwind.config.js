/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'Satoshi', 'system-ui', 'sans-serif'],
      },
      colors: {
        primary: {
          DEFAULT: '#FB9A40',
          hover: '#E8861F',
          light: '#FFF4E8',
          50: '#FFF8F0',
          100: '#FFECD5',
          200: '#FFD9AB',
          300: '#FFC17A',
          400: '#FFA94D',
          500: '#FB9A40',
          600: '#E8861F',
          700: '#C06B10',
          800: '#9A5409',
          900: '#7A4307',
        },
        accent: {
          DEFAULT: '#FF6B35',
          light: '#FF8C5A',
          dark: '#E04E1A',
        },
        surface: {
          DEFAULT: '#FAFBFC',
          warm: '#FDF8F3',
          card: '#FFFFFF',
        },
      },
      borderRadius: {
        'card': '20px',
        'button': '14px',
      },
      backdropBlur: {
        'glass': '20px',
      },
      boxShadow: {
        'glow': '0 0 40px -10px rgba(251, 154, 64, 0.3)',
        'card': '0 4px 24px -4px rgba(0, 0, 0, 0.06), 0 1px 2px rgba(0, 0, 0, 0.04)',
        'card-hover': '0 20px 40px -8px rgba(251, 154, 64, 0.15), 0 4px 12px rgba(0, 0, 0, 0.05)',
        'sidebar': '4px 0 24px -4px rgba(0, 0, 0, 0.06)',
        'header': '0 2px 20px -2px rgba(0, 0, 0, 0.04)',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'scale-in': 'scaleIn 0.3s ease-out',
        'pulse-soft': 'pulseSoft 3s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(12px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [],
}
