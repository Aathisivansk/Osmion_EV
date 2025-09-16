from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from bson import json_util

app = Flask(__name__)
CORS(app)

# --- MongoDB Connection ---
# Make sure this is your correct connection string
MONGO_URI = "YOUR_mongodb://localhost:27017/" 
client = MongoClient(MONGO_URI)
db = client.get_database('Osmion')
# Connect to your new vehicles collection and your stations collection
vehicles_stations_collection = db.vehicles_stations


# --- API Endpoints ---

# NEW: Endpoint to get vehicle makes and models
@app.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    try:
        make = request.args.get('make')
        if make:
            # If a make is specified, return only models for that make
            models = vehicles_collection.find({'make': make}, {'_id': 0, 'model': 1})
            return json_util.dumps([model['model'] for model in models])
        else:
            # If no make is specified, return a unique list of all makes
            makes = vehicles_collection.distinct('make')
            return json_util.dumps(makes)
    except Exception as e:
        return jsonify({'message': f'Server error: {e}'}), 500

# NEW: Endpoint to get the connector type for a specific model
@app.route('/api/vehicle_connector', methods=['GET'])
def get_vehicle_connector():
    try:
        model = request.args.get('model')
        if not model:
            return jsonify({'message': 'Model parameter is required'}), 400
        
        vehicle = vehicles_collection.find_one({'model': model})
        if vehicle:
            return jsonify({'connectorType': vehicle.get('connectorType')})
        else:
            return jsonify({'message': 'Vehicle model not found'}), 404
    except Exception as e:
        return jsonify({'message': f'Server error: {e}'}), 500

# UPDATED: Endpoint to get stations, now with filtering
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        connector_type = request.args.get('connector')
        query = {}
        if connector_type:
            # Find stations where the 'sockets' array contains the specified connector type
            query['sockets'] = connector_type
        
        all_stations = list(stations_collection.find(query))
        return json_util.dumps(all_stations)
        
    except Exception as e:
        print(f"An error occurred fetching stations: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500

# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

