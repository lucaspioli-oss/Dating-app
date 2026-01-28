/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "hsl(280, 100%, 65%)",
        secondary: "hsl(320, 100%, 60%)",
        background: "hsl(280, 40%, 4%)",
        foreground: "hsl(0, 0%, 100%)",
        muted: "hsl(280, 20%, 20%)",
        "muted-foreground": "hsl(280, 10%, 60%)",
        card: "hsl(280, 30%, 8%)",
        border: "hsl(280, 20%, 15%)",
        // Cores específicas do funil
        "call-green": "#34C759",
        "call-red": "#FF3B30",
        "whatsapp-green": "#075E54",
        "whatsapp-dark": "#111B21",
        "whatsapp-bubble": "#005C4B",
        "whatsapp-user": "#DCF8C6",
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      animation: {
        'pulse-slow': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'ring': 'ring 1.5s ease-in-out infinite',
        'slide-up': 'slideUp 0.3s ease-out',
        'fade-in': 'fadeIn 0.3s ease-out',
      },
      keyframes: {
        ring: {
          '0%, 100%': { transform: 'rotate(-5deg)' },
          '50%': { transform: 'rotate(5deg)' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
