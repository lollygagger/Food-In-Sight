/**
 * All environment variables must be listed here for the typescript compiler
 * With Vite all environment variables must begin with VITE_ or they will not be recognized
 * To import environment variables with vite use import.meta.env.VITE_
 */


interface ImportMetaEnv {
    VITE_API_GATEWAY_URL: string;
    USER_DIET_API_GATEWAY_URL: string;
}

interface ImportMeta {
    env: ImportMetaEnv;
}