from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from pymongo import MongoClient
from bson.objectid import ObjectId
from bson.json_util import dumps
import json
import os
import random

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# MongoDB connection - ONLY CHANGE THESE 2 LINES!
try:
    client = MongoClient('mongodb://localhost:27017/')
    db = client.osmion_ev  # CHANGED: osmion_db → osmion_ev
    users_collection = db.user_profile  # CHANGED: users → user_profile
    print("✅ Successfully connected to MongoDB")
    print("📊 Using database: osmion_ev")
    print("📋 Using collection: user_profile")
except Exception as e:
    print(f"❌ Error connecting to MongoDB: {e}")

# Helper function to parse MongoDB document to JSON
def parse_json(data):
    return json.loads(dumps(data))

# Serve the HTML test page
@app.route('/test')
def serve_test_page():
    return """
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Tester - Osmion EV Backend</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2E7D32;
            text-align: center;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        input, textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        button {
            background-color: #2E7D32;
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 5px;
        }
        button:hover {
            background-color: #1B5E20;
        }
        .result {
            margin-top: 20px;
            padding: 15px;
            border-radius: 5px;
            background-color: #e8f5e8;
            border: 1px solid #c8e6c9;
        }
        .error {
            background-color: #ffebee;
            border: 1px solid #ffcdd2;
        }
        .tab {
            display: inline-block;
            padding: 10px 20px;
            cursor: pointer;
            border: 1px solid #ddd;
            border-bottom: none;
            border-radius: 5px 5px 0 0;
            margin-right: 5px;
        }
        .tab.active {
            background-color: #2E7D32;
            color: white;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Osmion EV Backend Tester</h1>
        <p>Test your Flask API endpoints easily</p>

        <div class="tabs">
            <div class="tab active" onclick="showTab('create')">Create User</div>
            <div class="tab" onclick="showTab('get')">Get User</div>
            <div class="tab" onclick="showTab('update')">Update User</div>
        </div>

        <!-- CREATE USER TAB -->
        <div id="create" class="tab-content active">
            <h2>Create New User</h2>
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" id="name" value="Test User">
            </div>
            <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" id="email" value="small@gmail.com">
            </div>
            <div class="form-group">
                <label for="mobile">Mobile Number:</label>
                <input type="text" id="mobile" value="8123456789">
            </div>
            <div class="form-group">
                <label for="pincode">PIN Code:</label>
                <input type="text" id="pincode" value="600001">
            </div>
            <div class="form-group">
                <label for="address">Address:</label>
                <textarea id="address">Test Address, Chennai</textarea>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" value="test123">
            </div>
            <button onclick="createUser()">Create User</button>
        </div>

        <!-- GET USER TAB -->
        <div id="get" class="tab-content">
            <h2>Get User Profile</h2>
            <div class="form-group">
                <label for="getEmail">Email:</label>
                <input type="email" id="getEmail" value="small@gmail.com">
            </div>
            <button onclick="getUser()">Get User</button>
        </div>

        <!-- UPDATE USER TAB -->
        <div id="update" class="tab-content">
            <h2>Update User Profile</h2>
            <div class="form-group">
                <label for="updateEmail">Email:</label>
                <input type="email" id="updateEmail" value="small@gmail.com">
            </div>
            <div class="form-group">
                <label for="updateName">Name:</label>
                <input type="text" id="updateName" value="Updated Name">
            </div>
            <div class="form-group">
                <label for="updateMobile">Mobile Number:</label>
                <input type="text" id="updateMobile" value="9876543210">
            </div>
            <button onclick="updateUser()">Update User</button>
        </div>

        <div id="result" class="result"></div>
    </div>

    <script>
        const API_BASE = 'http://10.0.2.2:5001';
        
        function showTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            document.querySelector(`.tab[onclick="showTab('${tabName}')"]`).classList.add('active');
        }

        function createUser() {
            const userData = {
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                mobile: document.getElementById('mobile').value,
                pincode: document.getElementById('pincode').value,
                address: document.getElementById('address').value,
                password: document.getElementById('password').value
            };

            fetch(`${API_BASE}/profile`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData)
            })
            .then(response => response.json())
            .then(data => {
                showResult('✅ User created successfully!', data);
            })
            .catch(error => {
                showResult('❌ Error creating user:', error, true);
            });
        }

        function getUser() {
            const email = document.getElementById('getEmail').value;
            
            fetch(`${API_BASE}/profile/${email}`)
            .then(response => response.json())
            .then(data => {
                showResult('✅ User data retrieved:', data);
            })
            .catch(error => {
                showResult('❌ Error fetching user:', error, true);
            });
        }

        function updateUser() {
            const email = document.getElementById('updateEmail').value;
            const updateData = {
                name: document.getElementById('updateName').value,
                mobileNumber: document.getElementById('updateMobile').value
            };

            fetch(`${API_BASE}/profile/${email}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(updateData)
            })
            .then(response => response.json())
            .then(data => {
                showResult('✅ User updated successfully!', data);
            })
            .catch(error => {
                showResult('❌ Error updating user:', error, true);
            });
        }

        function showResult(message, data, isError = false) {
            const resultDiv = document.getElementById('result');
            resultDiv.innerHTML = `
                <strong>${message}</strong><br><br>
                <pre>${JSON.stringify(data, null, 2)}</pre>
            `;
            resultDiv.className = isError ? 'result error' : 'result';
        }
    </script>
</body>
</html>
    """

