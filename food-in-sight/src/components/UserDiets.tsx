import React, { useEffect, useState } from "react";
import axios from "axios";

const API_BASE_URL = import.meta.env.USER_DIET_API_GATEWAY_URL; // Replace with your API Gateway base URL

interface Diet {
    Restriction: string;
    Ingredients: string[]; // Diets also contain ingredients, but we'll only display the name
}

interface UserDietManagerProps {
    userName: string;
}

const ManageDiets: React.FC<UserDietManagerProps> = ({ userName }) => {
    const [availableDiets, setAvailableDiets] = useState<Diet[]>([]);
    const [userDiets, setUserDiets] = useState<string[]>([]);
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        fetchDiets();
        fetchUserDiets();
    }, []);

    const fetchDiets = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/diets`);
            // Extract only the `name` property from diets
            const diets = response.data.map((diet: Diet) => ({
                name: diet.Restriction,
            }));
            setAvailableDiets(diets);
        } catch (err) {
            setError("Failed to load available diets.");
        }
    };

    const fetchUserDiets = async () => {
        try {
            const response = await axios.get(`${API_BASE_URL}/user/diets`, {
                params: { username: userName },
            });
            setUserDiets(response.data.data || []);
        } catch (err) {
            setError("Failed to load user diets.");
        }
    };

    const addDiet = async (diet: string) => {
        setLoading(true);
        try {
            await axios.post(`${API_BASE_URL}/user/diets`, {
                UserName: userName,
                Diet: diet,
            });
            setUserDiets((prev) => [...prev, diet]);
        } catch (err) {
            setError("Failed to add diet.");
        } finally {
            setLoading(false);
        }
    };

    const removeDiet = async (diet: string) => {
        setLoading(true);
        try {
            await axios.delete(`${API_BASE_URL}/user/diets`, {
                data: { UserName: userName, Diet: diet },
            });
            setUserDiets((prev) => prev.filter((d) => d !== diet));
        } catch (err) {
            setError("Failed to remove diet.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div>
            <h2>Manage Your Diets</h2>
            {error && <p style={{ color: "red" }}>{error}</p>}
            <div>
                <h3>Your Diets</h3>
                {userDiets.length > 0 ? (
                    <ul>
                        {userDiets.map((diet) => (
                            <li key={diet}>
                                {diet}
                                <button
                                    onClick={() => removeDiet(diet)}
                                    disabled={loading}
                                    style={{ marginLeft: "10px" }}
                                >
                                    Remove
                                </button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>You have no diets added yet.</p>
                )}
            </div>
            <div>
                <h3>Available Diets</h3>
                {availableDiets.length > 0 ? (
                    <ul>
                        {availableDiets.map((diet) => (
                            <li key={diet.Restriction}>
                                {diet.Restriction}
                                <button
                                    onClick={() => addDiet(diet.Restriction)}
                                    disabled={loading || userDiets.includes(diet.Restriction)}
                                    style={{ marginLeft: "10px" }}
                                >
                                    {userDiets.includes(diet.Restriction) ? "Added" : "Add"}
                                </button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>No diets available to add.</p>
                )}
            </div>
        </div>
    );
};

export default ManageDiets;
