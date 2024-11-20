import { Link } from "react-router-dom";
import "./Header.css"; // Make sure your CSS file is imported
import { AuthUser } from "aws-amplify/auth/cognito";

const Header = ({ user, signOut }: { user: AuthUser; signOut: () => void }) => {
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
