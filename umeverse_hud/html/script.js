/* ═══════════════════════════════════════
   Umeverse HUD - Script
   ═══════════════════════════════════════ */
(function () {
    'use strict';

    /* ──── Constants ──── */
    const GAUGE_R       = 80;
    const GAUGE_CIRC    = 2 * Math.PI * GAUGE_R;          // 502.654
    const GAUGE_ARC     = GAUGE_CIRC * 0.75;              // 376.991  (270°)
    const RING_R        = 18;
    const RING_CIRC     = 2 * Math.PI * RING_R;           // 113.097
    const MPH_FACTOR    = 2.23694;
    const KMH_FACTOR    = 3.6;

    /* ──── State ──── */
    let settings = {
        speedUnit:    'mph',
        showHealth:   true,
        showArmor:    true,
        showHunger:   true,
        showThirst:   true,
        showVehicle:  true,
        showMinimap:  true,
        scaleStatus:  100,
        scaleVehicle: 100,
        scaleMinimap: 100,
    };
    let positions     = {};
    let dragMode      = false;
    let isDragging    = false;
    let dragEl        = null;
    let dragOffX      = 0;
    let dragOffY      = 0;
    let vehicleVisible = false;

    /* ──── Element refs ──── */
    const $ = (id) => document.getElementById(id);

    const statusHud     = $('status-hud');
    const vehicleHud    = $('vehicle-hud');
    const minimapHud    = $('minimap-hud');
    const settingsPanel = $('hud-settings');
    const dragHint      = $('drag-hint');

    // Gauge fills
    const rpmFill   = $('rpm-fill');
    const fuelFill  = $('fuel-fill');
    const speedFill = $('speed-fill');

    // Text displays
    const speedText = $('speed-text');
    const speedUnit = $('speed-unit');
    const rpmText   = $('rpm-text');
    const gearText  = $('gear-text');
    const fuelText  = $('fuel-text');

    // Status ring fills
    const healthFill = $('health-fill');
    const armorFill  = $('armor-fill');
    const hungerFill = $('hunger-fill');
    const thirstFill = $('thirst-fill');

    // Status containers (for toggling visibility)
    const healthCont = $('health-container');
    const armorCont  = $('armor-container');
    const hungerCont = $('hunger-container');
    const thirstCont = $('thirst-container');

    // Indicators
    const seatbeltInd = $('seatbelt-indicator');
    const engineInd   = $('engine-indicator');

    // Settings controls
    const btnMph    = $('btn-mph');
    const btnKmh    = $('btn-kmh');
    const btnDrag   = $('btn-drag');
    const btnReset  = $('btn-reset');
    const btnSave   = $('btn-save');
    const btnClose  = $('settings-close');
    const btnDone   = $('btn-done-drag');

    const chkHealth  = $('chk-health');
    const chkArmor   = $('chk-armor');
    const chkHunger  = $('chk-hunger');
    const chkThirst  = $('chk-thirst');
    const chkVehicle = $('chk-vehicle');
    const chkMinimap = $('chk-minimap');

    const scaleStatusSlider  = $('scale-status');
    const scaleVehicleSlider = $('scale-vehicle');
    const scaleMinimapSlider = $('scale-minimap');
    const scaleStatusVal     = $('scale-status-val');
    const scaleVehicleVal    = $('scale-vehicle-val');
    const scaleMinimapVal    = $('scale-minimap-val');

    // Minimap elements
    const compassSvg   = $('compass-svg');
    const headingText  = $('heading-text');
    const streetText   = $('street-text');
    const zoneText     = $('zone-text');

    /* ══════════════════════════════════════
       Utility helpers
       ══════════════════════════════════════ */

    /** Set a 270° arc gauge fill (value 0-1) */
    function setGauge(el, value) {
        const v = Math.max(0, Math.min(1, value));
        el.style.strokeDashoffset = GAUGE_ARC * (1 - v);
    }

    /** Set a full-circle ring fill (value 0-100) */
    function setRing(el, value) {
        const v = Math.max(0, Math.min(100, value));
        el.style.strokeDashoffset = RING_CIRC * (1 - v / 100);
    }

    /** RPM colour (smooth blue → cyan → amber → red) */
    function rpmColor(rpm) {
        if (rpm < 0.45) return 'hsl(210, 80%, 56%)';
        if (rpm < 0.70) {
            const t = (rpm - 0.45) / 0.25;
            const hue = 210 - t * 170;   // 210 → 40
            return `hsl(${hue}, 85%, 54%)`;
        }
        const t = Math.min(1, (rpm - 0.70) / 0.30);
        const hue = 40 - t * 40;         // 40 → 0
        const sat = 85 + t * 10;          // 85 → 95
        return `hsl(${hue}, ${sat}%, 52%)`;
    }

    /** Fuel colour */
    function fuelColor(pct) {
        if (pct > 45) return 'var(--fuel-ok)';
        if (pct > 20) return 'var(--fuel-low)';
        return 'var(--fuel-crit)';
    }

    /* ══════════════════════════════════════
       Tick-mark generator
       ══════════════════════════════════════ */
    function generateTicks(containerId, ticks) {
        const g = $(containerId);
        if (!g) return;
        const innerR = 67;
        const outerR = 78;
        const labelR = 55;

        ticks.forEach(function (t) {
            const angle = (135 + t.pos * 270) * Math.PI / 180;
            const cos   = Math.cos(angle);
            const sin   = Math.sin(angle);

            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', 100 + innerR * cos);
            line.setAttribute('y1', 100 + innerR * sin);
            line.setAttribute('x2', 100 + outerR * cos);
            line.setAttribute('y2', 100 + outerR * sin);
            if (t.major) line.classList.add('major');
            g.appendChild(line);

            if (t.label !== undefined) {
                const txt = document.createElementNS('http://www.w3.org/2000/svg', 'text');
                txt.setAttribute('x', 100 + labelR * cos);
                txt.setAttribute('y', 100 + labelR * sin);
                txt.setAttribute('text-anchor', 'middle');
                txt.setAttribute('dominant-baseline', 'central');
                txt.textContent = t.label;
                g.appendChild(txt);
            }
        });
    }

    /* Initialise tick marks once */
    (function initTicks() {
        // RPM: 0-8 (×1000)
        const rpmTicks = [];
        for (let i = 0; i <= 8; i++) {
            rpmTicks.push({ pos: i / 8, major: true, label: String(i) });
            if (i < 8) rpmTicks.push({ pos: (i + 0.5) / 8, major: false });
        }
        generateTicks('rpm-ticks', rpmTicks);

        // Fuel: E → F
        generateTicks('fuel-ticks', [
            { pos: 0,    major: true, label: 'E' },
            { pos: 0.25, major: false },
            { pos: 0.5,  major: true, label: '½' },
            { pos: 0.75, major: false },
            { pos: 1,    major: true, label: 'F' },
        ]);

        // Speed: 0-200 (labels every 40)
        const speedTicks = [];
        for (let i = 0; i <= 200; i += 20) {
            const pos = i / 200;
            const isMajor = (i % 40 === 0);
            speedTicks.push({ pos: pos, major: isMajor, label: isMajor ? String(i) : undefined });
        }
        generateTicks('speed-ticks', speedTicks);
    })();

    /* Generate compass tick marks */
    (function initCompassTicks() {
        const g = $('compass-ticks');
        if (!g) return;
        for (let deg = 0; deg < 360; deg += 5) {
            // Skip cardinals (0, 90, 180, 270) since we have text labels
            if (deg % 90 === 0) continue;
            const isMajor = (deg % 45 === 0);
            const angle = deg * Math.PI / 180;
            const innerR = isMajor ? 82 : 85;
            const outerR = 92;
            const cos = Math.cos(angle);
            const sin = Math.sin(angle);
            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', 100 + innerR * cos);
            line.setAttribute('y1', 100 + innerR * sin);
            line.setAttribute('x2', 100 + outerR * cos);
            line.setAttribute('y2', 100 + outerR * sin);
            if (isMajor) line.classList.add('major');
            g.appendChild(line);
        }
    })();

    /* ══════════════════════════════════════
       NUI Message Handler
       ══════════════════════════════════════ */
    window.addEventListener('message', function (ev) {
        const d = ev.data;
        if (!d || !d.action) return;

        switch (d.action) {

            /* ── Init (sent once after playerLoaded) ── */
            case 'init':
                if (d.settings)  applySettings(d.settings);
                if (d.positions) applyPositions(d.positions);
                applyVisibility(); // Re-apply scale transforms after position restore
                setTimeout(syncMinimapToLua, 200);
                break;

            /* ── Status bars ── */
            case 'updateStatus':
                setRing(healthFill, d.health);
                setRing(armorFill,  d.armor);
                setRing(hungerFill, d.hunger);
                setRing(thirstFill, d.thirst);
                break;

            /* ── Vehicle cluster ── */
            case 'updateVehicle':
                if (d.show && settings.showVehicle) {
                    if (!vehicleVisible) {
                        vehicleHud.classList.remove('hidden');
                        vehicleVisible = true;
                    }
                    updateVehicle(d);
                } else {
                    if (vehicleVisible) {
                        vehicleHud.classList.add('hidden');
                        vehicleVisible = false;
                    }
                }
                break;

            /* ── Custom minimap ── */
            case 'updateMinimap':
                if (d.hidden) {
                    minimapHud.classList.add('hidden');
                } else if (settings.showMinimap) {
                    minimapHud.classList.remove('hidden');
                    updateMinimap(d);
                }
                break;

            /* ── Settings panel ── */
            case 'openSettings':
                openSettings();
                break;

            /* ── External toggle ── */
            case 'toggleHud':
                document.getElementById('hud-wrapper').style.display =
                    d.visible ? '' : 'none';
                break;
        }
    });

    /* ══════════════════════════════════════
       Vehicle update
       ══════════════════════════════════════ */
    function updateVehicle(d) {
        // Speed
        const factor = settings.speedUnit === 'kmh' ? KMH_FACTOR : MPH_FACTOR;
        const maxSpeed = 200;
        const speed  = Math.floor(d.speed * factor);
        speedText.textContent = speed;
        speedUnit.textContent = settings.speedUnit === 'kmh' ? 'KM/H' : 'MPH';

        // Speed arc fill (0-200 range)
        const speedPct = Math.min(1, speed / maxSpeed);
        setGauge(speedFill, speedPct);
        // Colour: white → amber → red at high speed
        if (speedPct < 0.6) {
            speedFill.style.stroke = 'rgba(255, 255, 255, 0.9)';
        } else if (speedPct < 0.85) {
            const t = (speedPct - 0.6) / 0.25;
            speedFill.style.stroke = `hsl(${45 - t * 15}, 90%, 60%)`;
        } else {
            speedFill.style.stroke = '#ef4444';
        }

        // RPM
        const rpm = Math.max(0, Math.min(1, d.rpm));
        setGauge(rpmFill, rpm);
        rpmFill.style.stroke = rpmColor(rpm);
        rpmText.textContent = (rpm * 8).toFixed(1);

        // Gear
        let gearStr;
        if (d.gear === 0)          gearStr = 'R';
        else if (speed < 2 && rpm < 0.25) gearStr = 'N';
        else                       gearStr = String(d.gear);
        gearText.textContent = gearStr;

        // Fuel
        const fuel = Math.max(0, Math.min(100, d.fuel));
        setGauge(fuelFill, fuel / 100);
        fuelFill.style.stroke = fuelColor(fuel);
        fuelText.textContent  = Math.floor(fuel);

        // Seatbelt indicator
        if (d.seatbelt) {
            seatbeltInd.className = 'indicator ok';
        } else {
            seatbeltInd.className = 'indicator warn';
        }

        // Engine indicator
        engineInd.style.color = '';
        if (d.engineHealth > 700) {
            engineInd.className = 'indicator ok';
        } else if (d.engineHealth > 300) {
            engineInd.className = 'indicator warn';
        } else {
            engineInd.className = 'indicator warn';
            engineInd.style.color = '#ef4444';
        }
    }

    /* ══════════════════════════════════════
       Minimap (compass) update
       ══════════════════════════════════════ */
    function updateMinimap(d) {
        // Rotate compass ring opposite to heading so "N" always faces north
        // GTA heading: 0=N, 90=W, 180=S, 270=E  (clockwise in-game is negative rotation)
        // We need CSS rotation: heading degrees clockwise
        const rotation = d.heading;
        compassSvg.style.transform = 'rotate(' + rotation + 'deg)';

        // Heading text
        const displayHeading = Math.round((360 - d.heading) % 360);
        headingText.textContent = displayHeading + '\u00B0';

        // Street info
        let streetStr = d.street || '';
        if (d.cross && d.cross.length > 0) {
            streetStr += ' / ' + d.cross;
        }
        streetText.textContent = streetStr || 'Unknown';
        zoneText.textContent   = d.zone || '';
    }

    /* ══════════════════════════════════════       Sync NUI compass position → native radar
       ════════════════════════════════════════ */
    function syncMinimapToLua() {
        if (!minimapHud || minimapHud.classList.contains('hidden')) return;
        var container = document.querySelector('.minimap-container');
        if (!container) return;
        var rect = container.getBoundingClientRect();
        fetch('https://umeverse_hud/syncMinimapPosition', {
            method: 'POST',
            body: JSON.stringify({
                left:    rect.left,
                bottom:  window.innerHeight - rect.bottom,
                size:    rect.width,
                screenW: window.innerWidth,
                screenH: window.innerHeight,
            })
        });
    }

    /* ════════════════════════════════════════       Settings Panel
       ══════════════════════════════════════ */
    function openSettings() {
        syncCheckboxes();
        settingsPanel.classList.remove('hidden');
    }

    function closeSettings() {
        settingsPanel.classList.add('hidden');
        if (dragMode) exitDragMode();
        fetch('https://umeverse_hud/closeSettings', { method: 'POST', body: '{}' });
    }

    function syncCheckboxes() {
        chkHealth.checked  = settings.showHealth;
        chkArmor.checked   = settings.showArmor;
        chkHunger.checked  = settings.showHunger;
        chkThirst.checked  = settings.showThirst;
        chkVehicle.checked = settings.showVehicle;
        chkMinimap.checked = settings.showMinimap;

        scaleStatusSlider.value  = settings.scaleStatus;
        scaleVehicleSlider.value = settings.scaleVehicle;
        scaleMinimapSlider.value = settings.scaleMinimap;
        scaleStatusVal.textContent  = settings.scaleStatus  + '%';
        scaleVehicleVal.textContent = settings.scaleVehicle + '%';
        scaleMinimapVal.textContent = settings.scaleMinimap + '%';

        btnMph.classList.toggle('active', settings.speedUnit === 'mph');
        btnKmh.classList.toggle('active', settings.speedUnit === 'kmh');
    }

    function readSettings() {
        settings.speedUnit    = btnKmh.classList.contains('active') ? 'kmh' : 'mph';
        settings.showHealth   = chkHealth.checked;
        settings.showArmor    = chkArmor.checked;
        settings.showHunger   = chkHunger.checked;
        settings.showThirst   = chkThirst.checked;
        settings.showVehicle  = chkVehicle.checked;
        settings.showMinimap  = chkMinimap.checked;
        settings.scaleStatus  = parseInt(scaleStatusSlider.value, 10);
        settings.scaleVehicle = parseInt(scaleVehicleSlider.value, 10);
        settings.scaleMinimap = parseInt(scaleMinimapSlider.value, 10);

        applyVisibility();
    }

    function applyVisibility() {
        healthCont.style.display = settings.showHealth ? '' : 'none';
        armorCont.style.display  = settings.showArmor  ? '' : 'none';
        hungerCont.style.display = settings.showHunger ? '' : 'none';
        thirstCont.style.display = settings.showThirst ? '' : 'none';

        statusHud.style.transform  = 'scale(' + (settings.scaleStatus  / 100) + ')';
        statusHud.style.transformOrigin  = 'bottom left';
        vehicleHud.style.transform = 'scale(' + (settings.scaleVehicle / 100) + ')';
        vehicleHud.style.transformOrigin = 'bottom center';
        minimapHud.style.transform = 'scale(' + (settings.scaleMinimap / 100) + ')';
        minimapHud.style.transformOrigin = 'bottom left';

        // Show/hide minimap
        if (settings.showMinimap) {
            minimapHud.classList.remove('hidden');
        } else {
            minimapHud.classList.add('hidden');
        }

        // Tell Lua about minimap preference
        fetch('https://umeverse_hud/setMinimap', {
            method: 'POST',
            body: JSON.stringify({ show: settings.showMinimap })
        });

        // Sync native radar position to match NUI compass
        setTimeout(syncMinimapToLua, 50);
    }

    /* ── Live slider previews ── */
    scaleStatusSlider.addEventListener('input', function () {
        scaleStatusVal.textContent = this.value + '%';
        statusHud.style.transform  = 'scale(' + (this.value / 100) + ')';
        statusHud.style.transformOrigin = 'bottom left';
    });
    scaleVehicleSlider.addEventListener('input', function () {
        scaleVehicleVal.textContent = this.value + '%';
        vehicleHud.style.transform = 'scale(' + (this.value / 100) + ')';
        vehicleHud.style.transformOrigin = 'bottom center';
    });
    scaleMinimapSlider.addEventListener('input', function () {
        scaleMinimapVal.textContent = this.value + '%';
        minimapHud.style.transform = 'scale(' + (this.value / 100) + ')';
        minimapHud.style.transformOrigin = 'bottom left';
        syncMinimapToLua();
    });

    function saveAll() {
        readSettings();
        fetch('https://umeverse_hud/saveSettings',  { method: 'POST', body: JSON.stringify({ settings:  settings  }) });
        fetch('https://umeverse_hud/savePositions',  { method: 'POST', body: JSON.stringify({ positions: positions }) });
    }

    /* ── Button listeners ── */
    btnMph.addEventListener('click', function () {
        btnMph.classList.add('active');
        btnKmh.classList.remove('active');
    });
    btnKmh.addEventListener('click', function () {
        btnKmh.classList.add('active');
        btnMph.classList.remove('active');
    });
    btnClose.addEventListener('click', closeSettings);
    btnSave.addEventListener('click', function () {
        saveAll();
        closeSettings();
    });

    btnDrag.addEventListener('click', function () {
        settingsPanel.classList.add('hidden');
        enterDragMode();
    });

    btnReset.addEventListener('click', function () {
        positions = {};
        settings.scaleStatus  = 100;
        settings.scaleVehicle = 100;
        settings.scaleMinimap = 100;
        document.querySelectorAll('.hud-element').forEach(function (el) {
            el.style.left      = '';
            el.style.top       = '';
            el.style.right     = '';
            el.style.bottom    = '';
            el.style.transform = '';
            el.style.transformOrigin = '';
        });
        syncCheckboxes();
        fetch('https://umeverse_hud/savePositions', { method: 'POST', body: JSON.stringify({ positions: {} }) });
        fetch('https://umeverse_hud/saveSettings',  { method: 'POST', body: JSON.stringify({ settings:  settings  }) });
        setTimeout(syncMinimapToLua, 100);
    });

    btnDone.addEventListener('click', function () {
        exitDragMode();
        openSettings();
    });

    /* ── Escape key ── */
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            if (dragMode) {
                exitDragMode();
                openSettings();
            } else if (!settingsPanel.classList.contains('hidden')) {
                closeSettings();
            }
        }
    });

    /* ══════════════════════════════════════
       Drag Mode
       ══════════════════════════════════════ */
    function enterDragMode() {
        dragMode = true;
        dragHint.classList.remove('hidden');
        document.querySelectorAll('.hud-element').forEach(function (el) {
            el.classList.add('draggable');
        });
        // Show vehicle HUD and minimap so they can be repositioned even when hidden
        vehicleHud.classList.remove('hidden');
        minimapHud.classList.remove('hidden');
    }

    function exitDragMode() {
        dragMode = false;
        dragHint.classList.add('hidden');
        document.querySelectorAll('.hud-element').forEach(function (el) {
            el.classList.remove('draggable');
        });
        // Re-hide vehicle HUD if it was hidden
        if (!vehicleVisible) vehicleHud.classList.add('hidden');
        // Re-hide minimap if disabled
        if (!settings.showMinimap) minimapHud.classList.add('hidden');
        // Save positions
        capturePositions();
        fetch('https://umeverse_hud/savePositions', { method: 'POST', body: JSON.stringify({ positions: positions }) });
        // Re-sync native radar to new compass position
        syncMinimapToLua();
    }

    /* ── Drag event wiring ── */
    document.addEventListener('mousedown', function (e) {
        if (!dragMode) return;
        const el = e.target.closest('.hud-element.draggable');
        if (!el) return;

        isDragging = true;
        dragEl     = el;
        const rect = el.getBoundingClientRect();
        dragOffX   = e.clientX - rect.left;
        dragOffY   = e.clientY - rect.top;

        // Convert current position to top/left pixels
        el.style.position  = 'fixed';
        el.style.left      = rect.left + 'px';
        el.style.top       = rect.top  + 'px';
        el.style.bottom    = 'auto';
        el.style.right     = 'auto';
        el.style.transform = 'none';
    });

    document.addEventListener('mousemove', function (e) {
        if (!isDragging || !dragEl) return;
        dragEl.style.left = (e.clientX - dragOffX) + 'px';
        dragEl.style.top  = (e.clientY - dragOffY) + 'px';
    });

    document.addEventListener('mouseup', function () {
        if (!isDragging) return;
        isDragging = false;
        dragEl     = null;
    });

    /* ── Scroll-wheel resize in drag mode ── */
    document.addEventListener('wheel', function (e) {
        if (!dragMode) return;
        const el = e.target.closest('.hud-element.draggable');
        if (!el) return;
        e.preventDefault();

        const key  = el.dataset.element;
        let prop;
        if (key === 'status')       prop = 'scaleStatus';
        else if (key === 'minimap') prop = 'scaleMinimap';
        else                        prop = 'scaleVehicle';
        const delta = e.deltaY < 0 ? 5 : -5;
        settings[prop] = Math.max(50, Math.min(200, settings[prop] + delta));

        el.style.transform       = 'scale(' + (settings[prop] / 100) + ')';
        el.style.transformOrigin = 'bottom left';
    }, { passive: false });

    /* ── Window resize: re-sync native radar position ── */
    window.addEventListener('resize', function () {
        setTimeout(syncMinimapToLua, 100);
    });

    /* ── Position persistence ── */
    function capturePositions() {
        document.querySelectorAll('.hud-element').forEach(function (el) {
            const key  = el.dataset.element;
            const rect = el.getBoundingClientRect();
            if (!key) return;
            positions[key] = {
                leftPct: (rect.left / window.innerWidth)  * 100,
                topPct:  (rect.top  / window.innerHeight) * 100,
            };
        });
    }

    function applyPositions(saved) {
        if (!saved) return;
        positions = saved;
        Object.keys(saved).forEach(function (key) {
            const el = document.querySelector('[data-element="' + key + '"]');
            if (!el || !saved[key]) return;
            el.style.position  = 'fixed';
            el.style.left      = saved[key].leftPct + '%';
            el.style.top       = saved[key].topPct  + '%';
            el.style.bottom    = 'auto';
            el.style.right     = 'auto';
            el.style.transform = 'none';
        });
    }

    function applySettings(saved) {
        if (!saved) return;
        Object.assign(settings, saved);
        applyVisibility();
    }

})();
