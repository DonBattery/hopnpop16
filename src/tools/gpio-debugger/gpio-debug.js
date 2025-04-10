(function () {
    // Configuration constants
    const GPIO_SIZE = 128;
    const MEMORY_BASE_ADDRESS = 0x5f80;

    // State variables
    let frames = [];
    let currentFrameIndex = -1;
    let editorEl = null;
    let currentHoveredCell = null;
    const gpioCells = [];

    // UI elements container
    const ui = (function createDebuggerUI() {
        const container = document.createElement("div");
        container.id = "gpio-debug";
        container.classList.add("closed");
        container.innerHTML = `
            <button id="gpio-toggle-btn">GPIO</button>
            <div id="gpio-panel-title">PICO-8 GPIO Debug Panel</div>
            <div id="gpio-actions">
                <button class="gpio-action-btn" id="gpio-clear-keep-first">Clear</button>
                <button class="gpio-action-btn" id="gpio-clear-all">Clear ALL</button>
                <button class="gpio-action-btn frame-btn" id="gpio-load-frames">Load Frames</button>
                <button class="gpio-action-btn frame-btn" id="gpio-set-frame">Set Frame</button>
                <button class="gpio-action-btn frame-btn" id="gpio-prev-frame">Prev Frame</button>
                <button class="gpio-action-btn frame-btn" id="gpio-next-frame">Next Frame</button>
                <div id="frame-status">No frames loaded</div>
            </div>
            <div id="gpio-content">
                <div id="bitfields">
                    <label class="label">Negotiator (Pin 1)</label>
                    <div class="bitfield" id="bitfield-0"></div>
                    <label class="label">Player1 (Pin 2)</label>
                    <div class="bitfield" id="bitfield-1"></div>
                </div>
                <label class="label">GPIO Pins (1 - 128) one byte each. Memory address inside PICO-8 (0x5f80 - 0x5fff)</label>
                <div id="gpio-grid"></div>
            </div>
        `;
        document.body.appendChild(container);

        // Create utility elements
        const tooltip = document.createElement("div");
        tooltip.className = "gpio-tooltip";
        document.body.appendChild(tooltip);

        const fileInput = document.createElement("input");
        fileInput.type = "file";
        fileInput.id = "gpio-frame-file-input";
        fileInput.accept = ".json";
        fileInput.style.display = "none";
        document.body.appendChild(fileInput);

        return {
            container,
            tooltip,
            toggleBtn: container.querySelector("#gpio-toggle-btn"),
            clearKeepFirstBtn: container.querySelector("#gpio-clear-keep-first"),
            clearAllBtn: container.querySelector("#gpio-clear-all"),
            loadFramesBtn: container.querySelector("#gpio-load-frames"),
            setFrameBtn: container.querySelector("#gpio-set-frame"),
            prevFrameBtn: container.querySelector("#gpio-prev-frame"),
            nextFrameBtn: container.querySelector("#gpio-next-frame"),
            frameStatus: container.querySelector("#frame-status"),
            fileInput,
            panelTitle: container.querySelector("#gpio-panel-title"),
            bitfield0: container.querySelector("#bitfield-0"),
            bitfield1: container.querySelector("#bitfield-1"),
            grid: container.querySelector("#gpio-grid")
        };
    })();

    // Initialize GPIO grid display
    function setupGpioGrid() {
        for (let i = 0; i < GPIO_SIZE; i++) {
            const el = document.createElement("div");
            el.className = 'gpio-cell';
            el.textContent = window.pico8_gpio?.[i] ?? 0;
            el.dataset.value = window.pico8_gpio?.[i] ?? 0;
            el.dataset.index = i;

            // Add mouse events for tooltip
            el.addEventListener("mouseenter", showTooltip);
            el.addEventListener("mouseleave", hideTooltip);
            el.addEventListener("mousemove", moveTooltip);

            gpioCells.push(el);
            ui.grid.appendChild(el);
        }
    }

    // Bitfield rendering
    function renderBits(bitfield, value) {
        bitfield.innerHTML = '';
        for (let i = 7; i >= 0; i--) {
            const bit = document.createElement("div");
            bit.className = "bit" + ((value >> i) & 1 ? " on" : "");
            bitfield.appendChild(bit);
        }
    }

    // Update all GPIO displays
    function updateGpioGrid() {
        const gpio = window.pico8_gpio || Array(GPIO_SIZE).fill(0);

        // Update bitfield displays
        renderBits(ui.bitfield0, gpio[0] || 0);
        renderBits(ui.bitfield1, gpio[1] || 0);

        // Update grid cells
        for (let i = 0; i < GPIO_SIZE; i++) {
            const value = gpio[i] ?? 0;
            gpioCells[i].textContent = value;
            gpioCells[i].dataset.value = value;
            gpioCells[i].setAttribute('data-value', value === 0 ? '0' : value);
        }
    }

    // Frame management functions
    function updateFrameStatus() {
        ui.frameStatus.textContent = frames.length === 0
            ? 'No frames loaded'
            : `Frame ${currentFrameIndex + 1}/${frames.length}`;
    }

    function applyCurrentFrame() {
        if (!frames.length || currentFrameIndex < 0 || currentFrameIndex >= frames.length) return;

        const frame = frames[currentFrameIndex];
        const offset = frame.pin_offset || 0;
        const values = frame.pin_values || [];

        if (!window.pico8_gpio) {
            window.pico8_gpio = Array(GPIO_SIZE).fill(0);
        }

        // Apply pin values from frame
        for (let i = 0; i < values.length; i++) {
            const pinIndex = offset + i;
            if (pinIndex < GPIO_SIZE) {
                window.pico8_gpio[pinIndex] = values[i];
            }
        }

        updateGpioGrid();
    }

    // Tooltip functions
    function showTooltip(e) {
        if (editorEl) return;
        currentHoveredCell = this;
        updateTooltipContent(this);
        ui.tooltip.style.display = "block";
        positionTooltip(e);
    }

    function hideTooltip() {
        ui.tooltip.style.display = "none";
        currentHoveredCell = null;
    }

    function moveTooltip(e) {
        if (ui.tooltip.style.display === "block") {
            positionTooltip(e);
            if (currentHoveredCell) updateTooltipContent(currentHoveredCell);
        }
    }

    function updateTooltipContent(cell) {
        const index = parseInt(cell.dataset.index);
        const value = window.pico8_gpio?.[index] ?? 0;
        const pinNumber = index + 1;
        const memoryAddress = MEMORY_BASE_ADDRESS + index;

        let tooltipContent = `Pin ${pinNumber}: ${value} (0x${value.toString(16).padStart(2, '0')})`;
        tooltipContent += `\nMemory: 0x${memoryAddress.toString(16).toUpperCase()}`;

        const bitfieldDiv = document.createElement("div");
        bitfieldDiv.className = "tooltip-bitfield";

        for (let i = 7; i >= 0; i--) {
            const bit = document.createElement("div");
            bit.className = "tooltip-bit" + ((value >> i) & 1 ? " on" : "");
            bitfieldDiv.appendChild(bit);
        }

        ui.tooltip.innerHTML = "";
        ui.tooltip.appendChild(document.createTextNode(tooltipContent));
        ui.tooltip.appendChild(bitfieldDiv);
    }

    function positionTooltip(e) {
        const tooltipRect = ui.tooltip.getBoundingClientRect();
        const tooltipWidth = tooltipRect.width || 120;
        const tooltipHeight = tooltipRect.height || 50;

        let x = Math.max(10, e.clientX + 10);
        let y = Math.max(10, e.clientY + 10);

        if (x + tooltipWidth > window.innerWidth - 10) {
            x = e.clientX - tooltipWidth - 10;
        }
        if (y + tooltipHeight > window.innerHeight - 10) {
            y = e.clientY - tooltipHeight - 10;
        }

        ui.tooltip.style.left = `${x}px`;
        ui.tooltip.style.top = `${y}px`;
    }

    // Editor functions
    function createEditor(index, targetEl) {
        if (editorEl) editorEl.remove();

        const gpio = window.pico8_gpio || Array(GPIO_SIZE).fill(0);
        const value = gpio[index] || 0;
        const memoryAddress = MEMORY_BASE_ADDRESS + index;
        const pinNumber = index + 1;

        editorEl = document.createElement("div");
        editorEl.className = "gpio-editor";

        // Create editor UI
        const addressInfo = document.createElement("div");
        addressInfo.className = "memory-address";
        addressInfo.textContent = `Pin ${pinNumber} (0x${memoryAddress.toString(16).toUpperCase()})`;
        editorEl.appendChild(addressInfo);

        const inputRow = document.createElement("div");
        inputRow.className = "input-row";

        const numInput = document.createElement("input");
        numInput.type = "number";
        numInput.min = 0;
        numInput.max = 255;
        numInput.value = value;

        const bits = [];
        const bitfield = document.createElement("div");
        bitfield.className = "gpio-bitfield";

        // Create bit toggles
        for (let i = 7; i >= 0; i--) {
            const bit = document.createElement("div");
            bit.className = "gpio-bit-toggle" + ((value >> i) & 1 ? " on" : "");
            bit.onclick = () => {
                bit.classList.toggle("on");
                updateValueFromBits();
            };
            bits.push(bit);
            bitfield.appendChild(bit);
        }

        // Value update functions
        function updateBitsFromValue(val) {
            bits.forEach((bit, i) => {
                bit.classList.toggle("on", (val >> (7 - i)) & 1);
            });
        }

        function updateValueFromBits() {
            let val = 0;
            bits.forEach((bit, i) => {
                if (bit.classList.contains("on")) {
                    val |= 1 << (7 - i);
                }
            });
            numInput.value = val;
            gpio[index] = val;
        }

        function applyValue() {
            const val = Math.min(255, Math.max(0, parseInt(numInput.value) || 0));
            gpio[index] = val;
            closeEditor();
        }

        function closeEditor() {
            editorEl.remove();
            editorEl = null;
            updateGpioGrid();
        }

        // Input event handlers
        numInput.addEventListener("keydown", (e) => {
            if (e.key === "Enter") {
                applyValue();
                e.preventDefault();
            }
        });

        numInput.oninput = () => {
            const val = Math.min(255, Math.max(0, parseInt(numInput.value) || 0));
            gpio[index] = val;
            updateBitsFromValue(val);
        };

        // Action buttons
        const okBtn = document.createElement("button");
        okBtn.textContent = "OK";
        okBtn.onclick = applyValue;

        const clearBtn = document.createElement("button");
        clearBtn.textContent = "Clear";
        clearBtn.className = "clear-btn";
        clearBtn.onclick = () => {
            numInput.value = 0;
            gpio[index] = 0;
            updateBitsFromValue(0);
            closeEditor();
        };

        // Assemble editor
        inputRow.appendChild(numInput);
        inputRow.appendChild(okBtn);
        inputRow.appendChild(clearBtn);
        editorEl.appendChild(inputRow);
        editorEl.appendChild(bitfield);
        document.body.appendChild(editorEl);

        // Position and focus
        positionEditor(targetEl);
        setTimeout(() => numInput.focus(), 0);
    }

    function positionEditor(targetEl) {
        const rect = targetEl.getBoundingClientRect();
        let left = rect.left;
        let top = rect.top - editorEl.offsetHeight - 10;

        if (top < 10) top = rect.bottom + 10;
        if (left + editorEl.offsetWidth > window.innerWidth - 10) {
            left = window.innerWidth - editorEl.offsetWidth - 10;
        }

        editorEl.style.left = `${Math.max(10, left)}px`;
        editorEl.style.top = `${Math.max(10, top)}px`;
    }

    // Main animation loop
    function loop() {
        updateGpioGrid();
        if (ui.tooltip.style.display === "block" && currentHoveredCell) {
            updateTooltipContent(currentHoveredCell);
        }
        requestAnimationFrame(loop);
    }

    // Event handlers
    function initEventHandlers() {
        // Toggle panel visibility
        ui.toggleBtn.onclick = () => ui.container.classList.toggle("closed");

        // Clear buttons
        ui.clearKeepFirstBtn.onclick = () => {
            if (!window.pico8_gpio) window.pico8_gpio = Array(GPIO_SIZE).fill(0);
            const firstPinValue = window.pico8_gpio[0] || 0;
            window.pico8_gpio = Array(GPIO_SIZE).fill(0);
            window.pico8_gpio[0] = firstPinValue;
            updateGpioGrid();
        };

        ui.clearAllBtn.onclick = () => {
            window.pico8_gpio = Array(GPIO_SIZE).fill(0);
            updateGpioGrid();
        };

        // Frame loading
        ui.loadFramesBtn.onclick = () => ui.fileInput.click();

        ui.fileInput.addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = (e) => {
                try {
                    const data = JSON.parse(e.target.result);
                    if (data?.frames?.length) {
                        frames = data.frames;
                        currentFrameIndex = 0;
                        updateFrameStatus();
                        applyCurrentFrame();
                    }
                } catch (error) {
                    console.error('Failed to load frames:', error);
                }
            };
            reader.readAsText(file);
            event.target.value = '';
        });

        // Frame navigation
        ui.prevFrameBtn.onclick = () => {
            if (frames.length && currentFrameIndex > 0) {
                currentFrameIndex--;
                updateFrameStatus();
                applyCurrentFrame();
            }
        };

        ui.nextFrameBtn.onclick = () => {
            if (frames.length && currentFrameIndex < frames.length - 1) {
                currentFrameIndex++;
                updateFrameStatus();
                applyCurrentFrame();
            }
        };

        // Frame selector
        ui.setFrameBtn.onclick = (e) => {
            if (document.querySelector(".frame-selector")) return;

            const selector = document.createElement("div");
            selector.className = "frame-selector";

            const input = document.createElement("input");
            input.type = "number";
            input.min = 1;
            input.max = frames.length;
            input.value = currentFrameIndex + 1;

            const okBtn = document.createElement("button");
            okBtn.textContent = "OK";
            okBtn.onclick = () => {
                const val = parseInt(input.value, 10);
                if (val >= 1 && val <= frames.length) {
                    currentFrameIndex = val - 1;
                    updateFrameStatus();
                    applyCurrentFrame();
                }
                selector.remove();
            };

            selector.appendChild(input);
            selector.appendChild(okBtn);
            document.body.appendChild(selector);

            // Position and focus
            const rect = e.target.getBoundingClientRect();
            selector.style.left = `${rect.left}px`;
            selector.style.top = `${rect.bottom + 5}px`;
            setTimeout(() => input.focus(), 0);

            // Close handlers
            function handleClickOutside(ev) {
                if (!selector.contains(ev.target)) {
                    selector.remove();
                    document.removeEventListener("mousedown", handleClickOutside);
                    document.removeEventListener("keydown", handleKey);
                }
            }

            function handleKey(ev) {
                if (ev.key === "Escape") {
                    selector.remove();
                    document.removeEventListener("mousedown", handleClickOutside);
                    document.removeEventListener("keydown", handleKey);
                }
            }

            document.addEventListener("mousedown", handleClickOutside);
            document.addEventListener("keydown", handleKey);
        };

        // Cell click handler
        document.addEventListener("click", (e) => {
            if (e.target.classList.contains("gpio-cell")) {
                const index = parseInt(e.target.dataset.index);
                createEditor(index, e.target);
                e.stopPropagation();
            } else if (editorEl && !editorEl.contains(e.target)) {
                editorEl.remove();
                editorEl = null;
            }
        });

        // Global key handler
        document.addEventListener("keydown", (e) => {
            if (e.key === "Escape" && editorEl) {
                editorEl.remove();
                editorEl = null;
            }
        });
    }

    // Initialization
    function init() {
        setupGpioGrid();
        initEventHandlers();
        requestAnimationFrame(loop);
    }

    // Start when DOM is ready
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();