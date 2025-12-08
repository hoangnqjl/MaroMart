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
          DEFAULT: '#6366F1',
          hover: '#8B5CF6',
        },
      },
      borderRadius: {
        'card': '16px',
        'button': '12px',
      },
      backdropBlur: {
        'glass': '16px',
      },
    },
  },
  plugins: [],
}
