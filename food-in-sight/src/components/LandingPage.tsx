import React from 'react';
import './LandingPage.css';

const LandingPage: React.FC = () => {
    return (
        <div className="landing-container">
        <header className="header">
            <h1>Welcome to Food-in-Sight</h1>
    <p>Your go-to app for food and ingredient insights.</p>
    </header>
    <main className="main-content">
    <section className="upload-section">
        <h2>Upload Food Images</h2>
    <input type="file" accept="image/*" />
    <button className="upload-button">Upload</button>
        </section>
        <section className="search-section">
        <h2>Search Ingredients</h2>
    <input type="text" placeholder="Search for ingredients..." />
    <button className="search-button">Search</button>
        </section>
        </main>
        <footer className="footer">
        <p>&copy; 2024 Food-in-Sight. All rights reserved.</p>
    </footer>
    </div>
);
};

export default LandingPage;