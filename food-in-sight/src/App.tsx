import { React } from 'react';
import { Amplify } from 'aws-amplify';

import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

import awsExports from './aws-exports';
import LandingPage from "./components/LandingPage.tsx";
Amplify.configure(awsExports);

export default function App() {
    return (
        <Authenticator>
            {({ signOut, user }) => (
                <main>
                    <p> Hello {user.username} </p>
                    <LandingPage />
                    <button onClick={signOut}>Sign Out</button>
                </main>
            )}
        </Authenticator>
    );
}