# app.py

from flask import Flask, request, jsonify
from bson.json_util import dumps
import json
from flask_cors import CORS
from flask_mail import Mail, Message
from pymongo import MongoClient
from bson import ObjectId
import datetime
import random
import string
import os # Import the os module

app = Flask(__name__)
CORS(app)

# --- Flask-Mail Configuration ---
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 465
app.config['MAIL_USERNAME'] = 'aathisivan1104@gmail.com'
# FIX: Use environment variables for sensitive data like passwords.
# In your terminal, you would set this like: export MAIL_PASSWORD='your_password'
app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
app.config['MAIL_USE_TLS'] = False
app.config['MAIL_USE_SSL'] = True
mail = Mail(app)

# --- MongoDB Connection (Improved Readability) ---
MONGO_URI = "mongodb://localhost:27017/"
try:
    client = MongoClient(MONGO_URI)

    # Use descriptive names for databases
    stations_db = client.get_database("charging_stations_db")
    auth_db = client.get_database('Osmion')
    community_db = client.get_database('ev_community_db')

    # Collections
    stations_collection = stations_db.stations
    users_collection = auth_db.User_Auth
    otp_collection = auth_db.OTPs
    vehicle_collection = auth_db.Vehicles
    posts_collection = community_db.posts
    comments_collection = community_db.comments
    host_collection = community_db['host']

    client.server_info() # Test connection
    print("✅ Successfully connected to MongoDB!")
except Exception as e:
    print(f"❌ Error connecting to MongoDB: {e}")
    exit()

# --- Helper Functions (No changes needed here) ---
def generate_otp(length=4):
    """Generates a random 4-digit OTP."""
    return ''.join(random.choices(string.digits, k=length))

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

def parse_json(data):
    return json.loads(dumps(data))


# --- API Endpoints ---

# --- User Authentication and Management (No changes needed here) ---

@app.route('/api/check_email', methods=['POST'])
def check_email():
    try:
        data = request.get_json()
        email = data.get('email')
        if not email:
            return jsonify({'message': 'Email is required'}), 400
        if users_collection.find_one({'email': email}):
            return jsonify({'exists': True}), 200
        else:
            return jsonify({'exists': False}), 200
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

@app.route('/api/send_otp', methods=['POST'])
def send_otp():
    try:
        data = request.get_json()
        email = data.get('email')
        if not email:
            return jsonify({'message': 'Email is required'}), 400
        otp = generate_otp()
        otp_collection.update_one({'email': email}, {'$set': {'otp': otp}}, upsert=True)

        print(f"Generated OTP for {email}: {otp}") # For debugging

        msg = Message('Your OTP for Osmion EV', sender=app.config['MAIL_USERNAME'], recipients=[email])
        msg.body = f'Your Login OTP is: {otp}'
        mail.send(msg)
        return jsonify({'message': 'OTP sent successfully'}), 200
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

