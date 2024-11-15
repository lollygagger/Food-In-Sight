import { Amplify } from 'aws-amplify';

import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

import awsmobile from "aws-exports";

import LandingPage from "./components/LandingPage.tsx";

Amplify.configure(awsmobile);

export default function App() {
    const user = {username: "testing"}
    return (
        <>
        {/*<Authenticator>*/}
        {/*    {({ signOut, user }) => (*/}
                <main>
                    {user ? (
                        <>
                            <p> Hello {user.username} </p>
                            <LandingPage/>
                            {/*<button onClick={signOut}>Sign Out</button>*/}
                        </>
                    ) : (
                        <p>Loading</p>
                    )}
                </main>
            {/*)}*/}
        {/*</Authenticator>*/}
        </>
    );
}