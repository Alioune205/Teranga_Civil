/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: [
    "./index.html",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        layer: {
          0: 'var(--layer-0)',
          1: 'var(--layer-1)',
          2: 'var(--layer-2)',
          3: 'var(--layer-3)',
          4: 'var(--layer-4)',
        },
        border: {
          strong: 'var(--border-strong)',
          subtle: 'var(--border-subtle)',
          glow: 'var(--border-glow)',
          DEFAULT: 'var(--border-strong)',
        },
        amber: {
          DEFAULT: 'var(--amber)',
          dim: 'var(--amber-dim)',
          glow: 'var(--amber-glow)',
          border: 'var(--amber-border)',
        },
        text: {
          100: 'var(--text-100)',
          200: 'var(--text-200)',
          300: 'var(--text-300)',
          400: 'var(--text-400)',
          500: 'var(--text-500)',
        },
        primary: 'var(--amber)',
        success: {
          DEFAULT: 'var(--success)',
          dim: 'var(--success-dim)',
        },
        warning: {
          DEFAULT: 'var(--warning)',
          dim: 'var(--warning-dim)',
        },
        error: {
          DEFAULT: 'var(--error)',
          dim: 'var(--error-dim)',
        },
        info: {
          DEFAULT: 'var(--info)',
          dim: 'var(--info-dim)',
        },
        danger: {
          DEFAULT: 'var(--error)',
          dim: 'var(--error-dim)',
        },
        // Maintien de certaines variables par défaut pour compatibilité radx-ui
        background: 'var(--layer-0)',
        foreground: 'var(--text-200)',
        ring: 'var(--amber)',
        input: 'var(--border-strong)',
        muted: { DEFAULT: 'var(--layer-2)', foreground: 'var(--text-400)' },
        accent: { DEFAULT: 'var(--layer-2)', foreground: 'var(--text-100)' },
        card: { DEFAULT: 'var(--layer-1)', foreground: 'var(--text-200)' },
        popover: { DEFAULT: 'var(--layer-3)', foreground: 'var(--text-200)' },
      },
      borderRadius: {
        lg: '0.5rem',
        md: '0.375rem',
        sm: '0.25rem',
      },
      fontFamily: {
        sans: ['"IBM Plex Sans"', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['"Playfair Display"', 'Georgia', 'serif'],
        mono: ['"IBM Plex Mono"', 'monospace'],
        serif: ['"Playfair Display"', 'Georgia', 'serif'],
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "fade-in": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        "slide-in": {
          from: { transform: "translateX(-100%)" },
          to: { transform: "translateX(0)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.4s ease-out",
        "slide-in": "slide-in 0.3s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
