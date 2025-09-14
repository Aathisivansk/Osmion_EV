# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
import datetime

# --- Initialization ---
app = Flask(__name__)
# Enable Cross-Origin Resource Sharing to allow Flutter app to connect
CORS(app) 

# --- Database Connection ---
# IMPORTANT: Replace with your MongoDB Atlas connection string
MONGO_URI = "mongodb://localhost:27017"  # For local MongoDB instance
client = MongoClient(MONGO_URI)
db = client['ev_community_db'] # Database name
posts_collection = db['posts'] # Collection for posts
comments_collection = db['comments'] # Collection for comments
hosting_sessions_collection = db['hosting_sessions'] 
# Collection for hosting sessions

# --- Helper to convert MongoDB ObjectId to string ---
# --- Helper to convert MongoDB ObjectId to string ---
def serialize_doc(doc):
    """Converts a MongoDB doc to a JSON serializable format."""
    if doc is None:
        return None
    
    # This converts the document's own ID
    if '_id' in doc and isinstance(doc['_id'], ObjectId):
        doc['_id'] = str(doc['_id'])

    # ADD THIS BLOCK to convert the post_id reference
    if 'post_id' in doc and isinstance(doc['post_id'], ObjectId):
        doc['post_id'] = str(doc['post_id'])

    if 'timestamp' in doc and isinstance(doc['timestamp'], datetime.datetime):
        doc['timestamp'] = doc['timestamp'].isoformat()
        
    if 'comments' in doc:
        for comment in doc['comments']:
            # This part is recursive for nested objects, good to keep
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

        # Basic validation
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
        
        # Use update_one with upsert=True.
        # This will create a new session if one doesn't exist for the user,
        # or update the existing one if they submit new details.
        hosting_sessions_collection.update_one(
            {'userId': user_id},
            {'$set': session_data},
            upsert=True
        )

        return jsonify({"message": "Hosting session created/updated successfully"}), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts', methods=['GET'])
def get_posts():
    """Fetch all posts from the database."""
    try:
        # Fetch posts and sort by most recent
        all_posts = list(posts_collection.find().sort('timestamp', -1))
        return jsonify([serialize_doc(post) for post in all_posts]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/create', methods=['POST'])
def create_post():
    """Create a new post."""
    try:
        data = request.get_json()
        if not data or 'title' not in data or 'content' not in data:
            return jsonify({"error": "Missing title or content"}), 400

        post = {
            "username": data.get('username', 'Anonymous'),
            "userAvatarUrl": data.get('userAvatarUrl', 'https://i.pravatar.cc/150'),
            "title": data['title'],
            "content": data['content'],
            "upvotes": 0,
            "commentCount": 0,
            "timestamp": datetime.datetime.now(datetime.timezone.utc)
        }
        result = posts_collection.insert_one(post)
        post['_id'] = str(result.inserted_id) # Convert ObjectId to string for the response
        return jsonify(serialize_doc(post)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500
        
@app.route('/api/post/<post_id>/comment', methods=['POST'])
def add_comment(post_id):
    """Add a comment to a specific post."""
    try:
        data = request.get_json()
        if not data or 'text' not in data:
            return jsonify({"error": "Missing comment text"}), 400

        comment = {
            "post_id": ObjectId(post_id),
            "username": data.get('username', 'Anonymous'),
            "userAvatarUrl": data.get('userAvatarUrl', 'https://i.pravatar.cc/150'),
            "text": data['text'],
            "timestamp": datetime.datetime.now(datetime.timezone.utc)
        }
        
        # Insert the comment
        comments_collection.insert_one(comment)
        
        # Update the comment count on the post
        posts_collection.update_one(
            {'_id': ObjectId(post_id)},
            {'$inc': {'commentCount': 1}}
        )
        
        return jsonify(serialize_doc(comment)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/post/<post_id>/comments', methods=['GET'])
def get_comments(post_id):
    """Fetch all comments for a specific post."""
    try:
        comments = list(comments_collection.find({'post_id': ObjectId(post_id)}).sort('timestamp', 1))
        return jsonify([serialize_doc(comment) for comment in comments]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --- Run the App ---
if __name__ == '__main__':
    # Use 0.0.0.0 to make the server accessible on your local network
    app.run(host='0.0.0.0', port=5000, debug=True)