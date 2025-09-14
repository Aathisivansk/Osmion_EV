from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS

# Initialize Flask App
app = Flask(__name__)
CORS(app) # Enable Cross-Origin Resource Sharing

# --- MongoDB Connection ---
# Replace with your MongoDB Atlas connection string
MONGO_URI = "YOUR_MONGODB_CONNECTION_STRING" 
client = MongoClient(MONGO_URI)
# --- UPDATED DATABASE NAME ---
db = client.get_database('Osmion') # Now points to your 'Osmion' database
# --- UPDATED COLLECTION NAME ---
users_collection = db.User_Auth # Now points to your 'User_Auth' collection

# --- API Endpoints ---

# A simple test route to see if the server is running
@app.route('/')
def index():
    return "Hello from the Osmion EV Flask Server!"

# The endpoint for new user registration
@app.route('/api/register', methods=['POST'])
def register_user():
    try:
        # Get the data sent from the Flutter app
        user_data = request.get_json()

        # Extract the fields
        name = user_data.get('name')
        email = user_data.get('email')
        address = user_data.get('address')
        pincode = user_data.get('pincode')
        mobile = user_data.get('mobile')

        # Basic validation to ensure all fields are present
        if not all([name, email, address, pincode, mobile]):
            return jsonify({'message': 'Missing required fields'}), 400

        # Check if a user with this email already exists
        if users_collection.find_one({'email': email}):
            return jsonify({'message': 'User with this email already exists'}), 409 # 409 Conflict

        # Insert the new user data into the 'users' collection
        users_collection.insert_one({
            'name': name,
            'email': email,
            'address': address,
            'pincode': pincode,
            'mobile': mobile
        })

        return jsonify({'message': 'User registered successfully!'}), 201 # 201 Created

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500

# --- Run the App ---
if __name__ == '__main__':
    # Use 0.0.0.0 to make the server accessible on your local network
    app.run(host='0.0.0.0', port=5000, debug=True)

