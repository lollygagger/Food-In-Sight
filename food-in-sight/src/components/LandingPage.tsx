import './LandingPage.css';

const LandingPage= () => {
    return (
        <div className="landing-container">
            <h1>Upload an Image of Food</h1>
            <main className="main-content">

                <section className="upload-section">
                    <h2>Upload Food Images</h2>
                    <input type="file" accept="image/*" />
                    <button className="upload-button">Upload</button>
                </section>

                <section className="translate-section">
                    <h2>Translate A Label</h2>
                    <input type="file" accept="image/*" />
                    <button className="translate-label">Translate text in image</button>
                </section>

            </main>
        </div>
    );
};

export default LandingPage;