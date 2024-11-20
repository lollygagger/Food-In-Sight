/**
 * This is a method which takes in an image file and a Pre-Signed URL provided by the API Gateway and uploads the image
 * to the destination S3 Bucket
 * @param imageFile The image to upload to the S3 Bucket
 * @param presignedUrl The S3 Pre-Signed URl to upload the image to
 */
export const imageUploadUtil = async (imageFile: any, presignedUrl: URL) => {
    try {
        const response = await fetch(presignedUrl, {
            method: 'PUT',
            body: imageFile,
            headers: {
                'Content-Type': imageFile.type,
            },
        });

        if (response.ok) {
            console.log('Upload successful!');
            return true;
        } else {
            console.error('Upload failed:', response.statusText);
            return false;
        }
    } catch (error) {
        console.error('Error uploading image:', error);
        return false;
    }
};

/**
 * This is a method which sends a request for a Pre-Signed URL for an S3 Bucket
 * @param endpoint The endpoint which will be appended to the base API URI
 */
export const getPresignedUrl =  async (endpoint: string) => {
    const baseURI = import.meta.env.VITE_API_GATEWAY_URL
    const uri = baseURI + endpoint;
    try {
        const response = await fetch(uri, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        const data = await response.json(); // Assuming the URL is returned in a JSON object
        return data.presignedUrl;
    } catch (error) {
        console.error('Error getting pre-signed URL:', error);
    }
}