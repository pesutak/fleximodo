/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './layouts/**/*.html',
    './content/**/*.{html,md}',
    '../../layouts/**/*.html',
    '../../content/**/*.{html,md}',
    '../**/layouts/**/*.html',
    '../**/content/**/*.{html,md}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      colors: {
        primary: {
          50: '#F2F9F3',
          100: '#E6F3E8',
          200: '#CCE7D1',
          300: '#B3DBBA',
          400: '#99CFA3',
          500: '#80C38C',
          DEFAULT: '#6CB673', // (600) as default if you use `bg-primary, text-primary, etc.`
          600: '#6CB673',
          700: '#5A995F',
          800: '#487C4C',
          900: '#365E39',
          950: '#243F26',
        },
        "primary-dark": "#5A995F",
        "primary-contrast": "#ffffff",
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
  ],
  // Ensure Tailwind doesn't conflict with the lazy loading and responsive image features
  safelist: ['lazy-load', 'lazy-load-bg', 'lazy-load-video', 'picture', 'source', 'webp', 'srcset'],
};
