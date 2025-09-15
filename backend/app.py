from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from bson import json_util
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

# --- MongoDB Connection ---
# Make sure this is your correct connection string from MongoDB
MONGO_URI = "YOUR_MONGODB_CONNECTION_STRING" 
client = MongoClient(MONGO_URI)
db = client.get_database('Osmion')
users_collection = db.User_Auth
# UPDATED: This now correctly points to your 'Slot_booking' collection
stations_collection = db.Slot_booking 

# --- API Endpoints ---

# Your user authentication endpoints remain the same
@app.route('/api/check_email', methods=['POST'])
def check_email():
    try:
        data = request.get_json()
        email = data.get('email')
        if users_collection.find_one({'email': email}):
            return jsonify({'exists': True}), 200
        else:
            return jsonify({'exists': False}), 200
    except Exception as e:
        return jsonify({'message': f'Server error: {e}'}), 500

@app.route('/api/register', methods=['POST'])
def register_user():
    try:
        user_data = request.get_json()
        password = user_data.get('password')
        hashed_password = generate_password_hash(password)
        user_data['password'] = hashed_password
        users_collection.insert_one(user_data)
        return jsonify({'message': 'User registered successfully!'}), 201
    except Exception as e:
        return jsonify({'message': f'Server error: {e}'}), 500

@app.route('/api/login', methods=['POST'])
def login_user():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        user = users_collection.find_one({'email': email})
        if user and check_password_hash(user['password'], password):
            user_data = { 'name': user.get('name'), 'email': user.get('email') }
            return jsonify({'message': 'Login successful', 'user': user_data}), 200
        else:
            return jsonify({'message': 'Invalid email or password'}), 401
    except Exception as e:
        return jsonify({'message': f'Server error: {e}'}), 500

# This is the endpoint that provides the station data to your Flutter app
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        all_stations = list(stations_collection.find({}))
        # json_util correctly converts MongoDB's data types for Flutter
        return json_util.dumps(all_stations)
        
    except Exception as e:
        print(f"An error occurred while fetching stations: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500


# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

