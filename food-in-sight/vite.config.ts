import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  resolve: {
    alias: {
      // Create an alias for aws-exports to make sure it resolves properly
      'aws-exports': '/src/aws-exports.js'
    }
  },
  build: {
    rollupOptions: {
      // Explicitly exclude aws-exports from bundling
      external: ['aws-exports'],
    },
  },
  plugins: [react()],
});
