import { Amplify } from 'aws-amplify';
import { Authenticator } from '@aws-amplify/ui-react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom'; // Import Router and Route
import '@aws-amplify/ui-react/styles.css';

import awsmobile from "aws-exports";

import LandingPage from "./components/LandingPage.tsx";
import Header from "./components/Header.tsx";
import ResultsPage from "./components/ResultsPage.tsx";
import ProfilePage from "./components/ProfilePage.tsx";

Amplify.configure(awsmobile);

export default function App() {
    return (
        <Authenticator>
            {({ signOut, user }) => (
                <Router> {/* Wrap everything with Router */}
                    {user ? (
                        <main>
                            <Header />
                            <p>Hello {user.username}</p>

                            {/* Define the Routes for each page */}
                            <Routes>
                                <Route path="/" element={<LandingPage />} />
                                <Route path="/profile" element={<ProfilePage />} />
                                <Route path="/results" element={<ResultsPage />} />
                            </Routes>

                            <button onClick={signOut}>Sign Out</button>
                        </main>
                    ) : (
                        <p>Loading</p>
                    )}
                </Router>
            )}
        </Authenticator>
    );
}
