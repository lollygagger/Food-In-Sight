import {Link} from "react-router-dom";

const Header= () => {
    return (
        <header>
            <h1>This will be the header</h1>

            <nav className="nav-menu">
                <ul>
                    <li>
                        <Link to="/">Home</Link>
                    </li>
                    <li>
                        <Link to="/profile">Profile</Link>
                    </li>

                </ul>
            </nav>
        </header>
    );
};

export default Header;