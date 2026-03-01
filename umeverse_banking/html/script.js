/* ═══════════════════════════════════════
   Umeverse Banking - UI Script
   ═══════════════════════════════════════ */

let bankData = null;

// ──── Open / Close ────

function openBank(data) {
    bankData = data;
    document.getElementById('bank-container').classList.remove('hidden');

    document.getElementById('bank-welcome').textContent = `Welcome, ${data.name}`;
    updateBalances(data.cash, data.bank);
    renderTransactions(data.transactions);

    // Load transfer player list
    loadPlayerList();
}

function closeBank() {
    document.getElementById('bank-container').classList.add('hidden');
    bankData = null;
}

function updateBalances(cash, bank) {
    document.getElementById('cash-amount').textContent = `$${Number(cash).toLocaleString()}`;
    document.getElementById('bank-amount').textContent = `$${Number(bank).toLocaleString()}`;
}

// ──── Tabs ────

document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

        tab.classList.add('active');
        document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
    });
});

// ──── Quick Amount Buttons ────

document.querySelectorAll('#tab-deposit .quick-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const val = btn.dataset.amount;
        document.getElementById('deposit-amount').value = val === 'all' ? bankData.cash : val;
    });
});

document.querySelectorAll('#tab-withdraw .quick-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const val = btn.dataset.amount;
        document.getElementById('withdraw-amount').value = val === 'all' ? bankData.bank : val;
    });
});

// ──── Actions ────

document.getElementById('btn-deposit').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('deposit-amount').value);
    if (!amount || amount <= 0) return;

    fetch(`https://${GetParentResourceName()}/deposit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount })
    });

    document.getElementById('deposit-amount').value = '';
});

document.getElementById('btn-withdraw').addEventListener('click', () => {
    const amount = parseInt(document.getElementById('withdraw-amount').value);
    if (!amount || amount <= 0) return;

    fetch(`https://${GetParentResourceName()}/withdraw`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount })
    });

    document.getElementById('withdraw-amount').value = '';
});

document.getElementById('btn-transfer').addEventListener('click', () => {
    const targetId = document.getElementById('transfer-target').value;
    const amount = parseInt(document.getElementById('transfer-amount').value);

    if (!targetId || !amount || amount <= 0) return;

    fetch(`https://${GetParentResourceName()}/transfer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: parseInt(targetId), amount })
    });

    document.getElementById('transfer-amount').value = '';
});

document.getElementById('btn-close').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeBank`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// ──── Player List ────

function loadPlayerList() {
    fetch(`https://${GetParentResourceName()}/getPlayerList`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(res => res.json()).then(players => {
        const select = document.getElementById('transfer-target');
        select.innerHTML = '<option value="">Select a player...</option>';
        if (Array.isArray(players)) {
            players.forEach(p => {
                const opt = document.createElement('option');
                opt.value = p.id;
                opt.textContent = `[${p.id}] ${p.name}`;
                select.appendChild(opt);
            });
        }
    }).catch(() => {});
}

// ──── Transaction History ────

function renderTransactions(transactions) {
    const list = document.getElementById('transaction-list');
    list.innerHTML = '';

    if (!transactions || transactions.length === 0) {
        list.innerHTML = '<p class="empty-msg">No transactions found.</p>';
        return;
    }

    transactions.forEach(tx => {
        const isPositive = tx.type === 'deposit' || tx.type === 'transfer_in';
        const item = document.createElement('div');
        item.className = 'transaction-item';
        item.innerHTML = `
            <div class="tx-info">
                <div class="tx-type ${tx.type}">${tx.type.replace('_', ' ')}</div>
                <div class="tx-desc">${tx.description || ''}</div>
            </div>
            <div class="tx-amount ${isPositive ? 'positive' : 'negative'}">
                ${isPositive ? '+' : '-'}$${Number(tx.amount).toLocaleString()}
            </div>
            <div class="tx-date">${tx.created_at || ''}</div>
        `;
        list.appendChild(item);
    });
}

// ──── NUI Message Handler ────

window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.action) {
        case 'openBank':
            openBank(data.data);
            break;
        case 'closeBank':
            closeBank();
            break;
    }
});

// ──── Escape ────

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeBank`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
