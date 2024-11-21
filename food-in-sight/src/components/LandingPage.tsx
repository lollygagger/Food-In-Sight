import './LandingPage.css';
import { FaCloudUploadAlt } from "react-icons/fa";
import {useState} from "react";
import {getPresignedUrl, imageUpload} from "../utils/ImageUploadUtil.ts";
import {image_data} from "../assets/image_data.tsx"
import { useNavigate } from 'react-router-dom';
import { ExpectedResultStructure } from './Types.tsx';


const LandingPage= () => {

    const VITE_API_GATEWAY_URL = import.meta.env.VITE_API_GATEWAY_URL

    const navigate = useNavigate();

    const endpoint = "presign-translate";

    const [translateFile, setTranslateFile] = useState<File | null>(null);
    const [translateResult, setTranslateResult] = useState<any>("");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!translateFile) {
            alert("Please upload a file first!");
            return;
        }

        try {
            // First grab the pre-signed url used to upload to s3
            const preSignedUrl = await getPresignedUrl(endpoint, translateFile.name);

            // then send the file using the Pre-signed URL
            const res = await imageUpload(translateFile, preSignedUrl);

            if (res){
                console.log("Upload successful")
            }
            // Update the translateResult in the UI
            setTranslateResult(res ? "success": "fail");

        } catch (error) {
            console.error("An error occurred during the file upload:", error);
        }
    };

    const Submit2 = async (e: React.FormEvent) => {
        e.preventDefault();
        const apiUrl = `${VITE_API_GATEWAY_URL}/uploadimage`;

        fetch(apiUrl, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            image_data: image_data,
        }),
        })
        .then((response) => response.json())
        .then((data: ExpectedResultStructure) => navigate('/results', {state: {data: data}}))

    }

    return (
        <div className="landing-container">
            <h1>Upload an Image</h1>
            <main className="main-content">

                <form className="upload-section">
                    <h2>Upload Food Images</h2>
                    <input
                        type="file"
                        accept="image/*"
                    />
                    <button onClick={Submit2} className="upload-button">Upload <FaCloudUploadAlt style={{width: "10%"}}/></button>
                </form>

                <form onSubmit={handleSubmit} className="translate-section">
                    <h2>Translate A Label</h2>
                    <input
                        onChange={(e) => setTranslateFile(e.target.files?.[0] || null)}
                        type="file"
                        accept="image/*" />
                    <button className="translate-label">Translate text in image <FaCloudUploadAlt style={{width:"10%"}} /></button>
                </form>

                {translateResult && (
                    <div>
                        <h3>Output:</h3>
                        {translateResult}
                    </div>
                )}

            </main>
        </div>
    );
};

export default LandingPage;