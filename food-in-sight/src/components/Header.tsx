import {Link, useNavigate} from "react-router-dom";
import "./Header.css";
import { useAuthenticator } from '@aws-amplify/ui-react';

const Header = () => {
    const { user, signOut } = useAuthenticator((context) => [context.user]);

    const navigate = useNavigate();

    const handleProfileRedir = () => {
        navigate('/profile');
    };

    const handleHomeRedir = () => {
        navigate('/');
    }

    return (
        <header>
            <nav className="nav-menu">
                <button onClick={handleHomeRedir} className="nav-button">
                    Home
                </button>
                <button onClick={handleProfileRedir} className="nav-button">
                    Profile
                </button>

                <p className="welcome-text">Welcome {user.username}</p>
                <button className="logout-button" onClick={signOut}>Sign Out</button>
            </nav>
        </header>
    );
};

export default Header;
