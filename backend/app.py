from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from pymongo import MongoClient
from flask_cors import CORS # 1. Import CORS
import os

app = Flask(__name__)
CORS(app) # 2. Initialize CORS to allow cross-origin requests
app.secret_key = "supersecretkey" 

# --- Connect to MongoDB ---
MONGO_URI = "mongodb://localhost:27017/"
client = MongoClient(MONGO_URI)
db = client.get_database("charging_stations_db")
stations_collection = db.stations

@app.route('/')
def index():
    """Renders the main page with the form."""
    return render_template('index.html')

@app.route('/add', methods=['POST'])
def add_station():
    """Handles the form submission to add a new station."""
    # ... (this function remains unchanged)
    try:
        station_name = request.form.get('stationName')
        latitude = float(request.form.get('latitude'))
        longitude = float(request.form.get('longitude'))
        
        if not station_name or not latitude or not longitude:
            flash("All fields are required!", "error")
            return redirect(url_for('index'))

        station_document = {
            "stationName": station_name,
            "latitude": latitude,
            "longitude": longitude
        }
        
        stations_collection.insert_one(station_document)
        flash("Charging station added successfully!", "success")

    except (ValueError, TypeError):
        flash("Invalid input for latitude or longitude.", "error")
    except Exception as e:
        flash(f"An error occurred: {e}", "error")
        
    return redirect(url_for('index'))

# --- API Endpoint for Flutter App ---
@app.route('/api/stations', methods=['GET'])
def get_stations():
    """API endpoint to retrieve all charging station data."""
    # ... (this function remains unchanged)
    try:
        all_stations = stations_collection.find({})
        output = []
        for station in all_stations:
            station['_id'] = str(station['_id'])
            output.append(station)
        return jsonify(output)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)