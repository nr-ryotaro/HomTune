/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.{html,js}",
    "./index.html"
  ],
  theme: {
    extend: {
      colors: {
        'homtune': {
          'primary': '#1a1a1a',
          'secondary': '#4a4a4a',
          'accent': '#000000',
          'background': '#ffffff',
          'surface': '#fafafa',
          'border': '#e5e5e5',
          'alert': '#ef4444',
          'warning': '#f59e0b',
          'info': '#3b82f6'
        }
      },
      fontFamily: {
        'sans': ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      }
    },
  },
  plugins: [],
}
