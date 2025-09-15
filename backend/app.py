from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from bson import json_util # This is important for converting MongoDB data
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

# --- MongoDB Connection ---
MONGO_URI = "YOUR_MONGODB_CONNECTION_STRING" 
client = MongoClient(MONGO_URI)
db = client.get_database('Osmion')
users_collection = db.User_Auth
# NEW: Define the stations collection
stations_collection = db.stations

# --- API Endpoints ---

# ... (Your existing /api/check_email, /api/register, /api/login endpoints remain here) ...

# --- NEW: Endpoint to get all charging stations ---
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        # Fetch all documents from the 'stations' collection
        all_stations = list(stations_collection.find({}))
        
        # Convert the MongoDB documents to a JSON format and send them
        # json_util.dumps correctly handles MongoDB's special data types
        return json_util.dumps(all_stations)
        
    except Exception as e:
        print(f"An error occurred while fetching stations: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500


# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)