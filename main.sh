#!/bin/bash

# Set variables
PROJECT_NAME="car-dealer-pos-software"
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"
DATABASE="PostgreSQL"
FIREBASE_PROJECT_ID="your-firebase-project-id"
FIREBASE_EMAIL="allyelvis6569@gmail.com"
FIREBASE_TOKEN="your-firebase-token"

# Function to check if command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1 ;
}

# Step 1: Create the project directory structure
echo "Creating project directories..."
mkdir -p ~/${PROJECT_NAME}/{${FRONTEND_DIR},${BACKEND_DIR},database}

#################### FRONTEND ########################

# Step 2: Initialize frontend (React)
echo "Setting up frontend (React)..."
cd ~/${PROJECT_NAME}/${FRONTEND_DIR}
npx create-react-app .
npm install react-router-dom axios

# Create React Components for Car Dealer and POS Management
mkdir -p src/components/{Inventory,Customers,Sales,POS}
cd src/components

# Create Car Inventory Management Component
cat <<EOL > Inventory/CarInventory.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const CarInventory = () => {
    const [cars, setCars] = useState([]);

    useEffect(() => {
        fetchCars();
    }, []);

    const fetchCars = async () => {
        const res = await axios.get('/api/cars');
        setCars(res.data);
    };

    return (
        <div>
            <h2>Car Inventory</h2>
            <table>
                <thead>
                    <tr>
                        <th>Make</th>
                        <th>Model</th>
                        <th>Year</th>
                        <th>Price</th>
                    </tr>
                </thead>
                <tbody>
                    {cars.map(car => (
                        <tr key={car._id}>
                            <td>{car.make}</td>
                            <td>{car.model}</td>
                            <td>{car.year}</td>
                            <td>{car.price}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default CarInventory;
EOL

# Create Customer Management Component
cat <<EOL > Customers/CustomerManagement.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const CustomerManagement = () => {
    const [customers, setCustomers] = useState([]);

    useEffect(() => {
        fetchCustomers();
    }, []);

    const fetchCustomers = async () => {
        const res = await axios.get('/api/customers');
        setCustomers(res.data);
    };

    return (
        <div>
            <h2>Customer Management</h2>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                    </tr>
                </thead>
                <tbody>
                    {customers.map(customer => (
                        <tr key={customer._id}>
                            <td>{customer.name}</td>
                            <td>{customer.email}</td>
                            <td>{customer.phone}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default CustomerManagement;
EOL

# Create POS Component for Transactions
cat <<EOL > POS/PointOfSale.js
import React, { useState } from 'react';
import axios from 'axios';

const PointOfSale = () => {
    const [items, setItems] = useState([]);
    const [total, setTotal] = useState(0);

    const handleAddItem = async (carId) => {
        const res = await axios.get(\`/api/cars/\${carId}\`);
        const car = res.data;
        setItems([...items, car]);
        setTotal(total + car.price);
    };

    const handleCheckout = async () => {
        await axios.post('/api/sales', { items, total });
        alert('Transaction completed!');
    };

    return (
        <div>
            <h2>Point of Sale</h2>
            <button onClick={() => handleAddItem('car-id')}>Add Item</button>
            <div>
                <h3>Cart</h3>
                <ul>
                    {items.map((item, index) => (
                        <li key={index}>{item.make} - {item.price}</li>
                    ))}
                </ul>
                <h3>Total: {total}</h3>
                <button onClick={handleCheckout}>Checkout</button>
            </div>
        </div>
    );
};

export default PointOfSale;
EOL

#################### BACKEND ########################

# Step 3: Initialize backend (Node.js with Express)
echo "Setting up backend (Node.js)..."
cd ~/${PROJECT_NAME}/${BACKEND_DIR}
npm init -y
npm install express mongoose body-parser cors

# Create basic Express server file with APIs
cat <<EOL > server.js
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const app = express();

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/car_dealer', { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('MongoDB connected...'))
  .catch(err => console.log(err));

app.use(cors());
app.use(bodyParser.json());

// Car Schema
const Car = mongoose.model('Car', new mongoose.Schema({
    make: String,
    model: String,
    year: Number,
    price: Number,
}));

// Customer Schema
const Customer = mongoose.model('Customer', new mongoose.Schema({
    name: String,
    email: String,
    phone: String,
}));

// Sales Schema
const Sale = mongoose.model('Sale', new mongoose.Schema({
    items: Array,
    total: Number,
    date: { type: Date, default: Date.now },
}));

// API Endpoints

// Cars
app.get('/api/cars', async (req, res) => {
    const cars = await Car.find();
    res.json(cars);
});

app.post('/api/cars', async (req, res) => {
    const car = new Car(req.body);
    await car.save();
    res.json(car);
});

// Customers
app.get('/api/customers', async (req, res) => {
    const customers = await Customer.find();
    res.json(customers);
});

app.post('/api/customers', async (req, res) => {
    const customer = new Customer(req.body);
    await customer.save();
    res.json(customer);
});

// Sales
app.post('/api/sales', async (req, res) => {
    const sale = new Sale(req.body);
    await sale.save();
    res.json(sale);
});

// Start the server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server started on port \${PORT}\`));
EOL

#################### DATABASE ########################

# Step 4: Database setup (PostgreSQL or MongoDB)
echo "Configuring database (MongoDB)..."
cd ~/${PROJECT_NAME}/database
# MongoDB setup already covered by the backend section, no extra PostgreSQL needed

#################### FIREBASE DEPLOYMENT ########################

# Step 5: Firebase setup
echo "Setting up Firebase..."
if ! command_exists firebase ; then
    echo "Firebase CLI not found, installing Firebase CLI..."
    npm install -g firebase-tools
fi

firebase login --email ${FIREBASE_EMAIL} --no-localhost
firebase projects:create ${FIREBASE_PROJECT_ID}
firebase init hosting functions

# Modify Firebase functions for deploying backend API
cd functions
npm install express cors mongoose
cat <<EOL > index.js
const functions = require('firebase-functions');
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

// MongoDB connection (for Firebase)
mongoose.connect(functions.config().mongo.uri, { useNewUrlParser: true, useUnifiedTopology: true });

// Define routes
app.get('/', (req, res) => res.send('Hello from Firebase Functions!'));

// Expose the API as a function
exports.api = functions.https.onRequest(app);
EOL

# Step 6: Build and deploy to Firebase
echo "Building frontend..."
cd ~/${PROJECT_NAME}/${FRONTEND_DIR}
npm run build

echo "Deploying to Firebase..."
cd ~/${PROJECT_NAME}
firebase deploy --only hosting,functions

echo "Project setup complete! Car Dealer and POS Software deployed to Firebase."

# End of Script