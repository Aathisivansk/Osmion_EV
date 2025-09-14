# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
import datetime

# --- Initialization ---
app = Flask(__name__)
CORS(app) 

# --- Database Connection ---
MONGO_URI = "mongodb://localhost:27017"
client = MongoClient(MONGO_URI)

# Pointing to your correct database and collections
db = client['osmion_ev'] 
host_collection = db['host'] 

def serialize_doc(doc):
    """Converts a MongoDB doc to a JSON serializable format."""
    if doc is None:
        return None
    if '_id' in doc and isinstance(doc['_id'], ObjectId):
        doc['_id'] = str(doc['_id'])
    if 'post_id' in doc and isinstance(doc['post_id'], ObjectId):
        doc['post_id'] = str(doc['post_id'])
    if 'timestamp' in doc and isinstance(doc['timestamp'], datetime.datetime):
        doc['timestamp'] = doc['timestamp'].isoformat()
    if 'comments' in doc:
        for comment in doc['comments']:
            comment = serialize_doc(comment)
    return doc

# --- API Endpoints (Routes) ---

@app.route('/api/hosts/create', methods=['POST'])
def create_hosting_session():
    """Create or update a user's hosting session."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Invalid data"}), 400

        required_fields = ['userId', 'location', 'socketType', 'availableUntil', 'pricePerHour', 'contactDetails']
        if not all(field in data for field in required_fields):
            return jsonify({"error": "Missing required fields"}), 400
            
        user_id = data['userId']
        
        session_data = {
            "userId": user_id,
            "isHosting": data.get('isHosting', False),
            "location": data['location'],
            "socketType": data['socketType'],
            "pricePerHour": data['pricePerHour'],
            "contactDetails": data['contactDetails'],
            "availableUntil": datetime.datetime.fromisoformat(data['availableUntil'].replace('Z', '+00:00')),
            "createdAt": datetime.datetime.now(datetime.timezone.utc)
        }
        
        host_collection.update_one(
            {'userId': user_id},
            {'$set': session_data},
            upsert=True
        )

        return jsonify({"message": "Hosting session created/updated successfully"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Run the App ---
# This block is required to start the server.
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)