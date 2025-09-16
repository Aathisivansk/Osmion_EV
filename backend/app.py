from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from bson import json_util
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

# --- MongoDB Connection ---
# Make sure this is your correct connection string
MONGO_URI = "YOUR_MONGODB_CONNECTION_STRING" 
client = MongoClient(MONGO_URI)
db = client.get_database('Osmion')
users_collection = db.User_Auth
# This MUST match the name of the collection where you saved your station info
stations_collection = db.stations 

# --- API Endpoints ---

# Your user authentication endpoints can remain here if needed

# --- UPDATED: Endpoint to get stations with filtering ---
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        # Get the connector type from the request's query parameters (e.g., /api/stations?connector=CCS2)
        connector_type = request.args.get('connector')

        query = {}
        # If a connector type is provided in the URL, add it to our database query.
        # This will search for stations where the 'sockets' array contains the specific connector type.
        if connector_type:
            query['sockets'] = connector_type

        # Fetch documents from the 'stations' collection based on the filter
        all_stations = list(stations_collection.find(query))
        
        # Return the found stations as JSON
        return json_util.dumps(all_stations)
        
    except Exception as e:
        print(f"An error occurred while fetching stations: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500


# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
