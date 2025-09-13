from flask import Flask, render_template, request, redirect, url_for, flash
from pymongo import MongoClient
import os

app = Flask(__name__)
# A secret key is needed for flashing messages
app.secret_key = "supersecretkey" 

# --- Connect to MongoDB ---
# IMPORTANT: Replace the connection string with your own from MongoDB Atlas or your local setup.
# For security, it's best to use an environment variable for your connection string.
MONGO_URI = os.environ.get('MONGO_URI', "mongodb+srv://<username>:<password>@<cluster-url>/<dbname>?retryWrites=true&w=majority")
client = MongoClient(MONGO_URI)
db = client.get_database("charging_stations_db") # Or whatever you named your database
stations_collection = db.stations # The collection to store station data

@app.route('/')
def index():
    """
    Renders the main page with the form.
    """
    return render_template('index.html')

@app.route('/add', methods=['POST'])
def add_station():
    """
    Handles the form submission and adds the new station to the database.
    """
    try:
        # Get data from the submitted form
        station_name = request.form.get('stationName')
        latitude = float(request.form.get('latitude'))
        longitude = float(request.form.get('longitude'))
        
        # Basic validation
        if not station_name or not latitude or not longitude:
            flash("All fields are required!", "error")
            return redirect(url_for('index'))

        # Create the document to insert
        station_document = {
            "stationName": station_name,
            "latitude": latitude,
            "longitude": longitude
        }
        
        # Insert into the MongoDB collection
        stations_collection.insert_one(station_document)
        
        flash("Charging station added successfully!", "success")

    except (ValueError, TypeError):
        # Handle cases where latitude/longitude are not valid numbers
        flash("Invalid input for latitude or longitude. Please enter valid numbers.", "error")
    except Exception as e:
        # Handle other potential errors (e.g., database connection issues)
        flash(f"An error occurred: {e}", "error")
        
    return redirect(url_for('index'))

if __name__ == '__main__':
    # Use 0.0.0.0 to make it accessible on your local network
    app.run(host='0.0.0.0', port=5000, debug=True)