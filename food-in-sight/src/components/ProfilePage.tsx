import { useAuthenticator, AccountSettings, ThemeProvider } from "@aws-amplify/ui-react";
import { useNavigate } from "react-router-dom";
import "./ProfilePage.css";
import UserDiets from "./UserDiets";

const ProfilePage = () => {
    const { user } = useAuthenticator((context) => [context.user]);

    const navigate = useNavigate();

    const handlePasswordUpdate = () => {
        navigate('/');
    };

    const customTheme = {
        name: 'custom-theme',
    };


    return (
        <div className="profile-page">

            <div className="user-info-box">
                <div className="user-info">
                    <h2>User Information</h2>
                    <p><strong>Username:</strong> {user.username}</p>
                    <p><strong>UserID:</strong> {user.userId}</p>
                </div>

                <div className="password-change">
                    <h3>Change Password</h3>
                    <ThemeProvider theme={customTheme}>
                        <AccountSettings.ChangePassword onSuccess={handlePasswordUpdate} />
                    </ThemeProvider>
                </div>
            </div>

            <div className="user-info-box">
                <div className="user-info">
                    <h2>Diet Information</h2>
                    <UserDiets userName={user.username} />
                </div>
            </div>

        </div>
    );
};

export default ProfilePage;