"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var electron_1 = require("electron");
var path_1 = require("path");
// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) {
    electron_1.app.quit();
}
var mainWindow = null;
var createWindow = function() {
    var _a = electron_1.screen.getPrimaryDisplay().workAreaSize,
        width = _a.width,
        height = _a.height;
    // Create the browser window.
    mainWindow = new electron_1.BrowserWindow({
        width: 600, // Initial width
        height: height, // Full height
        x: 0,
        y: 0,
        frame: false, // No title bar
        transparent: true, // Transparent background
        alwaysOnTop: true, // Float on top
        webPreferences: {
            preload: path_1.default.join(__dirname, 'preload.js'),
            nodeIntegration: true,
            contextIsolation: false, // For easier dev, can tighten later
        },
    });
    // Load the index.html of the app.
    if (process.env.NODE_ENV === 'development') {
        mainWindow.loadURL('http://localhost:5173');
    } else {
        mainWindow.loadFile(path_1.default.join(__dirname, '../dist/index.html'));
    }
    // Open the DevTools.
    // mainWindow.webContents.openDevTools();
};
// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
electron_1.app.on('ready', createWindow);
// Quit when all windows are closed, except on macOS.
electron_1.app.on('window-all-closed', function() {
    if (process.platform !== 'darwin') {
        electron_1.app.quit();
    }
});
electron_1.app.on('activate', function() {
    if (electron_1.BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});