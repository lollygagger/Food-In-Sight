// App.ts
import React, { useState, useEffect } from 'react';
import { Amplify } from 'aws-amplify';
import { BrowserRouter as Router, Route, Switch, Redirect } from 'react-router-dom';
import awsmobile from "./aws-exports";  // AWS Amplify configuration file

import LandingPage from './components/LandingPage';
import SignIn from './components/SignIn';
import ProtectedPage from './components/ProtectedPage';

Amplify.configure(awsmobile);

const App: React.FC = () => {
    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState<boolean>(true);

    useEffect(() => {
        const checkAuth = async () => {
            try {
                // Check if the user is authenticated
                const currentUser = await Auth.currentAuthenticatedUser();
                setUser(currentUser);
            } catch (error) {
                setUser(null);
            } finally {
                setLoading(false);
            }
        };

        checkAuth();
    }, []);

    if (loading) {
        return <div>Loading...</div>; // Show a loading state while checking authentication
    }

    return (
        <Router>
            <div>
                <h1>Food-in-Sight App</h1>
                {user ? (
                    <div>
                        <p>Welcome, {user.username}</p>
                        <button onClick={() => Auth.signOut()}>Sign out</button>
                    </div>
                ) : (
                    <div>
                        <p>Please log in to access the app.</p>
                        <Redirect to="/signin" />
                    </div>
                )}

                <Switch>
                    <Route path="/signin">
                        <SignIn />
                    </Route>
                    <Route path="/protected">
                        {user ? <ProtectedPage /> : <Redirect to="/signin" />}
                    </Route>
                    <Route path="/" exact>
                        <LandingPage />
                    </Route>
                </Switch>
            </div>
        </Router>
    );
};

export default App;
