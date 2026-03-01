/* ═══════════════════════════════════════
   Umeverse Framework - Core UI Script
   ═══════════════════════════════════════ */

// ──── Notification System ────

function showNotification(message, type = 'info', duration = 5000) {
    const container = document.getElementById('notification-container');
    const notif = document.createElement('div');
    notif.className = `notification ${type}`;
    notif.textContent = message;
    container.appendChild(notif);

    setTimeout(() => {
        notif.classList.add('fadeOut');
        setTimeout(() => notif.remove(), 300);
    }, duration);
}

// ──── Character Select ────

let currentCharacters = [];
let maxSlots = 3;

function showCharacterSelect(characters, maxSlotsConfig, serverName) {
    currentCharacters = characters;
    maxSlots = maxSlotsConfig || 3;

    document.getElementById('server-name').textContent = serverName || 'Umeverse RP';
    document.getElementById('character-select').classList.remove('hidden');
    document.getElementById('character-create').classList.add('hidden');
    document.getElementById('death-screen').classList.add('hidden');

    renderCharacterList();
}

function renderCharacterList() {
    const list = document.getElementById('char-list');
    list.innerHTML = '';

    if (currentCharacters.length === 0) {
        list.innerHTML = '<div class="empty-slot">No characters found. Create one to get started!</div>';
        return;
    }

    currentCharacters.forEach((char) => {
        const card = document.createElement('div');
        card.className = 'char-card';

        const money = char.money || {};
        const job = char.job || {};

        card.innerHTML = `
            <div class="char-info">
                <h3>${char.firstname} ${char.lastname}</h3>
                <p>${job.label || 'Unemployed'} | Cash: $${(money.cash || 0).toLocaleString()} | Bank: $${(money.bank || 0).toLocaleString()}</p>
            </div>
            <div style="display:flex;align-items:center;">
                <div class="char-meta">ID: ${char.citizenid}</div>
                <button class="delete-btn" data-id="${char.citizenid}">Delete</button>
            </div>
        `;

        card.addEventListener('click', (e) => {
            if (e.target.classList.contains('delete-btn')) return;
            selectCharacter(char.citizenid);
        });

        const deleteBtn = card.querySelector('.delete-btn');
        deleteBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            if (confirm('Are you sure you want to delete this character? This cannot be undone.')) {
                deleteCharacter(char.citizenid);
            }
        });

        list.appendChild(card);
    });
}

function selectCharacter(citizenid) {
    document.getElementById('character-select').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/selectCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: citizenid })
    });
}

function deleteCharacter(citizenid) {
    fetch(`https://${GetParentResourceName()}/deleteCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: citizenid })
    });
}

// ──── Character Creation ────

function showCharacterCreate() {
    document.getElementById('character-select').classList.add('hidden');
    document.getElementById('character-create').classList.remove('hidden');
}

document.getElementById('btn-create-char').addEventListener('click', () => {
    if (currentCharacters.length >= maxSlots) {
        showNotification('You have reached the maximum number of characters.', 'error');
        return;
    }
    showCharacterCreate();
});

document.getElementById('btn-back-select').addEventListener('click', () => {
    document.getElementById('character-create').classList.add('hidden');
    document.getElementById('character-select').classList.remove('hidden');
});

document.getElementById('create-form').addEventListener('submit', (e) => {
    e.preventDefault();

    const firstname = document.getElementById('firstname').value.trim();
    const lastname = document.getElementById('lastname').value.trim();
    const gender = document.getElementById('gender').value;
    const birthdate = document.getElementById('birthdate').value;
    const nationality = document.getElementById('nationality').value.trim() || 'American';

    if (!firstname || !lastname) {
        showNotification('Please fill in all required fields.', 'error');
        return;
    }

    document.getElementById('character-create').classList.add('hidden');

    fetch(`https://${GetParentResourceName()}/createCharacter`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            firstname,
            lastname,
            gender,
            birthdate,
            nationality
        })
    });

    // Reset form
    document.getElementById('create-form').reset();
});

// ──── Death Screen ────

let deathInterval = null;

function showDeathScreen(timer) {
    const screen = document.getElementById('death-screen');
    const countdown = document.getElementById('death-countdown');
    const respawnBtn = document.getElementById('btn-respawn');

    screen.classList.remove('hidden');
    countdown.textContent = timer;

    if (timer <= 0) {
        respawnBtn.disabled = false;
        document.getElementById('death-timer').textContent = 'You can now respawn.';
    } else {
        respawnBtn.disabled = true;
    }
}

function hideDeathScreen() {
    document.getElementById('death-screen').classList.add('hidden');
}

document.getElementById('btn-respawn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/respawn`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// ──── NUI Message Handler ────

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'notify':
            showNotification(data.message, data.type, data.duration);
            break;

        case 'showCharacterSelect':
            showCharacterSelect(data.characters, data.maxSlots, data.serverName);
            break;

        case 'showCharacterCreate':
            document.getElementById('server-name').textContent = data.serverName || 'Umeverse RP';
            showCharacterCreate();
            break;

        case 'showDeathScreen':
            showDeathScreen(data.timer);
            break;

        case 'hideDeathScreen':
            hideDeathScreen();
            break;
    }
});

// ──── Escape Key to Close ────

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Don't allow closing during character select/create — player must pick a character
        const charSelect = document.getElementById('character-select');
        const charCreate = document.getElementById('character-create');

        if (!charSelect.classList.contains('hidden') || !charCreate.classList.contains('hidden')) {
            // If in character create, go back to select instead
            if (!charCreate.classList.contains('hidden')) {
                charCreate.classList.add('hidden');
                charSelect.classList.remove('hidden');
            }
            return;
        }

        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
