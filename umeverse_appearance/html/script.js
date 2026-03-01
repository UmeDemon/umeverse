(function () {
    'use strict';

    const COMPONENTS = [
        { id: 0, name: 'Head' },
        { id: 1, name: 'Mask' },
        { id: 2, name: 'Hair' },
        { id: 3, name: 'Torso' },
        { id: 4, name: 'Legs' },
        { id: 5, name: 'Bag' },
        { id: 6, name: 'Shoes' },
        { id: 7, name: 'Accessory' },
        { id: 8, name: 'Undershirt' },
        { id: 9, name: 'Kevlar' },
        { id: 10, name: 'Badge' },
        { id: 11, name: 'Torso 2' }
    ];

    const PROPS = [
        { id: 0, name: 'Hat' },
        { id: 1, name: 'Glasses' },
        { id: 2, name: 'Ears' },
        { id: 6, name: 'Watch' },
        { id: 7, name: 'Bracelet' }
    ];

    const OVERLAYS = [
        { id: 0, name: 'Blemishes' },
        { id: 1, name: 'Facial Hair' },
        { id: 2, name: 'Eyebrows' },
        { id: 3, name: 'Ageing' },
        { id: 4, name: 'Makeup' },
        { id: 5, name: 'Blush' },
        { id: 6, name: 'Complexion' },
        { id: 7, name: 'Sun Damage' },
        { id: 8, name: 'Lipstick' },
        { id: 9, name: 'Moles / Freckles' },
        { id: 10, name: 'Chest Hair' },
        { id: 11, name: 'Body Blemishes' },
        { id: 12, name: 'Add Body Blemishes' }
    ];

    let currentTab = 'components';
    let maxValues = {};
    let menuMode = 'clothing'; // 'clothing' or 'barber'

    const container = document.getElementById('appearance-container');
    const tabBar = document.getElementById('tab-bar');
    const slidersArea = document.getElementById('sliders-area');

    // NUI message handler
    window.addEventListener('message', function (event) {
        const data = event.data;

        if (data.action === 'openMenu') {
            maxValues = data.maxValues || {};
            menuMode = data.mode || 'clothing';
            container.classList.remove('hidden');
            buildTabs();
            switchTab('components');
        } else if (data.action === 'closeMenu') {
            container.classList.add('hidden');
        }
    });

    // ESC key
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            doCancel();
        }
    });

    function buildTabs() {
        tabBar.innerHTML = '';

        if (menuMode === 'barber') {
            // Only hair, overlays, hair color
            addTab('components', 'Hair');
            addTab('overlays', 'Face / Overlays');
            addTab('haircolor', 'Hair Color');
        } else {
            addTab('components', 'Clothing');
            addTab('props', 'Props');
            addTab('overlays', 'Face / Overlays');
            addTab('haircolor', 'Hair Color');
        }
    }

    function addTab(id, label) {
        const btn = document.createElement('button');
        btn.className = 'tab-btn';
        btn.dataset.tab = id;
        btn.textContent = label;
        btn.onclick = function () { switchTab(id); };
        tabBar.appendChild(btn);
    }

    function switchTab(tabId) {
        currentTab = tabId;
        document.querySelectorAll('.tab-btn').forEach(b => {
            b.classList.toggle('active', b.dataset.tab === tabId);
        });
        renderSliders();
    }

    function renderSliders() {
        slidersArea.innerHTML = '';

        if (currentTab === 'components') {
            const items = menuMode === 'barber' ? [COMPONENTS[2]] : COMPONENTS;
            items.forEach(comp => {
                const maxDraw = (maxValues.components && maxValues.components[comp.id]) ? maxValues.components[comp.id].maxDrawable : 25;
                const maxTex = (maxValues.components && maxValues.components[comp.id]) ? maxValues.components[comp.id].maxTexture : 10;

                addSlider(comp.name + ' Drawable', 0, maxDraw, 0, function (val) {
                    fetch('https://umeverse_appearance/updateComponent', {
                        method: 'POST',
                        body: JSON.stringify({ componentId: comp.id, drawable: parseInt(val), texture: 0 })
                    });
                }, 'comp_draw_' + comp.id);

                addSlider(comp.name + ' Texture', 0, maxTex, 0, function (val) {
                    fetch('https://umeverse_appearance/updateComponent', {
                        method: 'POST',
                        body: JSON.stringify({ componentId: comp.id, drawable: -1, texture: parseInt(val) })
                    });
                }, 'comp_tex_' + comp.id);
            });
        } else if (currentTab === 'props') {
            PROPS.forEach(prop => {
                const maxDraw = (maxValues.props && maxValues.props[prop.id]) ? maxValues.props[prop.id].maxDrawable : 25;
                const maxTex = (maxValues.props && maxValues.props[prop.id]) ? maxValues.props[prop.id].maxTexture : 10;

                addSlider(prop.name + ' Drawable', -1, maxDraw, -1, function (val) {
                    fetch('https://umeverse_appearance/updateProp', {
                        method: 'POST',
                        body: JSON.stringify({ propId: prop.id, drawable: parseInt(val), texture: 0 })
                    });
                }, 'prop_draw_' + prop.id);

                addSlider(prop.name + ' Texture', 0, maxTex, 0, function (val) {
                    fetch('https://umeverse_appearance/updateProp', {
                        method: 'POST',
                        body: JSON.stringify({ propId: prop.id, drawable: -1, texture: parseInt(val) })
                    });
                }, 'prop_tex_' + prop.id);
            });
        } else if (currentTab === 'overlays') {
            OVERLAYS.forEach(ov => {
                const maxIdx = (maxValues.overlays && maxValues.overlays[ov.id]) ? maxValues.overlays[ov.id].maxIndex : 10;

                addSlider(ov.name, 0, maxIdx, 0, function (val) {
                    fetch('https://umeverse_appearance/updateOverlay', {
                        method: 'POST',
                        body: JSON.stringify({ overlayId: ov.id, index: parseInt(val), opacity: 1.0 })
                    });
                }, 'overlay_idx_' + ov.id);

                addSlider(ov.name + ' Opacity', 0, 100, 100, function (val) {
                    fetch('https://umeverse_appearance/updateOverlay', {
                        method: 'POST',
                        body: JSON.stringify({ overlayId: ov.id, index: -1, opacity: parseInt(val) / 100.0 })
                    });
                }, 'overlay_opa_' + ov.id);
            });
        } else if (currentTab === 'haircolor') {
            addSlider('Hair Color', 0, 63, 0, function (val) {
                fetch('https://umeverse_appearance/updateHairColor', {
                    method: 'POST',
                    body: JSON.stringify({ colorPrimary: parseInt(val) })
                });
            }, 'hair_primary');

            addSlider('Hair Highlight', 0, 63, 0, function (val) {
                fetch('https://umeverse_appearance/updateHairColor', {
                    method: 'POST',
                    body: JSON.stringify({ colorSecondary: parseInt(val) })
                });
            }, 'hair_secondary');
        }
    }

    function addSlider(label, min, max, defaultVal, onChange, sliderId) {
        const group = document.createElement('div');
        group.className = 'slider-group';

        const lbl = document.createElement('div');
        lbl.className = 'slider-label';
        lbl.innerHTML = '<span>' + label + '</span><span id="val_' + sliderId + '">' + defaultVal + '</span>';

        const slider = document.createElement('input');
        slider.type = 'range';
        slider.min = min;
        slider.max = max;
        slider.value = defaultVal;
        slider.id = sliderId;
        slider.addEventListener('input', function () {
            document.getElementById('val_' + sliderId).textContent = this.value;
            onChange(this.value);
        });

        group.appendChild(lbl);
        group.appendChild(slider);
        slidersArea.appendChild(group);
    }

    // Rotate buttons
    document.getElementById('btn-rotate-left').addEventListener('click', function () {
        fetch('https://umeverse_appearance/rotatePed', {
            method: 'POST',
            body: JSON.stringify({ direction: 'left' })
        });
    });
    document.getElementById('btn-rotate-right').addEventListener('click', function () {
        fetch('https://umeverse_appearance/rotatePed', {
            method: 'POST',
            body: JSON.stringify({ direction: 'right' })
        });
    });

    // Save / Cancel
    document.getElementById('btn-save').addEventListener('click', function () {
        fetch('https://umeverse_appearance/saveAppearance', {
            method: 'POST', body: JSON.stringify({})
        });
    });

    document.getElementById('btn-cancel').addEventListener('click', function () {
        doCancel();
    });

    function doCancel() {
        fetch('https://umeverse_appearance/cancelAppearance', {
            method: 'POST', body: JSON.stringify({})
        });
    }
})();
