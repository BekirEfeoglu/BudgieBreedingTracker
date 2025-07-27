
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  // Use relative paths for Capacitor compatibility
  base: './',
  server: {
    host: mode === 'development' ? 'localhost' : '::',
    port: 8080,
    // Güvenlik: Development server'da sadece localhost'a izin ver
    strictPort: true,
    // CORS ayarları
    cors: {
      origin: mode === 'development' ? ['http://localhost:8080', 'http://localhost:5173'] : false,
      credentials: true
    }
  },
  plugins: [
    react(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    rollupOptions: {
      external: mode === 'development' ? [] : [
        // Capacitor modüllerini external olarak tanımlamıyoruz
      ],
      output: {
        manualChunks: {
          // Vendor chunks for better caching
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu', '@radix-ui/react-toast'],
          'query-vendor': ['@tanstack/react-query'],
          'supabase-vendor': ['@supabase/supabase-js'],
          'lucide-vendor': ['lucide-react'],
          'utils': ['clsx', 'tailwind-merge', 'class-variance-authority'],
        }
      }
    },
    // Enable tree shaking and use terser only in production
    minify: mode === 'production' ? 'terser' : false,
    ...(mode === 'production' && {
      terserOptions: {
        compress: {
          drop_console: true,
          drop_debugger: true,
        },
      },
    }),
    // Enable gzip compression
    reportCompressedSize: true,
    // Chunk size warnings
    chunkSizeWarningLimit: 1000,
    // Güvenlik: Source map'leri sadece development'ta etkinleştir
    sourcemap: mode === 'development',
  },
  define: {
    global: 'globalThis',
  },
  envDir: '.', // Environment dosyalarının konumu
  envPrefix: 'VITE_', // Environment variables prefix'i
  // Enable CSS code splitting
  css: {
    modules: {
      localsConvention: 'camelCase',
    },
    devSourcemap: mode === 'development',
  },
  // Optimize dependencies
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router-dom',
      '@tanstack/react-query',
      'lucide-react',
    ],
    exclude: mode === 'development' ? [] : [
      // Capacitor modüllerini exclude etmiyoruz
    ]
  },
  // Güvenlik ayarları
  preview: {
    host: 'localhost',
    port: 4173,
    strictPort: true,
  }
}));
