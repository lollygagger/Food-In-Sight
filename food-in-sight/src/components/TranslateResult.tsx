import './ResultsPage.css'
import {useLocation} from "react-router-dom";

const TranslateResults = () => {
    const location = useLocation();
    const stringResult: string = location.state?.translatedText["translated_text"];
    const lines: string[] = stringResult.split("\n");

    return (
        <div className="main">
            <ul>
                {lines.map((line: string, index: number) => (
                    <li key={index}>{line}</li>
                ))}
            </ul>
        </div>
    );
};

export default TranslateResults;