@app.route('/')
def home():
    return jsonify({"message": "Flask-MongoDB API is running!"})

@app.route('/profile/<string:user_email>', methods=['GET'])
def get_user_profile(user_email):
    try:
        print(f"📨 Fetching profile for: {user_email}")
        user_data = users_collection.find_one({"email": user_email})
        
        if user_data:
            # Convert ObjectId to string and return the data
            user_data = parse_json(user_data)
            return jsonify({
                "success": True,
                "data": {
                    "name": user_data.get("name", ""),
                    "email": user_data.get("email", ""),
                    "mobileNumber": user_data.get("mobile", user_data.get("mobileNumber", "")),
                    "pinCode": user_data.get("pincode", user_data.get("pinCode", "")),
                    "address": user_data.get("address", "")
                }
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404
    except Exception as e:
        print(f"❌ Error fetching user: {e}")
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500

@app.route('/profile', methods=['POST'])
def create_user_profile():
    try:
        data = request.get_json()
        print(f"📨 Creating profile with data: {data}")

        if not data:
            return jsonify({
                "success": False,
                "message": "No data provided"
            }), 400

        # Check if user already exists
        if users_collection.find_one({"email": data["email"]}):
            return jsonify({
                "success": False,
                "message": "User with this email already exists"
            }), 409

        # Insert new user
        result = users_collection.insert_one(data)
        print(f"✅ User created with ID: {result.inserted_id}")
        return jsonify({
            "success": True,
            "message": "User created successfully",
            "id": str(result.inserted_id)
        }), 201

    except Exception as e:
        print(f"❌ Error creating user: {e}")
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500

@app.route('/profile/<string:user_email>', methods=['PUT'])
def update_user_profile(user_email):
    try:
        data = request.get_json()
        print(f"📨 Updating profile for {user_email} with data: {data}")

        if not data:
            return jsonify({
                "success": False,
                "message": "No data provided"
            }), 400

        # Field mapping between Flutter and MongoDB
        field_mapping = {
            "name": "name",
            "mobileNumber": "mobile",
            "pinCode": "pincode",
            "address": "address"
        }
        
        # Prepare update data
        update_data = {}
        for flutter_field, db_field in field_mapping.items():
            if flutter_field in data:
                update_data[db_field] = data[flutter_field]

        # Update the user
        result = users_collection.update_one(
            {"email": user_email},
            {"$set": update_data}
        )

        if result.matched_count == 0:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404

        print(f"✅ Profile updated for: {user_email}")
        return jsonify({
            "success": True,
            "message": "Profile updated successfully"
        }), 200

    except Exception as e:
        print(f"❌ Error updating user: {e}")
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500
    # Add this import at the top with other imports
import random

# =============================================================================
# VEHICLES API ENDPOINTS
# =============================================================================

@app.route('/vehicles', methods=['GET'])
def get_vehicles():
    """Get all vehicles for a user"""
    try:
        print("📨 Fetching vehicles...")
        # This will be implemented when your teammates create the backend
        # For now, return sample data
        sample_vehicles = [
            {
                "_id": "1",
                "model": "Mathrdra BE 6",
                "connectorType": "CCS-2",
                "chargerType": "AC Type-2",
                "registrationNumber": "TN5865000",
                "batteryCapacity": "60 kWh",
                "range": "400 km"
            },
            {
                "_id": "2", 
                "model": "Tata Nexon EV",
                "connectorType": "CCS-2",
                "chargerType": "AC Type-2",
                "registrationNumber": "TN1234567",
                "batteryCapacity": "40 kWh",
                "range": "312 km"
            }
        ]
        return jsonify({
            "success": True,
            "data": sample_vehicles
        }), 200
    except Exception as e:
        print(f"❌ Error fetching vehicles: {e}")
        return jsonify({
            "success": False,
            "message": f"Error fetching vehicles: {str(e)}"
        }), 500

@app.route('/vehicles', methods=['POST'])
def add_vehicle():
    """Add a new vehicle"""
    try:
        data = request.get_json()
        print(f"📨 Adding vehicle: {data}")
        
        # Validate required fields
        required_fields = ["model", "connectorType", "chargerType", "registrationNumber"]
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({
                    "success": False,
                    "message": f"Missing required field: {field}"
                }), 400
        
        # This will be implemented when your teammates create the backend
        # For now, return success with mock data
        new_vehicle = {
            "_id": str(random.randint(1000, 9999)),
            "model": data["model"],
            "connectorType": data["connectorType"],
            "chargerType": data["chargerType"],
            "registrationNumber": data["registrationNumber"],
            "batteryCapacity": data.get("batteryCapacity", "N/A"),
            "range": data.get("range", "N/A")
        }
        
        print(f"✅ Vehicle added: {new_vehicle}")
        return jsonify({
            "success": True,
            "message": "Vehicle added successfully",
            "data": new_vehicle
        }), 201
    except Exception as e:
        print(f"❌ Error adding vehicle: {e}")
        return jsonify({
            "success": False,
            "message": f"Error adding vehicle: {str(e)}"
        }), 500

@app.route('/vehicles/<string:vehicle_id>', methods=['PUT'])
def update_vehicle(vehicle_id):
    """Update a vehicle"""
    try:
        data = request.get_json()
        print(f"📨 Updating vehicle {vehicle_id}: {data}")
        
        # This will be implemented when your teammates create the backend
        # For now, return success
        print(f"✅ Vehicle {vehicle_id} updated successfully")
        return jsonify({
            "success": True,
            "message": "Vehicle updated successfully"
        }), 200
    except Exception as e:
        print(f"❌ Error updating vehicle: {e}")
        return jsonify({
            "success": False,
            "message": f"Error updating vehicle: {str(e)}"
        }), 500

@app.route('/vehicles/<string:vehicle_id>', methods=['DELETE'])
def delete_vehicle(vehicle_id):
    """Delete a vehicle"""
    try:
        print(f"📨 Deleting vehicle: {vehicle_id}")
        
        # This will be implemented when your teammates create the backend
        # For now, return success
        print(f"✅ Vehicle {vehicle_id} deleted successfully")
        return jsonify({
            "success": True,
            "message": "Vehicle deleted successfully"
        }), 200
    except Exception as e:
        print(f"❌ Error deleting vehicle: {e}")
        return jsonify({
            "success": False,
            "message": f"Error deleting vehicle: {str(e)}"
        }), 500

# =============================================================================
# VEHICLES TESTER HTML PAGE
# =============================================================================

@app.route('/vehicles-test')
def vehicles_test_page():
    """Serve vehicles testing page"""
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Vehicles API Tester - Osmion EV</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 1000px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                background: white;
                padding: 20px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            h1 {
                color: #2E7D32;
                text-align: center;
            }
            .form-group {
                margin-bottom: 15px;
            }
            label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
                color: #333;
            }
            input, select, textarea {
                width: 100%;
                padding: 10px;
                border: 1px solid #ddd;
                border-radius: 5px;
                font-size: 14px;
            }
            button {
                background-color: #2E7D32;
                color: white;
                padding: 12px 20px;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-size: 16px;
                margin: 5px;
            }
            button:hover {
                background-color: #1B5E20;
            }
            .result {
                margin-top: 20px;
                padding: 15px;
                border-radius: 5px;
                background-color: #e8f5e8;
                border: 1px solid #c8e6c9;
            }
            .error {
                background-color: #ffebee;
                border: 1px solid #ffcdd2;
            }
            .tab {
                display: inline-block;
                padding: 10px 20px;
                cursor: pointer;
                border: 1px solid #ddd;
                border-bottom: none;
                border-radius: 5px 5px 0 0;
                margin-right: 5px;
            }
            .tab.active {
                background-color: #2E7D32;
                color: white;
            }
            .tab-content {
                display: none;
            }
            .tab-content.active {
                display: block;
            }
            .vehicle-card {
                border: 1px solid #ddd;
                border-radius: 5px;
                padding: 15px;
                margin: 10px 0;
                background-color: #f9f9f9;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚗 Vehicles API Tester</h1>
            <p>Test your Vehicles API endpoints</p>

            <div class="tabs">
                <div class="tab active" onclick="showTab('getVehicles')">Get Vehicles</div>
                <div class="tab" onclick="showTab('addVehicle')">Add Vehicle</div>
                <div class="tab" onclick="showTab('manageVehicles')">Manage Vehicles</div>
            </div>

            <!-- GET VEHICLES TAB -->
            <div id="getVehicles" class="tab-content active">
                <h2>Get All Vehicles</h2>
                <button onclick="getVehicles()">Get Vehicles</button>
                <div id="vehiclesList"></div>
            </div>

            <!-- ADD VEHICLE TAB -->
            <div id="addVehicle" class="tab-content">
                <h2>Add New Vehicle</h2>
                <div class="form-group">
                    <label for="model">Model:</label>
                    <input type="text" id="model" value="Mathrdra BE 6">
                </div>
                <div class="form-group">
                    <label for="connectorType">Connector Type:</label>
                    <select id="connectorType">
                        <option value="CCS-2">CCS-2</option>
                        <option value="CHAdeMO">CHAdeMO</option>
                        <option value="Type-2">Type-2</option>
                        <option value="GB/T">GB/T</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="chargerType">Charger Type:</label>
                    <select id="chargerType">
                        <option value="AC Type-2">AC Type-2</option>
                        <option value="DC Fast">DC Fast Charger</option>
                        <option value="AC Slow">AC Slow Charger</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="registrationNumber">Registration Number:</label>
                    <input type="text" id="registrationNumber" value="TN5865000">
                </div>
                <div class="form-group">
                    <label for="batteryCapacity">Battery Capacity (optional):</label>
                    <input type="text" id="batteryCapacity" value="60 kWh">
                </div>
                <div class="form-group">
                    <label for="range">Range (optional):</label>
                    <input type="text" id="range" value="400 km">
                </div>
                <button onclick="addVehicle()">Add Vehicle</button>
            </div>

            <!-- MANAGE VEHICLES TAB -->
            <div id="manageVehicles" class="tab-content">
                <h2>Manage Vehicles</h2>
                <p>Select a vehicle to manage:</p>
                <div id="manageVehiclesList"></div>
            </div>

            <div id="result" class="result"></div>
        </div>

        <script>
            const API_BASE = 'http://127.0.0.1:5001';
            
            function showTab(tabName) {
                document.querySelectorAll('.tab-content').forEach(tab => {
                    tab.classList.remove('active');
                });
                document.querySelectorAll('.tab').forEach(tab => {
                    tab.classList.remove('active');
                });
                
                document.getElementById(tabName).classList.add('active');
                document.querySelector(`.tab[onclick="showTab('${tabName}')"]`).classList.add('active');
                
                if (tabName === 'getVehicles') {
                    getVehicles();
                } else if (tabName === 'manageVehicles') {
                    loadVehiclesForManagement();
                }
            }

            function getVehicles() {
                fetch(`${API_BASE}/vehicles`)
                .then(response => response.json())
                .then(data => {
                    displayVehicles(data);
                    showResult('✅ Vehicles retrieved:', data);
                })
                .catch(error => {
                    showResult('❌ Error fetching vehicles:', error, true);
                });
            }

            function displayVehicles(data) {
                const vehiclesList = document.getElementById('vehiclesList');
                if (data.success && data.data && data.data.length > 0) {
                    vehiclesList.innerHTML = '<h3>Vehicles:</h3>';
                    data.data.forEach(vehicle => {
                        vehiclesList.innerHTML += `
                            <div class="vehicle-card">
                                <strong>${vehicle.model}</strong><br>
                                Connector: ${vehicle.connectorType}<br>
                                Charger: ${vehicle.chargerType}<br>
                                Reg: ${vehicle.registrationNumber}<br>
                                Battery: ${vehicle.batteryCapacity || 'N/A'}<br>
                                Range: ${vehicle.range || 'N/A'}
                            </div>
                        `;
                    });
                } else {
                    vehiclesList.innerHTML = '<p>No vehicles found</p>';
                }
            }

            function addVehicle() {
                const vehicleData = {
                    model: document.getElementById('model').value,
                    connectorType: document.getElementById('connectorType').value,
                    chargerType: document.getElementById('chargerType').value,
                    registrationNumber: document.getElementById('registrationNumber').value,
                    batteryCapacity: document.getElementById('batteryCapacity').value,
                    range: document.getElementById('range').value
                };

                fetch(`${API_BASE}/vehicles`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(vehicleData)
                })
                .then(response => response.json())
                .then(data => {
                    showResult('✅ Vehicle added:', data);
                    // Refresh vehicles list
                    if (document.getElementById('getVehicles').classList.contains('active')) {
                        getVehicles();
                    }
                })
                .catch(error => {
                    showResult('❌ Error adding vehicle:', error, true);
                });
            }

            function loadVehiclesForManagement() {
                fetch(`${API_BASE}/vehicles`)
                .then(response => response.json())
                .then(data => {
                    const manageList = document.getElementById('manageVehiclesList');
                    if (data.success && data.data && data.data.length > 0) {
                        manageList.innerHTML = '';
                        data.data.forEach(vehicle => {
                            manageList.innerHTML += `
                                <div class="vehicle-card">
                                    <strong>${vehicle.model}</strong> (${vehicle.registrationNumber})
                                    <button onclick="editVehicle('${vehicle._id}')">Edit</button>
                                    <button onclick="deleteVehicle('${vehicle._id}')" style="background-color: #f44336;">Delete</button>
                                </div>
                            `;
                        });
                    } else {
                        manageList.innerHTML = '<p>No vehicles found</p>';
                    }
                })
                .catch(error => {
                    showResult('❌ Error loading vehicles:', error, true);
                });
            }

            function editVehicle(vehicleId) {
                showResult('ℹ️ Edit feature will be implemented when backend is ready', {vehicleId});
            }

            function deleteVehicle(vehicleId) {
                if (confirm('Are you sure you want to delete this vehicle?')) {
                    fetch(`${API_BASE}/vehicles/${vehicleId}`, {
                        method: 'DELETE'
                    })
                    .then(response => response.json())
                    .then(data => {
                        showResult('✅ Vehicle deleted:', data);
                        loadVehiclesForManagement();
                    })
                    .catch(error => {
                        showResult('❌ Error deleting vehicle:', error, true);
                    });
                }
            }

            function showResult(message, data, isError = false) {
                const resultDiv = document.getElementById('result');
                resultDiv.innerHTML = `
                    <strong>${message}</strong><br><br>
                    <pre>${JSON.stringify(data, null, 2)}</pre>
                `;
                resultDiv.className = isError ? 'result error' : 'result';
            }

            // Load vehicles on page load
            getVehicles();
        </script>
    </body>
    </html>
    """

if __name__ == '__main__':
    print("🚀 Starting Flask server on http://localhost:5001")
    print("📞 Your Flutter app will connect to this server")
    print("💾 Data will be saved to MongoDB: osmion_ev.user_profile")
    print("🌐 Test pages available at:")
    print("   - User API: http://localhost:5001/test")
    print("   - Vehicles API: http://localhost:5001/vehicles-test")
    app.run(debug=True, host='0.0.0.0', port=5001)