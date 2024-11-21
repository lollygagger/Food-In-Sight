import React, { useEffect, useState } from "react";
import axios from "axios";

interface ManageDietsProps {
    userName: string;
}

interface Diet {
    Restriction: string;
    Ingredients: string[];
}

const UserDiets: React.FC<ManageDietsProps> = ({ userName }) => {
    const [availableDiets, setAvailableDiets] = useState<string[]>([]);
    const [userDiets, setUserDiets] = useState<string[]>([]);
    const [selectedDiet, setSelectedDiet] = useState<string>("");

    const API_BASE_URL = import.meta.env.VITE_USER_DIET_API_GATEWAY_URL;

    // Fetch available diets
    useEffect(() => {
        const fetchDiets = async () => {
            try {
                const response = await axios.get<Diet[]>(`${API_BASE_URL}/diets`);
                const restrictions = response.data.map((diet) => diet.Restriction);
                setAvailableDiets(restrictions);
            } catch (error) {
                console.error("Error fetching diets:", error);
            }
        };

        fetchDiets();
    }, []);

    // Fetch user's current diets
    useEffect(() => {
        const fetchUserDiets = async () => {
            try {
                const response = await axios.get(`${API_BASE_URL}/user/diets`, {
                    params: { username: userName },
                });
                setUserDiets(response.data.data || []);
            } catch (error) {
                console.error("Error fetching user diets:", error);
            }
        };

        fetchUserDiets();
    }, [userName]);

    // Add diet to user
    const handleAddDiet = async () => {
        if (!selectedDiet) return;

        try {
            await axios.post(`${API_BASE_URL}/user/diets`, {
                UserName: userName,
                Diet: selectedDiet,
            });
            setUserDiets((prevDiets) => [...prevDiets, selectedDiet]);
            setSelectedDiet(""); // Clear selection after adding
        } catch (error) {
            console.error("Error adding diet:", error);
        }
    };

    // Remove diet from user
    const handleRemoveDiet = async (diet: string) => {
        try {
            await axios.delete(`${API_BASE_URL}/user/diets`, {
                data: { UserName: userName, Diet: diet },
            });
            setUserDiets((prevDiets) => prevDiets.filter((d) => d !== diet));
        } catch (error) {
            console.error("Error removing diet:", error);
        }
    };

    return (
        <div className="manage-diets">
            <h3>Manage Your Diets</h3>
            <div className="available-diets">
                <h4>Available Diets</h4>
                <select
                    value={selectedDiet}
                    onChange={(e) => setSelectedDiet(e.target.value)}
                >
                    <option value="">Select a diet</option>
                    {availableDiets.map((diet) => (
                        <option key={diet} value={diet}>
                            {diet}
                        </option>
                    ))}
                </select>
                <button onClick={handleAddDiet} disabled={!selectedDiet}>
                    Add Diet
                </button>
            </div>

            <div className="user-diets">
                <h4>Your Diets</h4>
                {userDiets.length > 0 ? (
                    <ul>
                        {userDiets.map((diet) => (
                            <li key={diet}>
                                {diet}{" "}
                                <button onClick={() => handleRemoveDiet(diet)}>Remove</button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>No diets added yet.</p>
                )}
            </div>
        </div>
    );
};

export default UserDiets;
