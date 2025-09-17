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
from werkzeug.utils import secure_filename
from dotenv import load_dotenv

# Firebase Admin SDK imports
import firebase_admin
from firebase_admin import credentials, messaging

load_dotenv()  # Load environment variables from a .env file if present

# Initialize Firebase Admin SDK (ensure you have the service account key JSON file)
if not firebase_admin._apps:
    cred = credentials.Certificate(os.getenv('FIREBASE_CREDENTIALS_PATH', 'serviceAccountKey.json'))
    firebase_admin.initialize_app(cred)

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# --- Flask-Mail Configuration ---
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 465
app.config['MAIL_USERNAME'] = 'aathisivan1104@gmail.com'
app.config['MAIL_PASSWORD'] = "mwmlktxvykdbseoz"
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
    well_wishers_collection = auth_db.well_wishers
    transactions_collection = auth_db.transactions


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

# --- NEW: Endpoint to store a user's FCM token ---
@app.route('/api/user/fcm_token', methods=['POST'])
def update_fcm_token():
    try:
        data = request.get_json()
        email = data.get('email')
        fcm_token = data.get('fcm_token')

        if not email or not fcm_token:
            return jsonify({'success': False, 'message': 'Email and FCM token are required'}), 400

        users_collection.update_one(
            {'email': email},
            {'$set': {'fcmToken': fcm_token}},
            upsert=True
        )
        return jsonify({'success': True, 'message': 'FCM token updated successfully'}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

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
        name = user_data.get('name')
        email = user_data.get('email')
        address = user_data.get('address')
        pincode = user_data.get('pincode')
        mobile = user_data.get('mobile')
        # --- NEW: Get the FCM token from the request ---
        fcm_token = user_data.get('fcmToken', '') # Default to empty string if not provided

        if not all([name, email, address, pincode, mobile]):
            return jsonify({'message': 'Missing required fields'}), 400

        if users_collection.find_one({'email': email}):
            return jsonify({'message': 'User with this email already exists'}), 409

        # --- MODIFIED: Include fcmToken and profileImageUrl on creation ---
        users_collection.insert_one({
            'name': name,
            'email': email,
            'address': address,
            'pincode': pincode,
            'mobile': mobile,
            'fcmToken': fcm_token, # Add the token here
            'profileImageUrl': '',
            'walletBalance': 0
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
                    "address": user_data.get("address", ""),
                    "profileImageUrl": user_data.get("profileImageUrl", ""),
                    "walletBalance": user_data.get("walletBalance", 0)
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

@app.route('/api/profile/image', methods=['POST'])
def upload_profile_image():
    try:
        # Check if the email is in the form part of the request
        if 'email' not in request.form:
            return jsonify({'success': False, 'message': 'No email provided in form data'}), 400

        # Check if the file part is in the request
        if 'profile_image' not in request.files:
            return jsonify({'success': False, 'message': 'No image file found in request'}), 400

        email = request.form['email']
        file = request.files['profile_image']

        if file.filename == '':
            return jsonify({'success': False, 'message': 'No file selected'}), 400

        if file:
            # Sanitize the filename to prevent security issues
            filename = secure_filename(file.filename)

            # Create a unique filename to prevent overwriting files
            unique_filename = f"{email.split('@')[0]}_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}{os.path.splitext(filename)[1]}"

            # Save the file to your E:/backend/uploads folder
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            file.save(file_path)

            # Construct the URL that the app can use to access the image
            # Make sure your IP address here is correct for your network
            image_url = f"http://10.62.58.59:5000/uploads/{unique_filename}"

            # Update the user's document in MongoDB with the new URL
            users_collection.update_one(
                {'email': email},
                {'$set': {'profileImageUrl': image_url}}
            )

            return jsonify({'success': True, 'message': 'Profile image updated successfully', 'imageUrl': image_url}), 200

    except Exception as e:
        # Print the full error to the console for easier debugging
        print(f"An error occurred during file upload: {e}")
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500


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

# --- Well-Wisher & SOS Endpoints ---

@app.route('/api/users/search', methods=['GET'])
def search_users():
    try:
        query = request.args.get('query', '')
        if len(query) < 2:
            return jsonify([]) # Return empty list if query is too short

        # Search for users by name or email (case-insensitive)
        users_cursor = users_collection.find(
            {"$or": [
                {"name": {"$regex": query, "$options": "i"}},
                {"email": {"$regex": query, "$options": "i"}}
            ]},
            {"name": 1, "email": 1, "profileImageUrl": 1, "_id": 0} # Projection
        ).limit(10)

        users = list(users_cursor)
        return jsonify(users), 200
    except Exception as e:
        return jsonify({"message": f"An error occurred: {e}"}), 500


@app.route('/api/well_wishers/add', methods=['POST'])
def add_well_wisher():
    try:
        data = request.get_json()
        user_email = data.get('user_email')
        wisher_email = data.get('wisher_email')

        if not user_email or not wisher_email:
            return jsonify({'success': False, 'message': 'User email and wisher email are required'}), 400

        # Prevent adding oneself
        if user_email == wisher_email:
            return jsonify({'success': False, 'message': 'You cannot add yourself as a well-wisher'}), 400

        # Check if the relationship already exists
        existing = well_wishers_collection.find_one({
            'user_email': user_email,
            'wisher_email': wisher_email,
        })
        if existing:
            return jsonify({'success': False, 'message': 'This user is already a well-wisher'}), 409


        well_wishers_collection.insert_one({
            'user_email': user_email,
            'wisher_email': wisher_email,
        })
        return jsonify({'success': True, 'message': 'Well-wisher added successfully'}), 201
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

@app.route('/api/well_wishers/remove', methods=['POST'])
def remove_well_wisher():
    try:
        data = request.get_json()
        user_email = data.get('user_email')
        wisher_email = data.get('wisher_email')

        if not user_email or not wisher_email:
            return jsonify({'success': False, 'message': 'User email and wisher email are required'}), 400

        result = well_wishers_collection.delete_one({
            'user_email': user_email,
            'wisher_email': wisher_email,
        })

        if result.deleted_count > 0:
            return jsonify({'success': True, 'message': 'Well-wisher removed successfully'}), 200
        else:
            return jsonify({'success': False, 'message': 'Well-wisher not found'}), 404
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

@app.route('/api/well_wishers/<string:user_email>', methods=['GET'])
def get_well_wishers(user_email):
    try:
        wishers_cursor = well_wishers_collection.find({'user_email': user_email})
        wisher_emails = [w['wisher_email'] for w in wishers_cursor]

        # Fetch details for each well-wisher
        wishers_details = list(users_collection.find(
            {"email": {"$in": wisher_emails}},
            {"name": 1, "email": 1, "profileImageUrl": 1, "_id": 0}
        ))

        return jsonify({'success': True, 'well_wishers': wishers_details}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

@app.route('/api/sos/trigger', methods=['POST'])
def trigger_sos():
    try:
        data = request.get_json()
        user_email = data.get('user_email')
        location = data.get('location', 'an unknown location') # Get location from the app

        if not user_email:
            return jsonify({'success': False, 'message': 'User email is required'}), 400

        user = users_collection.find_one({"email": user_email})
        if not user:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        wishers_cursor = well_wishers_collection.find({'user_email': user_email})
        wisher_emails = [w['wisher_email'] for w in wishers_cursor]

        if not wisher_emails:
            return jsonify({'success': True, 'message': 'SOS triggered, but you have no well-wishers to notify.'}), 200

        # Find the FCM tokens of the well-wishers
        wisher_users = users_collection.find({"email": {"$in": wisher_emails}})
        recipient_tokens = [u['fcmToken'] for u in wisher_users if 'fcmToken' in u]

        if not recipient_tokens:
            return jsonify({'success': True, 'message': 'SOS triggered, but your well-wishers have not set up notifications.'}), 200

        # Construct the notification message
        notification_message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title='SOS Alert from Osmion!',
                body=f"{user.get('name', 'A user')} has triggered an SOS alert from {location}. Please check on them."
            ),
            tokens=recipient_tokens,
        )

        # Send the message
        messaging.send_each_for_multicast(notification_message)
        print(f"SOS notification sent to {len(recipient_tokens)} well-wishers for {user_email}")

        return jsonify({'success': True, 'message': 'SOS alert sent to your well-wishers!'}), 200

    except Exception as e:
        print(f"Error triggering SOS: {e}")
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

# --- NEW: Transaction Endpoints ---

@app.route('/api/transactions/create', methods=['POST'])
def create_transaction():
    try:
        data = request.get_json()
        user_email = data.get('user_email')
        station_name = data.get('station_name')
        amount = data.get('amount')
        payment_method = data.get('payment_method')

        if not all([user_email, station_name, amount, payment_method]):
            return jsonify({'success': False, 'message': 'Missing required transaction fields'}), 400

        # --- NEW: Check user's balance before proceeding ---
        user = users_collection.find_one({'email': user_email})
        if not user or user.get('walletBalance', 0) < amount:
            return jsonify({'success': False, 'message': 'Insufficient wallet balance'}), 402

        # --- NEW: Deduct amount from wallet ---
        # We use $inc with a negative number to subtract
        users_collection.update_one(
            {'email': user_email},
            {'$inc': {'walletBalance': -amount}}
        )

        # Record the transaction
        transaction = {
            'user_email': user_email,
            'station_name': station_name,
            'amount': amount,
            'payment_method': payment_method,
            'timestamp': datetime.datetime.now(datetime.timezone.utc)
        }
        transactions_collection.insert_one(transaction)

        return jsonify({'success': True, 'message': 'Transaction recorded successfully'}), 201
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

@app.route('/api/transactions/<string:user_email>', methods=['GET'])
def get_transactions(user_email):
    try:
        # Fetch transactions for the user and sort by newest first
        transactions_cursor = transactions_collection.find(
            {'user_email': user_email}
        ).sort('timestamp', -1)

        transactions = []
        for trans in transactions_cursor:
            # Manually serialize the document to handle ObjectId and datetime
            transactions.append({
                'station_name': trans.get('station_name'),
                'amount': trans.get('amount'),
                'payment_method': trans.get('payment_method'),
                'timestamp': trans.get('timestamp').isoformat()
            })

        return jsonify({'success': True, 'transactions': transactions}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

@app.route('/api/wallet/add', methods=['POST'])
def add_to_wallet():
    try:
        data = request.get_json()
        email = data.get('email')
        amount = data.get('amount')

        if not email or not isinstance(amount, (int, float)):
            return jsonify({'success': False, 'message': 'Email and a valid amount are required'}), 400

        # Use $inc to atomically increase the balance
        result = users_collection.update_one(
            {'email': email},
            {'$inc': {'walletBalance': amount}}
        )

        if result.matched_count == 0:
            return jsonify({'success': False, 'message': 'User not found'}), 404

        # Fetch the updated user to return the new balance
        updated_user = users_collection.find_one({'email': email})
        new_balance = updated_user.get('walletBalance', 0)

        return jsonify({'success': True, 'message': f'Added {amount} successfully', 'newBalance': new_balance}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': f'An error occurred: {e}'}), 500

# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)