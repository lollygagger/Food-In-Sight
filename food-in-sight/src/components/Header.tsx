import { Link } from "react-router-dom";
import "./Header.css";
import { useAuthenticator } from '@aws-amplify/ui-react';

const Header = () => {
    const { user, signOut } = useAuthenticator((context) => [context.user]);

    return (
        <header>
            <nav className="nav-menu">
                <button className="nav-button">
                    <Link to="/" className="nav-link">Home</Link>
                </button>
                <button className="nav-button">
                    <Link to="/profile" className="nav-link">Profile</Link>
                </button>

                <p className="welcome-text">Welcome {user.username}</p>
                <button className="logout-button" onClick={signOut}>Sign Out</button>
            </nav>
        </header>
    );
};

export default Header;
