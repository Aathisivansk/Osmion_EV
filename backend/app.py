from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from pymongo import MongoClient
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)
app.secret_key = "supersecretkey"

# --- Connect to MongoDB ---
# IMPORTANT: Replace with your actual MongoDB connection string
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
    """Handles the form submission to add a new station with detailed data."""
    try:
        # --- NEW: Get all new fields from the form ---
        station_name = request.form.get('stationName')
        latitude = float(request.form.get('latitude'))
        longitude = float(request.form.get('longitude'))
        charger_type = request.form.get('chargerType')
        rating = float(request.form.get('rating'))
        
        # Checkbox sends 'on' if checked, otherwise it's missing from the form
        slot_available = True if request.form.get('slotAvailable') == 'on' else False
        
        # Split comma-separated strings into lists
        sockets_raw = request.form.get('sockets', '')
        sockets = [s.strip() for s in sockets_raw.split(',') if s.strip()]

        amenities_raw = request.form.get('amenities', '')
        amenities = [a.strip() for a in amenities_raw.split(',') if a.strip()]
        
        # --- NEW: Create the document with all fields ---
        station_document = {
            "stationName": station_name,
            "latitude": latitude,
            "longitude": longitude,
            "chargerType": charger_type,
            "rating": rating,
            "slotAvailable": slot_available,
            "sockets": sockets,
            "amenities": amenities
        }

        print(station_document)  # Debugging line to check the document structure
        
        stations_collection.insert_one(station_document)
        flash("Charging station added successfully!", "success")

    except (ValueError, TypeError):
        flash("Invalid input for numeric fields (lat, long, rating).", "error")
    except Exception as e:
        flash(f"An error occurred: {e}", "error")
        
    return redirect(url_for('index'))

@app.route('/api/stations', methods=['GET'])
def get_stations():
    """API endpoint to retrieve all charging station data."""
    # This function works as-is and will now return the new fields automatically
    try:
        all_stations = stations_collection.find({})
        output = []
        for station in all_stations:
            station['_id'] = str(station['_id'])
            output.append(station)
        print( output)  # Debugging line to check output
        return jsonify(output)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)