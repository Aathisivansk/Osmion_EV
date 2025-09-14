# backend/app.py
from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from flask_mail import Mail, Message
import random
import string

# Initialize Flask App
app = Flask(__name__)
# CORS allows your Flutter app to communicate with this server
CORS(app)

# --- Flask-Mail Configuration ---
# IMPORTANT: Replace with your email server details
# For Gmail, you might need to use an "App Password"
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 465
app.config['MAIL_USERNAME'] = 'aathisivan1104@gmail.com'
app.config['MAIL_PASSWORD'] = 'DC8C2A2006A22804D75B3B79D3806A516DF9C9FDB22AC28129627C30A8DF50D1'
app.config['MAIL_USE_TLS'] = False
app.config['MAIL_USE_SSL'] = True
mail = Mail(app)

# --- MongoDB Connection ---
# IMPORTANT: Replace this with your actual connection string from MongoDB Atlas
# Make sure your database is named 'Osmion' and your collection is 'User_Auth'
MONGO_URI = "mongodb://10.62.58.114:27017/"

try:
    client = MongoClient(MONGO_URI)
    db = client.get_database('Osmion')
    users_collection = db.User_Auth
    # Collection to store OTPs temporarily
    otp_collection = db.OTPs
    print("Successfully connected to MongoDB!")
except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
    exit()


# --- Helper Function ---
def generate_otp(length=4):
    """Generate a random OTP."""
    return ''.join(random.choices(string.digits, k=length))


# --- API Endpoints ---

# Endpoint to send OTP
@app.route('/api/send_otp', methods=['POST'])
def send_otp():
    try:
        data = request.get_json()
        email = data.get('email')
        if not email:
            return jsonify({'message': 'Email is required'}), 400

        otp = generate_otp()
        # Store the OTP with the email, you might want to add an expiration time
        otp_collection.update_one({'email': email}, {'$set': {'otp': otp}}, upsert=True)

        msg = Message('Your OTP for Osmion EV', sender=app.config['MAIL_USERNAME'], recipients=[email])
        msg.body = f'Your OTP is: {otp}'
        mail.send(msg)

        return jsonify({'message': 'OTP sent successfully'}), 200

    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500


# Endpoint to verify OTP
@app.route('/api/verify_otp', methods=['POST'])
def verify_otp():
    try:
        data = request.get_json()
        email = data.get('email')
        otp = data.get('otp')
        if not email or not otp:
            return jsonify({'message': 'Email and OTP are required'}), 400

        stored_otp_doc = otp_collection.find_one({'email': email})
        if stored_otp_doc and stored_otp_doc['otp'] == otp:
            # OTP is correct, remove it after verification
            otp_collection.delete_one({'email': email})
            return jsonify({'message': 'OTP verified successfully'}), 200
        else:
            return jsonify({'message': 'Invalid OTP'}), 401

    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# Endpoint 1: Check if an email exists
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

# Endpoint 2: Register a new user
@app.route('/api/register', methods=['POST'])
def register_user():
    try:
        user_data = request.get_json()
        name = user_data.get('name')
        email = user_data.get('email')
        address = user_data.get('address')
        pincode = user_data.get('pincode')
        mobile = user_data.get('mobile')
        password = user_data.get('password')

        if not all([name, email, address, pincode, mobile, password]):
            return jsonify({'message': 'Missing required fields'}), 400

        if users_collection.find_one({'email': email}):
            return jsonify({'message': 'User with this email already exists'}), 409

        hashed_password = generate_password_hash(password)

        users_collection.insert_one({
            'name': name,
            'email': email,
            'address': address,
            'pincode': pincode,
            'mobile': mobile,
            'password': hashed_password
        })
        return jsonify({'message': 'User registered successfully!'}), 201
    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500

# Endpoint 3: Log in an existing user
@app.route('/api/login', methods=['POST'])
def login_user():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'message': 'Email and password are required'}), 400

        user = users_collection.find_one({'email': email})

        if user and check_password_hash(user['password'], password):
            user_data_to_return = {
                'name': user.get('name'),
                'email': user.get('email')
            }
            return jsonify({'message': 'Login successful', 'user': user_data_to_return}), 200
        else:
            return jsonify({'message': 'Invalid email or password'}), 401

    except Exception as e:
        return jsonify({'message': f'An internal server error occurred: {e}'}), 500


# --- Run the App ---
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)