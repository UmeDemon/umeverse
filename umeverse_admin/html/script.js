/* ═══════════════════════════════════════
   Umeverse Admin - UI Script
   ═══════════════════════════════════════ */

let panelData = null;

// ──── Open / Close ────

function openPanel(data) {
    panelData = data;
    document.getElementById('admin-container').classList.remove('hidden');
    document.getElementById('admin-badge').textContent = data.adminLabel || 'Admin';

    renderPlayerList(data.players);
    populateSelects(data);
    renderBanList(data.bans);
}

function closePanel() {
    document.getElementById('admin-container').classList.add('hidden');
    panelData = null;
}

// ──── Tabs ────

document.querySelectorAll('.admin-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        document.querySelectorAll('.admin-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.admin-content').forEach(c => c.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
    });
});

// ──── Player List ────

function renderPlayerList(players) {
    const list = document.getElementById('player-list');
    list.innerHTML = '';

    if (!players || players.length === 0) {
        list.innerHTML = '<p style="text-align:center;color:rgba(255,255,255,0.2);padding:20px;">No players online.</p>';
        return;
    }

    players.forEach(p => {
        const row = document.createElement('div');
        row.className = 'player-row';
        row.innerHTML = `
            <span class="p-id">#${p.id}</span>
            <span class="p-name">${p.name} <small style="color:rgba(255,255,255,0.25)">(${p.citizenid})</small></span>
            <span class="p-meta">${p.job} | ${p.ping}ms</span>
        `;
        list.appendChild(row);
    });
}

// ──── Search ────

document.getElementById('player-search').addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase();
    if (!panelData) return;

    const filtered = panelData.players.filter(p =>
        p.name.toLowerCase().includes(query) ||
        p.citizenid.toLowerCase().includes(query) ||
        String(p.id).includes(query)
    );
    renderPlayerList(filtered);
});

// ──── Populate Selects ────

function populateSelects(data) {
    // Player select
    const manageSelect = document.getElementById('manage-player');
    manageSelect.innerHTML = '';
    data.players.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id;
        opt.textContent = `[${p.id}] ${p.name}`;
        manageSelect.appendChild(opt);
    });

    // Job select
    const jobSelect = document.getElementById('job-select');
    jobSelect.innerHTML = '';
    data.jobs.forEach(j => {
        const opt = document.createElement('option');
        opt.value = j.name;
        opt.textContent = j.label;
        opt.dataset.grades = JSON.stringify(j.grades);
        jobSelect.appendChild(opt);
    });

    // Update grades on job change
    jobSelect.addEventListener('change', updateGrades);
    updateGrades();

    // Item select
    const itemSelect = document.getElementById('item-select');
    itemSelect.innerHTML = '';
    data.items.forEach(i => {
        const opt = document.createElement('option');
        opt.value = i.name;
        opt.textContent = i.label;
        itemSelect.appendChild(opt);
    });
}

function updateGrades() {
    const jobSelect = document.getElementById('job-select');
    const gradeSelect = document.getElementById('grade-select');
    gradeSelect.innerHTML = '';

    const selected = jobSelect.options[jobSelect.selectedIndex];
    if (!selected) return;

    const grades = JSON.parse(selected.dataset.grades || '[]');
    grades.forEach(g => {
        const opt = document.createElement('option');
        opt.value = g.grade;
        opt.textContent = `${g.grade}: ${g.name}`;
        gradeSelect.appendChild(opt);
    });
}

// ──── Quick Actions ────

document.querySelectorAll('.action-card').forEach(card => {
    card.addEventListener('click', () => {
        const action = card.dataset.action;
        if (action === 'revive_self') {
            sendAction('revive', {});
        } else if (action === 'heal_self') {
            sendAction('heal', {});
        } else {
            sendAction(action, {});
        }
    });
});

document.getElementById('btn-spawn-vehicle').addEventListener('click', () => {
    const model = document.getElementById('spawn-model').value.trim();
    if (!model) return;
    sendAction('spawn_vehicle', { model });
    document.getElementById('spawn-model').value = '';
});

document.getElementById('btn-tp-coords').addEventListener('click', () => {
    const x = document.getElementById('tp-x').value;
    const y = document.getElementById('tp-y').value;
    const z = document.getElementById('tp-z').value;
    if (!x || !y || !z) return;
    sendAction('teleport_coords', { x: parseFloat(x), y: parseFloat(y), z: parseFloat(z) });
});

// ──── Manage Actions ────

function getTargetId() {
    return parseInt(document.getElementById('manage-player').value);
}

document.getElementById('btn-goto').addEventListener('click', () => {
    sendAction('goto_player', { targetId: getTargetId() });
});

document.getElementById('btn-bring').addEventListener('click', () => {
    sendAction('bring_player', { targetId: getTargetId() });
});

