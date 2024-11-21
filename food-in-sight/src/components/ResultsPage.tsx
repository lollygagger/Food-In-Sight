import './ResultsPage.css'
import { useLocation } from "react-router-dom";
import { ExpectedResultStructure } from './Types';

const ResultsPage = () => {

    const location = useLocation(); // Get location object which contains the state passed during navigation
    const data: ExpectedResultStructure = location.state?.data;
  
    return (
        <div className="main">
            <h1>Results Page</h1>
            <h2>Message:</h2>
            <p>{data.message}</p>
            <br/>
            <h2>Result:</h2>
            <p>{data.result}</p>

        </div>
    );
};

export default ResultsPage;