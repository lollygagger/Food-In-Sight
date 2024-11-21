import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  resolve: {
    alias: {
      // Correct the alias path relative to the project root
      'aws-exports': '/src/aws-exports.js'
    }
  },
  build: {
    // Optional: If you want to keep the `external` setting, ensure it's correctly configured
    // external: ['aws-exports'],
  },
  plugins: [react()],
});
