/**
 * MI Tablet - JavaScript Controller
 * Handles NUI communication, app management, and UI interactions
 */

// ============================================
// Configuration & State
// ============================================

const TabletState = {
    isOpen: false,
    currentScreen: 'home',
    currentApp: null,
    settings: {
        wallpaper: 'default',
        customWallpaper: '',
        brightness: 100,
        volume: 50,
        notifications: true,
        darkMode: false,
        fontSize: 'medium'
    },
    apps: [],
    wallpapers: [],
    playerData: null,
    notes: [],
    isDarkwebMode: false
};

// Get resource name helper
if (window.GetCurrentResourceName === undefined) {
    window.GetCurrentResourceName = () => {
        return window.location.hostname.replace('cfx-nui-', '') || 'mi-tablet';
    };
}

// ============================================
// NUI Communication
// ============================================

/**
 * Send data to the Lua client
 */
async function nuiCallback(event, data = {}) {
    try {
        const response = await fetch(`https://${GetCurrentResourceName()}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (error) {
        console.error(`[MI Tablet] NUI Callback Error (${event}):`, error);
        return null;
    }
}

/**
 * Close the tablet
 */
function closeTablet() {
    nuiCallback('close');
    hideTablet();
}

// ============================================
// UI Management
// ============================================

/**
 * Show the tablet UI
 */
function showTablet() {
    const container = document.getElementById('tablet-container');
    
    // Remove hidden class and add visible class
    container.classList.remove('hidden');
    
    // Force a reflow to ensure the transition works
    container.offsetHeight;
    
    // Add visible class to trigger fade in
    container.classList.add('visible');
    
    TabletState.isOpen = true;
    console.log('[MI Tablet] Tablet UI shown');
    updateTime();
    startTimeUpdater();
}

/**
 * Hide the tablet UI
 */
function hideTablet() {
    const container = document.getElementById('tablet-container');
    container.classList.remove('visible');
    
    // Stop any active polling
    stopTerritoriesLocationPolling();
    
    TabletState.isOpen = false;
    stopTimeUpdater();
    console.log('[MI Tablet] Tablet UI hidden');
}

/**
 * Switch between screens
 */
function switchScreen(screenId) {
    // Cleanup any active app intervals/listeners before switching
    if (TabletState.currentApp === 'events') {
        cleanupPlayerEvents();
    }
    
    const screens = document.querySelectorAll('.screen');
    screens.forEach(screen => {
        screen.classList.remove('active');
        screen.classList.add('hidden');
    });
    
    const targetScreen = document.getElementById(`${screenId}-screen`);
    if (targetScreen) {
        targetScreen.classList.remove('hidden');
        targetScreen.classList.add('active');
        TabletState.currentScreen = screenId;
    }
}

/**
 * Navigate to home screen
 */
function goHome() {
    // Stop territories polling if active
    stopTerritoriesLocationPolling();
    
    // Remove darkweb app styling if present
    document.getElementById('app-screen').classList.remove('darkweb-app-mode');
    
    // Send close callback BEFORE nulling currentApp
    const closingApp = TabletState.currentApp;
    nuiCallback('appClosed', { appId: closingApp });
    
    switchScreen('home');
    TabletState.currentApp = null;
}

// ============================================
// Time & Date Management
// ============================================

let timeUpdaterInterval = null;

function updateTime() {
    nuiCallback('getTime').then(data => {
        if (data) {
            document.getElementById('current-time').textContent = data.formatted;
            
            const lockTime = document.getElementById('lock-time');
            if (lockTime) lockTime.textContent = data.formatted;
        }
    });
    
    // Update date
    const now = new Date();
    const options = { weekday: 'long', month: 'long', day: 'numeric' };
    const dateStr = now.toLocaleDateString('en-US', options);
    
    document.getElementById('current-date').textContent = dateStr;
    
    const lockDate = document.getElementById('lock-date');
    if (lockDate) lockDate.textContent = dateStr;
}

function startTimeUpdater() {
    if (timeUpdaterInterval) clearInterval(timeUpdaterInterval);
    timeUpdaterInterval = setInterval(updateTime, 30000); // Update every 30 seconds
}

function stopTimeUpdater() {
    if (timeUpdaterInterval) {
        clearInterval(timeUpdaterInterval);
        timeUpdaterInterval = null;
    }
}

// ============================================
// App Management
// ============================================

/**
 * Initialize apps on the home screen
 */
function initializeApps(apps) {
    TabletState.apps = apps;
    const appGrid = document.getElementById('app-grid');
    const dock = document.getElementById('dock');
    
    appGrid.innerHTML = '';
    dock.innerHTML = '';
    
    // Define dock apps
    const dockApps = ['browser', 'notes', 'settings'];
    
    apps.forEach(app => {
        if (!app.enabled) return;
        
        const appElement = createAppIcon(app);
        
        if (dockApps.includes(app.id)) {
            dock.appendChild(appElement.cloneNode(true));
        } else if (app.id !== 'home') {
            appGrid.appendChild(appElement);
        }
    });
    
    // Re-attach event listeners
    attachAppClickListeners();
}

/**
 * Create an app icon element
 */
function createAppIcon(app) {
    const iconMapping = {
        'home': 'fa-home',
        'settings': 'fa-cog',
        'browser': 'fa-globe',
        'notes': 'fa-sticky-note',
        'calculator': 'fa-calculator',
        'weather': 'fa-cloud-sun',
        'camera': 'fa-camera',
        'gallery': 'fa-images',
        'rep': 'fa-chart-line',
        'banking': 'fa-building-columns',
        'crypto': 'fa-microchip',
        'admins': 'fa-user-shield',
        'events': 'fa-crown',
        'mechanic': 'fa-wrench',
        'bills': 'fa-file-invoice-dollar'
    };
    
    const appDiv = document.createElement('div');
    appDiv.className = 'app-icon';
    appDiv.dataset.appId = app.id;
    
    appDiv.innerHTML = `
        <div class="app-icon-wrapper">
            <i class="fas ${iconMapping[app.id] || 'fa-' + app.icon}"></i>
        </div>
        <span class="app-name">${app.name}</span>
    `;
    
    return appDiv;
}

/**
 * Attach click listeners to app icons
 */
function attachAppClickListeners() {
    document.querySelectorAll('.app-icon').forEach(icon => {
        icon.addEventListener('click', () => {
            const appId = icon.dataset.appId;
            openApp(appId);
        });
    });
}

/**
 * Open an app
 */
function openApp(appId) {
    TabletState.currentApp = appId;
    nuiCallback('appOpened', { appId });
    
    switch (appId) {
        case 'settings':
            openSettings();
            break;
        case 'calculator':
            openCalculator();
            break;
        case 'notes':
            openNotes();
            break;
        case 'weather':
            openWeather();
            break;
        case 'browser':
            openBrowser();
            break;
        case 'camera':
            openCamera();
            break;
        case 'gallery':
            openGallery();
            break;
        case 'rep':
            openRep();
            break;
        case 'banking':
            openBanking();
            break;
        case 'crypto':
            openCrypto();
            break;
        case 'admins':
            openAdmins();
            break;
        case 'casino':
            openCasino();
            break;
        case 'events':
            openPlayerEvents();
            break;
        case 'maps':
            openMaps();
            break;
        case 'mechanic':
            openMechanic();
            break;
        case 'bills':
            openBills();
            break;
        default:
            openGenericApp(appId);
    }
}

/**
 * Open a generic app (placeholder)
 */
function openGenericApp(appId) {
    const app = TabletState.apps.find(a => a.id === appId);
    if (!app) return;
    
    document.getElementById('app-title').textContent = app.name;
    document.getElementById('app-content').innerHTML = `
        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; text-align: center; color: var(--text-tertiary);">
            <i class="fas fa-${app.icon}" style="font-size: 64px; margin-bottom: 20px; opacity: 0.5;"></i>
            <h2 style="margin-bottom: 8px; color: var(--text-secondary);">${app.name}</h2>
            <p>This app is coming soon!</p>
        </div>
    `;
    
    switchScreen('app');
}

// ============================================
// Settings App
// ============================================

function openSettings() {
    switchScreen('settings');
    loadSettingsValues();
}

function loadSettingsValues() {
    // Load current settings into form
    document.getElementById('setting-wallpaper').value = TabletState.settings.wallpaper;
    document.getElementById('setting-brightness').value = TabletState.settings.brightness;
    document.getElementById('setting-darkmode').checked = TabletState.settings.darkMode;
    document.getElementById('setting-volume').value = TabletState.settings.volume;
    document.getElementById('setting-notifications').checked = TabletState.settings.notifications;
    document.getElementById('setting-fontsize').value = TabletState.settings.fontSize;
    
    // Handle custom wallpaper input
    const customContainer = document.getElementById('custom-wallpaper-container');
    const customInput = document.getElementById('setting-custom-wallpaper');
    if (TabletState.settings.wallpaper === 'custom') {
        customContainer.style.display = 'flex';
        customInput.value = TabletState.settings.customWallpaper || '';
    } else {
        customContainer.style.display = 'none';
    }
    
    // Update owner name
    if (TabletState.playerData) {
        document.getElementById('owner-name').textContent = TabletState.playerData.name;
    }
}

function initializeWallpaperOptions() {
    const select = document.getElementById('setting-wallpaper');
    select.innerHTML = '';
    
    TabletState.wallpapers.forEach(wp => {
        const option = document.createElement('option');
        option.value = wp;
        option.textContent = wp.charAt(0).toUpperCase() + wp.slice(1).replace(/-/g, ' ');
        select.appendChild(option);
    });
    
    // Add custom URL option
    const customOption = document.createElement('option');
    customOption.value = 'custom';
    customOption.textContent = 'Custom URL';
    select.appendChild(customOption);
}

function applySettings() {
    // Apply wallpaper
    const wallpaper = document.getElementById('wallpaper');
    if (TabletState.settings.wallpaper === 'custom' && TabletState.settings.customWallpaper) {
        wallpaper.className = 'wallpaper-custom';
        wallpaper.style.backgroundImage = `url('${TabletState.settings.customWallpaper}')`;
    } else {
        wallpaper.className = `wallpaper-${TabletState.settings.wallpaper}`;
        wallpaper.style.backgroundImage = '';
    }
    
    // Apply brightness
    const brightness = TabletState.settings.brightness;
    document.getElementById('tablet-frame').style.filter = `brightness(${brightness}%)`;
    
    // Apply dark mode
    if (TabletState.settings.darkMode) {
        document.getElementById('tablet-frame').classList.add('dark-mode');
    } else {
        document.getElementById('tablet-frame').classList.remove('dark-mode');
    }
    
    // Apply font size
    const frame = document.getElementById('tablet-frame');
    frame.classList.remove('font-small', 'font-medium', 'font-large');
    frame.classList.add(`font-${TabletState.settings.fontSize}`);
}

function saveSettings() {
    nuiCallback('saveSettings', { settings: TabletState.settings });
}

// ============================================
// Calculator App
// ============================================

let calcState = {
    current: '0',
    previous: '',
    operation: null,
    history: [],
    mode: 'basic' // 'basic' or 'scientific'
};

function openCalculator() {
    const template = document.getElementById('calculator-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Calculator';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initCalculator();
}

function initCalculator() {
    calcState = { current: '0', previous: '', operation: null, history: [], mode: 'basic' };
    updateCalcDisplay();
    renderCalcHistory();
    
    // Button click handlers
    document.querySelectorAll('.calc-btn').forEach(btn => {
        btn.addEventListener('click', handleCalcClick);
    });
    
    // Mode toggle buttons
    document.querySelectorAll('.calc-mode-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const mode = e.target.dataset.mode;
            calcState.mode = mode;
            document.querySelectorAll('.calc-mode-btn').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            
            // Show/hide scientific buttons
            const sciButtons = document.getElementById('calc-scientific-buttons');
            if (sciButtons) {
                sciButtons.style.display = mode === 'scientific' ? 'grid' : 'none';
            }
        });
    });
    
    // Clear history button
    const clearHistoryBtn = document.querySelector('.calc-history-clear');
    if (clearHistoryBtn) {
        clearHistoryBtn.addEventListener('click', () => {
            calcState.history = [];
            renderCalcHistory();
        });
    }
}

function handleCalcClick(e) {
    const btn = e.target.closest('.calc-btn');
    if (!btn) return;
    
    if (btn.classList.contains('number')) {
        handleNumber(btn.dataset.value);
    } else if (btn.classList.contains('operator')) {
        handleOperator(btn.dataset.action);
    } else if (btn.classList.contains('function')) {
        handleFunction(btn.dataset.action);
    } else if (btn.classList.contains('equals')) {
        calculate();
    } else if (btn.classList.contains('scientific')) {
        handleScientific(btn.dataset.action);
    }
    
    updateCalcDisplay();
}

function handleNumber(num) {
    if (calcState.current === '0' && num !== '.') {
        calcState.current = num;
    } else if (num === '.' && calcState.current.includes('.')) {
        return;
    } else {
        calcState.current += num;
    }
}

function handleOperator(op) {
    if (op === 'equals') {
        calculate();
        return;
    }
    
    if (calcState.previous && calcState.operation) {
        calculate();
    }
    
    calcState.previous = calcState.current;
    calcState.current = '0';
    calcState.operation = op;
}

function handleFunction(fn) {
    switch (fn) {
        case 'clear':
            calcState.current = '0';
            calcState.previous = '';
            calcState.operation = null;
            break;
        case 'plusminus':
            calcState.current = (parseFloat(calcState.current) * -1).toString();
            break;
        case 'percent':
            calcState.current = (parseFloat(calcState.current) / 100).toString();
            break;
    }
}

function handleScientific(fn) {
    const current = parseFloat(calcState.current);
    let result;
    
    switch (fn) {
        case 'sin':
            result = Math.sin(current * Math.PI / 180); // Degrees to radians
            break;
        case 'cos':
            result = Math.cos(current * Math.PI / 180);
            break;
        case 'tan':
            result = Math.tan(current * Math.PI / 180);
            break;
        case 'log':
            result = current > 0 ? Math.log10(current) : 'Error';
            break;
        case 'ln':
            result = current > 0 ? Math.log(current) : 'Error';
            break;
        case 'sqrt':
            result = current >= 0 ? Math.sqrt(current) : 'Error';
            break;
        case 'square':
            result = current * current;
            break;
        case 'power':
            // Set up for power operation (like x^y)
            calcState.previous = calcState.current;
            calcState.current = '0';
            calcState.operation = 'power';
            return;
        case 'pi':
            result = Math.PI;
            break;
        case 'e':
            result = Math.E;
            break;
        default:
            return;
    }
    
    // Round to avoid floating point issues
    if (typeof result === 'number') {
        result = Math.round(result * 1000000000) / 1000000000;
    }
    
    calcState.current = result.toString();
}

function calculate() {
    if (!calcState.operation || !calcState.previous) return;
    
    const prev = parseFloat(calcState.previous);
    const curr = parseFloat(calcState.current);
    const ops = { add: '+', subtract: '−', multiply: '×', divide: '÷', power: '^' };
    let result;
    
    switch (calcState.operation) {
        case 'add':
            result = prev + curr;
            break;
        case 'subtract':
            result = prev - curr;
            break;
        case 'multiply':
            result = prev * curr;
            break;
        case 'divide':
            result = curr !== 0 ? prev / curr : 'Error';
            break;
        case 'power':
            result = Math.pow(prev, curr);
            break;
    }
    
    // Add to history
    const expression = `${prev} ${ops[calcState.operation]} ${curr}`;
    calcState.history.unshift({ expression, result: result.toString() });
    if (calcState.history.length > 20) calcState.history.pop(); // Keep last 20
    renderCalcHistory();
    
    // Highlight result briefly
    const resultEl = document.querySelector('.calc-result');
    if (resultEl) {
        resultEl.classList.add('highlight');
        setTimeout(() => resultEl.classList.remove('highlight'), 300);
    }
    
    calcState.current = result.toString();
    calcState.previous = '';
    calcState.operation = null;
}

function updateCalcDisplay() {
    const resultEl = document.querySelector('.calc-result');
    const expressionEl = document.querySelector('.calc-expression');
    
    if (resultEl) {
        let display = calcState.current;
        if (display.length > 12) {
            display = parseFloat(display).toExponential(6);
        }
        resultEl.textContent = display;
    }
    
    if (expressionEl) {
        const ops = { add: '+', subtract: '−', multiply: '×', divide: '÷' };
        expressionEl.textContent = calcState.previous ? 
            `${calcState.previous} ${ops[calcState.operation] || ''}` : '';
    }
}

function renderCalcHistory() {
    const listEl = document.querySelector('.calc-history-list');
    if (!listEl) return;
    
    if (calcState.history.length === 0) {
        listEl.innerHTML = `
            <div class="calc-history-empty">
                <i class="fas fa-history"></i>
                <span>No history yet</span>
            </div>
        `;
        return;
    }
    
    listEl.innerHTML = calcState.history.map((item, idx) => `
        <div class="calc-history-item" data-index="${idx}">
            <div class="calc-history-expression">${item.expression} =</div>
            <div class="calc-history-result">${item.result}</div>
        </div>
    `).join('');
    
    // Click history item to use that result
    listEl.querySelectorAll('.calc-history-item').forEach(item => {
        item.addEventListener('click', () => {
            const idx = parseInt(item.dataset.index);
            calcState.current = calcState.history[idx].result;
            updateCalcDisplay();
        });
    });
}

// ============================================
// Notes App
// ============================================

let notesState = {
    notes: [],
    activeNote: null
};

function openNotes() {
    const template = document.getElementById('notes-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Notes';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initNotes();
}

function initNotes() {
    // Load notes from localStorage
    const saved = localStorage.getItem('mi-tablet-notes');
    notesState.notes = saved ? JSON.parse(saved) : [];
    
    renderNotesList();
    
    // Event listeners
    document.getElementById('new-note-btn').addEventListener('click', createNewNote);
    document.getElementById('delete-note-btn').addEventListener('click', deleteCurrentNote);
    document.getElementById('note-title').addEventListener('input', saveNoteChanges);
    document.getElementById('note-content').addEventListener('input', saveNoteChanges);
    
    // Select first note if exists
    if (notesState.notes.length > 0) {
        selectNote(notesState.notes[0].id);
    } else {
        createNewNote();
    }
}

function renderNotesList() {
    const list = document.getElementById('notes-list');
    list.innerHTML = '';
    
    if (notesState.notes.length === 0) {
        list.innerHTML = `
            <div class="notes-empty">
                <i class="fas fa-sticky-note"></i>
                <span>No notes yet</span>
            </div>
        `;
        return;
    }
    
    notesState.notes.forEach(note => {
        const noteEl = document.createElement('div');
        noteEl.className = `note-item ${note.id === notesState.activeNote ? 'active' : ''}`;
        noteEl.dataset.noteId = note.id;
        
        const date = new Date(note.updated);
        const dateStr = date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }).toUpperCase();
        
        noteEl.innerHTML = `
            <div class="note-item-title">${note.title || 'Untitled'}</div>
            <div class="note-item-preview">${note.content.substring(0, 40) || 'No content...'}</div>
            <div class="note-item-date">${dateStr}</div>
        `;
        noteEl.addEventListener('click', () => selectNote(note.id));
        list.appendChild(noteEl);
    });
}

function selectNote(noteId) {
    notesState.activeNote = noteId;
    const note = notesState.notes.find(n => n.id === noteId);
    
    if (note) {
        document.getElementById('note-title').value = note.title;
        document.getElementById('note-content').value = note.content;
        
        const date = new Date(note.updated);
        const dateStr = date.toLocaleDateString('en-GB', { 
            day: '2-digit', 
            month: 'short', 
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).toUpperCase();
        document.getElementById('note-date').textContent = `LAST EDITED: ${dateStr}`;
    }
    
    renderNotesList();
}

function createNewNote() {
    const newNote = {
        id: Date.now().toString(),
        title: '',
        content: '',
        created: Date.now(),
        updated: Date.now()
    };
    
    notesState.notes.unshift(newNote);
    saveNotesToStorage();
    selectNote(newNote.id);
}

function saveNoteChanges() {
    const note = notesState.notes.find(n => n.id === notesState.activeNote);
    if (!note) return;
    
    note.title = document.getElementById('note-title').value;
    note.content = document.getElementById('note-content').value;
    note.updated = Date.now();
    
    saveNotesToStorage();
    renderNotesList();
}

function deleteCurrentNote() {
    if (!notesState.activeNote) return;
    
    const index = notesState.notes.findIndex(n => n.id === notesState.activeNote);
    if (index > -1) {
        notesState.notes.splice(index, 1);
        saveNotesToStorage();
        
        if (notesState.notes.length > 0) {
            selectNote(notesState.notes[0].id);
        } else {
            createNewNote();
        }
    }
}

function saveNotesToStorage() {
    localStorage.setItem('mi-tablet-notes', JSON.stringify(notesState.notes));
}

// ============================================
// Weather App
// ============================================

function openWeather() {
    const template = document.getElementById('weather-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Weather';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    loadWeather();
}

function loadWeather() {
    nuiCallback('getWeather').then(data => {
        if (data) {
            updateWeatherUI(data);
        }
    });
}

function updateWeatherUI(data) {
    const iconMap = {
        'Clear': 'fa-sun',
        'Sunny': 'fa-sun',
        'Cloudy': 'fa-cloud',
        'Overcast': 'fa-cloud',
        'Rainy': 'fa-cloud-rain',
        'Rain': 'fa-cloud-rain',
        'Clearing': 'fa-cloud-sun',
        'Partly Cloudy': 'fa-cloud-sun',
        'Thunderstorm': 'fa-bolt',
        'Thunder': 'fa-bolt',
        'Smoggy': 'fa-smog',
        'Foggy': 'fa-smog',
        'Fog': 'fa-smog',
        'Snowy': 'fa-snowflake',
        'Snow': 'fa-snowflake',
        'Light Snow': 'fa-snowflake',
        'Blizzard': 'fa-snowflake'
    };
    
    const moonPhaseIcons = {
        'New Moon': 'fa-moon',
        'Waxing Crescent': 'fa-moon',
        'First Quarter': 'fa-moon',
        'Waxing Gibbous': 'fa-moon',
        'Full Moon': 'fa-circle',
        'Waning Gibbous': 'fa-moon',
        'Last Quarter': 'fa-moon',
        'Waning Crescent': 'fa-moon'
    };
    
    // Main weather icon
    const weatherIcon = document.querySelector('.weather-icon i');
    if (weatherIcon) {
        weatherIcon.className = `fas ${iconMap[data.weather] || 'fa-cloud'}`;
    }
    
    // Temperature
    const weatherTemp = document.querySelector('.weather-temp');
    if (weatherTemp && data.temperature !== undefined) {
        weatherTemp.textContent = `${data.temperature}°C`;
    }
    
    // Feels like
    const feelsLike = document.getElementById('feels-like');
    if (feelsLike) {
        feelsLike.textContent = `${data.feelsLike || data.temperature || 23}°C`;
    }
    
    // Weather description
    const weatherDesc = document.querySelector('.weather-desc');
    if (weatherDesc) {
        weatherDesc.textContent = data.weather || 'Clear';
    }
    
    // Location
    const locationSpan = document.querySelector('.weather-location span');
    if (locationSpan && data.location) {
        locationSpan.textContent = data.location;
    }
    
    // Sunrise
    const sunrise = document.getElementById('sunrise-time');
    if (sunrise) {
        sunrise.textContent = data.sunrise || '06:32';
    }
    
    // Sunset
    const sunset = document.getElementById('sunset-time');
    if (sunset) {
        sunset.textContent = data.sunset || '20:15';
    }
    
    // Moon phase
    const moonPhase = document.getElementById('moon-phase');
    const moonIcon = document.getElementById('moon-icon');
    if (moonPhase) {
        moonPhase.textContent = data.moonPhase || 'Waxing';
    }
    if (moonIcon && data.moonPhase) {
        moonIcon.className = `fas ${moonPhaseIcons[data.moonPhase] || 'fa-moon'}`;
    }
    
    // Wind speed
    const windSpeed = document.getElementById('wind-speed');
    if (windSpeed) {
        windSpeed.textContent = `${data.windSpeed || 12} km/h`;
    }
    
    // Humidity
    const humidity = document.getElementById('humidity');
    if (humidity) {
        humidity.textContent = `${data.humidity || 65}%`;
    }
    
    // Visibility
    const visibility = document.getElementById('visibility');
    if (visibility) {
        visibility.textContent = `${data.visibility || 10} km`;
    }
    
    // UV Index
    const uvIndex = document.getElementById('uv-index');
    if (uvIndex) {
        uvIndex.textContent = data.uvIndex || '6';
    }
    
    // Precipitation/Rain chance
    const precipitation = document.getElementById('precipitation');
    if (precipitation) {
        precipitation.textContent = `${data.rainChance || 15}%`;
    }
    
    // Pressure
    const pressure = document.getElementById('pressure');
    if (pressure) {
        pressure.textContent = `${data.pressure || 1013} hPa`;
    }
    
    // Forecast
    if (data.forecast && data.forecast.length > 0) {
        const forecastDays = document.querySelectorAll('.forecast-day');
        data.forecast.forEach((day, index) => {
            if (forecastDays[index]) {
                const dayName = forecastDays[index].querySelector('.forecast-day-name');
                const dayIcon = forecastDays[index].querySelector('.forecast-icon');
                const highTemp = forecastDays[index].querySelector('.forecast-temp-high');
                const lowTemp = forecastDays[index].querySelector('.forecast-temp-low');
                
                if (dayName) dayName.textContent = day.day || getDayName(index);
                if (dayIcon) dayIcon.className = `fas ${iconMap[day.weather] || 'fa-cloud'} forecast-icon`;
                if (highTemp) highTemp.textContent = `${day.high}°`;
                if (lowTemp) lowTemp.textContent = `${day.low}°`;
            }
        });
    }
}

function getDayName(daysFromNow) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const today = new Date();
    today.setDate(today.getDate() + daysFromNow + 1);
    return daysFromNow === 0 ? 'Tomorrow' : days[today.getDay()];
}

// ============================================
// Maps App
// ============================================

let mapsState = {
    currentCoords: { x: 0, y: 0, z: 0 },
    currentZone: 'Unknown',
    savedLocations: [],
    updateInterval: null,
    waypointCoords: null,
    // Map interaction state
    mapZoom: 1,
    mapOffsetX: 0,
    mapOffsetY: 0,
    isDragging: false,
    dragStartX: 0,
    dragStartY: 0,
    lastOffsetX: 0,
    lastOffsetY: 0
};

// GTA V Map bounds (approximate)
const MAP_BOUNDS = {
    minX: -4000,
    maxX: 4500,
    minY: -4000,
    maxY: 8000
};

// Points of Interest
const MapsPoiData = [
    // Services
    { id: 'pillbox', name: 'Pillbox Hospital', category: 'services', icon: 'fa-hospital', coords: { x: 311.8, y: -583.2 } },
    { id: 'mrpd', name: 'Mission Row PD', category: 'services', icon: 'fa-building-shield', coords: { x: 428.0, y: -981.5 } },
    { id: 'bennys', name: "Benny's Motorworks", category: 'services', icon: 'fa-wrench', coords: { x: -211.0, y: -1320.7 } },
    { id: 'lscustoms', name: 'LS Customs', category: 'services', icon: 'fa-car', coords: { x: -365.4, y: -131.8 } },
    { id: 'paleto_hospital', name: 'Paleto Bay Med', category: 'services', icon: 'fa-hospital', coords: { x: -247.8, y: 6331.5 } },
    
    // Shops
    { id: '247_1', name: '24/7 Downtown', category: 'shops', icon: 'fa-store', coords: { x: 25.7, y: -1347.3 } },
    { id: '247_2', name: '24/7 Vinewood', category: 'shops', icon: 'fa-store', coords: { x: 373.6, y: 325.6 } },
    { id: 'ltdgas', name: 'LTD Gasoline', category: 'shops', icon: 'fa-gas-pump', coords: { x: -707.8, y: -913.5 } },
    { id: 'ammunation', name: 'Ammu-Nation', category: 'shops', icon: 'fa-crosshairs', coords: { x: 252.6, y: -50.0 } },
    { id: 'clothing', name: 'Clothing Store', category: 'shops', icon: 'fa-shirt', coords: { x: 72.3, y: -1399.1 } },
    
    // Entertainment
    { id: 'casino', name: 'Diamond Casino', category: 'entertainment', icon: 'fa-diamond', coords: { x: 924.0, y: 46.1 } },
    { id: 'vanilla', name: 'Vanilla Unicorn', category: 'entertainment', icon: 'fa-martini-glass', coords: { x: 127.8, y: -1278.0 } },
    { id: 'pier', name: 'Del Perro Pier', category: 'entertainment', icon: 'fa-umbrella-beach', coords: { x: -1649.5, y: -1113.4 } },
    { id: 'golf', name: 'Golf Club', category: 'entertainment', icon: 'fa-golf-ball-tee', coords: { x: -1375.2, y: 56.8 } },
    { id: 'cinema', name: 'Ten Cent Theater', category: 'entertainment', icon: 'fa-film', coords: { x: 299.6, y: 201.0 } },
];

function openMaps() {
    const template = document.getElementById('maps-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Maps';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initMaps();
}

function initMaps() {
    // Reset map state
    mapsState.mapZoom = 1;
    mapsState.mapOffsetX = 0;
    mapsState.mapOffsetY = 0;
    
    // Load saved locations from storage
    loadSavedLocations();
    
    // Render initial state
    renderSavedLocations();
    renderPoiList('all');
    
    // Initialize map
    initMapDisplay();
    
    // Start location updates
    updateCurrentLocation();
    mapsState.updateInterval = setInterval(updateCurrentLocation, 2000);
    
    // Event listeners
    document.getElementById('maps-locate').addEventListener('click', () => {
        updateCurrentLocation();
        centerMapOnPlayer();
    });
    document.getElementById('maps-clear-waypoint').addEventListener('click', clearWaypoint);
    document.getElementById('maps-copy-coords').addEventListener('click', copyCurrentCoords);
    document.getElementById('maps-save-current').addEventListener('click', saveCurrentLocation);
    
    // Toggle view button
    document.getElementById('maps-toggle-view').addEventListener('click', toggleMapsPanel);
    
    // Zoom controls
    document.getElementById('maps-zoom-in').addEventListener('click', () => zoomMap(0.2));
    document.getElementById('maps-zoom-out').addEventListener('click', () => zoomMap(-0.2));
    document.getElementById('maps-center-player').addEventListener('click', centerMapOnPlayer);
    
    // POI category filters
    document.querySelectorAll('.maps-poi-category').forEach(btn => {
        btn.addEventListener('click', (e) => {
            document.querySelectorAll('.maps-poi-category').forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            renderPoiList(e.target.dataset.category);
        });
    });
    
    // Search functionality
    document.getElementById('maps-search').addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase().trim();
        filterMapsResults(query);
    });
}

function initMapDisplay() {
    const mapDisplay = document.getElementById('maps-display');
    const mapImage = document.getElementById('maps-image');
    
    if (!mapDisplay || !mapImage) return;
    
    // Ensure image is visible
    mapImage.style.opacity = '1';
    mapImage.style.visibility = 'visible';
    
    // Center map initially
    const container = document.getElementById('maps-display-container');
    const containerRect = container.getBoundingClientRect();
    mapsState.mapOffsetX = (containerRect.width - 1000) / 2;
    mapsState.mapOffsetY = (containerRect.height - 1000) / 2;
    
    updateMapTransform();
    
    // Mouse/touch drag handling
    mapDisplay.addEventListener('mousedown', startMapDrag);
    mapDisplay.addEventListener('mousemove', dragMap);
    mapDisplay.addEventListener('mouseup', endMapDrag);
    mapDisplay.addEventListener('mouseleave', endMapDrag);
    
    // Touch support
    mapDisplay.addEventListener('touchstart', (e) => {
        const touch = e.touches[0];
        startMapDrag({ clientX: touch.clientX, clientY: touch.clientY });
    });
    mapDisplay.addEventListener('touchmove', (e) => {
        const touch = e.touches[0];
        dragMap({ clientX: touch.clientX, clientY: touch.clientY });
    });
    mapDisplay.addEventListener('touchend', endMapDrag);
    
    // Scroll to zoom
    mapDisplay.addEventListener('wheel', (e) => {
        e.preventDefault();
        const delta = e.deltaY > 0 ? -0.1 : 0.1;
        zoomMap(delta);
    });
    
    // Click to set waypoint
    mapDisplay.addEventListener('dblclick', (e) => {
        const rect = mapImage.getBoundingClientRect();
        const clickX = e.clientX - rect.left;
        const clickY = e.clientY - rect.top;
        
        // Convert pixel position to game coords
        const gameCoords = pixelToGameCoords(clickX, clickY);
        setWaypoint(gameCoords.x, gameCoords.y);
        showWaypointMarker(gameCoords.x, gameCoords.y);
    });
}

function startMapDrag(e) {
    mapsState.isDragging = true;
    mapsState.dragStartX = e.clientX;
    mapsState.dragStartY = e.clientY;
    mapsState.lastOffsetX = mapsState.mapOffsetX;
    mapsState.lastOffsetY = mapsState.mapOffsetY;
}

function dragMap(e) {
    if (!mapsState.isDragging) return;
    
    const dx = e.clientX - mapsState.dragStartX;
    const dy = e.clientY - mapsState.dragStartY;
    
    mapsState.mapOffsetX = mapsState.lastOffsetX + dx;
    mapsState.mapOffsetY = mapsState.lastOffsetY + dy;
    
    updateMapTransform();
}

function endMapDrag() {
    mapsState.isDragging = false;
}

function zoomMap(delta) {
    mapsState.mapZoom = Math.max(0.5, Math.min(3, mapsState.mapZoom + delta));
    updateMapTransform();
    updatePlayerMarker();
    if (mapsState.waypointCoords) {
        showWaypointMarker(mapsState.waypointCoords.x, mapsState.waypointCoords.y);
    }
}

function updateMapTransform() {
    const mapImage = document.getElementById('maps-image');
    if (!mapImage) return;
    
    mapImage.style.left = `${mapsState.mapOffsetX}px`;
    mapImage.style.top = `${mapsState.mapOffsetY}px`;
    mapImage.style.transform = `scale(${mapsState.mapZoom})`;
}

function gameToPixelCoords(gameX, gameY) {
    // GTA V map: X roughly -4000 to 4500, Y roughly -4000 to 8000
    // Map image is 1000x1000 pixels
    const mapWidth = 1000;
    const mapHeight = 1000;
    
    // Normalize game coords to 0-1
    const normalizedX = (gameX - MAP_BOUNDS.minX) / (MAP_BOUNDS.maxX - MAP_BOUNDS.minX);
    const normalizedY = (gameY - MAP_BOUNDS.minY) / (MAP_BOUNDS.maxY - MAP_BOUNDS.minY);
    
    // Convert to pixel coords (Y is inverted on map image)
    const pixelX = normalizedX * mapWidth;
    const pixelY = (1 - normalizedY) * mapHeight;
    
    return { x: pixelX, y: pixelY };
}

function pixelToGameCoords(pixelX, pixelY) {
    const mapWidth = 1000;
    const mapHeight = 1000;
    
    // Normalize pixel coords
    const normalizedX = pixelX / mapWidth;
    const normalizedY = 1 - (pixelY / mapHeight);
    
    // Convert to game coords
    const gameX = normalizedX * (MAP_BOUNDS.maxX - MAP_BOUNDS.minX) + MAP_BOUNDS.minX;
    const gameY = normalizedY * (MAP_BOUNDS.maxY - MAP_BOUNDS.minY) + MAP_BOUNDS.minY;
    
    return { x: gameX, y: gameY };
}

function updatePlayerMarker() {
    const marker = document.getElementById('maps-player-marker');
    const mapImage = document.getElementById('maps-image');
    if (!marker || !mapImage) return;
    
    const pixelCoords = gameToPixelCoords(mapsState.currentCoords.x, mapsState.currentCoords.y);
    
    // Position relative to map image
    const rect = mapImage.getBoundingClientRect();
    const container = document.getElementById('maps-display-container');
    const containerRect = container.getBoundingClientRect();
    
    const left = rect.left - containerRect.left + (pixelCoords.x * mapsState.mapZoom);
    const top = rect.top - containerRect.top + (pixelCoords.y * mapsState.mapZoom);
    
    marker.style.left = `${left}px`;
    marker.style.top = `${top}px`;
}

function showWaypointMarker(x, y) {
    const marker = document.getElementById('maps-waypoint-marker');
    const mapImage = document.getElementById('maps-image');
    if (!marker || !mapImage) return;
    
    mapsState.waypointCoords = { x, y };
    
    const pixelCoords = gameToPixelCoords(x, y);
    const rect = mapImage.getBoundingClientRect();
    const container = document.getElementById('maps-display-container');
    const containerRect = container.getBoundingClientRect();
    
    const left = rect.left - containerRect.left + (pixelCoords.x * mapsState.mapZoom);
    const top = rect.top - containerRect.top + (pixelCoords.y * mapsState.mapZoom);
    
    marker.style.left = `${left}px`;
    marker.style.top = `${top}px`;
    marker.style.display = 'block';
}

function centerMapOnPlayer() {
    const container = document.getElementById('maps-display-container');
    if (!container) return;
    
    const containerRect = container.getBoundingClientRect();
    const pixelCoords = gameToPixelCoords(mapsState.currentCoords.x, mapsState.currentCoords.y);
    
    // Center the player position in the container
    mapsState.mapOffsetX = (containerRect.width / 2) - (pixelCoords.x * mapsState.mapZoom);
    mapsState.mapOffsetY = (containerRect.height / 2) - (pixelCoords.y * mapsState.mapZoom);
    
    updateMapTransform();
    updatePlayerMarker();
}

function toggleMapsPanel() {
    const panel = document.getElementById('maps-panel');
    const btn = document.getElementById('maps-toggle-view');
    if (!panel || !btn) return;
    
    panel.classList.toggle('expanded');
    
    if (panel.classList.contains('expanded')) {
        btn.innerHTML = '<i class="fas fa-map"></i><span>Map View</span>';
    } else {
        btn.innerHTML = '<i class="fas fa-list"></i><span>POI List</span>';
    }
}

function updateCurrentLocation() {
    nuiCallback('getPlayerLocation').then(data => {
        if (data) {
            mapsState.currentCoords = data.coords || { x: 0, y: 0, z: 0 };
            mapsState.currentZone = data.zone || 'Unknown';
            
            const coordsEl = document.getElementById('maps-current-coords');
            const zoneEl = document.getElementById('maps-current-zone');
            
            if (coordsEl) {
                coordsEl.textContent = `${mapsState.currentCoords.x.toFixed(1)}, ${mapsState.currentCoords.y.toFixed(1)}, ${mapsState.currentCoords.z.toFixed(1)}`;
            }
            if (zoneEl) {
                zoneEl.textContent = mapsState.currentZone;
            }
            
            // Update player marker position
            updatePlayerMarker();
        }
    });
}

function clearWaypoint() {
    const marker = document.getElementById('maps-waypoint-marker');
    if (marker) marker.style.display = 'none';
    mapsState.waypointCoords = null;
    
    nuiCallback('clearWaypoint').then(() => {
        console.log('[MI Tablet] Waypoint cleared');
    });
}

function copyCurrentCoords() {
    const coordsStr = `${mapsState.currentCoords.x.toFixed(2)}, ${mapsState.currentCoords.y.toFixed(2)}, ${mapsState.currentCoords.z.toFixed(2)}`;
    navigator.clipboard.writeText(coordsStr).then(() => {
        const btn = document.getElementById('maps-copy-coords');
        const originalText = btn.innerHTML;
        btn.innerHTML = '<i class="fas fa-check"></i><span>Copied!</span>';
        setTimeout(() => btn.innerHTML = originalText, 1500);
    });
}

function saveCurrentLocation() {
    const name = prompt('Enter a name for this location:');
    if (!name) return;
    
    const location = {
        id: Date.now(),
        name: name,
        coords: { ...mapsState.currentCoords },
        zone: mapsState.currentZone
    };
    
    mapsState.savedLocations.push(location);
    saveSavedLocations();
    renderSavedLocations();
}

function loadSavedLocations() {
    try {
        const saved = localStorage.getItem('mi-tablet-saved-locations');
        mapsState.savedLocations = saved ? JSON.parse(saved) : [];
    } catch (e) {
        mapsState.savedLocations = [];
    }
}

function saveSavedLocations() {
    localStorage.setItem('mi-tablet-saved-locations', JSON.stringify(mapsState.savedLocations));
}

function renderSavedLocations() {
    const listEl = document.getElementById('maps-saved-list');
    if (!listEl) return;
    
    if (mapsState.savedLocations.length === 0) {
        listEl.innerHTML = `
            <div class="maps-saved-empty">
                <i class="fas fa-bookmark"></i>
                <span>No saved locations yet</span>
            </div>
        `;
        return;
    }
    
    listEl.innerHTML = mapsState.savedLocations.map(loc => `
        <div class="maps-saved-item" data-id="${loc.id}">
            <div class="maps-saved-icon">
                <i class="fas fa-location-dot"></i>
            </div>
            <div class="maps-saved-info">
                <div class="maps-saved-name">${loc.name}</div>
                <div class="maps-saved-coords">${loc.coords.x.toFixed(1)}, ${loc.coords.y.toFixed(1)}</div>
            </div>
            <button class="maps-saved-delete" data-id="${loc.id}">
                <i class="fas fa-trash"></i>
            </button>
        </div>
    `).join('');
    
    // Add click handlers
    listEl.querySelectorAll('.maps-saved-item').forEach(item => {
        item.addEventListener('click', (e) => {
            if (e.target.closest('.maps-saved-delete')) return;
            const id = parseInt(item.dataset.id);
            const loc = mapsState.savedLocations.find(l => l.id === id);
            if (loc) setWaypoint(loc.coords.x, loc.coords.y);
        });
    });
    
    listEl.querySelectorAll('.maps-saved-delete').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const id = parseInt(btn.dataset.id);
            mapsState.savedLocations = mapsState.savedLocations.filter(l => l.id !== id);
            saveSavedLocations();
            renderSavedLocations();
        });
    });
}

function renderPoiList(category) {
    const listEl = document.getElementById('maps-poi-list');
    if (!listEl) return;
    
    const filtered = category === 'all' 
        ? MapsPoiData 
        : MapsPoiData.filter(poi => poi.category === category);
    
    listEl.innerHTML = filtered.map(poi => `
        <div class="maps-poi-item" data-coords-x="${poi.coords.x}" data-coords-y="${poi.coords.y}">
            <div class="maps-poi-icon ${poi.category}">
                <i class="fas ${poi.icon}"></i>
            </div>
            <span class="maps-poi-name">${poi.name}</span>
        </div>
    `).join('');
    
    // Add click handlers
    listEl.querySelectorAll('.maps-poi-item').forEach(item => {
        item.addEventListener('click', () => {
            const x = parseFloat(item.dataset.coordsX);
            const y = parseFloat(item.dataset.coordsY);
            setWaypoint(x, y);
        });
    });
}

function filterMapsResults(query) {
    if (!query) {
        renderPoiList(document.querySelector('.maps-poi-category.active')?.dataset.category || 'all');
        return;
    }
    
    const listEl = document.getElementById('maps-poi-list');
    const filtered = MapsPoiData.filter(poi => 
        poi.name.toLowerCase().includes(query)
    );
    
    if (filtered.length === 0) {
        listEl.innerHTML = '<div class="maps-saved-empty"><i class="fas fa-search"></i><span>No results found</span></div>';
        return;
    }
    
    listEl.innerHTML = filtered.map(poi => `
        <div class="maps-poi-item" data-coords-x="${poi.coords.x}" data-coords-y="${poi.coords.y}">
            <div class="maps-poi-icon ${poi.category}">
                <i class="fas ${poi.icon}"></i>
            </div>
            <span class="maps-poi-name">${poi.name}</span>
        </div>
    `).join('');
    
    listEl.querySelectorAll('.maps-poi-item').forEach(item => {
        item.addEventListener('click', () => {
            const x = parseFloat(item.dataset.coordsX);
            const y = parseFloat(item.dataset.coordsY);
            setWaypoint(x, y);
        });
    });
}

function setWaypoint(x, y) {
    showWaypointMarker(x, y);
    nuiCallback('setWaypoint', { x, y }).then(() => {
        console.log('[MI Tablet] Waypoint set to', x, y);
    });
}

// ============================================
// Browser App
// ============================================

function openBrowser() {
    const template = document.getElementById('browser-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Browser';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initBrowser();
}

function initBrowser() {
    document.querySelectorAll('.browser-shortcut').forEach(shortcut => {
        shortcut.addEventListener('click', () => {
            const url = shortcut.dataset.url;
            document.getElementById('browser-url').value = url;
        });
    });
}

// ============================================
// Camera App
// ============================================

let cameraState = {
    isActive: false,
    isSelfie: false,
    gameView: null,
    canvas: null,
    uploadConfig: null
};

function openCamera() {
    const template = document.getElementById('camera-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Camera';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initCameraApp();
}

function initCameraApp() {
    // Get upload config from server
    nuiCallback('getCameraConfig').then(config => {
        cameraState.uploadConfig = config;
        console.log('[Camera] Upload config loaded:', JSON.stringify(config));
    });
    
    // Add click listeners
    document.getElementById('camera-capture').addEventListener('click', () => {
        // Open camera mode - normal
        nuiCallback('openCameraMode', { selfie: false });
    });
    
    document.getElementById('camera-switch').addEventListener('click', () => {
        // Open camera mode - selfie
        nuiCallback('openCameraMode', { selfie: true });
    });
    
    document.getElementById('camera-gallery').addEventListener('click', () => {
        openGallery();
    });
}

// Enter camera mode (called from Lua)
function enterCameraMode(isSelfie, keybinds) {
    cameraState.isActive = true;
    cameraState.isSelfie = isSelfie;
    
    // Hide tablet UI
    document.getElementById('tablet-frame').style.display = 'none';
    
    // Show camera overlay
    const overlay = document.getElementById('camera-mode-overlay');
    if (overlay) {
        overlay.classList.remove('hidden');
        overlay.classList.add('active');
        
        // Update keybind hints
        if (keybinds) {
            document.getElementById('camera-hint-photo').textContent = keybinds.TakePhoto || 'ENTER';
            document.getElementById('camera-hint-flip').textContent = keybinds.FlipCamera || 'F';
            document.getElementById('camera-hint-exit').textContent = keybinds.Exit || 'BACKSPACE';
        }
        
        // Update selfie indicator
        updateCameraModeIndicator(isSelfie);
    }
    
    // Initialize game view for screen capture
    initGameViewCapture();
    
    console.log('[Camera] Entered camera mode, selfie:', isSelfie);
}

// Exit camera mode
function exitCameraMode() {
    cameraState.isActive = false;
    
    // Hide camera overlay
    const overlay = document.getElementById('camera-mode-overlay');
    if (overlay) {
        overlay.classList.remove('active');
        overlay.classList.add('hidden');
    }
    
    // Show tablet UI
    document.getElementById('tablet-frame').style.display = '';
    
    // Stop game view
    if (cameraState.gameView) {
        // Don't destroy, just hide
    }
    
    console.log('[Camera] Exited camera mode');
}

// Update camera mode indicator
function updateCameraModeIndicator(isSelfie) {
    const indicator = document.getElementById('camera-mode-indicator');
    if (indicator) {
        indicator.textContent = isSelfie ? 'SELFIE' : 'PHOTO';
        indicator.className = 'camera-mode-indicator ' + (isSelfie ? 'selfie' : 'photo');
    }
}

// Initialize game view for screen capture
function initGameViewCapture() {
    // Create canvas if it doesn't exist
    if (!cameraState.canvas) {
        cameraState.canvas = document.getElementById('gameview-canvas');
        if (!cameraState.canvas) {
            cameraState.canvas = document.createElement('canvas');
            cameraState.canvas.id = 'gameview-canvas';
            cameraState.canvas.width = 1920;
            cameraState.canvas.height = 1080;
            cameraState.canvas.style.display = 'none';
            document.body.appendChild(cameraState.canvas);
        }
    }
    
    // Use the global GameView instance
    if (window.gameViewInstance) {
        cameraState.gameView = window.gameViewInstance.createGameView(cameraState.canvas);
        console.log('[Camera] GameView initialized');
    } else {
        console.error('[Camera] GameView not loaded');
    }
}

// Capture photo
async function capturePhoto(quality, mime) {
    console.log('[Camera] capturePhoto called, canvas:', !!cameraState.canvas, 'gameView:', !!cameraState.gameView);
    
    // Ensure we have upload config - retry loading if API key is missing
    if (!cameraState.uploadConfig || !cameraState.uploadConfig.apiKey) {
        console.log('[Camera] Config missing or no API key, attempting to load...');
        
        // Try up to 3 times with a small delay
        for (let attempt = 0; attempt < 3; attempt++) {
            try {
                const config = await nuiCallback('getCameraConfig');
                if (config && config.apiKey) {
                    cameraState.uploadConfig = config;
                    console.log('[Camera] Config loaded on attempt', attempt + 1, ':', JSON.stringify(config));
                    break;
                } else {
                    console.log('[Camera] Attempt', attempt + 1, 'returned empty API key, waiting...');
                    await new Promise(resolve => setTimeout(resolve, 500)); // Wait 500ms before retry
                }
            } catch (e) {
                console.error('[Camera] Failed to load config:', e);
            }
        }
    }
    
    if (!cameraState.canvas) {
        console.error('[Camera] No canvas for capture');
        return;
    }
    
    try {
        const dataUrl = cameraState.canvas.toDataURL(mime || 'image/webp', quality || 0.92);
        console.log('[Camera] Got dataUrl, length:', dataUrl.length);
        
        // Upload the image
        await uploadPhoto(dataUrl);
    } catch (error) {
        console.error('[Camera] Capture error:', error);
        nuiCallback('photoCaptured', { imageData: null, error: error.message });
    }
}

// Upload photo to Fivemanage
async function uploadPhoto(dataUrl) {
    const config = cameraState.uploadConfig;
    
    if (!config || !config.apiKey) {
        console.error('[Camera] No upload config or API key');
        nuiCallback('photoCaptured', { imageData: null, error: 'No API key configured' });
        return;
    }
    
    try {
        // Convert data URL to blob
        const response = await fetch(dataUrl);
        const blob = await response.blob();
        
        // Create form data
        const formData = new FormData();
        formData.append('file', blob, 'photo.webp');
        formData.append('metadata', JSON.stringify({
            name: 'MI Tablet Photo',
            description: `Captured ${new Date().toISOString()}`
        }));
        
        let uploadUrl = 'https://fmapi.net/api/v2/image';
        if (config.service === 'fivemerr') {
            uploadUrl = 'https://api.fivemerr.com/v1/media/images';
        }
        
        // Upload to service
        const uploadResponse = await fetch(uploadUrl, {
            method: 'POST',
            headers: {
                'Authorization': config.apiKey
            },
            body: formData
        });
        
        if (!uploadResponse.ok) {
            throw new Error(`Upload failed: ${uploadResponse.status}`);
        }
        
        const responseData = await uploadResponse.json();
        const photoUrl = responseData.url || responseData.data?.url;
        
        if (photoUrl) {
            console.log('[Camera] Photo uploaded:', photoUrl);
            
            // Tell server to save the URL
            nuiCallback('photoUploaded', { url: photoUrl });
        } else {
            throw new Error('No URL returned from upload');
        }
    } catch (error) {
        console.error('[Camera] Upload error:', error);
        nuiCallback('photoCaptured', { imageData: null, error: error.message });
    }
}

// Camera flash effect
function cameraFlash() {
    const flash = document.getElementById('camera-flash');
    if (flash) {
        flash.classList.add('active');
        setTimeout(() => {
            flash.classList.remove('active');
        }, 150);
    }
}

// ============================================
// Gallery App
// ============================================

let galleryState = {
    photos: [],
    selectedTab: 'photos'
};

function openGallery() {
    const template = document.getElementById('gallery-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Gallery';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    initGallery();
    loadGalleryPhotos();
}

function initGallery() {
    document.querySelectorAll('.gallery-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.gallery-tab').forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            galleryState.selectedTab = tab.dataset.tab;
            
            if (tab.dataset.tab === 'photos') {
                renderGalleryPhotos();
            } else {
                renderGalleryAlbums();
            }
        });
    });
}

function loadGalleryPhotos() {
    const content = document.querySelector('.gallery-content');
    if (!content) return;
    
    content.innerHTML = `
        <div class="gallery-loading">
            <i class="fas fa-spinner fa-spin"></i>
            <span>Loading photos...</span>
        </div>
    `;
    
    nuiCallback('fetchGalleryPhotos').then(data => {
        galleryState.photos = data.photos || [];
        renderGalleryPhotos();
    }).catch(() => {
        galleryState.photos = [];
        renderGalleryPhotos();
    });
}

function renderGalleryPhotos() {
    const content = document.querySelector('.gallery-content');
    if (!content) return;
    
    if (galleryState.photos.length === 0) {
        content.innerHTML = `
            <div class="gallery-empty">
                <i class="fas fa-images"></i>
                <p>No photos yet</p>
                <span>Take a photo with the camera app</span>
            </div>
        `;
        return;
    }
    
    content.innerHTML = '<div class="gallery-grid"></div>';
    const grid = content.querySelector('.gallery-grid');
    
    galleryState.photos.forEach(photo => {
        const item = document.createElement('div');
        item.className = 'gallery-item';
        item.dataset.photoId = photo.id;
        item.innerHTML = `
            <img src="${photo.url}" alt="Photo" loading="lazy">
            <div class="gallery-item-overlay">
                <button class="gallery-item-view" title="View">
                    <i class="fas fa-expand"></i>
                </button>
                <button class="gallery-item-delete" title="Delete">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `;
        
        // View photo
        item.querySelector('.gallery-item-view').addEventListener('click', (e) => {
            e.stopPropagation();
            viewPhoto(photo);
        });
        
        // Delete photo
        item.querySelector('.gallery-item-delete').addEventListener('click', (e) => {
            e.stopPropagation();
            deletePhoto(photo.id);
        });
        
        // Click to view
        item.addEventListener('click', () => viewPhoto(photo));
        
        grid.appendChild(item);
    });
}

function renderGalleryAlbums() {
    const content = document.querySelector('.gallery-content');
    if (!content) return;
    
    content.innerHTML = `
        <div class="gallery-empty">
            <i class="fas fa-folder-open"></i>
            <p>No albums yet</p>
            <span>Albums feature coming soon</span>
        </div>
    `;
}

function viewPhoto(photo) {
    // Create fullscreen viewer
    const viewer = document.createElement('div');
    viewer.className = 'photo-viewer';
    viewer.innerHTML = `
        <div class="photo-viewer-backdrop"></div>
        <div class="photo-viewer-content">
            <img src="${photo.url}" alt="Photo">
            <div class="photo-viewer-info">
                <span class="photo-date">${photo.date ? new Date(photo.date).toLocaleDateString() : ''}</span>
            </div>
            <button class="photo-viewer-close">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    
    document.body.appendChild(viewer);
    
    // Force reflow for animation
    viewer.offsetHeight;
    viewer.classList.add('active');
    
    // Close on click
    viewer.querySelector('.photo-viewer-backdrop').addEventListener('click', () => {
        viewer.classList.remove('active');
        setTimeout(() => viewer.remove(), 300);
    });
    
    viewer.querySelector('.photo-viewer-close').addEventListener('click', () => {
        viewer.classList.remove('active');
        setTimeout(() => viewer.remove(), 300);
    });
}

function deletePhoto(photoId) {
    if (!confirm('Delete this photo?')) return;
    
    nuiCallback('deleteGalleryPhoto', { photoId }).then(data => {
        if (data.success) {
            galleryState.photos = galleryState.photos.filter(p => p.id !== photoId);
            renderGalleryPhotos();
        }
    });
}

// ============================================
// Rep App
// ============================================

function openRep() {
    const template = document.getElementById('rep-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Rep';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    loadRepData();
}

function loadRepData() {
    // Show loading state
    const repList = document.getElementById('rep-list');
    const repEmpty = document.getElementById('rep-empty');
    
    if (repList) repList.innerHTML = '<div class="rep-line"><span class="prompt">$</span><span class="name">Loading...</span><span class="rep-cursor"></span></div>';
    if (repEmpty) repEmpty.style.display = 'none';
    
    // Fetch rep data from server
    nuiCallback('getCurrentRep').then(data => {
        if (data && data.repData) {
            updateRepUI(data.repData);
        } else {
            showEmptyRepState();
        }
    }).catch(() => {
        showEmptyRepState();
    });
}

function updateRepUI(repData) {
    const repList = document.getElementById('rep-list');
    const repEmpty = document.getElementById('rep-empty');
    
    if (!repList) return;
    
    // Convert repData object to array of entries, filtering out values less than 1
    const entries = Object.entries(repData).filter(([name, value]) => {
        const numValue = parseFloat(value) || 0;
        return numValue >= 1;
    });
    
    if (entries.length === 0) {
        showEmptyRepState();
        return;
    }
    
    // Hide empty state
    if (repEmpty) repEmpty.style.display = 'none';
    
    // Clear and populate list
    repList.innerHTML = '';
    
    entries.forEach(([name, value]) => {
        const repLine = document.createElement('div');
        repLine.className = 'rep-line';
        
        const numValue = parseFloat(value) || 0;
        const valueClass = numValue >= 0 ? 'positive' : 'negative';
        
        repLine.innerHTML = `
            <span class="name">${name}</span>
            <span class="value ${valueClass}">${numValue}</span>
        `;
        
        repList.appendChild(repLine);
    });
}

function showEmptyRepState() {
    const repList = document.getElementById('rep-list');
    const repEmpty = document.getElementById('rep-empty');
    
    if (repList) repList.innerHTML = '';
    if (repEmpty) repEmpty.style.display = 'flex';
}

// ============================================
// Banking App
// ============================================

function openBanking() {
    const template = document.getElementById('banking-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Banking';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    loadBankingData();
}

function loadBankingData() {
    // Show loading state
    const loading = document.getElementById('banking-loading');
    if (loading) loading.style.display = 'flex';
    
    // Fetch accounts from server
    nuiCallback('fetchBankAccounts').then(data => {
        if (loading) loading.style.display = 'none';
        
        if (data && data.accounts && data.accounts.length > 0) {
            updateBankingUI(data.accounts);
            // Also fetch recent transactions for primary account
            if (data.accounts[0]) {
                loadBankingTransactions(data.accounts[0].number);
            }
        } else {
            showEmptyBankingState();
        }
    }).catch(() => {
        if (loading) loading.style.display = 'none';
        showEmptyBankingState();
    });
}

function updateBankingUI(accounts) {
    const summaryEl = document.getElementById('banking-summary');
    const accountsEl = document.getElementById('banking-accounts');
    
    if (!summaryEl || !accountsEl) return;
    
    // Calculate total balance
    let totalBalance = 0;
    accounts.forEach(acc => {
        totalBalance += parseFloat(acc.balance) || 0;
    });
    
    // Update summary card
    summaryEl.innerHTML = `
        <div class="banking-summary-header">
            <span class="banking-summary-label">Total Balance</span>
            <span class="banking-summary-bank"><i class="fas fa-shield-alt"></i> Fleeca</span>
        </div>
        <div class="banking-total-balance">£${formatCurrency(totalBalance)}</div>
        <div class="banking-account-count">${accounts.length} account${accounts.length !== 1 ? 's' : ''}</div>
    `;
    
    // Update accounts list
    accountsEl.innerHTML = '';
    accounts.forEach(account => {
        const accountCard = document.createElement('div');
        accountCard.className = 'banking-account-card';
        accountCard.dataset.accountNumber = account.number;
        
        const accountType = account.type || 'personal';
        const iconClass = getAccountIconClass(accountType);
        const iconName = getAccountIcon(accountType);
        
        accountCard.innerHTML = `
            <div class="banking-account-info">
                <div class="banking-account-icon ${iconClass}">
                    <i class="fas ${iconName}"></i>
                </div>
                <div class="banking-account-details">
                    <span class="banking-account-name">${account.name || capitalizeFirst(accountType) + ' Account'}</span>
                    <span class="banking-account-number">${formatAccountNumber(account.number)}</span>
                </div>
            </div>
            <span class="banking-account-balance">£${formatCurrency(account.balance)}</span>
        `;
        
        accountCard.addEventListener('click', () => {
            loadBankingTransactions(account.number);
        });
        
        accountsEl.appendChild(accountCard);
    });
}

function loadBankingTransactions(accountNumber) {
    nuiCallback('fetchBankTransactions', { accountNumber, recent: true }).then(data => {
        if (data && data.transactions && data.transactions.length > 0) {
            updateTransactionsUI(data.transactions);
        } else {
            showEmptyTransactionsState();
        }
    }).catch(() => {
        showEmptyTransactionsState();
    });
}

function updateTransactionsUI(transactions) {
    const transactionsEl = document.getElementById('banking-transactions');
    if (!transactionsEl) return;
    
    transactionsEl.innerHTML = '';
    
    // Show only last 10 transactions
    const recentTransactions = transactions.slice(0, 10);
    
    recentTransactions.forEach(tx => {
        const txEl = document.createElement('div');
        txEl.className = 'banking-transaction';
        
        const txType = tx.type || 'transfer';
        const isPositive = txType === 'deposit' || (tx.amount > 0 && txType !== 'withdraw');
        const iconClass = txType === 'deposit' ? 'deposit' : txType === 'withdraw' ? 'withdraw' : 'transfer';
        const iconName = txType === 'deposit' ? 'fa-arrow-down' : txType === 'withdraw' ? 'fa-arrow-up' : 'fa-exchange-alt';
        
        txEl.innerHTML = `
            <div class="banking-transaction-info">
                <div class="banking-transaction-icon ${iconClass}">
                    <i class="fas ${iconName}"></i>
                </div>
                <div class="banking-transaction-details">
                    <span class="banking-transaction-title">${tx.description || capitalizeFirst(txType)}</span>
                    <span class="banking-transaction-date">${formatTransactionDate(tx.date)}</span>
                </div>
            </div>
            <span class="banking-transaction-amount ${isPositive ? 'positive' : 'negative'}">
                ${isPositive ? '+' : '-'}£${formatCurrency(Math.abs(tx.amount))}
            </span>
        `;
        
        transactionsEl.appendChild(txEl);
    });
}

function showEmptyBankingState() {
    const summaryEl = document.getElementById('banking-summary');
    if (summaryEl) {
        summaryEl.innerHTML = `
            <div class="banking-summary-header">
                <span class="banking-summary-label">Total Balance</span>
                <span class="banking-summary-bank"><i class="fas fa-shield-alt"></i> Fleeca</span>
            </div>
            <div class="banking-total-balance">£0.00</div>
            <div class="banking-account-count">No accounts found</div>
        `;
    }
}

function showEmptyTransactionsState() {
    const transactionsEl = document.getElementById('banking-transactions');
    if (transactionsEl) {
        transactionsEl.innerHTML = `
            <div class="banking-empty-transactions">
                <i class="fas fa-receipt"></i>
                <span>No recent transactions</span>
            </div>
        `;
    }
}

// Helper functions for banking
function formatCurrency(amount) {
    return parseFloat(amount || 0).toLocaleString('en-GB', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}

function formatAccountNumber(number) {
    if (!number) return '****';
    const str = String(number);
    if (str.length <= 4) return str;
    return '****' + str.slice(-4);
}

function formatTransactionDate(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const now = new Date();
    const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    
    return date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });
}

function getAccountIconClass(type) {
    const classes = {
        'personal': 'personal',
        'business': 'business',
        'savings': 'savings',
        'shared': 'shared',
        'joint': 'shared'
    };
    return classes[type] || 'personal';
}

function getAccountIcon(type) {
    const icons = {
        'personal': 'fa-user',
        'business': 'fa-briefcase',
        'savings': 'fa-piggy-bank',
        'shared': 'fa-users',
        'joint': 'fa-users'
    };
    return icons[type] || 'fa-wallet';
}

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// ============================================
// Crypto Mining App
// ============================================

function openCrypto() {
    document.getElementById('app-title').textContent = 'Crypto Mining';
    document.getElementById('app-content').innerHTML = `
        <div class="crypto-app">
            <div class="crypto-header">
                <div class="crypto-summary">
                    <span id="crypto-rig-count">0</span> rigs
                </div>
                <button id="crypto-refresh-btn" class="crypto-btn">
                    <i class="fas fa-rotate"></i> Refresh
                </button>
            </div>
            <div id="crypto-rigs-list" class="crypto-rigs-list"></div>
            <div id="crypto-empty" class="crypto-empty" style="display:none;">
                <i class="fas fa-server"></i>
                <span>No rigs placed yet</span>
            </div>
            <div class="crypto-hint">
                Place a server rack and a computer near each other to create a rig.
            </div>
        </div>
    `;

    switchScreen('app');
    loadCryptoRigs();

    const refreshBtn = document.getElementById('crypto-refresh-btn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', loadCryptoRigs);
    }
}

function loadCryptoRigs() {
    const listEl = document.getElementById('crypto-rigs-list');
    const emptyEl = document.getElementById('crypto-empty');

    if (listEl) listEl.innerHTML = '<div class="crypto-loading">Loading rigs...</div>';
    if (emptyEl) emptyEl.style.display = 'none';

    nuiCallback('crypto:getRigs').then(data => {
        const rigs = (data && data.rigs) ? data.rigs : [];
        renderCryptoRigs(rigs);
    }).catch(() => {
        if (listEl) listEl.innerHTML = '<div class="crypto-error">Failed to load rigs.</div>';
    });
}

function renderCryptoRigs(rigList) {
    const listEl = document.getElementById('crypto-rigs-list');
    const emptyEl = document.getElementById('crypto-empty');
    const countEl = document.getElementById('crypto-rig-count');

    if (!listEl) return;
    if (countEl) countEl.textContent = rigList.length;

    if (!rigList.length) {
        listEl.innerHTML = '';
        if (emptyEl) emptyEl.style.display = 'flex';
        return;
    }

    if (emptyEl) emptyEl.style.display = 'none';

    listEl.innerHTML = rigList.map(rig => `
        <div class="crypto-rig-card">
            <div class="crypto-rig-info">
                <div class="crypto-rig-title">Rig #${rig.id}</div>
                <div class="crypto-rig-meta">Rack: ${rig.rackId} · PC: ${rig.pcId}</div>
            </div>
            <div class="crypto-rig-status ${rig.active ? 'active' : 'idle'}">${rig.active ? 'Active' : 'Idle'}</div>
            <button class="crypto-rig-btn" data-rig-id="${rig.id}">${rig.active ? 'Stop' : 'Start'}</button>
        </div>
    `).join('');

    listEl.querySelectorAll('.crypto-rig-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const rigId = btn.dataset.rigId;
            nuiCallback('crypto:toggleMining', { rigId }).then(() => {
                loadCryptoRigs();
            });
        });
    });
}

