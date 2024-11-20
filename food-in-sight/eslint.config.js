import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';

export default {
    ignores: ['dist'], // Ignore the dist directory
    overrides: [
        {
            files: ['**/*.{ts,tsx}'], // Target TypeScript files
            languageOptions: {
                ecmaVersion: 2020, // Support modern ECMAScript features
                globals: {
                    ...globals.browser, // Add browser globals
                },
                parser: '@typescript-eslint/parser', // Use the TypeScript parser
                parserOptions: {
                    sourceType: 'module',
                },
            },
            plugins: {
                'react-hooks': reactHooks,
                'react-refresh': reactRefresh,
            },
            rules: {
                // Include recommended React hooks rules
                ...reactHooks.configs.recommended.rules,
                // Add react-refresh specific rule
                'react-refresh/only-export-components': [
                    'warn',
                    { allowConstantExport: true },
                ],
            },
        },
    ],
};
