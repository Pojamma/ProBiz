const express = require('express');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Serve static files
app.use(express.static(path.join(__dirname, '..', 'websites')));

// API endpoint to provide Google Maps API key
app.get('/api/maps-key', (req, res) => {
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    
    if (!apiKey) {
        console.error('GOOGLE_MAPS_API_KEY environment variable is not set');
        return res.status(500).json({ 
            error: 'Google Maps API key not configured' 
        });
    }
    
    res.json({ apiKey });
});

// Serve the main SunCalc page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'websites', 'suncalc', 'suncalc.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        hasApiKey: !!process.env.GOOGLE_MAPS_API_KEY
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
    console.log(`SunCalc server running on http://localhost:${PORT}`);
    console.log(`Google Maps API key configured: ${!!process.env.GOOGLE_MAPS_API_KEY}`);
});