// ============================================
// Player Events App Functions (View & Join Events)
// ============================================

let playerEventsUpdateInterval = null;
let playerIsInEvent = false;  // Track if current player is in the event

function openPlayerEvents() {
    const template = document.getElementById('player-events-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Events Hub';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    
    // Attach event listeners to launcher cards
    document.querySelectorAll('.events-launcher-card').forEach(card => {
        card.addEventListener('click', () => {
            const eventsApp = card.dataset.eventsApp;
            openPlayerEventsSubApp(eventsApp);
        });
    });
}

function openPlayerEventsSubApp(appId) {
    switch (appId) {
        case 'events':
            openPlayerEventsList();
            break;
        default:
            console.log('[MI Tablet] Unknown events app:', appId);
    }
}

function openPlayerEventsList() {
    const template = document.getElementById('player-events-list-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Active Events';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Attach back button listener
    document.getElementById('player-events-back-btn').addEventListener('click', openPlayerEvents);
    
    // Attach LMS join button listener
    const joinBtn = document.getElementById('lms-join-btn');
    if (joinBtn) {
        joinBtn.addEventListener('click', () => handleJoinEvent('lastmanstanding'));
    }
    
    // Attach LMS leave button listener
    const leaveBtn = document.getElementById('lms-leave-btn');
    if (leaveBtn) {
        leaveBtn.addEventListener('click', () => handleLeaveEvent('lastmanstanding'));
    }
    
    // Attach Prophunt join button listener
    const prophuntJoinBtn = document.getElementById('prophunt-join-btn');
    if (prophuntJoinBtn) {
        prophuntJoinBtn.addEventListener('click', () => handleJoinEvent('prophunt'));
    }
    
    // Attach Prophunt leave button listener
    const prophuntLeaveBtn = document.getElementById('prophunt-leave-btn');
    if (prophuntLeaveBtn) {
        prophuntLeaveBtn.addEventListener('click', () => handleLeaveEvent('prophunt'));
    }
    
    // Load initial event status
    loadEventStatus();
    
    // Set up auto-refresh every 2 seconds
    playerEventsUpdateInterval = setInterval(loadEventStatus, 2000);
}

function loadEventStatus() {
    // Load LMS status
    nuiCallback('getEventStatus', { eventId: 'lastmanstanding' }).then(data => {
        updateEventUI('lastmanstanding', data);
    }).catch(err => {
        console.error('[MI Tablet] Error fetching LMS event status:', err);
        updateEventUI('lastmanstanding', { state: 'inactive', timeRemaining: 0, playerCount: 0, isPlayerInEvent: false });
    });
    
    // Load Prophunt status
    nuiCallback('getEventStatus', { eventId: 'prophunt' }).then(data => {
        updateEventUI('prophunt', data);
    }).catch(err => {
        console.error('[MI Tablet] Error fetching Prophunt event status:', err);
        updateEventUI('prophunt', { state: 'inactive', timeRemaining: 0, playerCount: 0, isPlayerInEvent: false });
    });
}

function updateEventUI(eventId, data) {
    // Determine element prefix based on event type
    const prefix = eventId === 'prophunt' ? 'prophunt' : 'lms';
    
    const statusBadge = document.getElementById(`${prefix}-status-badge`);
    const statusText = document.getElementById(`${prefix}-status-text`);
    const timerContainer = document.getElementById(`${prefix}-timer-container`);
    const timerText = document.getElementById(`${prefix}-timer`);
    const playersContainer = document.getElementById(`${prefix}-players-container`);
    const playersText = document.getElementById(`${prefix}-players`);
    const joinBtn = document.getElementById(`${prefix}-join-btn`);
    const leaveBtn = document.getElementById(`${prefix}-leave-btn`);
    
    if (!statusBadge || !statusText) return;
    
    // Update player in event status (store per-event)
    if (eventId === 'prophunt') {
        window.playerIsInProphunt = data.isPlayerInEvent || false;
    } else {
        playerIsInEvent = data.isPlayerInEvent || false;
    }
    const isInThisEvent = eventId === 'prophunt' ? window.playerIsInProphunt : playerIsInEvent;
    
    // Remove all status classes
    statusBadge.classList.remove('inactive', 'joining', 'active');
    
    switch (data.state) {
        case 'joining':
            // Joining period - can join/leave
            statusBadge.classList.add('joining');
            statusText.textContent = 'Joining';
            
            // Show timer with countdown
            timerContainer.style.display = 'flex';
            timerText.textContent = formatEventTime(data.timeRemaining);
            
            // Show player count
            playersContainer.style.display = 'flex';
            playersText.textContent = data.playerCount || 0;
            
            // Update buttons based on whether player is in event
            if (isInThisEvent) {
                // Player is in event - show leave button, hide join
                joinBtn.style.display = 'none';
                leaveBtn.style.display = 'flex';
            } else {
                // Player not in event - show join button, hide leave
                joinBtn.style.display = 'flex';
                joinBtn.disabled = false;
                joinBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i><span>Join Event</span>';
                leaveBtn.style.display = 'none';
            }
            break;
            
        case 'active':
            // Event is active - cannot join or leave
            statusBadge.classList.add('active');
            statusText.textContent = data.isFinalZone ? 'Final Zone' : (data.gamePhase || 'Active');
            
            // Show timer
            timerContainer.style.display = 'flex';
            timerText.textContent = formatEventTime(data.timeRemaining);
            
            // Show player count
            playersContainer.style.display = 'flex';
            playersText.textContent = data.playerCount || 0;
            
            // Disable join button, hide leave
            joinBtn.style.display = 'flex';
            joinBtn.disabled = true;
            joinBtn.innerHTML = '<i class="fas fa-lock"></i><span>In Progress</span>';
            leaveBtn.style.display = 'none';
            break;
            
        case 'inactive':
        default:
            // Event not active
            statusBadge.classList.add('inactive');
            statusText.textContent = 'Inactive';
            
            // Hide timer and players
            timerContainer.style.display = 'none';
            playersContainer.style.display = 'none';
            
            // Disable join button, hide leave
            joinBtn.style.display = 'flex';
            joinBtn.disabled = true;
            joinBtn.innerHTML = '<i class="fas fa-hourglass-half"></i><span>Not Active</span>';
            leaveBtn.style.display = 'none';
            break;
    }
}

function formatEventTime(seconds) {
    if (!seconds || seconds <= 0) return '--:--';
    
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    
    if (mins >= 60) {
        const hrs = Math.floor(mins / 60);
        const remainMins = mins % 60;
        return `${hrs}:${remainMins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function handleJoinEvent(eventId) {
    const prefix = eventId === 'prophunt' ? 'prophunt' : 'lms';
    const joinBtn = document.getElementById(`${prefix}-join-btn`);
    const leaveBtn = document.getElementById(`${prefix}-leave-btn`);
    if (!joinBtn) return;
    
    // Disable button temporarily
    joinBtn.disabled = true;
    joinBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span>Joining...</span>';
    
    // Call server to join
    nuiCallback('joinEvent', { eventId: eventId }).then(data => {
        if (data && data.success) {
            if (eventId === 'prophunt') {
                window.playerIsInProphunt = true;
            } else {
                playerIsInEvent = true;
            }
            // Switch to showing leave button
            joinBtn.style.display = 'none';
            leaveBtn.style.display = 'flex';
        } else {
            joinBtn.disabled = false;
            joinBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i><span>Join Event</span>';
            console.error('[MI Tablet] Failed to join event:', data?.error);
        }
    }).catch(err => {
        joinBtn.disabled = false;
        joinBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i><span>Join Event</span>';
        console.error('[MI Tablet] Error joining event:', err);
    });
}

function handleLeaveEvent(eventId) {
    const prefix = eventId === 'prophunt' ? 'prophunt' : 'lms';
    const joinBtn = document.getElementById(`${prefix}-join-btn`);
    const leaveBtn = document.getElementById(`${prefix}-leave-btn`);
    if (!leaveBtn) return;
    
    // Disable button temporarily
    leaveBtn.disabled = true;
    leaveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i><span>Leaving...</span>';
    
    // Call server to leave
    nuiCallback('leaveEvent', { eventId: eventId }).then(data => {
        if (data && data.success) {
            if (eventId === 'prophunt') {
                window.playerIsInProphunt = false;
            } else {
                playerIsInEvent = false;
            }
            // Switch to showing join button
            leaveBtn.style.display = 'none';
            leaveBtn.disabled = false;
            leaveBtn.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Leave</span>';
            joinBtn.style.display = 'flex';
            joinBtn.disabled = false;
            joinBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i><span>Join Event</span>';
        } else {
            leaveBtn.disabled = false;
            leaveBtn.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Leave</span>';
            console.error('[MI Tablet] Failed to leave event:', data?.error);
        }
    }).catch(err => {
        leaveBtn.disabled = false;
        leaveBtn.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Leave</span>';
        console.error('[MI Tablet] Error leaving event:', err);
    });
}

// Cleanup interval when leaving the app
function cleanupPlayerEvents() {
    if (playerEventsUpdateInterval) {
        clearInterval(playerEventsUpdateInterval);
        playerEventsUpdateInterval = null;
    }
}

// ============================================
// Admins App Functions (Admin Apps Launcher)
// ============================================

function openAdmins() {
    const template = document.getElementById('admins-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Admin Panel';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    
    // Attach event listeners to admin app cards
    document.querySelectorAll('.admins-app-card').forEach(card => {
        card.addEventListener('click', () => {
            const adminApp = card.dataset.adminApp;
            openAdminSubApp(adminApp);
        });
    });
}

function openAdminSubApp(appId) {
    switch (appId) {
        case 'events':
            openEventsApp();
            break;
        case 'avscripts':
            openAVScriptsApp();
            break;
        case 'realestate':
            openRealEstateApp();
            break;
        default:
            console.log('[MI Tablet] Unknown admin app:', appId);
    }
}

// ============================================
// AV Scripts Admin Functions
// ============================================

// AV Admin Commands Configuration
const AVAdminCommands = [
    {
        id: 'admin:business',
        name: 'Business Admin',
        description: 'Manage businesses',
        icon: 'fa-briefcase',
        iconClass: 'business',
        command: 'admin:business',
        category: 'panels'
    },
    {
        id: 'admin:drugs',
        name: 'Drugs Admin',
        description: 'Drug system panel',
        icon: 'fa-pills',
        iconClass: 'drugs',
        command: 'admin:drugs',
        category: 'panels'
    },
    {
        id: 'admin:gangs',
        name: 'Gangs Admin',
        description: 'Gang system panel',
        icon: 'fa-users-slash',
        iconClass: 'gangs',
        command: 'admin:gangs',
        category: 'panels'
    },
    {
        id: 'admin:racing',
        name: 'Racing Admin',
        description: 'Racing system panel',
        icon: 'fa-flag-checkered',
        iconClass: 'racing',
        command: 'admin:racing',
        category: 'panels'
    },
    {
        id: 'weather',
        name: 'Weather',
        description: 'Weather control',
        icon: 'fa-cloud-sun',
        iconClass: 'weather',
        command: 'weather',
        category: 'panels'
    },
    {
        id: 'boosting:contract',
        name: 'Give Contract',
        description: 'Give boosting contract',
        icon: 'fa-car',
        iconClass: 'contract',
        command: 'boosting:contract',
        category: 'utility'
    },
    {
        id: 'shell',
        name: 'Shell Spawner',
        description: 'Spawn shell for editing',
        icon: 'fa-cube',
        iconClass: 'shell',
        command: 'shell',
        category: 'utility'
    }
];

// Real Estate Commands Configuration
const RealEstateCommands = [
    {
        id: 'shellcreator',
        name: 'Shell Creator',
        description: 'Create & edit shells',
        icon: 'fa-house-chimney',
        iconClass: 'realestate',
        command: 'shellcreator'
    },
    {
        id: 'propplacer',
        name: 'Prop Placer',
        description: 'Place & edit props',
        icon: 'fa-couch',
        iconClass: 'propplacer',
        command: 'propplacer'
    },
    {
        id: 'objectstats',
        name: 'Object Stats',
        description: 'Debug object info',
        icon: 'fa-info-circle',
        iconClass: 'objectstats',
        command: 'objectstats'
    },
    {
        id: 'coords',
        name: 'Coords',
        description: 'Show current coords',
        icon: 'fa-map-marker-alt',
        iconClass: 'coords',
        command: 'coords'
    },
    {
        id: 'recordcoords',
        name: 'Record Coords',
        description: 'Record coords to file',
        icon: 'fa-save',
        iconClass: 'recordcoords',
        command: 'recordcoords'
    }
];

function openAVScriptsApp() {
    const template = document.getElementById('avscripts-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'AV Admin Commands';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Attach back button listener
    document.getElementById('avscripts-back-btn').addEventListener('click', openAdmins);
    
    // Load AV commands
    loadAVCommandsData();
}

function loadAVCommandsData() {
    const panelsGrid = document.getElementById('avscripts-commands-grid');
    const utilityGrid = document.getElementById('avscripts-utility-grid');
    
    if (!panelsGrid || !utilityGrid) return;
    
    panelsGrid.innerHTML = '';
    utilityGrid.innerHTML = '';
    
    // Render commands by category
    AVAdminCommands.forEach(cmd => {
        const btn = createAVCommandButton(cmd);
        if (cmd.category === 'panels') {
            panelsGrid.appendChild(btn);
        } else if (cmd.category === 'utility') {
            utilityGrid.appendChild(btn);
        }
    });
}

function createAVCommandButton(cmd) {
    const btn = document.createElement('button');
    btn.className = 'avscripts-cmd-btn';
    btn.dataset.commandId = cmd.id;
    
    btn.innerHTML = `
        <div class="avscripts-cmd-icon ${cmd.iconClass}">
            <i class="fas ${cmd.icon}"></i>
        </div>
        <span class="avscripts-cmd-name">${escapeHtml(cmd.name)}</span>
        <span class="avscripts-cmd-desc">${escapeHtml(cmd.description)}</span>
    `;
    
    btn.addEventListener('click', () => executeAVCommand(cmd));
    
    return btn;
}

function executeAVCommand(cmd) {
    console.log('[MI Tablet] Executing AV command:', cmd.command);
    
    // Call server to execute the command
    nuiCallback('executeAVCommand', { command: cmd.command }).then(data => {
        if (data && data.success) {
            console.log('[MI Tablet] AV command executed successfully');
            // Close the tablet UI after executing the command
            closeTablet();
        } else {
            console.error('[MI Tablet] Failed to execute AV command:', data?.error);
        }
    }).catch(err => {
        console.error('[MI Tablet] Error executing AV command:', err);
    });
}

// ============================================
// Real Estate Admin Functions
// ============================================

function openRealEstateApp() {
    const template = document.getElementById('realestate-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Real Estate Tools';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Attach back button listener
    document.getElementById('realestate-back-btn').addEventListener('click', openAdmins);
    
    // Load Real Estate commands
    loadRealEstateCommandsData();
}

function loadRealEstateCommandsData() {
    const commandsGrid = document.getElementById('realestate-commands-grid');
    
    if (!commandsGrid) return;
    
    commandsGrid.innerHTML = '';
    
    // Render commands
    RealEstateCommands.forEach(cmd => {
        const btn = createRealEstateCommandButton(cmd);
        commandsGrid.appendChild(btn);
    });
}

function createRealEstateCommandButton(cmd) {
    const btn = document.createElement('button');
    btn.className = 'realestate-cmd-btn';
    btn.dataset.commandId = cmd.id;
    
    btn.innerHTML = `
        <div class="realestate-cmd-icon ${cmd.iconClass}">
            <i class="fas ${cmd.icon}"></i>
        </div>
        <span class="realestate-cmd-name">${escapeHtml(cmd.name)}</span>
        <span class="realestate-cmd-desc">${escapeHtml(cmd.description)}</span>
    `;
    
    btn.addEventListener('click', () => executeRealEstateCommand(cmd));
    
    return btn;
}

function executeRealEstateCommand(cmd) {
    console.log('[MI Tablet] Executing Real Estate command:', cmd.command);
    
    // Call server to execute the command (uses same callback as AV commands)
    nuiCallback('executeAVCommand', { command: cmd.command }).then(data => {
        if (data && data.success) {
            console.log('[MI Tablet] Real Estate command executed successfully');
            // Close the tablet UI after executing the command
            closeTablet();
        } else {
            console.error('[MI Tablet] Failed to execute Real Estate command:', data?.error);
        }
    }).catch(err => {
        console.error('[MI Tablet] Error executing Real Estate command:', err);
    });
}

// ============================================
// Events App Functions
// ============================================

// Available events configuration
const AvailableEvents = [
    {
        id: 'lastmanstanding',
        name: 'Last Man Standing',
        description: 'Battle royale style elimination event',
        icon: 'fa-skull-crossbones',
        resource: 'lastmanstanding_event',
        startEvent: 'lms:server:startEvent',
        stopEvent: 'lms:server:stopEvent'
    },
    {
        id: 'prophunt',
        name: 'Prop Hunt',
        description: 'Hide as props or hunt hidden players',
        icon: 'fa-ghost',
        resource: 'prophunt',
        startEvent: 'prophunt:server:startEvent',
        stopEvent: 'prophunt:server:stopEvent'
    }
];

let activeEvent = null;

function openEventsApp() {
    const template = document.getElementById('events-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Events Manager';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Attach back button listener
    document.getElementById('events-back-btn').addEventListener('click', openAdmins);
    
    // Load events
    loadEventsData();
}

function loadEventsData() {
    const eventsList = document.getElementById('events-list');
    if (!eventsList) return;
    
    eventsList.innerHTML = '';
    
    // Check for active event from server
    nuiCallback('getActiveEvent').then(data => {
        if (data && data.activeEvent) {
            activeEvent = data.activeEvent;
            showActiveEventBanner(data.activeEvent);
        }
    }).catch(() => {
        // No active event or error
    });
    
    // Render available events
    AvailableEvents.forEach(event => {
        const card = createEventCard(event);
        eventsList.appendChild(card);
    });
    
    // Attach stop button listener
    const stopBtn = document.getElementById('events-stop-active');
    if (stopBtn) {
        stopBtn.addEventListener('click', stopActiveEvent);
    }
}

function createEventCard(event) {
    const card = document.createElement('div');
    card.className = 'events-card';
    card.dataset.eventId = event.id;
    
    const isActive = activeEvent && activeEvent.id === event.id;
    
    card.innerHTML = `
        <div class="events-card-info">
            <div class="events-card-icon">
                <i class="fas ${event.icon}"></i>
            </div>
            <div class="events-card-details">
                <span class="events-card-name">${escapeHtml(event.name)}</span>
                <span class="events-card-desc">${escapeHtml(event.description)}</span>
            </div>
        </div>
        <div class="events-card-actions">
            <button class="events-start-btn" ${isActive ? 'disabled' : ''} data-event-id="${event.id}">
                <i class="fas fa-play"></i>
                ${isActive ? 'Running' : 'Start'}
            </button>
        </div>
    `;
    
    // Attach start button listener
    const startBtn = card.querySelector('.events-start-btn');
    if (startBtn && !isActive) {
        startBtn.addEventListener('click', () => startEvent(event));
    }
    
    return card;
}

function startEvent(event) {
    // Disable the button and show loading
    const btn = document.querySelector(`[data-event-id="${event.id}"]`);
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Starting...';
    }
    
    // Call server to start event
    nuiCallback('startEvent', { eventId: event.id, eventData: event }).then(data => {
        if (data && data.success) {
            activeEvent = event;
            showActiveEventBanner(event);
            
            // Update button state
            if (btn) {
                btn.innerHTML = '<i class="fas fa-check"></i> Running';
            }
            
            // Refresh the events list
            loadEventsData();
        } else {
            // Failed to start
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-play"></i> Start';
            }
            console.error('[MI Tablet] Failed to start event:', data?.error);
        }
    }).catch(err => {
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-play"></i> Start';
        }
        console.error('[MI Tablet] Error starting event:', err);
    });
}

function stopActiveEvent() {
    if (!activeEvent) return;
    
    const stopBtn = document.getElementById('events-stop-active');
    if (stopBtn) {
        stopBtn.disabled = true;
        stopBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Stopping...';
    }
    
    nuiCallback('stopEvent', { eventId: activeEvent.id, eventData: activeEvent }).then(data => {
        if (data && data.success) {
            activeEvent = null;
            hideActiveEventBanner();
            loadEventsData();
        } else {
            if (stopBtn) {
                stopBtn.disabled = false;
                stopBtn.innerHTML = '<i class="fas fa-stop"></i> Stop';
            }
        }
    }).catch(() => {
        if (stopBtn) {
            stopBtn.disabled = false;
            stopBtn.innerHTML = '<i class="fas fa-stop"></i> Stop';
        }
    });
}

function showActiveEventBanner(event) {
    const banner = document.getElementById('events-active-banner');
    const nameEl = document.getElementById('events-active-name');
    
    if (banner) {
        banner.style.display = 'flex';
    }
    if (nameEl) {
        nameEl.textContent = event.name + ' is running';
    }
}

function hideActiveEventBanner() {
    const banner = document.getElementById('events-active-banner');
    if (banner) {
        banner.style.display = 'none';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================
// Casino Management App Functions
// ============================================

function openCasino() {
    const template = document.getElementById('casino-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Casino Management';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    switchScreen('app');
    
    // Load casino data
    loadCasinoData();
    
    // Attach event listeners
    attachCasinoEventListeners();
}

function loadCasinoData() {
    // Request casino data from server
    nuiCallback('getCasinoData').then(data => {
        if (data) {
            updateCasinoDisplay(data);
        }
    }).catch(err => {
        console.error('[MI Tablet] Error loading casino data:', err);
    });
}

function updateCasinoDisplay(data) {
    // Update balance
    const balanceEl = document.getElementById('casino-balance');
    if (balanceEl && data.balance !== undefined) {
        balanceEl.textContent = '$' + formatNumber(data.balance);
    }
    
    // Update employee count
    const employeesEl = document.getElementById('casino-employees');
    if (employeesEl && data.employees) {
        employeesEl.textContent = data.employees.length;
        renderEmployeeList(data.employees);
    }
    
    // Update current podium vehicle
    const currentVehicleEl = document.getElementById('casino-current-vehicle');
    if (currentVehicleEl && data.currentVehicle) {
        currentVehicleEl.textContent = data.currentVehicle;
    }
}

function renderEmployeeList(employees) {
    const listEl = document.getElementById('casino-employees-list');
    if (!listEl) return;
    
    listEl.innerHTML = '';
    
    if (!employees || employees.length === 0) {
        listEl.innerHTML = '<div class="casino-empty-state"><i class="fas fa-users"></i><span>No employees found</span></div>';
        return;
    }
    
    employees.forEach(emp => {
        const card = document.createElement('div');
        card.className = 'casino-employee-card';
        card.innerHTML = `
            <div class="casino-employee-info">
                <span class="casino-employee-name">${escapeHtml(emp.name)}</span>
                <span class="casino-employee-cid">CID: ${emp.citizenid}</span>
            </div>
            <div class="casino-employee-grade">
                <span class="casino-grade-badge grade-${emp.grade}">${escapeHtml(emp.gradeName)}</span>
            </div>
            <div class="casino-employee-actions">
                <button class="casino-btn-icon danger" data-action="fire" data-cid="${emp.citizenid}">
                    <i class="fas fa-user-times"></i>
                </button>
            </div>
        `;
        
        // Attach fire button listener
        const fireBtn = card.querySelector('[data-action="fire"]');
        if (fireBtn) {
            fireBtn.addEventListener('click', () => fireEmployee(emp.citizenid));
        }
        
        listEl.appendChild(card);
    });
}

function attachCasinoEventListeners() {
    // Set Podium Vehicle
    const setVehicleBtn = document.getElementById('casino-set-vehicle-btn');
    if (setVehicleBtn) {
        setVehicleBtn.addEventListener('click', () => {
            const input = document.getElementById('casino-vehicle-input');
            const vehicleModel = input.value.trim();
            
            if (!vehicleModel) {
                showNotification('error', 'Please enter a vehicle spawn name');
                return;
            }
            
            setPodiumVehicle(vehicleModel);
        });
    }
    
    // Hire Employee
    const hireBtn = document.getElementById('casino-hire-btn');
    if (hireBtn) {
        hireBtn.addEventListener('click', () => {
            const cidInput = document.getElementById('casino-employee-id-input');
            const gradeSelect = document.getElementById('casino-employee-grade-select');
            
            const citizenid = cidInput.value.trim();
            const grade = parseInt(gradeSelect.value);
            
            if (!citizenid) {
                showNotification('error', 'Please enter a Citizen ID');
                return;
            }
            
            hireEmployee(citizenid, grade);
        });
    }
    
    // Withdraw Funds
    const withdrawBtn = document.getElementById('casino-withdraw-btn');
    if (withdrawBtn) {
        withdrawBtn.addEventListener('click', () => {
            const input = document.getElementById('casino-withdraw-input');
            const amount = parseInt(input.value);
            
            if (!amount || amount <= 0) {
                showNotification('error', 'Please enter a valid amount');
                return;
            }
            
            withdrawFunds(amount);
        });
    }
    
    // Deposit Funds
    const depositBtn = document.getElementById('casino-deposit-btn');
    if (depositBtn) {
        depositBtn.addEventListener('click', () => {
            const input = document.getElementById('casino-deposit-input');
            const amount = parseInt(input.value);
            
            if (!amount || amount <= 0) {
                showNotification('error', 'Please enter a valid amount');
                return;
            }
            
            depositFunds(amount);
        });
    }
}

function setPodiumVehicle(vehicleModel) {
    const btn = document.getElementById('casino-set-vehicle-btn');
    const input = document.getElementById('casino-vehicle-input');
    
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Setting...';
    }
    
    nuiCallback('casino:setPodiumVehicle', { vehicle: vehicleModel }).then(data => {
        if (data && data.success) {
            showNotification('success', 'Podium vehicle updated successfully');
            const currentVehicleEl = document.getElementById('casino-current-vehicle');
            if (currentVehicleEl) {
                currentVehicleEl.textContent = vehicleModel;
            }
            if (input) input.value = '';
        } else {
            showNotification('error', data?.message || 'Failed to set podium vehicle');
        }
        
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-check"></i> Set Vehicle';
        }
    }).catch(err => {
        showNotification('error', 'Error setting podium vehicle');
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-check"></i> Set Vehicle';
        }
    });
}

function hireEmployee(citizenid, grade) {
    const btn = document.getElementById('casino-hire-btn');
    const cidInput = document.getElementById('casino-employee-id-input');
    
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Hiring...';
    }
    
    nuiCallback('casino:hireEmployee', { citizenid, grade }).then(data => {
        if (data && data.success) {
            showNotification('success', 'Employee hired successfully');
            if (cidInput) cidInput.value = '';
            loadCasinoData(); // Refresh employee list
        } else {
            showNotification('error', data?.message || 'Failed to hire employee');
        }
        
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-user-plus"></i> Hire';
        }
    }).catch(err => {
        showNotification('error', 'Error hiring employee');
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-user-plus"></i> Hire';
        }
    });
}

function fireEmployee(citizenid) {
    if (!confirm('Are you sure you want to fire this employee?')) {
        return;
    }
    
    nuiCallback('casino:fireEmployee', { citizenid }).then(data => {
        if (data && data.success) {
            showNotification('success', 'Employee fired successfully');
            loadCasinoData(); // Refresh employee list
        } else {
            showNotification('error', data?.message || 'Failed to fire employee');
        }
    }).catch(err => {
        showNotification('error', 'Error firing employee');
    });
}

function withdrawFunds(amount) {
    const btn = document.getElementById('casino-withdraw-btn');
    const input = document.getElementById('casino-withdraw-input');
    
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    }
    
    nuiCallback('casino:withdraw', { amount }).then(data => {
        if (data && data.success) {
            showNotification('success', `Withdrew $${formatNumber(amount)}`);
            if (input) input.value = '';
            loadCasinoData(); // Refresh balance
        } else {
            showNotification('error', data?.message || 'Failed to withdraw funds');
        }
        
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-money-bill-wave"></i> Withdraw';
        }
    }).catch(err => {
        showNotification('error', 'Error withdrawing funds');
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-money-bill-wave"></i> Withdraw';
        }
    });
}

function depositFunds(amount) {
    const btn = document.getElementById('casino-deposit-btn');
    const input = document.getElementById('casino-deposit-input');
    
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    }
    
    nuiCallback('casino:deposit', { amount }).then(data => {
        if (data && data.success) {
            showNotification('success', `Deposited $${formatNumber(amount)}`);
            if (input) input.value = '';
            loadCasinoData(); // Refresh balance
        } else {
            showNotification('error', data?.message || 'Failed to deposit funds');
        }
        
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-hand-holding-usd"></i> Deposit';
        }
    }).catch(err => {
        showNotification('error', 'Error depositing funds');
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-hand-holding-usd"></i> Deposit';
        }
    });
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function showNotification(type, message) {
    // Simple notification - can be enhanced
    console.log(`[Casino] ${type.toUpperCase()}: ${message}`);
    // You could add a visual notification system here
}

// ============================================
// Event Listeners
// ============================================

// NUI Message Handler
window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.type) {
        case 'open':
            if (data.apps) initializeApps(data.apps);
            if (data.settings) {
                TabletState.settings = { ...TabletState.settings, ...data.settings };
                applySettings();
            }
            if (data.wallpapers) {
                TabletState.wallpapers = data.wallpapers;
                initializeWallpaperOptions();
            }
            if (data.playerData) {
                TabletState.playerData = data.playerData;
            }
            showTablet();
            break;
            
        case 'close':
            hideTablet();
            break;
            
        case 'updatePlayerData':
            TabletState.playerData = data.playerData;
            if (TabletState.currentScreen === 'settings') {
                loadSettingsValues();
            }
            break;
            
        case 'updateRepData':
            if (TabletState.currentApp === 'rep' && data.repData) {
                updateRepUI(data.repData);
            }
            break;
        
        // Camera mode events
        case 'enterCameraMode':
            enterCameraMode(data.isSelfie, data.keybinds);
            break;
            
        case 'exitCameraMode':
            exitCameraMode();
            break;
            
        case 'cameraUpdate':
            updateCameraModeIndicator(data.isSelfie);
            break;
            
        case 'cameraFlash':
            cameraFlash();
            break;
            
        case 'capturePhoto':
            capturePhoto(data.quality, data.mime);
            break;
            
        case 'photoAdded':
            // Add photo to gallery if it's open
            if (TabletState.currentApp === 'gallery' && data.url) {
                galleryState.photos.unshift({ id: Date.now(), url: data.url, date: new Date().toISOString() });
                renderGalleryPhotos();
            }
            break;
    }
});

// Keyboard Events
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && TabletState.isOpen) {
        if (TabletState.currentScreen !== 'home') {
            goHome();
        } else {
            closeTablet();
        }
    }
});

// Navigation Buttons
document.addEventListener('DOMContentLoaded', () => {
    // Back buttons
    document.getElementById('app-back-btn').addEventListener('click', goHome);
    document.getElementById('app-close-btn').addEventListener('click', goHome);
    document.getElementById('settings-back-btn').addEventListener('click', goHome);
    
    // Home indicator
    document.querySelector('.indicator-bar').addEventListener('click', () => {
        if (TabletState.currentScreen !== 'home') {
            goHome();
        }
    });
    
    // Settings change handlers
    document.getElementById('setting-wallpaper').addEventListener('change', (e) => {
        TabletState.settings.wallpaper = e.target.value;
        
        // Show/hide custom URL input
        const customContainer = document.getElementById('custom-wallpaper-container');
        if (e.target.value === 'custom') {
            customContainer.style.display = 'flex';
        } else {
            customContainer.style.display = 'none';
            applySettings();
            saveSettings();
        }
    });
    
    // Custom wallpaper URL apply button
    document.getElementById('apply-custom-wallpaper').addEventListener('click', () => {
        const url = document.getElementById('setting-custom-wallpaper').value.trim();
        if (url) {
            TabletState.settings.customWallpaper = url;
            applySettings();
            saveSettings();
        }
    });
    
    // Allow pressing Enter to apply custom wallpaper
    document.getElementById('setting-custom-wallpaper').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            document.getElementById('apply-custom-wallpaper').click();
        }
    });
    
    document.getElementById('setting-brightness').addEventListener('input', (e) => {
        TabletState.settings.brightness = parseInt(e.target.value);
        applySettings();
    });
    
    document.getElementById('setting-brightness').addEventListener('change', saveSettings);
    
    document.getElementById('setting-darkmode').addEventListener('change', (e) => {
        TabletState.settings.darkMode = e.target.checked;
        applySettings();
        saveSettings();
    });
    
    document.getElementById('setting-volume').addEventListener('change', (e) => {
        TabletState.settings.volume = parseInt(e.target.value);
        saveSettings();
    });
    
    document.getElementById('setting-notifications').addEventListener('change', (e) => {
        TabletState.settings.notifications = e.target.checked;
        saveSettings();
    });
    
    document.getElementById('setting-fontsize').addEventListener('change', (e) => {
        TabletState.settings.fontSize = e.target.value;
        applySettings();
        saveSettings();
    });
    
    // Darkweb / Crime Homepage handlers
    initDarkweb();
});

// ============================================
// Darkweb / Crime Homepage Functions
// ============================================

function initDarkweb() {
    const darkwebTrigger = document.getElementById('darkweb-trigger');
    const darkwebHomeBtn = document.getElementById('darkweb-home-btn');
    const homeContainer = document.getElementById('home-screen-container');
    
    if (darkwebTrigger) {
        darkwebTrigger.addEventListener('click', (e) => {
            e.stopPropagation();
            // Check if player can access darkweb (not police/medical)
            nuiCallback('canAccessDarkweb').then(data => {
                if (data && data.allowed) {
                    flipToDarkweb();
                } else {
                    // Silently fail - don't reveal the hidden feature exists
                    console.log('[MI Tablet] Darkweb access denied');
                }
            }).catch(() => {
                // Silently fail on error
                console.log('[MI Tablet] Darkweb access check failed');
            });
        });
    }
    
    if (darkwebHomeBtn) {
        darkwebHomeBtn.addEventListener('click', () => {
            flipToNormal();
        });
    }
    
    // Darkweb app icons
    document.querySelectorAll('.darkweb-app-icon').forEach(icon => {
        icon.addEventListener('click', () => {
            const appId = icon.dataset.app;
            openDarkwebApp(appId);
        });
    });
}

function flipToDarkweb() {
    const homeContainer = document.getElementById('home-screen-container');
    if (homeContainer) {
        homeContainer.classList.add('flipped');
        TabletState.isDarkwebMode = true;
        console.log('[MI Tablet] Flipped to Darkweb mode');
    }
}

function flipToNormal() {
    const homeContainer = document.getElementById('home-screen-container');
    if (homeContainer) {
        homeContainer.classList.remove('flipped');
        TabletState.isDarkwebMode = false;
        console.log('[MI Tablet] Flipped to Normal mode');
    }
}

function openDarkwebApp(appId) {
    // Set current app
    TabletState.currentApp = appId;
    nuiCallback('appOpened', { appId });
    
    switch (appId) {
        case 'criminal-rep':
            openCriminalRep();
            break;
        case 'territories':
            openTerritories();
            break;
        default:
            console.log('[MI Tablet] Unknown darkweb app:', appId);
    }
}

function openCriminalRep() {
    const template = document.getElementById('criminal-rep-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Street Rep';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Add darkweb styling to app screen
    document.getElementById('app-screen').classList.add('darkweb-app-mode');
    
    switchScreen('app');
    loadCriminalRepData();
}

function openTerritories() {
    // Clean up old map instance if it exists
    if (territoriesLeafletMap) {
        territoriesLeafletMap.remove();
        territoriesLeafletMap = null;
        territoriesLeafletLayer = null;
    }
    
    const template = document.getElementById('territories-app-template');
    const content = template.content.cloneNode(true);
    
    document.getElementById('app-title').textContent = 'Territories';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);
    
    // Add darkweb styling to app screen
    document.getElementById('app-screen').classList.add('darkweb-app-mode');
    
    switchScreen('app');
    
    // Load territories data
    loadTerritoriesData();
    
    // Setup refresh button
    const refreshBtn = document.getElementById('territories-refresh-btn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', () => {
            refreshBtn.classList.add('spinning');
            loadTerritoriesData().finally(() => {
                setTimeout(() => refreshBtn.classList.remove('spinning'), 500);
            });
        });
    }
    
    // Load and setup color pickers
    loadTerritoriesColors();
    setupTerritoriesColorPickers();
    
    // Start location polling
    startTerritoriesLocationPolling();
}

let territoriesLocationInterval = null;

// Default territory colors
const territoriesDefaultColors = {
    owned: '#00ff00',      // Green for player's gang
    other: '#00ffff',      // Cyan for other gangs
    contested: '#ffaa00',  // Orange for contested
    claiming: '#ffff00',   // Yellow for claiming/in-progress
    unclaimed: '#8b0000',  // Dark red for unclaimed/neutral
    restricted: '#808080'  // Gray for restricted zones
};

// Get current territory colors (with fallback to defaults)
function getTerritoriesColors() {
    try {
        const stored = localStorage.getItem('mi-tablet-territories-colors');
        if (stored) {
            return JSON.parse(stored);
        }
    } catch (e) {
        console.error('[MI Tablet] Failed to parse territory colors:', e);
    }
    return { ...territoriesDefaultColors };
}

// Save territory colors
function saveTerritoriesColors(colors) {
    try {
        localStorage.setItem('mi-tablet-territories-colors', JSON.stringify(colors));
    } catch (e) {
        console.error('[MI Tablet] Failed to save territory colors:', e);
    }
}

// Load colors into UI
function loadTerritoriesColors() {
    const colors = getTerritoriesColors();
    
    const ownedInput = document.getElementById('territories-color-owned');
    const otherInput = document.getElementById('territories-color-other');
    const contestedInput = document.getElementById('territories-color-contested');
    const claimingInput = document.getElementById('territories-color-claiming');
    const unclaimedInput = document.getElementById('territories-color-unclaimed');
    const restrictedInput = document.getElementById('territories-color-restricted');
    
    if (ownedInput) ownedInput.value = colors.owned;
    if (otherInput) otherInput.value = colors.other;
    if (contestedInput) contestedInput.value = colors.contested;
    if (claimingInput) claimingInput.value = colors.claiming;
    if (unclaimedInput) unclaimedInput.value = colors.unclaimed;
    if (restrictedInput) restrictedInput.value = colors.restricted;
}

// Setup color picker listeners
function setupTerritoriesColorPickers() {
    const ownedInput = document.getElementById('territories-color-owned');
    const otherInput = document.getElementById('territories-color-other');
    const contestedInput = document.getElementById('territories-color-contested');
    const claimingInput = document.getElementById('territories-color-claiming');
    const unclaimedInput = document.getElementById('territories-color-unclaimed');
    const restrictedInput = document.getElementById('territories-color-restricted');
    const resetBtn = document.getElementById('territories-reset-colors');
    
    const updateColors = () => {
        const colors = {
            owned: ownedInput?.value || territoriesDefaultColors.owned,
            other: otherInput?.value || territoriesDefaultColors.other,
            contested: contestedInput?.value || territoriesDefaultColors.contested,
            claiming: claimingInput?.value || territoriesDefaultColors.claiming,
            unclaimed: unclaimedInput?.value || territoriesDefaultColors.unclaimed,
            restricted: restrictedInput?.value || territoriesDefaultColors.restricted
        };
        saveTerritoriesColors(colors);
        // Redraw map with new colors
        if (territoriesLeafletMap && territoriesLeafletLayer) {
            redrawTerritoriesMap();
        }
    };
    
    if (ownedInput) ownedInput.addEventListener('change', updateColors);
    if (otherInput) otherInput.addEventListener('change', updateColors);
    if (contestedInput) contestedInput.addEventListener('change', updateColors);
    if (claimingInput) claimingInput.addEventListener('change', updateColors);
    if (unclaimedInput) unclaimedInput.addEventListener('change', updateColors);
    if (restrictedInput) restrictedInput.addEventListener('change', updateColors);
    
    if (resetBtn) {
        resetBtn.addEventListener('click', () => {
            saveTerritoriesColors(territoriesDefaultColors);
            loadTerritoriesColors();
            if (territoriesLeafletMap && territoriesLeafletLayer) {
                redrawTerritoriesMap();
            }
        });
    }
}

// Setup tab switching
function setupTerritoriesTabs() {
    // Use requestAnimationFrame to ensure DOM is fully painted
    requestAnimationFrame(() => {
        // Then wait another frame to be safe
        setTimeout(() => {
            const tabButtons = document.querySelectorAll('.territories-control-btn');
            const tabContents = document.querySelectorAll('.territories-tab-content');
            
            if (tabButtons.length === 0 || tabContents.length === 0) {
                // Retry after a longer delay if not found
                if (!setupTerritoriesTabs.retryCount) {
                    setupTerritoriesTabs.retryCount = 0;
                }
                setupTerritoriesTabs.retryCount++;
                
                if (setupTerritoriesTabs.retryCount > 5) {
                    return;
                }
                
                setTimeout(() => setupTerritoriesTabs(), 500);
                return;
            }
            
            tabButtons.forEach(btn => {
                btn.addEventListener('click', () => {
                    const tabName = btn.dataset.tab;
                    
                    // Remove active class from all buttons and contents
                    tabButtons.forEach(b => b.classList.remove('active'));
                    tabContents.forEach(c => c.classList.remove('active'));
                    
                    // Add active class to clicked button and corresponding content
                    btn.classList.add('active');
                    const activeContent = document.querySelector(`.territories-tab-content[data-tab="${tabName}"]`);
                    if (activeContent) {
                        activeContent.classList.add('active');
                        // Invalidate map size when switching to territories tab
                        if (tabName === 'territories' && territoriesLeafletMap) {
                            setTimeout(() => territoriesLeafletMap.invalidateSize(true), 100);
                        }
                    }
                });
            });
        }, 50);
    });
}

// Redraw the map with current colors
function redrawTerritoriesMap() {
    if (!territoriesLeafletLayer || !territoriesLeafletMap) return;
    territoriesLeafletLayer.clearLayers();
    
    // Redraw all current territories
    // We need to store the current territories data
    if (window.territoriesCurrentData && window.territoriesCurrentData.length > 0) {
        drawTerritoriesMap(window.territoriesCurrentData, currentGangInfo);
    }
}

function startTerritoriesLocationPolling() {
    stopTerritoriesLocationPolling();
    // Poll location every 3 seconds
    territoriesLocationInterval = setInterval(() => {
        loadTerritoriesLocation();
    }, 3000);
    // Load immediately
    loadTerritoriesLocation();
}

function stopTerritoriesLocationPolling() {
    if (territoriesLocationInterval) {
        clearInterval(territoriesLocationInterval);
        territoriesLocationInterval = null;
    }
}

function loadTerritoriesData() {
    const loadingEl = document.getElementById('territories-loading');
    const emptyEl = document.getElementById('territories-empty');
    const gangInfoEl = document.getElementById('territories-gang-info');
    const listSectionEl = document.getElementById('territories-list-section');
    const locationEl = document.getElementById('territories-location');
    
    if (loadingEl) loadingEl.style.display = 'flex';
    if (emptyEl) emptyEl.style.display = 'none';
    if (listSectionEl) listSectionEl.style.display = 'none';
    if (locationEl) locationEl.style.display = 'none';
    
    // Update status
    updateTerritoriesStatus('SCANNING');
    
    // Create timeout promise to prevent infinite loading
    const timeoutPromise = new Promise((resolve) => {
        setTimeout(() => resolve([null, null]), 5000);
    });
    
    const dataPromise = Promise.all([
        nuiCallback('getGangInfo'),
        nuiCallback('getGangTerritories')
    ]);
    
    return Promise.race([dataPromise, timeoutPromise]).then(([gangInfo, territories]) => {
        console.log('[MI Tablet] Territories gangInfo:', JSON.stringify(gangInfo));
        console.log('[MI Tablet] Territories data:', JSON.stringify(territories));
        
        if (loadingEl) loadingEl.style.display = 'none';
        
        // Check if gangInfo is valid and player is in a gang
        if (!gangInfo) {
            console.log('[MI Tablet] No gang info returned');
            if (emptyEl) emptyEl.style.display = 'flex';
            updateTerritoriesStatus('OFFLINE');
            return;
        }
        
        // Store gang info globally for use in territory filtering
        window.territoriesGangInfo = gangInfo;
        
        // Display gang info even if territories are empty
        displayGangInfo(gangInfo);
        
        // Display gang members
        displayGangMembers(gangInfo);
        
        // Display territories if available
        if (territories && Object.keys(territories).length > 0) {
            displayTerritories(territories, gangInfo);
            if (gangInfoEl) gangInfoEl.style.display = 'block';
            if (listSectionEl) listSectionEl.style.display = 'block';
            updateTerritoriesStatus('ACTIVE');
        } else {
            // Show gang info but indicate territories not available
            if (gangInfoEl) gangInfoEl.style.display = 'block';
            if (listSectionEl) listSectionEl.style.display = 'block';
            const listEl = document.getElementById('territories-list');
            if (listEl) {
                listEl.innerHTML = '<div class="territories-no-data">Territory data not available - syncing with game</div>';
            }
            updateTerritoriesStatus('ACTIVE');
        }
        
        if (locationEl) locationEl.style.display = 'block';
    }).catch(err => {
        console.error('[MI Tablet] Failed to load territories:', err);
        if (loadingEl) loadingEl.style.display = 'none';
        if (emptyEl) emptyEl.style.display = 'flex';
        updateTerritoriesStatus('ERROR');
    });
}

function updateTerritoriesStatus(status) {
    const statusEl = document.getElementById('territories-status');
    if (!statusEl) return;
    
    const statusMap = {
        'SCANNING': { icon: 'fa-spinner fa-spin', text: 'SCANNING' },
        'ACTIVE': { icon: 'fa-circle', text: 'ACTIVE' },
        'OFFLINE': { icon: 'fa-circle', text: 'OFFLINE' },
        'ERROR': { icon: 'fa-triangle-exclamation', text: 'ERROR' }
    };
    
    const config = statusMap[status] || statusMap['OFFLINE'];
    statusEl.innerHTML = `<i class="fas ${config.icon}"></i><span>${config.text}</span>`;
}

let territoriesLeafletMap = null;
let territoriesLeafletLayer = null;
let currentGangInfo = null;

// Calculate how many territories are currently being claimed
function getTerritoriesClaimingCount(territoryArray) {
    if (!territoryArray) return 0;
    
    return territoryArray.filter(t => {
        const status = t.status || t.data?.status || 'unknown';
        return status === 'claiming' || status === 'contested';
    }).length;
}

// Maximum territories that can be in claiming status simultaneously
const MAX_EXPANSION_ZONES = 4;

// Calculate total influence for a territory
function getTerritoriesInfluencePercent(territory) {
    if (!territory) return 0;
    
    const influence = territory.data?.influence || territory.influence;
    if (!influence) return 0;
    
    let total = 0;
    
    // Handle object format (keyed by gang ID)
    if (typeof influence === 'object' && !Array.isArray(influence)) {
        for (const gangId in influence) {
            const gangInfluence = influence[gangId];
            if (gangInfluence && typeof gangInfluence === 'object' && gangInfluence.amount) {
                total += gangInfluence.amount;
            }
        }
    }
    // Handle array format
    else if (Array.isArray(influence)) {
        for (const item of influence) {
            if (item && item.amount) {
                total += item.amount;
            }
        }
    }
    
    // Clamp to 0-100 range
    return Math.min(100, Math.max(0, Math.round(total)));
}

function drawTerritoriesMap(territories, gangInfo = null) {
    if (gangInfo) currentGangInfo = gangInfo;
    
    // Store territories for redrawing with color changes
    window.territoriesCurrentData = territories;
    const mapSection = document.getElementById('territories-map-section');
    const mapEl = document.getElementById('territories-map');
    
    if (!mapSection || !mapEl) return;
    if (!territories || territories.length === 0) {
        mapSection.style.display = 'none';
        return;
    }

    mapSection.style.display = 'block';

    if (!window.L) {
        console.error('[MI Tablet] Leaflet not loaded');
        return;
    }

    if (!territoriesLeafletMap) {
        // Clear any existing Leaflet instances from the container
        mapEl.innerHTML = '';
        
        const tileHost = 'https://cfx-nui-core/html/assets/tiles/{z}-{x}_{y}.webp';
        const crs = L.extend({}, L.CRS.Simple, {
            transformation: new L.Transformation(1 / 144, 39.4, -1 / 145, 57.95)
        });
        const bounds = L.latLngBounds([[-4000, -4000], [8000, 4000]]);

        territoriesLeafletMap = L.map(mapEl, {
            zoom: 4,
            maxBounds: bounds,
            crs: crs,
            zoomSnap: 1,
            attributionControl: false,
            zoomControl: false
        });

        L.tileLayer(tileHost, {
            maxZoom: 7,
            minZoom: 3,
            opacity: 1,
            zIndex: 1,
            noWrap: true,
            attribution: '&copy; TMC'
        }).addTo(territoriesLeafletMap);

        territoriesLeafletLayer = L.layerGroup().addTo(territoriesLeafletMap);
        territoriesLeafletMap.setView([-1200, 0], 4);
    } else {
        territoriesLeafletLayer.clearLayers();
    }

    const toNumber = (value) => {
        const n = parseFloat(value);
        return Number.isFinite(n) ? n : null;
    };

    const getCoords = (territory) => {
        const candidates = [
            territory?.coords,
            territory?.data?.coords,
            territory?.data?.centre,
            territory?.data?.center,
            territory?.data?.location,
            territory?.data?.position,
            territory?.data?.pos
        ];

        for (const c of candidates) {
            if (!c) continue;
            if (typeof c === 'string') {
                try {
                    const parsed = JSON.parse(c);
                    if (parsed) {
                        const x = toNumber(parsed.x ?? parsed[0] ?? parsed[1]);
                        const y = toNumber(parsed.y ?? parsed[1] ?? parsed[2]);
                        const z = toNumber(parsed.z ?? parsed[2] ?? parsed[3]);
                        if (x !== null && y !== null) return { x, y, z: z ?? 0 };
                    }
                } catch (e) {
                    continue;
                }
            }

            if (typeof c === 'object') {
                const x = toNumber(c.x ?? c[0] ?? c[1]);
                const y = toNumber(c.y ?? c[1] ?? c[2]);
                const z = toNumber(c.z ?? c[2] ?? c[3]);
                if (x !== null && y !== null) return { x, y, z: z ?? 0 };
            }
        }

        return null;
    };

    const getPolygonPoints = (territory) => {
        const points = territory?.data?.points || territory?.data?.polygon || territory?.data?.poly;
        if (!Array.isArray(points) || points.length < 3) return null;
        return points.map(p => {
            if (Array.isArray(p)) {
                return [Number(p[1] ?? p[0]), Number(p[0] ?? p[1])];
            }
            if (p && typeof p === 'object') {
                const x = Number(p.x ?? p[0] ?? 0);
                const y = Number(p.y ?? p[1] ?? 0);
                return [y, x];
            }
            return null;
        }).filter(Boolean);
    };

    const points = territories.map(t => ({ territory: t, coords: getCoords(t), poly: getPolygonPoints(t) }))
        .filter(p => p.coords || (p.poly && p.poly.length > 2));
    if (points.length === 0) return;

    const hexPoints = (x, y, radius) => {
        const pts = [];
        for (let i = 0; i < 6; i++) {
            const angle = (Math.PI / 180) * (60 * i);
            const hx = x + (radius * Math.cos(angle));
            const hy = y + (radius * Math.sin(angle));
            pts.push([hy, hx]);
        }
        return pts;
    };

    const bounds = L.latLngBounds([]);
    
    // Get custom territory colors
    const customColors = getTerritoriesColors();

    // Render all territories immediately
    points.forEach(({ territory, coords, poly }, index) => {
        const status = territory.status || territory.data?.status || 'unclaimed';
        const owner = territory.owner || territory.data?.owner;
        const playerGangId = window.territoriesGangInfo?.gangId || currentGangInfo?.gangId;
        
        let color = customColors.unclaimed; // Default for unclaimed/neutral
        
        // Determine color based on ownership and status
        if (status === 'restricted') {
            // Restricted zones use restricted color
            color = customColors.restricted;
        } else if (status === 'claiming') {
            // Claiming zones use claiming color (in-progress)
            color = customColors.claiming;
        } else if (status === 'contested') {
            // Contested zones use contested color
            color = customColors.contested;
        } else if (owner && owner !== false) {
            // Territory is owned by someone (and not marked as false/unclaimed)
            const ownerId = parseInt(owner);
            const playerGangInt = parseInt(playerGangId);
            
            if (ownerId === playerGangInt) {
                // Player's gang owns it - use custom owned color
                color = customColors.owned;
            } else {
                // Another gang owns it - use gang color if available, otherwise custom other color
                if (territory.gangColor) {
                    color = territory.gangColor;
                } else if (territory.data?.gangColor) {
                    color = territory.data.gangColor;
                } else {
                    color = customColors.other;
                }
            }
        }

        const radius = territory.data?.radius || territory.data?.size || territory.data?.range || 60.0;
        const polyPoints = (poly && poly.length > 2) ? poly : (coords ? hexPoints(coords.x, coords.y, radius) : []);
        polyPoints.forEach(pt => bounds.extend(pt));

        const polyLayer = L.polygon(polyPoints, {
            color: '#ffffff80',
            weight: 2,
            fillColor: color,
            fillOpacity: 0.35
        });
        
        // Build tooltip with label and influence percentage
        const influencePercent = getTerritoriesInfluencePercent(territory);
        const label = territory.label || territory.data?.label || `Territory ${territory.id}`;
        const displayLabel = (label === 'N/A' || label === 'n/a') ? `Territory ${territory.id}` : label;
        const tooltipText = `${displayLabel}<br/>Influence: ${influencePercent}%`;
        polyLayer.bindTooltip(tooltipText, { permanent: false });
        
        // Add feature properties for filtering
        polyLayer.feature = {
            properties: {
                id: territory.id
            }
        };

        polyLayer.addTo(territoriesLeafletLayer);
    });
    
    // Apply filtering and player location asynchronously (as enhancements, not blockers)
    setTimeout(() => {
        console.log('[MI Tablet] Starting async enhancements - filtering and player location');
        
        // Try to get player location and center map
        nuiCallback('getLocationInfo').then(locationData => {
            console.log('[MI Tablet] getLocationInfo response:', locationData);
            if (locationData && locationData.coords) {
                const playerCoords = locationData.coords;
                console.log('[MI Tablet] Centering map on player:', playerCoords);
                // Center map on player location with zoom level 6 for detailed local view
                territoriesLeafletMap.setView([playerCoords.y, playerCoords.x], 6);
                
                // Add player location marker
                if (window.playerLocationMarker) {
                    window.playerLocationMarker.remove();
                }
                
                // Create player location marker as a circle
                window.playerLocationMarker = L.circleMarker(
                    [playerCoords.y, playerCoords.x],
                    {
                        radius: 8,
                        fillColor: '#00ffff',
                        color: '#ffffff',
                        weight: 2,
                        opacity: 1,
                        fillOpacity: 0.8
                    }
                ).bindTooltip('Your Location', { permanent: false, direction: 'top' })
                 .addTo(territoriesLeafletLayer);
            } else {
                // Fallback to fitBounds if no location data
                if (bounds.isValid()) {
                    territoriesLeafletMap.fitBounds(bounds, { padding: [30, 30] });
                }
            }
        }).catch(err => {
            console.warn('[MI Tablet] Could not get location, using fitBounds:', err);
            if (bounds.isValid()) {
                territoriesLeafletMap.fitBounds(bounds, { padding: [30, 30] });
            }
        });
        
        // Try to filter territories by connectivity (for list only, not map)
        nuiCallback('getOwnedTerritoryIds').then(ownedIds => {
            console.log('[MI Tablet] getOwnedTerritoryIds response:', ownedIds);
            if (!ownedIds || ownedIds.length === 0) {
                console.log('[MI Tablet] No owned territories returned, showing all');
                return;
            }
            
            const ownedSet = new Set(ownedIds);
            const playerGangId = window.territoriesGangInfo?.gangId || currentGangInfo?.gangId;
            
            const distance = (p1, p2) => {
                const dx = p1.x - p2.x;
                const dy = p1.y - p2.y;
                return Math.sqrt(dx * dx + dy * dy);
            };
            
            const ADJACENCY_THRESHOLD = 200;
            const territoriesToShow = new Set();
            
            // Mark owned territories for list display
            points.forEach(({ territory }) => {
                if (ownedSet.has(territory.id)) {
                    territoriesToShow.add(territory.id);
                }
            });
            
            // Mark adjacent unclaimed territories for list display (must be unclaimed/status check, exclude restricted)
            points.forEach(({ territory, coords: coords1 }) => {
                if (ownedSet.has(territory.id) && coords1) {
                    points.forEach(({ territory: other, coords: coords2 }) => {
                        const otherStatus = other.status || other.data?.status || 'unclaimed';
                        const otherOwner = other.owner || other.data?.owner;
                        // Only include if it's actually unclaimed (no owner or owner is false) and NOT restricted
                        if (!ownedSet.has(other.id) && (!otherOwner || otherOwner === false) && otherStatus !== 'restricted' && coords2) {
                            if (distance(coords1, coords2) < ADJACENCY_THRESHOLD) {
                                territoriesToShow.add(other.id);
                            }
                        }
                    });
                }
            });
            
            // Store for later use in territory list filtering (list only)
            window.territoriesFilteredIds = Array.from(territoriesToShow);
            console.log('[MI Tablet] Filtered territories for list (owned + adjacent):', window.territoriesFilteredIds);
            
            // Re-render the territories list now that filter is set
            if (window.territoriesDisplayRender) {
                window.territoriesDisplayRender();
            }
            
            // Keep all territories on map - no filtering for map view
            console.log('[MI Tablet] Keeping all territories on map for visibility');
        }).catch(err => {
            console.warn('[MI Tablet] Could not calculate adjacent territories:', err);
        });
    }, 100);
    
    setTimeout(() => territoriesLeafletMap.invalidateSize(true), 50);
}

function displayGangInfo(gangInfo) {
    const gangInfoEl = document.getElementById('territories-gang-info');
    if (!gangInfoEl) return;
    
    const settings = gangInfo.gangSettings;
    const memberCount = gangInfo.gangMembers ? gangInfo.gangMembers.length : 0;
    const currentRank = gangInfo.gangMembers?.find(m => m.csn === gangInfo.csn)?.rank || 'Unknown';
    const rankLabel = settings.ranks?.find(r => r.name === currentRank)?.label || currentRank;
    
    gangInfoEl.innerHTML = `
        <div class="territories-gang-card">
            <div class="territories-gang-header">
                <div class="territories-gang-name" style="color: ${settings.colour || '#ff3333'}">
                    ${settings.name || 'Unknown Gang'}
                </div>
                <div class="territories-gang-rank">${rankLabel}</div>
            </div>
            <div class="territories-gang-stats">
                <div class="territories-gang-stat">
                    <i class="fas fa-users"></i>
                    <span>${memberCount}/${settings.maxMembers || 0}</span>
                </div>
                <button class="territories-action-btn territories-upkeep-btn" onclick="territoriesShowUpkeep()" title="View gang upkeep information">
                    <i class="fas fa-info-circle"></i>
                    <span>Upkeep</span>
                </button>
            </div>
        </div>
    `;
}

function displayGangMembers(gangInfo) {
    const membersSection = document.getElementById('territories-members-section');
    const membersList = document.getElementById('territories-members-list');
    
    if (!membersSection || !membersList) return;
    
    if (!gangInfo.gangMembers || gangInfo.gangMembers.length === 0) {
        membersSection.style.display = 'none';
        return;
    }
    
    membersSection.style.display = 'block';
    membersList.innerHTML = '';
    
    // Display each member
    gangInfo.gangMembers.forEach((member) => {
        if (!member) return;
        
        const memberEl = document.createElement('div');
        memberEl.className = 'territories-member-item';
        memberEl.innerHTML = `
            <div class="territories-member-info">
                <div class="territories-member-name">${member.name || 'Unknown'}</div>
                <div class="territories-member-rank">${member.rank || 'member'}</div>
            </div>
            <div class="territories-member-csn">${member.csn}</div>
        `;
        
        membersList.appendChild(memberEl);
    });
}

function displayTerritories(territories, gangInfo) {
    const listEl = document.getElementById('territories-list');
    if (!listEl) return;
    
    listEl.innerHTML = '';
    
    // Convert territories object to array, preserving IDs
    let territoryArray = [];
    if (Array.isArray(territories)) {
        territoryArray = territories;
    } else if (territories && typeof territories === 'object') {
        territoryArray = Object.entries(territories).map(([key, value]) => ({
            ...value,
            id: value.id || key  // Ensure ID is set
        }));
    }
    
    if (!territoryArray || territoryArray.length === 0) {
        listEl.innerHTML = '<div class="territories-no-data">No territories controlled</div>';
        // Draw empty map
        drawTerritoriesMap([], gangInfo);
        return;
    }
    
    // Store for use in render function
    window.territoriesCachedArray = territoryArray;
    window.territoriesCachedGangInfo = gangInfo;
    
    // Draw map with territories
    drawTerritoriesMap(territoryArray, gangInfo);
    
    console.log('[MI Tablet] Displaying ' + territoryArray.length + ' territories');
    
    // Display each territory - wait a moment for filtering to complete
    const displayTerritories_Render = () => {
        const listEl = document.getElementById('territories-list');
        if (!listEl) {
            console.warn('[MI Tablet] Could not find territories-list element');
            return;
        }
        
        const territoryArray = window.territoriesCachedArray || [];
        
        // Clear the list first
        listEl.innerHTML = '';
        
        const displayCount = territoryArray.filter(t => !window.territoriesFilteredIds || window.territoriesFilteredIds.includes(t.id)).length;
        console.log('[MI Tablet] Rendering territories - showing ' + displayCount + ' of ' + territoryArray.length);
        
        // Get current player's gang ID for ownership checking
        const playerGangId = window.territoriesGangInfo?.gangSettings?.id;
        
        territoryArray.forEach((territory, index) => {
            if (!territory) return;
            
            // Skip if this territory is filtered out (not owned or nearby)
            if (window.territoriesFilteredIds && !window.territoriesFilteredIds.includes(territory.id)) {
                return;
            }
            
            // Skip other gang territories from the list (they show on map only)
            const ownerId = territory.data?.owner || territory.owner;
            if (ownerId && ownerId !== playerGangId && ownerId !== false) {
                return;
            }
            
            // Skip restricted zones from the list
            if (territory.data?.status === 'restricted' || territory.status === 'restricted') {
                return;
            }
            
            const label = territory.label || territory.data?.label || 'Territory ' + index;
            const status = territory.data?.status || territory.status || 'unknown';
            const isOwned = ownerId && ownerId === playerGangId;
            const statusClass = status === 'captured' ? 'captured' : (status === 'claiming' ? 'claiming' : 'unclaimed');
            const statusText = status ? status.toUpperCase() : 'UNCLAIMED';
            const influencePercent = getTerritoriesInfluencePercent(territory);
            
            // Check if claim is on cooldown
            const claimCooldown = territory.data?.cooldowns?.claim || 0;
            const contestCooldown = territory.data?.cooldowns?.contest || 0;
            
            const territoryEl = document.createElement('div');
            territoryEl.className = 'territories-item territories-' + statusClass;
            
            // Build actions HTML based on ownership
            let actionsHTML = '';
            if (isOwned) {
                // Owned territories - show relinquish button
                actionsHTML = `<div class="territories-item-actions">
                    <span class="territories-status-badge">OWNED</span>
                    <button class="territories-action-btn territories-action-relinquish" onclick="territoriesAttemptRelinquish(${index})" title="Give up this territory">
                        <i class="fas fa-hand-fist"></i> Relinquish
                    </button>
                </div>`;
            } else if (status === 'restricted') {
                // Restricted zones - no actions
                actionsHTML = '<div class="territories-item-actions"><span class="territories-status-badge">NEUTRAL</span></div>';
            } else {
                // Claimable territories - check influence, cooldown, and expansion limit requirements
                const claimInfluenceRequired = 75; // From ZoneClaimConfig
                const contestInfluenceRequired = 50; // From ZoneContestConfig
                const claimingCount = getTerritoriesClaimingCount(window.territoriesCachedArray);
                const canExpand = claimingCount < MAX_EXPANSION_ZONES;
                
                const claimCooldown = territory.data?.cooldowns?.claim || 0;
                const contestCooldown = territory.data?.cooldowns?.contest || 0;
                
                // Determine if claim is disabled (by cooldown, influence, or expansion limit)
                const claimDisabled = (claimCooldown > 0 || influencePercent < claimInfluenceRequired || !canExpand) ? 'disabled' : '';
                const contestDisabled = (contestCooldown > 0 || influencePercent < contestInfluenceRequired) ? 'disabled' : '';
                
                // Build tooltips with reasons
                let claimTitle = 'Claim this territory (5000 cash + 200 cash_roll required)';
                if (claimCooldown > 0) {
                    claimTitle = 'On cooldown';
                } else if (influencePercent < claimInfluenceRequired) {
                    claimTitle = `Need ${claimInfluenceRequired}% influence (${influencePercent}% current)`;
                } else if (!canExpand) {
                    claimTitle = `Expansion limit reached (${claimingCount}/${MAX_EXPANSION_ZONES} zones claiming)`;
                }
                
                let contestTitle = 'Contest this territory (25000 cash + 75 cash_roll required)';
                if (contestCooldown > 0) {
                    contestTitle = 'On cooldown';
                } else if (influencePercent < contestInfluenceRequired) {
                    contestTitle = `Need ${contestInfluenceRequired}% influence (${influencePercent}% current)`;
                }
                
                actionsHTML = `<div class="territories-item-actions">
                    <button class="territories-action-btn territories-action-claim" onclick="territoriesAttemptClaim(${index})" ${claimDisabled} title="${claimTitle}">
                        <i class="fas fa-flag"></i> Claim
                    </button>
                    <button class="territories-action-btn territories-action-contest" onclick="territoriesAttemptContest(${index})" ${contestDisabled} title="${contestTitle}">
                        <i class="fas fa-crossed-swords"></i> Contest
                    </button>
                </div>`;
            }
            
            territoryEl.innerHTML = `
                <div class="territories-item-header">
                    <div class="territories-item-label">${label}</div>
                    <div class="territories-item-status">
                        <i class="fas fa-circle-notch"></i> ${statusText}
                    </div>
                </div>
                <div class="territories-item-info">
                    <span><i class="fas fa-map-marker"></i> Territory ${territory.id}</span>
                    <span><i class="fas fa-percentage"></i> Influence: ${influencePercent}%</span>
                </div>
                ${actionsHTML}
            `;
        
            listEl.appendChild(territoryEl);
        });
        
        // Setup tabs AFTER rendering is complete
        setupTerritoriesTabs();
    };
    
    // Store the render function globally so it can be called from async callbacks
    window.territoriesDisplayRender = displayTerritories_Render;
    
    // Wait for filtering to complete before rendering
    // The filtering happens at 100ms in drawTerritoriesMap setTimeout, so wait 200ms to be safe
    setTimeout(displayTerritories_Render, 200);
}

function loadTerritoriesLocation() {
    nuiCallback('getLocationInfo').then(data => {
        displayLocationInfo(data);
    }).catch(err => {
        console.error('[MI Tablet] Failed to load location:', err);
    });
}

function displayLocationInfo(locationData) {
    const locationInfoEl = document.getElementById('territories-location-info');
    const actionsEl = document.getElementById('territories-location-actions');
    
    if (!locationInfoEl || !actionsEl) return;
    
    // Check if player is in a zone based on new location data
    if (!locationData) {
        locationInfoEl.innerHTML = '<span>Not in a territory zone</span>';
        actionsEl.innerHTML = '';
        return;
    }
    
    // New location info includes inZone flag
    if (locationData.inZone) {
        const zoneName = locationData.zoneInfo?.label || 'Territory Zone';
        const zoneStatus = locationData.zoneInfo?.status || 'unknown';
        locationInfoEl.innerHTML = `<span style="color: #00ff00;"><i class="fas fa-check-circle"></i> In Zone: ${zoneName} (${zoneStatus.toUpperCase()})</span>`;
    } else {
        locationInfoEl.innerHTML = '<span>Not in a territory zone</span>';
    }
    
    // Build action buttons (legacy support for old location data format)
    let buttonsHTML = '';
    
    if (locationData.canClaim) {
        buttonsHTML += `<button class="territories-action-btn claim" onclick="territoriesAttemptClaim()">
            <i class="fas fa-flag"></i>
            <span>Claim</span>
        </button>`;
    }
    
    if (locationData.canContest) {
        buttonsHTML += `<button class="territories-action-btn contest" onclick="territoriesAttemptContest()">
            <i class="fas fa-swords"></i>
            <span>Contest</span>
        </button>`;
    }
    
    if (locationData.canUpgrade) {
        buttonsHTML += `<button class="territories-action-btn upgrade" onclick="territoriesUpgrade()">
            <i class="fas fa-arrow-up"></i>
            <span>Upgrade</span>
        </button>`;
    }
    
    if (locationData.canRelinquish) {
        buttonsHTML += `<button class="territories-action-btn relinquish" onclick="territoriesRelinquish()">
            <i class="fas fa-xmark"></i>
            <span>Relinquish</span>
        </button>`;
    }
    
    if (buttonsHTML === '') {
        actionsEl.innerHTML = '';
    } else {
        actionsEl.innerHTML = buttonsHTML;
    }
}

function territoriesAttemptClaim(territoryIndex) {
    const territoryArray = window.territoriesCachedArray || [];
    const territory = territoryArray[territoryIndex];
    
    if (!territory) {
        console.error('[MI Tablet] territoriesAttemptClaim: Territory not found at index', territoryIndex);
        showTerritoryNotification('Territory not found', 'error');
        return;
    }
    
    console.log(`[MI Tablet] territoriesAttemptClaim: Attempting to claim territory ${territory.id} (${territory.label || 'N/A'})`, { zoneId: territory.id });
    
    const claimBtn = document.querySelector(`[onclick="territoriesAttemptClaim(${territoryIndex})"]`);
    if (claimBtn) claimBtn.disabled = true;
    
    // Pass territory ID to server
    nuiCallback('gangAttemptClaim', { zoneId: territory.id }).then((result) => {
        console.log(`[MI Tablet] territoriesAttemptClaim: Server response for zone ${territory.id}:`, result);
        if (result && result.success) {
            showTerritoryNotification(`Claiming ${territory.label || 'Territory ' + territory.id}`, 'success');
        } else if (result === false) {
            showTerritoryNotification('Claim failed - check server logs', 'error');
        } else {
            showTerritoryNotification(result?.message || 'Failed to claim territory', 'error');
        }
        setTimeout(() => loadTerritoriesData(), 1000);
    }).catch(err => {
        console.error('[MI Tablet] Claim failed:', err);
        showTerritoryNotification('Claim error: ' + (err.message || 'Unknown error'), 'error');
        if (claimBtn) claimBtn.disabled = false;
    });
}

function territoriesAttemptContest(territoryIndex) {
    const territoryArray = window.territoriesCachedArray || [];
    const territory = territoryArray[territoryIndex];
    
    if (!territory) {
        showTerritoryNotification('Territory not found', 'error');
        return;
    }
    
    const contestBtn = document.querySelector(`[onclick="territoriesAttemptContest(${territoryIndex})"]`);
    if (contestBtn) contestBtn.disabled = true;
    
    // Pass territory ID to server
    nuiCallback('gangAttemptContest', { zoneId: territory.id }).then((result) => {
        if (result && result.success) {
            showTerritoryNotification(`Contesting ${territory.label || 'Territory ' + territory.id}`, 'success');
        } else {
            showTerritoryNotification(result?.message || 'Failed to contest territory', 'error');
        }
        setTimeout(() => loadTerritoriesData(), 1000);
    }).catch(err => {
        console.error('[MI Tablet] Contest failed:', err);
        showTerritoryNotification('Contest error: ' + (err.message || 'Unknown error'), 'error');
        if (contestBtn) contestBtn.disabled = false;
    });
}

function territoriesUpgrade() {
    const upgradeBtn = document.querySelector('[onclick="territoriesUpgrade()"]');
    if (upgradeBtn) upgradeBtn.disabled = true;
    
    nuiCallback('gangUpgradeTerritory').then((result) => {
        if (result && result.success) {
            showTerritoryNotification('Territory upgraded successfully', 'success');
        } else {
            showTerritoryNotification('Failed to upgrade territory', 'error');
        }
        setTimeout(() => loadTerritoriesData(), 1000);
    }).catch(err => {
        console.error('[MI Tablet] Upgrade failed:', err);
        showTerritoryNotification('Upgrade error: ' + (err.message || 'Unknown error'), 'error');
        if (upgradeBtn) upgradeBtn.disabled = false;
    });
}

function territoriesRelinquish() {
    if (!confirm('Are you sure you want to relinquish this territory?')) return;
    
    const relinquishBtn = document.querySelector('[onclick="territoriesRelinquish()"]');
    if (relinquishBtn) relinquishBtn.disabled = true;
    
    nuiCallback('gangRelinquishZone').then((result) => {
        if (result && result.success) {
            showTerritoryNotification('Territory relinquished', 'success');
        } else {
            showTerritoryNotification('Failed to relinquish territory', 'error');
        }
        setTimeout(() => loadTerritoriesData(), 1000);
    }).catch(err => {
        console.error('[MI Tablet] Relinquish failed:', err);
        showTerritoryNotification('Relinquish error: ' + (err.message || 'Unknown error'), 'error');
        if (relinquishBtn) relinquishBtn.disabled = false;
    });
}

function territoriesShowUpkeep() {
    const gangInfo = document.querySelector('.territories-gang-card');
    if (!gangInfo) {
        showInfoModal('Error', 'Gang information not available');
        return;
    }
    
    showInfoModal('Loading', 'Fetching gang upkeep information...');
    
    // Use timeout to prevent UI freeze
    const timeoutPromise = new Promise((resolve, reject) => {
        setTimeout(() => reject(new Error('Request timeout')), 5000);
    });
    
    Promise.race([
        nuiCallback('getGangUpkeep'),
        timeoutPromise
    ]).then((result) => {
        if (result && result.upkeep) {
            const weeklyCost = (result.upkeep.weeklyCost || 0).toLocaleString();
            const balance = (result.upkeep.balance || 0).toLocaleString();
            const daysUntilDue = result.upkeep.daysUntilDue || 'Unknown';
            
            const content = `
                <div class="info-line">
                    <span class="info-label">Weekly Cost:</span>
                    <span class="info-value">$${weeklyCost}</span>
                </div>
                <div class="info-line">
                    <span class="info-label">Current Balance:</span>
                    <span class="info-value">$${balance}</span>
                </div>
                <div class="info-line">
                    <span class="info-label">Days Until Due:</span>
                    <span class="info-value">${daysUntilDue}</span>
                </div>
            `;
            
            showInfoModal('Gang Upkeep', content);
        } else {
            showInfoModal('Error', 'Upkeep information not available');
        }
    }).catch(err => {
        console.error('[MI Tablet] Upkeep fetch failed:', err);
        showInfoModal('Error', 'Failed to fetch upkeep information');
    });
}

function territoriesRefresh() {
    const refreshBtn = document.getElementById('territories-refresh-btn');
    if (refreshBtn) {
        refreshBtn.style.animation = 'spin 1s linear infinite';
    }
    
    loadTerritoriesData().then(() => {
        if (refreshBtn) {
            refreshBtn.style.animation = 'none';
        }
    });
}

function territoriesRefreshLocation() {
    loadTerritoriesLocation();
}

function showTerritoryNotification(message, type = 'info') {
    // Create a temporary notification div
    const notification = document.createElement('div');
    notification.className = `territories-notification ${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        background: ${type === 'success' ? '#00ff00' : type === 'error' ? '#ff0000' : '#00ffff'};
        color: #000;
        border-radius: 4px;
        z-index: 10000;
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

function loadCriminalRepData() {
    const repList = document.getElementById('criminal-rep-list');
    const repEmpty = document.getElementById('criminal-rep-empty');
    
    if (repList) repList.innerHTML = '<div class="criminal-rep-line"><span class="name">Accessing encrypted data...</span></div>';
    if (repEmpty) repEmpty.style.display = 'none';
    
    // Fetch criminal rep data from server
    nuiCallback('getCriminalRep').then(data => {
        if (data && data.repData && Object.keys(data.repData).length > 0) {
            updateCriminalRepUI(data.repData);
        } else {
            showEmptyCriminalRepState();
        }
    }).catch(() => {
        showEmptyCriminalRepState();
    });
}

function updateCriminalRepUI(repData) {
    const repList = document.getElementById('criminal-rep-list');
    const repEmpty = document.getElementById('criminal-rep-empty');
    
    if (!repList) return;
    
    // Convert repData object to array of entries, filtering out values less than 1
    const entries = Object.entries(repData).filter(([name, value]) => {
        const numValue = parseFloat(value) || 0;
        return numValue >= 1;
    });
    
    if (entries.length === 0) {
        showEmptyCriminalRepState();
        return;
    }
    
    // Hide empty state
    if (repEmpty) repEmpty.style.display = 'none';
    
    // Clear and populate list
    repList.innerHTML = '';
    
    entries.forEach(([name, value]) => {
        const repLine = document.createElement('div');
        repLine.className = 'criminal-rep-line';
        
        const numValue = parseFloat(value) || 0;
        const valueClass = numValue >= 0 ? 'positive' : 'negative';
        
        repLine.innerHTML = `
            <span class="name">${name}</span>
            <span class="value ${valueClass}">${numValue}</span>
        `;
        
        repList.appendChild(repLine);
    });
}

function showEmptyCriminalRepState() {
    const repList = document.getElementById('criminal-rep-list');
    const repEmpty = document.getElementById('criminal-rep-empty');
    
    if (repList) repList.innerHTML = '';
    if (repEmpty) repEmpty.style.display = 'flex';
}

// ============================================
// Development Mode (for testing outside FiveM)
// ============================================

if (window.location.protocol === 'file:' || window.location.hostname === 'localhost') {
    console.log('[MI Tablet] Running in development mode');
    
    // Mock data for development
    setTimeout(() => {
        window.postMessage({
            type: 'open',
            apps: [
                { id: 'settings', name: 'Settings', icon: 'settings', enabled: true, isSystem: true },
                { id: 'browser', name: 'Browser', icon: 'globe', enabled: true, isSystem: false },
                { id: 'notes', name: 'Notes', icon: 'sticky-note', enabled: true, isSystem: false },
                { id: 'calculator', name: 'Calculator', icon: 'calculator', enabled: true, isSystem: false },
                { id: 'weather', name: 'Weather', icon: 'cloud-sun', enabled: true, isSystem: false },
                { id: 'camera', name: 'Camera', icon: 'camera', enabled: true, isSystem: false },
                { id: 'gallery', name: 'Gallery', icon: 'images', enabled: true, isSystem: false }
            ],
            settings: {
                wallpaper: 'default',
                brightness: 100,
                volume: 50,
                notifications: true,
                darkMode: false,
                fontSize: 'medium'
            },
            wallpapers: ['default', 'gradient-blue', 'gradient-purple', 'gradient-dark', 'nature-1', 'abstract-1'],
            playerData: {
                name: 'John Doe',
                job: 'Civilian',
                citizenid: 'ABC12345'
            }
        }, '*');
    }, 500);
}

// ============================================
// Info Modal System
// ============================================

function showInfoModal(title, content) {
    // Check if modal already exists
    let modal = document.getElementById('info-modal-overlay');
    
    if (!modal) {
        // Create modal from template
        const template = document.getElementById('info-modal-template');
        if (!template) {
            console.error('[MI Tablet] Info modal template not found');
            return;
        }
        
        const clone = template.content.cloneNode(true);
        document.body.appendChild(clone);
        modal = document.getElementById('info-modal-overlay');
    }
    
    // Update modal content
    const titleEl = document.getElementById('info-modal-title');
    const bodyEl = document.getElementById('info-modal-body');
    
    if (titleEl) titleEl.textContent = title;
    if (bodyEl) bodyEl.innerHTML = content;
    
    // Show modal
    if (modal) modal.style.display = 'flex';
}

function closeInfoModal() {
    const modal = document.getElementById('info-modal-overlay');
    if (modal) {
        modal.style.display = 'none';
    }
}

// Close modal when clicking overlay
document.addEventListener('click', function(event) {
    const modal = document.getElementById('info-modal-overlay');
    if (event.target === modal) {
        closeInfoModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeInfoModal();
    }
});

// ============================================
// GANG SETTINGS, MEMBERS, AND RELINQUISH FUNCTIONS
// ============================================

// Save gang setting
function saveSetting(settingType) {
    const gangInfo = window.territoriesGangInfo;
    if (!gangInfo) {
        showTerritoryNotification('Gang info not loaded', 'error');
        return;
    }
    
    let value = '';
    if (settingType === 'name') {
        value = document.getElementById('gang-name-input')?.value || '';
    } else if (settingType === 'color') {
        value = document.getElementById('gang-color-input')?.value || '';
    } else if (settingType === 'fillColor') {
        value = document.getElementById('gang-fill-color-input')?.value || '';
    }
    
    if (!value) {
        showTerritoryNotification('Please enter a value', 'error');
        return;
    }
    
    console.log(`[MI Tablet] Saving gang ${settingType}: ${value}`);
    nuiCallback('gangUpdateSetting', { 
        settingType: settingType, 
        value: value,
        gangId: gangInfo.gangId 
    }).then((result) => {
        if (result && result.success) {
            showTerritoryNotification(`${settingType} updated successfully`, 'success');
        } else {
            showTerritoryNotification(`Failed to update ${settingType}`, 'error');
        }
    }).catch(err => {
        console.error('[MI Tablet] Error updating setting:', err);
        showTerritoryNotification('Error updating setting', 'error');
    });
}

// Add gang rank
function addGangRank() {
    const rankName = document.getElementById('new-rank-input')?.value || '';
    if (!rankName) {
        showTerritoryNotification('Please enter a rank name', 'error');
        return;
    }
    
    const gangInfo = window.territoriesGangInfo;
    if (!gangInfo) {
        showTerritoryNotification('Gang info not loaded', 'error');
        return;
    }
    
    console.log(`[MI Tablet] Adding gang rank: ${rankName}`);
    nuiCallback('gangAddRank', { 
        rankName: rankName,
        gangId: gangInfo.gangId 
    }).then((result) => {
        if (result && result.success) {
            showTerritoryNotification('Rank added successfully', 'success');
            document.getElementById('new-rank-input').value = '';
            // Reload gang info
            loadTerritoriesData();
        } else {
            showTerritoryNotification('Failed to add rank', 'error');
        }
    }).catch(err => {
        console.error('[MI Tablet] Error adding rank:', err);
        showTerritoryNotification('Error adding rank', 'error');
    });
}

// Invite gang member
function inviteMember() {
    const csn = document.getElementById('invite-csn-input')?.value?.toUpperCase() || '';
    if (!csn || csn.length < 8) {
        showTerritoryNotification('Please enter a valid CSN (e.g., YZO12345)', 'error');
        return;
    }
    
    const gangInfo = window.territoriesGangInfo;
    if (!gangInfo) {
        showTerritoryNotification('Gang info not loaded', 'error');
        return;
    }
    
    console.log(`[MI Tablet] Inviting member: ${csn}`);
    nuiCallback('gangInviteMember', { 
        csn: csn,
        gangId: gangInfo.gangId 
    }).then((result) => {
        if (result && result.success) {
            showTerritoryNotification(`Invitation sent to ${csn}`, 'success');
            document.getElementById('invite-csn-input').value = '';
        } else {
            showTerritoryNotification(result?.message || 'Failed to invite member', 'error');
        }
    }).catch(err => {
        console.error('[MI Tablet] Error inviting member:', err);
        showTerritoryNotification('Error inviting member', 'error');
    });
}

// Relinquish territory
function territoriesAttemptRelinquish(territoryIndex) {
    const territoryArray = window.territoriesCachedArray || [];
    const territory = territoryArray[territoryIndex];
    
    if (!territory) {
        console.error('[MI Tablet] territoriesAttemptRelinquish: Territory not found at index', territoryIndex);
        showTerritoryNotification('Territory not found', 'error');
        return;
    }
    
    // Show confirmation dialog
    const confirmed = confirm(`Are you sure you want to relinquish territory ${territory.label || 'Territory ' + territory.id}?\n\nThis action cannot be undone.`);
    if (!confirmed) return;
    
    console.log(`[MI Tablet] territoriesAttemptRelinquish: Attempting to relinquish territory ${territory.id}`);
    
    nuiCallback('gangRelinquishZone', { zoneId: territory.id }).then((result) => {
        console.log(`[MI Tablet] territoriesAttemptRelinquish: Server response for zone ${territory.id}:`, result);
        if (result && result.success) {
            showTerritoryNotification(`${territory.label || 'Territory ' + territory.id} relinquished`, 'success');
            setTimeout(() => loadTerritoriesData(), 1000);
        } else {
            showTerritoryNotification(result?.message || 'Failed to relinquish territory', 'error');
        }
    }).catch(err => {
        console.error('[MI Tablet] Failed to relinquish territory:', err);
        showTerritoryNotification('Error relinquishing territory', 'error');
    });
}

// ============================================
// Mechanic App
// ============================================

function openMechanic() {
    const template = document.getElementById('mechanic-app-template');
    const content = template.content.cloneNode(true);

    document.getElementById('app-title').textContent = 'Mechanic';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);

    switchScreen('app');
}

// ============================================
// Bills App
// ============================================

function openBills() {
    const template = document.getElementById('bills-app-template');
    const content = template.content.cloneNode(true);

    document.getElementById('app-title').textContent = 'Bills';
    document.getElementById('app-content').innerHTML = '';
    document.getElementById('app-content').appendChild(content);

    switchScreen('app');

    // Attach billing button listener
    const billingBtn = document.getElementById('bills-send-billing-btn');
    if (billingBtn) {
        billingBtn.addEventListener('click', () => {
            nuiCallback('executeBilling').then(result => {
                if (result && result.success) {
                    console.log('[MI Tablet] Billing command executed');
                } else {
                    console.error('[MI Tablet] Failed to execute billing command');
                }
            });
        });
    }
}

console.log('[MI Tablet] Script loaded successfully');
