"use strict";

const http = require("http");
const crypto = require("crypto");
const { spawn } = require("child_process");

const MANAGER_PORT = numberEnv("PORT", 8080);
const ROOM_HOST = process.env.ROOM_HOST || "72.61.217.238";
const ROOM_PORT_START = numberEnv("ROOM_PORT_START", 4522);
const ROOM_PORT_END = numberEnv("ROOM_PORT_END", 4599);
const GODOT_BIN = process.env.GODOT_BIN || "/opt/godot/Godot_v4.7-stable_linux.x86_64";
const PROJECT_PATH = process.env.PROJECT_PATH || "/opt/ruptura/Ruptura_Temporal-Godot-Mobile";
const ROOM_IDLE_MS = numberEnv("ROOM_IDLE_MS", 15 * 60 * 1000);
const WARM_STANDBY_ROOMS = numberEnv("WARM_STANDBY_ROOMS", 1);
const WARM_STANDBY_REFILL_MS = numberEnv("WARM_STANDBY_REFILL_MS", 1500);
const MAX_PLAYERS = 2;

const rooms = new Map();
let warmRefillTimer = null;

function numberEnv(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(body)
  });
  res.end(body);
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 16 * 1024) {
        reject(new Error("payload too large"));
        req.destroy();
      }
    });
    req.on("end", () => {
      if (!body) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

function roomPublic(room) {
  return {
    code: room.code,
    host: ROOM_HOST,
    port: room.port,
    players: room.players,
    maxPlayers: MAX_PLAYERS,
    createdAt: room.createdAt
  };
}

function allocatePort() {
  const used = new Set(Array.from(rooms.values()).map((room) => room.port));
  for (let port = ROOM_PORT_START; port <= ROOM_PORT_END; port += 1) {
    if (!used.has(port)) {
      return port;
    }
  }
  return 0;
}

function createCode() {
  return crypto.randomBytes(3).toString("hex").toUpperCase();
}

function startRoom(ownerName, options = {}) {
  const standby = Boolean(options.standby);
  const port = allocatePort();
  if (!port) {
    throw new Error("no room ports available");
  }

  let code = createCode();
  while (rooms.has(code)) {
    code = createCode();
  }

  const args = [
    "--headless",
    "--path",
    PROJECT_PATH,
    "--",
    "--dedicated-server",
    `--room-code=${code}`,
    `--port=${port}`
  ];
  if (standby) {
    args.push("--warm-standby");
  }
  const child = spawn(GODOT_BIN, args, {
    cwd: PROJECT_PATH,
    stdio: ["ignore", "pipe", "pipe"]
  });

  const room = {
    code,
    port,
    ownerName: standby ? "" : (ownerName || "host"),
    players: standby ? 0 : 1,
    standby,
    createdAt: Date.now(),
    lastSeen: Date.now(),
    child,
    idleTimer: null,
    stopping: false
  };
  rooms.set(code, room);

  child.stdout.on("data", (chunk) => process.stdout.write(`[${code}] ${chunk}`));
  child.stderr.on("data", (chunk) => process.stderr.write(`[${code}] ${chunk}`));
  child.on("exit", (status, signal) => {
    clearTimeout(room.idleTimer);
    rooms.delete(code);
    console.log(`room ${code}${room.standby ? " standby" : ""} exited status=${status} signal=${signal}`);
    if (room.standby && !room.stopping) {
      scheduleWarmStandbyRefill();
    }
  });

  if (!standby) {
    scheduleRoomStop(room);
  }
  console.log(`room ${code}${standby ? " warmed" : " started"} on ${ROOM_HOST}:${port}`);
  return room;
}

function scheduleRoomStop(room) {
  clearTimeout(room.idleTimer);
  room.idleTimer = setTimeout(() => {
    stopRoom(room.code, "idle timeout");
  }, ROOM_IDLE_MS);
}

function stopRoom(code, reason) {
  const room = rooms.get(code);
  if (!room) {
    return false;
  }
  console.log(`stopping room ${code}: ${reason}`);
  room.stopping = true;
  clearTimeout(room.idleTimer);
  rooms.delete(code);
  let exited = false;
  room.child.once("exit", () => {
    exited = true;
  });
  room.child.kill("SIGTERM");
  setTimeout(() => {
    if (!exited) {
      room.child.kill("SIGKILL");
    }
  }, 5000).unref();
  return true;
}

function warmStandbyRooms() {
  return Array.from(rooms.values()).filter((room) => room.standby && room.players === 0);
}

function activeRooms() {
  return Array.from(rooms.values()).filter((room) => !room.standby);
}

function scheduleWarmStandbyRefill() {
  if (WARM_STANDBY_ROOMS <= 0 || warmRefillTimer) {
    return;
  }
  warmRefillTimer = setTimeout(() => {
    warmRefillTimer = null;
    ensureWarmStandby();
  }, WARM_STANDBY_REFILL_MS);
  warmRefillTimer.unref();
}

function ensureWarmStandby() {
  if (WARM_STANDBY_ROOMS <= 0) {
    return;
  }
  let missing = WARM_STANDBY_ROOMS - warmStandbyRooms().length;
  while (missing > 0) {
    try {
      startRoom("", { standby: true });
    } catch (error) {
      console.error(`failed to warm standby room: ${error.message}`);
      break;
    }
    missing -= 1;
  }
}

function claimWarmStandby(ownerName) {
  const room = warmStandbyRooms().sort((left, right) => left.createdAt - right.createdAt)[0];
  if (!room) {
    return null;
  }
  room.standby = false;
  room.ownerName = ownerName || "host";
  room.players = 1;
  room.createdAt = Date.now();
  room.lastSeen = Date.now();
  scheduleRoomStop(room);
  console.log(`room ${room.code} claimed from warm standby by ${room.ownerName}`);
  scheduleWarmStandbyRefill();
  return room;
}

function availableRoom() {
  const candidates = activeRooms()
    .filter((room) => room.players < MAX_PLAYERS)
    .sort((left, right) => right.createdAt - left.createdAt);
  if (candidates.length === 0) {
    return null;
  }
  return reserveRoom(candidates[0]);
}

function listAvailableRooms() {
  return activeRooms()
    .filter((room) => room.players < MAX_PLAYERS)
    .sort((left, right) => right.createdAt - left.createdAt)
    .map(roomPublic);
}

function reserveRoom(room) {
  if (!room || room.players >= MAX_PLAYERS) {
    return null;
  }
  room.players += 1;
  room.lastSeen = Date.now();
  scheduleRoomStop(room);
  return room;
}

function roomByCode(code) {
  return rooms.get(String(code || "").toUpperCase()) || null;
}

async function route(req, res) {
  if (req.method === "OPTIONS") {
    sendJson(res, 204, {});
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "GET" && url.pathname === "/health") {
    sendJson(res, 200, { ok: true, rooms: activeRooms().length, standby: warmStandbyRooms().length });
    return;
  }

  if (req.method === "POST" && url.pathname === "/rooms") {
    const payload = await readJson(req);
    const ownerName = String(payload.name || "host");
    const room = claimWarmStandby(ownerName) || startRoom(ownerName);
    sendJson(res, 201, roomPublic(room));
    return;
  }

  if (req.method === "GET" && url.pathname === "/rooms") {
    sendJson(res, 200, { rooms: listAvailableRooms() });
    return;
  }

  if (req.method === "GET" && url.pathname === "/rooms/available") {
    const room = availableRoom();
    if (!room) {
      sendJson(res, 404, { error: "no available rooms" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const joinMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})\/join$/);
  if (req.method === "POST" && joinMatch) {
    const room = reserveRoom(roomByCode(joinMatch[1]));
    if (!room) {
      sendJson(res, 404, { error: "room not available" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const getMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})$/);
  if (req.method === "GET" && getMatch) {
    const room = roomByCode(getMatch[1]);
    if (!room) {
      sendJson(res, 404, { error: "room not found" });
      return;
    }
    sendJson(res, 200, roomPublic(room));
    return;
  }

  const deleteMatch = url.pathname.match(/^\/rooms\/([A-F0-9]{6})$/);
  if (req.method === "DELETE" && deleteMatch) {
    const stopped = stopRoom(deleteMatch[1], "delete request");
    sendJson(res, stopped ? 200 : 404, { stopped });
    scheduleWarmStandbyRefill();
    return;
  }

  sendJson(res, 404, { error: "not found" });
}

const server = http.createServer((req, res) => {
  route(req, res).catch((error) => {
    console.error(error);
    sendJson(res, 500, { error: error.message });
  });
});

server.listen(MANAGER_PORT, "0.0.0.0", () => {
  console.log(`ruptura relay manager listening on :${MANAGER_PORT}`);
  console.log(`rooms will advertise ${ROOM_HOST}:${ROOM_PORT_START}-${ROOM_PORT_END}`);
  ensureWarmStandby();
});
