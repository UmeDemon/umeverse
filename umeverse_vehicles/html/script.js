let currentType = 'garage'; // 'garage' or 'impound'

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openGarage') {
        currentType = 'garage';
        document.getElementById('garage-title').textContent = data.title || 'Garage';
        renderVehicles(data.vehicles || []);
        document.getElementById('garage-container').classList.remove('hidden');
    }

    if (data.action === 'openImpound') {
        currentType = 'impound';
        document.getElementById('garage-title').textContent = 'Impound Lot';
        renderVehicles(data.vehicles || []);
        document.getElementById('garage-container').classList.remove('hidden');
    }

    if (data.action === 'closeGarage') {
        document.getElementById('garage-container').classList.add('hidden');
    }
});

function renderVehicles(vehicles) {
    const list = document.getElementById('vehicle-list');
    const emptyMsg = document.getElementById('empty-msg');
    list.innerHTML = '';

    if (!vehicles || vehicles.length === 0) {
        emptyMsg.classList.remove('hidden');
        return;
    }

    emptyMsg.classList.add('hidden');

    vehicles.forEach((veh) => {
        const card = document.createElement('div');
        card.classList.add('vehicle-card');

        const stateClass = veh.state === 1 ? 'state-stored' : veh.state === 0 ? 'state-out' : 'state-impounded';
        const stateText = veh.state === 1 ? 'Stored' : veh.state === 0 ? 'Out' : 'Impounded';

        const fuelPct = Math.min(100, Math.max(0, veh.fuel || 0));
        const bodyPct = Math.min(100, Math.max(0, (veh.body || 1000) / 10));
        const enginePct = Math.min(100, Math.max(0, (veh.engine || 1000) / 10));

        const canSpawn = (currentType === 'garage' && veh.state === 1) || (currentType === 'impound' && veh.state === 2);

        let btnLabel = 'Retrieve';
        if (currentType === 'impound') btnLabel = 'Pay & Retrieve';

        card.innerHTML = `
            <div class="vehicle-info">
                <div class="vehicle-name">${escapeHtml(veh.model)}</div>
                <div class="vehicle-plate">${escapeHtml(veh.plate)}</div>
                <div class="vehicle-stats">
                    <div class="stat">
                        <span>Fuel</span>
                        <div class="stat-bar"><div class="stat-fill fuel" style="width:${fuelPct}%"></div></div>
                    </div>
                    <div class="stat">
                        <span>Body</span>
                        <div class="stat-bar"><div class="stat-fill body" style="width:${bodyPct}%"></div></div>
                    </div>
                    <div class="stat">
                        <span>Engine</span>
                        <div class="stat-bar"><div class="stat-fill engine" style="width:${enginePct}%"></div></div>
                    </div>
                </div>
            </div>
            <div class="vehicle-state">
                <span class="state-badge ${stateClass}">${stateText}</span>
                <button class="spawn-btn" ${canSpawn ? '' : 'disabled'} onclick="selectVehicle(${veh.id})">${btnLabel}</button>
            </div>
        `;

        list.appendChild(card);
    });
}

function selectVehicle(vehicleId) {
    fetch(`https://${GetParentResourceName()}/selectVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: vehicleId, type: currentType }),
    });
    closeGarage();
}

function closeGarage() {
    document.getElementById('garage-container').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeGarage`, { method: 'POST', body: '{}' });
}

function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ESC key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeGarage();
    }
});