document.getElementById('btn-revive-target').addEventListener('click', () => {
    sendAction('revive', { targetId: getTargetId() });
});

document.getElementById('btn-heal-target').addEventListener('click', () => {
    sendAction('heal', { targetId: getTargetId() });
});

document.getElementById('btn-freeze').addEventListener('click', () => {
    sendAction('freeze', { targetId: getTargetId() });
});

document.getElementById('btn-spectate').addEventListener('click', () => {
    sendAction('spectate', { targetId: getTargetId() });
});

document.getElementById('btn-give-money').addEventListener('click', () => {
    const moneyType = document.getElementById('money-type').value;
    const amount = parseInt(document.getElementById('money-amount').value);
    if (!amount || amount <= 0) return;
    sendAction('give_money', { targetId: getTargetId(), moneyType, amount });
    document.getElementById('money-amount').value = '';
});

document.getElementById('btn-remove-money').addEventListener('click', () => {
    const moneyType = document.getElementById('money-type').value;
    const amount = parseInt(document.getElementById('money-amount').value);
    if (!amount || amount <= 0) return;
    sendAction('remove_money', { targetId: getTargetId(), moneyType, amount });
    document.getElementById('money-amount').value = '';
});

document.getElementById('btn-set-job').addEventListener('click', () => {
    const job = document.getElementById('job-select').value;
    const grade = parseInt(document.getElementById('grade-select').value);
    sendAction('set_job', { targetId: getTargetId(), job, grade });
});

document.getElementById('btn-give-item').addEventListener('click', () => {
    const item = document.getElementById('item-select').value;
    const amount = parseInt(document.getElementById('item-amount').value) || 1;
    sendAction('give_item', { targetId: getTargetId(), item, amount });
});

document.getElementById('btn-kick').addEventListener('click', () => {
    const reason = document.getElementById('punish-reason').value || 'No reason';
    sendAction('kick', { targetId: getTargetId(), reason });
});

document.getElementById('btn-ban').addEventListener('click', () => {
    const reason = document.getElementById('punish-reason').value || 'No reason';
    const duration = parseInt(document.getElementById('ban-duration').value) || 0;
    if (confirm(`Ban player for ${duration === 0 ? 'PERMANENTLY' : duration + ' hours'}?`)) {
        sendAction('ban', { targetId: getTargetId(), reason, duration });
    }
});

document.getElementById('btn-clear-inv').addEventListener('click', () => {
    if (confirm('Clear this player\'s entire inventory?')) {
        sendAction('clear_inventory', { targetId: getTargetId() });
    }
});

// ──── Server Actions ────

document.getElementById('btn-announce').addEventListener('click', () => {
    const msg = document.getElementById('announce-msg').value.trim();
    if (!msg) return;
    sendAction('announce', { message: msg });
    document.getElementById('announce-msg').value = '';
});

document.getElementById('btn-set-weather').addEventListener('click', () => {
    const weather = document.getElementById('weather-select').value;
    sendAction('set_weather', { weather });
});

document.getElementById('btn-set-time').addEventListener('click', () => {
    const hour = parseInt(document.getElementById('time-hour').value);
    const minute = parseInt(document.getElementById('time-minute').value) || 0;
    if (isNaN(hour)) return;
    sendAction('set_time', { hour, minute });
});

// ──── Ban List ────

function renderBanList(bans) {
    const list = document.getElementById('ban-list');
    list.innerHTML = '';

    if (!bans || bans.length === 0) {
        list.innerHTML = '<p style="text-align:center;color:rgba(255,255,255,0.2);padding:20px;">No bans found.</p>';
        return;
    }

    bans.forEach(ban => {
        const row = document.createElement('div');
        row.className = 'ban-row';
        row.innerHTML = `
            <div class="ban-info">
                <div class="ban-reason">${ban.reason || 'No reason'}</div>
                <div class="ban-meta">${ban.citizenid || ban.identifier} | ${ban.permanent ? 'Permanent' : 'Expires: ' + (ban.expires || 'N/A')}</div>
            </div>
            <button class="ban-unban" data-id="${ban.id}">Unban</button>
        `;

        row.querySelector('.ban-unban').addEventListener('click', () => {
            sendAction('unban', { banId: ban.id });
            row.remove();
        });

        list.appendChild(row);
    });
}

// ──── Helper ────

function sendAction(action, data) {
    fetch(`https://${GetParentResourceName()}/adminAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action, data })
    });
}

// ──── Close ────

document.getElementById('btn-close').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closePanel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// ──── NUI Messages ────

window.addEventListener('message', (event) => {
    switch (event.data.action) {
        case 'openPanel': openPanel(event.data.data); break;
        case 'closePanel': closePanel(); break;
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closePanel`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
