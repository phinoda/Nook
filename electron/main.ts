import { app, BrowserWindow, screen } from 'electron';
import path from 'path';

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
// if (require('electron-squirrel-startup')) {
//     app.quit();
// }

let mainWindow: BrowserWindow | null = null;
let animationInterval: NodeJS.Timeout | null = null;
let pollingInterval: NodeJS.Timeout | null = null;

const WINDOW_WIDTH = 400;
const ANIMATION_DURATION = 200; // ms
const ANIMATION_STEPS = 20;
const TRIGGER_ZONE_WIDTH = 20;
const POLLING_INTERVAL_MS = 100;

const startMousePolling = () => {
    pollingInterval = setInterval(() => {
        const point = screen.getCursorScreenPoint();
        const primaryDisplay = screen.getPrimaryDisplay();
        const { width, x } = primaryDisplay.bounds; // Use bounds for full edge detection

        // Calculate the actual right edge coordinate (usually x + width)
        const rightEdge = x + width;

        // If mouse is in the trigger zone (right edge of primary display)
        // AND strictly on the primary display (not on the secondary monitor to the right)
        if (point.x >= rightEdge - TRIGGER_ZONE_WIDTH && point.x < rightEdge) {
            if (mainWindow && !mainWindow.isVisible()) {
                showMainWindow();
            }
        }
    }, POLLING_INTERVAL_MS);
};

const showMainWindow = () => {
    if (!mainWindow) return;
    const { width } = screen.getPrimaryDisplay().bounds;
    const targetX = width - WINDOW_WIDTH;

    mainWindow.show();
    animateWindow(targetX);
};

const hideMainWindow = () => {
    if (!mainWindow) return;
    const { width } = screen.getPrimaryDisplay().bounds;
    const targetX = width;

    animateWindow(targetX, () => {
        if (mainWindow) mainWindow.hide();
    });
};

const animateWindow = (targetX: number, callback?: () => void) => {
    if (!mainWindow) return;
    if (animationInterval) clearInterval(animationInterval);

    const startX = mainWindow.getPosition()[0];
    const distance = targetX - startX;
    const stepSize = distance / ANIMATION_STEPS;
    let currentStep = 0;

    animationInterval = setInterval(() => {
        if (!mainWindow) {
            if (animationInterval) clearInterval(animationInterval);
            return;
        }

        currentStep++;
        const newX = startX + (stepSize * currentStep);
        mainWindow.setPosition(Math.round(newX), 0);

        if (currentStep >= ANIMATION_STEPS) {
            if (animationInterval) clearInterval(animationInterval);
            mainWindow.setPosition(targetX, 0);
            if (callback) callback();
        }
    }, ANIMATION_DURATION / ANIMATION_STEPS);
};

const createWindow = () => {
    const { width, height } = screen.getPrimaryDisplay().bounds;

    // Create the browser window.
    mainWindow = new BrowserWindow({
        width: WINDOW_WIDTH,
        height: height,
        x: width - WINDOW_WIDTH, // Position on right edge (visible)
        y: 0,
        frame: false,
        transparent: false, // Disabled for dev - enable later
        show: true, // Show for dev
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
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
    } else {
        mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
    }

    // Hide when losing focus
    mainWindow.on('blur', () => {
        hideMainWindow();
    });

    startMousePolling();
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', createWindow);

// Quit when all windows are closed, except on macOS.
app.on('window-all-closed', () => {
    if (pollingInterval) clearInterval(pollingInterval);
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});
