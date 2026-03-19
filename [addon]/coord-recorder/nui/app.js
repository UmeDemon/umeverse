let coordsData = [];
let formatsData = {};

// Listen for messages from the client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openResults') {
        coordsData = data.coords;
        formatsData = data.formats;
        
        document.getElementById('coordCount').textContent = data.count;
        populateCoordsList(data.coords);
        populateFormats(data.formats);
        
        document.getElementById('mainContainer').classList.add('visible');
    }
});

// Populate the coordinates list
function populateCoordsList(coords) {
    const container = document.getElementById('coordsList');
    container.innerHTML = '';
    
    coords.forEach((coord, index) => {
        const item = document.createElement('div');
        item.className = 'coord-item';
        item.innerHTML = `
            <div class="coord-index">#${coord.index}</div>
            <div class="coord-values">
                <span class="coord-label">X:</span> <span class="coord-value">${coord.x}</span>
                <span class="coord-label">Y:</span> <span class="coord-value">${coord.y}</span>
                <span class="coord-label">Z:</span> <span class="coord-value">${coord.z}</span>
                <span class="coord-label">H:</span> <span class="coord-value">${coord.h}</span>
            </div>
            <button class="copy-single-btn" data-index="${index}">📋</button>
        `;
        container.appendChild(item);
    });
    
    // Add click handlers for single copy buttons
    document.querySelectorAll('.copy-single-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const index = parseInt(this.getAttribute('data-index'));
            const coord = coordsData[index];
            const text = `vector3(${coord.x}, ${coord.y}, ${coord.z})`;
            copyToClipboard(text);
        });
    });
}

// Populate format outputs
function populateFormats(formats) {
    document.getElementById('vector3Output').textContent = formats.vector3;
    document.getElementById('vector4Output').textContent = formats.vector4;
    document.getElementById('tableOutput').textContent = formats.table;
    document.getElementById('jsonOutput').textContent = formats.json;
    document.getElementById('simpleOutput').textContent = formats.simple;
}

// Tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        // Remove active from all tabs and contents
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        
        // Add active to clicked tab
        this.classList.add('active');
        
        // Show corresponding content
        const tabId = this.getAttribute('data-tab');
        document.getElementById('tab-' + tabId).classList.add('active');
    });
});

// Copy buttons
document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const format = this.getAttribute('data-format');
        const text = formatsData[format];
        copyToClipboard(text);
    });
});

// Copy to clipboard function
function copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    
    // Show notification
    showCopyNotification();
}

// Show copy notification
function showCopyNotification() {
    const notification = document.getElementById('copyNotification');
    notification.classList.add('visible');
    
    setTimeout(() => {
        notification.classList.remove('visible');
    }, 2000);
}

// Close UI
function closeUI() {
    document.getElementById('mainContainer').classList.remove('visible');
    
    fetch('https://coord-recorder/closeUI', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Close button
document.getElementById('closeBtn').addEventListener('click', closeUI);
document.getElementById('closeRecorderBtn').addEventListener('click', closeUI);

// Start new recording
document.getElementById('startNewBtn').addEventListener('click', function() {
    document.getElementById('mainContainer').classList.remove('visible');
    
    fetch('https://coord-recorder/startNew', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// ESC key to close
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});
