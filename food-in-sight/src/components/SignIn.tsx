// components/SignIn.tsx
import React from 'react';
import { Auth } from 'aws-amplify';

const SignIn: React.FC = () => {
    const signIn = async () => {
        try {
            const user = await Auth.signIn('username', 'password'); // Replace with actual user input
            console.log('Sign in success:', user);
        } catch (error) {
            console.log('Error signing in:', error);
        }
    };

    return (
        <div>
            <h2>Sign In</h2>
            <button onClick={signIn}>Sign in</button>
        </div>
    );
};

export default SignIn;
