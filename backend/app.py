from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash

# Initialize Flask App
app = Flask(__name__)
# CORS allows your Flutter app to communicate with this server
CORS(app)

# --- MongoDB Connection ---
# IMPORTANT: Replace this with your actual connection string from MongoDB Atlas
# Make sure your database is named 'Osmion' and your collection is 'User_Auth'
MONGO_URI = "YOUR_MONGODB_CONNECTION_STRING" 

try:
    client = MongoClient(MONGO_URI)
    db = client.get_database('Osmion')
    users_collection = db.User_Auth
    print("Successfully connected to MongoDB!")
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit()


# --- API Endpoints ---

# Endpoint 1: Check if an email exists
# This is called when the user clicks "Continue" on the first screen.
@app.route('/api/check_email', methods=['POST'])
def check_email():
    try:
        data = request.get_json()
        email = data.get('email')
        if not email:
            return jsonify({'message': 'Email is required'}), 400

        # Look for a user with the given email in the database
        if users_collection.find_one({'email': email}):
            # If found, tell the Flutter app the user exists
            return jsonify({'exists': True}), 200
        else:
            # If not found, tell the Flutter app the user does not exist
            return jsonify({'exists': False}), 200
            
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# Endpoint 2: Register a new user
# This is called from the UserRegisterPage.
@app.route('/api/register', methods=['POST'])
def register_user():
    try:
        user_data = request.get_json()
        name = user_data.get('name')
        email = user_data.get('email')
        address = user_data.get('address')
        pincode = user_data.get('pincode')
        mobile = user_data.get('mobile')
        password = user_data.get('password')

        if not all([name, email, address, pincode, mobile, password]):
            return jsonify({'message': 'Missing required fields'}), 400

        # Check again if user already exists (as a safeguard)
        if users_collection.find_one({'email': email}):
            return jsonify({'message': 'User with this email already exists'}), 409

        # IMPORTANT: Hash the password for security before saving it.
        # Never store plain text passwords.
        hashed_password = generate_password_hash(password)

        users_collection.insert_one({
            'name': name,
            'email': email,
            'address': address,
            'pincode': pincode,
            'mobile': mobile,
            'password': hashed_password # Save the secure, hashed password
        })
        return jsonify({'message': 'User registered successfully!'}), 201 # 201 means "Created"
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# Endpoint 3: Log in an existing user
# This is called from the LoginPasswordPage.
@app.route('/api/login', methods=['POST'])
def login_user():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'message': 'Email and password are required'}), 400

        user = users_collection.find_one({'email': email})

        # Check if a user was found and if the provided password matches the stored hash
        if user and check_password_hash(user['password'], password):
            # Login is successful. Send back some user data (but not the password hash).
            user_data_to_return = {
                'name': user.get('name'),
                'email': user.get('email')
            }
            return jsonify({'message': 'Login successful', 'user': user_data_to_return}), 200
        else:
            # If no user or wrong password, send an error
            return jsonify({'message': 'Invalid email or password'}), 401 # 401 means "Unauthorized"
            
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500


# --- Run the App ---
if __name__ == '__main__':
    # Before running, you may need to install the password hashing library:
    # pip install werkzeug
    app.run(host='0.0.0.0', port=5000, debug=True)

