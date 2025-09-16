from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from bson import json_util
import traceback
from datetime import datetime

app = Flask(__name__)
CORS(app)

# --- MongoDB Connection ---
MONGO_URI = "mongodb://localhost:27017/Osmion" 
try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command('ismaster')
    db = client.get_database('Osmion')
    stations_collection = db.stations_vehicles
    # NEW: Connect to the bookings collection
    bookings_collection = db.bookings
    print("Successfully connected to MongoDB!")
except Exception as e:
    print(f"FATAL: Could not connect to MongoDB.")
    traceback.print_exc()
    exit()

# --- API Endpoints ---

# ... (Your existing /api/stations endpoint remains the same) ...
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        all_stations = list(stations_collection.find({}))
        print(f"Found {len(all_stations)} stations in the database.")
        return json_util.dumps(all_stations)
    except Exception as e:
        print(f"An error occurred while fetching stations: {e}")
        return jsonify({'message': 'An internal server error occurred'}), 500

# --- NEW: Endpoint to get available slots for a charger on a specific date ---
@app.route('/api/slots', methods=['GET'])
def get_slots():
    try:
        # Get parameters from the request URL (e.g., /api/slots?chargerId=A&date=2025-09-15)
        charger_id = request.args.get('chargerId')
        date_str = request.args.get('date') # Expected format: YYYY-MM-DD

        if not charger_id or not date_str:
            return jsonify({'message': 'Charger ID and date are required'}), 400
        
        # Find all bookings for this charger on the given date
        start_of_day = datetime.strptime(f"{date_str} 00:00:00", "%Y-%m-%d %H:%M:%S")
        end_of_day = datetime.strptime(f"{date_str} 23:59:59", "%Y-%m-%d %H:%M:%S")

        query = {
            "chargerId": charger_id,
            "slotStartTime": {"$gte": start_of_day, "$lte": end_of_day}
        }
        
        booked_slots = list(bookings_collection.find(query))
        # Create a set of booked start times for quick lookup
        booked_start_times = {booking['slotStartTime'].strftime("%H:%M") for booking in booked_slots}

        # --- Generate all possible 15-minute slots for a 24-hour period ---
        all_slots = []
        for hour in range(24): # 0 to 23
            for minute in range(0, 60, 15): # 0, 15, 30, 45
                
                time_str = f"{hour:02d}:{minute:02d}"
                
                # Check if this time slot is in our set of booked times
                status = "occupied" if time_str in booked_start_times else "available"
                
                all_slots.append({
                    "time": time_str,
                    "status": status
                })

        return jsonify(all_slots)

    except Exception as e:
        print(f"An error occurred while fetching slots: {e}")
        traceback.print_exc()
        return jsonify({'message': 'An internal server error occurred'}), 500

# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

