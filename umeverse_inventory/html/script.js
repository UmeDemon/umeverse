/* ═══════════════════════════════════════
   Umeverse Inventory - UI Script
   ═══════════════════════════════════════ */

let inventoryData = null;
let selectedItem = null;
let selectedSource = null; // 'player' or 'secondary'

const typeIcons = {
    food: '🍔', drink: '🥤', medical: '💊', tool: '🔧',
    misc: '📦', document: '📄', ammo: '🔫', weapon: '🔫',
};

// ──── Open Inventory ────

function openInventory(data) {
    inventoryData = data;
    document.getElementById('inventory-container').classList.remove('hidden');

    renderGrid('player-grid', data.playerInventory, data.maxSlots, 'player');
    updateWeightBar('player', data.playerWeight, data.maxWeight);

    if (data.secondary) {
        document.getElementById('secondary-inventory').classList.remove('hidden');
        document.getElementById('secondary-label').textContent = data.secondaryLabel || 'Secondary';
        renderGrid('secondary-grid', data.secondary, data.secondaryMaxSlots, 'secondary');
        updateWeightBar('secondary', data.secondaryWeight, data.secondaryMaxWeight);
    } else {
        document.getElementById('secondary-inventory').classList.add('hidden');
    }
}

function closeInventory() {
    document.getElementById('inventory-container').classList.add('hidden');
    hideContextMenu();
    hideTooltip();
    inventoryData = null;
}

// ──── Render Grid ────

function renderGrid(gridId, inventory, maxSlots, source) {
    const grid = document.getElementById(gridId);
    grid.innerHTML = '';

    const items = inventory || [];
    const displaySlots = Math.max(maxSlots || 40, items.length);

    for (let i = 0; i < displaySlots; i++) {
        const slot = document.createElement('div');
        slot.className = 'inv-slot';
        slot.dataset.index = i;
        slot.dataset.source = source;

        if (items[i]) {
            const item = items[i];
            const def = (inventoryData.itemDefs && inventoryData.itemDefs[item.name]) || {};
            const icon = typeIcons[item.type || def.type] || '📦';

            slot.classList.add('has-item');
            slot.dataset.item = item.name;
            slot.dataset.amount = item.amount;

            slot.innerHTML = `
                <div class="item-icon">${icon}</div>
                <div class="item-name">${item.label || item.name}</div>
                ${item.amount > 1 ? `<div class="item-amount">x${item.amount}</div>` : ''}
                <div class="item-weight">${((item.weight || 0) * item.amount / 1000).toFixed(1)}kg</div>
            `;

            // Right click context
            slot.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                selectedItem = item.name;
                selectedSource = source;
                showContextMenu(e.clientX, e.clientY, source);
            });

            // Hover tooltip
            slot.addEventListener('mouseenter', (e) => {
                showTooltip(e.clientX, e.clientY, item, def);
            });
            slot.addEventListener('mouseleave', hideTooltip);
            slot.addEventListener('mousemove', (e) => {
                moveTooltip(e.clientX, e.clientY);
            });

            // Double click to transfer
            slot.addEventListener('dblclick', () => {
                const targetSource = source === 'player' ? 'secondary' : 'player';
                if (inventoryData.secondary || targetSource === 'player') {
                    transferItem(item.name, item.amount, source, targetSource);
                }
            });
        }

        grid.appendChild(slot);
    }
}

// ──── Weight Bar ────

function updateWeightBar(type, current, max) {
    const fill = document.getElementById(`${type}-weight-fill`);
    const text = document.getElementById(`${type}-weight-text`);
    const pct = Math.min((current / max) * 100, 100);

    fill.style.width = pct + '%';

    if (pct > 80) {
        fill.style.background = 'linear-gradient(90deg, #ef4444, #dc2626)';
    } else if (pct > 60) {
        fill.style.background = 'linear-gradient(90deg, #eab308, #f59e0b)';
    } else {
        fill.style.background = 'linear-gradient(90deg, #3b82f6, #6366f1)';
    }

    text.textContent = `${(current / 1000).toFixed(1)} / ${(max / 1000).toFixed(0)}kg`;
}

// ──── Context Menu ────

function showContextMenu(x, y, source) {
    const menu = document.getElementById('context-menu');
    menu.classList.remove('hidden');
    menu.style.left = x + 'px';
    menu.style.top = y + 'px';

    // Show/hide use button based on source
    document.getElementById('ctx-use').style.display = source === 'player' ? 'block' : 'none';
    document.getElementById('ctx-give').style.display = source === 'player' ? 'block' : 'none';
}

function hideContextMenu() {
    document.getElementById('context-menu').classList.add('hidden');
    selectedItem = null;
    selectedSource = null;
}

document.getElementById('ctx-use').addEventListener('click', () => {
    if (selectedItem) {
        fetch(`https://${GetParentResourceName()}/useItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ item: selectedItem })
        });
    }
    hideContextMenu();
});

document.getElementById('ctx-give').addEventListener('click', () => {
    if (selectedItem && inventoryData.secondary) {
        transferItem(selectedItem, 1, 'player', 'secondary');
    }
    hideContextMenu();
});

document.getElementById('ctx-drop').addEventListener('click', () => {
    if (selectedItem) {
        fetch(`https://${GetParentResourceName()}/dropItem`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ item: selectedItem, amount: 1 })
        });
    }
    hideContextMenu();
});

document.getElementById('ctx-close').addEventListener('click', hideContextMenu);

// ──── Tooltip ────

function showTooltip(x, y, item, def) {
    const tooltip = document.getElementById('tooltip');
    tooltip.classList.remove('hidden');
    document.getElementById('tooltip-name').textContent = item.label || item.name;
    document.getElementById('tooltip-desc').textContent = def.description || '';
    document.getElementById('tooltip-weight').textContent = `${((item.weight || 0) / 1000).toFixed(1)}kg each`;
    document.getElementById('tooltip-type').textContent = (item.type || def.type || 'misc').toUpperCase();
    moveTooltip(x, y);
}

function moveTooltip(x, y) {
    const tooltip = document.getElementById('tooltip');
    tooltip.style.left = (x + 15) + 'px';
    tooltip.style.top = (y + 15) + 'px';
}

function hideTooltip() {
    document.getElementById('tooltip').classList.add('hidden');
}

// ──── Transfer ────

function transferItem(itemName, amount, from, to) {
    fetch(`https://${GetParentResourceName()}/moveItem`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ item: itemName, amount, from, to })
    });
}

// ──── NUI Message Handler ────

window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.action) {
        case 'openInventory':
            openInventory(data.data);
            break;
        case 'closeInventory':
            closeInventory();
            break;
    }
});

// ──── Keyboard ────

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'F2') {
        fetch(`https://${GetParentResourceName()}/closeInventory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

// ──── Click outside context menu ────

document.addEventListener('click', (e) => {
    if (!e.target.closest('#context-menu')) {
        hideContextMenu();
    }
});
