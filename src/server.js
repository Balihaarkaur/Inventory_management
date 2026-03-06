const express = require('express');
const cors = require('cors');
require('dotenv').config();

const pool = require('./db');
const userRoutes = require('./routes/userRoutes');
const hardwareRoutes = require('./routes/hardwareRoutes');
const historyRoutes = require('./routes/historyRoutes');
const scannerRoutes = require('./routes/scannerRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.url}`);
  console.log("Body:", req.body);
  next();
});

app.use(cors());
app.use(express.json());

app.use('/api/users', userRoutes);
app.use('/api/hardware', hardwareRoutes);
app.use('/api/history', historyRoutes);
app.use('/api/scanner', scannerRoutes);

app.use(errorHandler);

pool.connect()
    .then(() => {
        console.log('Database connected successfully');
        app.listen(PORT, "0.0.0.0", () => {
            console.log(`Server is running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection failed:', err.message);
        process.exit(1);
    });