@app.route('/api/verify_otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        email = data.get('email')
        otp = data.get('otp', '').strip()

        if not email or not otp:
            return jsonify({'message': 'Email and OTP are required'}), 400

        stored_otp_doc = otp_collection.find_one({'email': email})

        if stored_otp_doc and stored_otp_doc.get('otp', '').strip() == otp:
            otp_collection.delete_one({'email': email})
            user = users_collection.find_one({'email': email})
            if user:
                user_data_to_return = {'name': user.get('name'), 'email': user.get('email')}
                return jsonify({'message': 'Login successful', 'user': user_data_to_return}), 200
            else:
                return jsonify({'message': 'OTP verified successfully'}), 200
        else:
            return jsonify({'message': 'Invalid OTP'}), 401
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

@app.route('/api/register', methods=['POST'])
def register_user():
    try:
        user_data = request.get_json()
        name, email, address, pincode, mobile = (
            user_data.get('name'), user_data.get('email'), user_data.get('address'),
            user_data.get('pincode'), user_data.get('mobile')
        )

        if not all([name, email, address, pincode, mobile]):
            return jsonify({'message': 'Missing required fields'}), 400

        if users_collection.find_one({'email': email}):
            return jsonify({'message': 'User with this email already exists'}), 409

        users_collection.insert_one({
            'name': name, 'email': email, 'address': address,
            'pincode': pincode, 'mobile': mobile,
        })
        return jsonify({'message': 'User registered successfully!'}), 201
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# --- FIX: Added the /api prefix to the profile GET route ---
@app.route('/api/profile/<string:user_email>', methods=['GET'])
def get_user_profile(user_email):
    try:
        print(f"📨 Fetching profile for: {user_email}")
        user_data = users_collection.find_one({"email": user_email})

        if user_data:
            user_data = parse_json(user_data)
            return jsonify({
                "success": True,
                "data": {
                    "name": user_data.get("name", ""),
                    "email": user_data.get("email", ""),
                    "mobileNumber": user_data.get("mobile", ""),
                    "pinCode": user_data.get("pincode", ""),
                    "address": user_data.get("address", "")
                }
            }), 200
        else:
            return jsonify({"success": False, "message": "User not found"}), 404
    except Exception as e:
        print(f"❌ Error fetching user: {e}")
        return jsonify({"success": False, "message": f"Server error: {str(e)}"}), 500

# --- FIX: Added the /api prefix to the profile PUT route ---
@app.route('/api/profile/<string:user_email>', methods=['PUT'])
def update_user_profile(user_email):
    try:
        data = request.get_json()
        print(f"📨 Updating profile for {user_email} with data: {data}")

        if not data:
            return jsonify({"success": False, "message": "No data provided"}), 400

        field_mapping = {
            "name": "name", "mobileNumber": "mobile",
            "pinCode": "pincode", "address": "address"
        }

        update_data = {}
        for flutter_field, db_field in field_mapping.items():
            if flutter_field in data:
                update_data[db_field] = data[flutter_field]

        result = users_collection.update_one(
            {"email": user_email},
            {"$set": update_data}
        )

        if result.matched_count == 0:
            return jsonify({"success": False, "message": "User not found"}), 404

        print(f"✅ Profile updated for: {user_email}")
        return jsonify({"success": True, "message": "Profile updated successfully"}), 200

    except Exception as e:
        print(f"❌ Error updating user: {e}")
        return jsonify({"success": False, "message": f"Server error: {str(e)}"}), 500

# --- Vehicle Management (No changes needed here) ---
@app.route('/api/add_vehicle', methods=['POST'])
def add_vehicle():
    try:
        data = request.get_json()
        email, make, model, register_no, connector_type = (
            data.get('email'), data.get('make'), data.get('model'),
            data.get('register_no'), data.get('connector_type')
        )

        if not all([email, make, model, register_no, connector_type]):
            return jsonify({'message': 'Missing required vehicle fields'}), 400

        vehicle_collection.insert_one({
            'user_email': email, 'make': make, 'model': model,
            'register_no': register_no, 'connector_type': connector_type,
        })
        return jsonify({'message': 'Vehicle details saved successfully'}), 201
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# --- Charging Station Management (No changes needed here) ---
@app.route('/api/stations', methods=['GET'])
def get_stations():
    try:
        all_stations = stations_collection.find({})
        output = [serialize_doc(station) for station in all_stations]
        return jsonify(output)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- EV Community Forum (No changes needed here) ---
@app.route('/api/posts', methods=['GET'])
def get_posts():
    try:
        all_posts = list(posts_collection.find().sort('timestamp', -1))
        return jsonify([serialize_doc(post) for post in all_posts]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/create', methods=['POST'])
def create_post():
    try:
        data = request.get_json()
        if not data or 'title' not in data or 'content' not in data:
            return jsonify({"error": "Missing title or content"}), 400

        post = {
            "username": data.get('name'),
            "userAvatarUrl": data.get('userAvatarUrl'),
            "title": data['title'], "content": data['content'],
            "upvotes": 0, "commentCount": 0,
            "timestamp": datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=5, minutes=30)))
        }
        print(f"Creating post: {post}")  # Debugging line
        result = posts_collection.insert_one(post)
        post['_id'] = str(result.inserted_id)
        return jsonify(serialize_doc(post)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/post/<post_id>/comment', methods=['POST'])
def add_comment(post_id):
    try:
        data = request.get_json()
        if not data or 'text' not in data:
            return jsonify({"error": "Missing comment text"}), 400

        comment = {
            "post_id": ObjectId(post_id),
            "username": data.get('name', 'Anonymous'),
            "userAvatarUrl": data.get('userAvatarUrl', 'https://i.pravatar.cc/150'),
            "text": data['text'],
            "timestamp": datetime.datetime.now(datetime.timezone.utc)
        }

        comments_collection.insert_one(comment)

        posts_collection.update_one(
            {'_id': ObjectId(post_id)},
            {'$inc': {'commentCount': 1}}
        )

        return jsonify(serialize_doc(comment)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- ADD THIS NEW ROUTE TO YOUR app.py for upvoting ---
@app.route('/api/posts/<post_id>/upvote', methods=['POST'])
def upvote_post(post_id):
    try:
        # Use MongoDB's $inc operator to increment the upvotes field by 1
        result = posts_collection.update_one(
            {'_id': ObjectId(post_id)},
            {'$inc': {'upvotes': 1}}
        )

        if result.matched_count == 0:
            return jsonify({"success": False, "message": "Post not found"}), 404

        # Fetch the updated post to return the new upvote count
        updated_post = posts_collection.find_one({'_id': ObjectId(post_id)})

        return jsonify({
            "success": True,
            "message": "Post upvoted successfully",
            "upvotes": updated_post.get('upvotes', 0)
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route('/api/post/<post_id>/comments', methods=['GET'])
def get_comments(post_id):
    try:
        comments = list(comments_collection.find({'post_id': ObjectId(post_id)}).sort('timestamp', 1))
        return jsonify([serialize_doc(comment) for comment in comments]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/get_username', methods=['POST'])
def get_username_by_email():
    if client is None:
        return jsonify({"message": "Database connection error"}), 500

    data = request.get_json()
    if not data or 'email' not in data:
        return jsonify({"message": "Missing 'email' in request body"}), 400

    try:
        email = data['email']
        user_document = users_collection.find_one({'email': email}, {'name': 1, '_id': 0})

        if user_document:
            return jsonify(user_document), 200
        else:
            return jsonify({"message": "User not found"}), 404
    except Exception as e:
        return jsonify({"message": f"An internal server error occurred: {e}"}), 500

# --- FIX: Added the /api prefix to the vehicles GET route for consistency ---
@app.route('/api/vehicles/<string:user_email>', methods=['GET'])
def get_user_vehicles(user_email):
    """Get all vehicles for a specific user from the database"""
    try:
        print(f"📨 Fetching vehicles for user: {user_email}")

        # Find all vehicles that match the user_email
        vehicles_cursor = vehicle_collection.find({'user_email': user_email})

        vehicles = []
        for vehicle in vehicles_cursor:
            v = parse_json(vehicle)
            vehicles.append({
                "_id": str(v.get("_id", "")),
                "model": v.get("model", ""),
                # FIX: Ensure all fields your Flutter app expects are here
                "connectorType": v.get("connector_type", ""),
                "chargerType": v.get("chargerType", "N/A"), # Added a default value
                "registrationNumber": v.get("register_no", ""),
            })

        return jsonify({
            "success": True,
            "data": vehicles
        }), 200
    except Exception as e:
        print(f"❌ Error fetching user vehicles: {e}")
        return jsonify({
            "success": False,
            "message": f"Error fetching vehicles: {str(e)}"
        }), 500

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
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)