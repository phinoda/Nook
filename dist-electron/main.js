"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const electron_1 = require("electron");
const path_1 = __importDefault(require("path"));
// Handle creating/removing shortcuts on Windows when installing/uninstalling.
// if (require('electron-squirrel-startup')) {
//     app.quit();
// }
let mainWindow = null;
let animationInterval = null;
let pollingInterval = null;
const WINDOW_WIDTH = 400;
const ANIMATION_DURATION = 200; // ms
const ANIMATION_STEPS = 20;
const TRIGGER_ZONE_WIDTH = 10;
const POLLING_INTERVAL_MS = 100;
const startMousePolling = () => {
    pollingInterval = setInterval(() => {
        const point = electron_1.screen.getCursorScreenPoint();
        const { width } = electron_1.screen.getPrimaryDisplay().workAreaSize;
        // If mouse is in the trigger zone (right edge)
        if (point.x >= width - TRIGGER_ZONE_WIDTH) {
            showMainWindow();
        }
    }, POLLING_INTERVAL_MS);
};
const showMainWindow = () => {
    if (!mainWindow)
        return;
    const { width } = electron_1.screen.getPrimaryDisplay().workAreaSize;
    const targetX = width - WINDOW_WIDTH;
    mainWindow.show();
    animateWindow(targetX);
};
const hideMainWindow = () => {
    if (!mainWindow)
        return;
    const { width } = electron_1.screen.getPrimaryDisplay().workAreaSize;
    const targetX = width;
    animateWindow(targetX, () => {
        if (mainWindow)
            mainWindow.hide();
    });
};
const animateWindow = (targetX, callback) => {
    if (!mainWindow)
        return;
    if (animationInterval)
        clearInterval(animationInterval);
    const startX = mainWindow.getPosition()[0];
    const distance = targetX - startX;
    const stepSize = distance / ANIMATION_STEPS;
    let currentStep = 0;
    animationInterval = setInterval(() => {
        if (!mainWindow) {
            if (animationInterval)
                clearInterval(animationInterval);
            return;
        }
        currentStep++;
        const newX = startX + (stepSize * currentStep);
        mainWindow.setPosition(Math.round(newX), 0);
        if (currentStep >= ANIMATION_STEPS) {
            if (animationInterval)
                clearInterval(animationInterval);
            mainWindow.setPosition(targetX, 0);
            if (callback)
                callback();
        }
    }, ANIMATION_DURATION / ANIMATION_STEPS);
};
const createWindow = () => {
    const { width, height } = electron_1.screen.getPrimaryDisplay().workAreaSize;
    // Create the browser window.
    mainWindow = new electron_1.BrowserWindow({
        width: WINDOW_WIDTH,
        height: height,
        x: width - WINDOW_WIDTH, // Position on right edge (visible)
        y: 0,
        frame: false,
        transparent: false, // Disabled for dev - enable later
        show: true, // Show for dev
        webPreferences: {
            preload: path_1.default.join(__dirname, 'preload.js'),
            nodeIntegration: true,
            contextIsolation: false,
        },
    });
    // robust window configuration for "always on top" behavior across workspaces
    mainWindow.setAlwaysOnTop(true, 'floating');
    mainWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
    mainWindow.setFullScreenable(false);
    // Load the index.html of the app.
    if (process.env.NODE_ENV === 'development') {
        mainWindow.loadURL('http://localhost:5173');
        mainWindow.webContents.openDevTools();
    }
    else {
        mainWindow.loadFile(path_1.default.join(__dirname, '../dist/index.html'));
    }
    // Hide when losing focus
    mainWindow.on('blur', () => {
        hideMainWindow();
    });
    startMousePolling();
};
// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
electron_1.app.on('ready', createWindow);
// Quit when all windows are closed, except on macOS.
electron_1.app.on('window-all-closed', () => {
    if (pollingInterval)
        clearInterval(pollingInterval);
    if (process.platform !== 'darwin') {
        electron_1.app.quit();
    }
});
electron_1.app.on('activate', () => {
    if (electron_1.BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});
//# sourceMappingURL=main.js.map