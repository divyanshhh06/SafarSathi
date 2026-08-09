/**
 * SafarSathi Backend Master Server (BE-1 + BE-2 + BE-3 Integration)
 * Real-Time Public Transport Tracking Engine for Small Cities
 * Punjab Govt Challenge (IDSVH26003)
 */

require("dotenv").config();
const http = require("http");
const express = require("express");
const { Server } = require("socket.io");
const cors = require("cors");
const helmet = require("helmet");

const redisService = require("./services/redisService");
const initSocketEngine = require("./sockets/socketHandler");

const path = require("path");

const adminRoutes = require("./routes/adminRoutes");
const etaRoutes = require("./routes/etaRoutes");
const gtfsRoutes = require("./routes/gtfsRoutes");
const smsRoutes = require("./routes/smsRoutes");
const crowdRoutes = require("./routes/crowdRoutes");

const app = express();
const server = http.createServer(app);

// Socket.io WebSocket server setup with CORS
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "../public")));

// Root route serving OpenStreetMap simulator dashboard
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

// Diagnostics & Health Endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "UP",
    system: "SafarSathi Backend Engine (BE-1, BE-2, BE-3)",
    timestamp: new Date().toISOString(),
    redisConnected: redisService.isConnected
  });
});

// API Routes Integration
app.use("/api/admin", adminRoutes);
app.use("/api/eta", etaRoutes);
app.use("/api/gtfs", gtfsRoutes);
app.use("/api/sms", smsRoutes);
app.use("/api/crowd", crowdRoutes);

// Global 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "API Endpoint not found." });
});

// Start Server & Redis Engine
const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
  console.log(`=======================================================`);
  console.log(`🚀 SafarSathi Backend Engine Running on Port ${PORT}`);
  console.log(`📡 WebSocket Engine Ready (ws://localhost:${PORT})`);
  console.log(`📍 IDSVH26003: Punjab Govt Public Transport Tracking`);
  console.log(`=======================================================`);

  // Initialize Redis Spatial Geo-Cache Layer (BE-1)
  await redisService.initRedis();

  // Initialize Socket.io Handling
  initSocketEngine(io);
});

module.exports = { app, server };
