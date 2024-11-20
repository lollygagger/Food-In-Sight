import {useAuthenticator, AccountSettings} from "@aws-amplify/ui-react";
import {useNavigate} from "react-router-dom";
import "./ProfilePage.css";

const ProfilePage= () => {
    const { user } = useAuthenticator((context) => [context.user]);

    const navigate = useNavigate();

    const handlePasswordUpdate = () => {
        navigate('/');
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
                    <AccountSettings.ChangePassword onSuccess={handlePasswordUpdate}/>
                </div>
            </div>

            <div className="user-info-box">
                <div className="user-info">
                    <h2>Diet Information</h2>

                </div>
            </div>

        </div>
    );
};

export default ProfilePage;