// Aether Luxury Analog Simulator Javascript logic
const canvas = document.getElementById("watchCanvas");
const ctx = canvas.getContext("2d");

// Configuration state matching Monkey C defaults
const state = {
    colorTheme: 3, // Midnight Gold
    isSleep: false,
    showSeconds: true,
    steps: 8400,
    temperature: 72,
    heartRate: 76
};

// Theme color mapping from AetherView.mc
const themes = [
    ["#E8B4A0", "#8B5E4D", "#F5D5C8"], // 0 Rose Gold
    ["#5EB8B8", "#2F6B6B", "#A8E0E0"], // 1 Arctic Teal
    ["#E07A3D", "#8C4720", "#F5B88A"], // 2 Ember Orange
    ["#C5A26F", "#6B5537", "#E8D5A3"], // 3 Midnight Gold (default)
    ["#5C8A5E", "#2F4730", "#9DC29E"], // 4 Forest Green
    ["#A78BBA", "#5C4A6B", "#D4C1E8"], // 5 Lavender Mist
    ["#B8C4CE", "#5F6B77", "#E6EBF0"], // 6 Pearl Silver
    ["#F4A261", "#8C5C2E", "#F8C58C"]  // 7 Solar Amber
];

// Helper to draw rotated coordinates
function rotatePoint(cx, cy, cosA, sinA, xOffset, yOffset) {
    const rx = cx + (xOffset * cosA - yOffset * sinA);
    const ry = cy + (xOffset * sinA + yOffset * cosA);
    return { x: rx, y: ry };
}

// Draw the custom 3-point crown
function drawCrown(ctx, cx, cy, px, py, goldColor) {
    ctx.fillStyle = goldColor;

    // Base structure polygon
    ctx.beginPath();
    ctx.moveTo(px - 5, py + 8);
    ctx.lineTo(px + 5, py + 8);
    ctx.lineTo(px + 6, py + 5);
    ctx.lineTo(px + 4, py + 4);
    ctx.lineTo(px - 4, py + 4);
    ctx.lineTo(px - 6, py + 5);
    ctx.closePath();
    ctx.fill();

    // 3 spikes
    ctx.beginPath();
    ctx.moveTo(px - 1.5, py + 4);
    ctx.lineTo(px + 1.5, py + 4);
    ctx.lineTo(px, py - 4);
    ctx.closePath();
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(px - 5.0, py + 4);
    ctx.lineTo(px - 3.0, py + 4);
    ctx.lineTo(px - 6, py - 1);
    ctx.closePath();
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(px + 3.0, py + 4);
    ctx.lineTo(px + 5.0, py + 4);
    ctx.lineTo(px + 6, py - 1);
    ctx.closePath();
    ctx.fill();

    // 3 dots on tips
    ctx.beginPath();
    ctx.arc(px, py - 4, 1.5, 0, Math.PI * 2);
    ctx.fill();

    ctx.beginPath();
    ctx.arc(px - 6, py - 1, 1.5, 0, Math.PI * 2);
    ctx.fill();

    ctx.beginPath();
    ctx.arc(px + 6, py - 1, 1.5, 0, Math.PI * 2);
    ctx.fill();

    // Base cutout (same as background color)
    ctx.fillStyle = "#05070A";
    ctx.beginPath();
    ctx.arc(px, py + 6, 2.5, 0, Math.PI * 2);
    ctx.fill();
}

// Draw a single baton index marker
function drawBatonMarker(ctx, cx, cy, angle, rDist, w, h, goldColor, lumColor) {
    const cosA = Math.cos(angle);
    const sinA = Math.sin(angle);

    const px = cx + rDist * cosA;
    const py = cy + rDist * sinA;

    // Gold outer frame
    ctx.fillStyle = goldColor;
    ctx.beginPath();
    let pt = rotatePoint(px, py, cosA, sinA, -h / 2, -w / 2);
    ctx.moveTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, h / 2, -w / 2);
    ctx.lineTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, h / 2, w / 2);
    ctx.lineTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, -h / 2, w / 2);
    ctx.lineTo(pt.x, pt.y);
    ctx.closePath();
    ctx.fill();

    // Luminous inner cap
    ctx.fillStyle = lumColor;
    ctx.beginPath();
    pt = rotatePoint(px, py, cosA, sinA, -h / 2 + 1.5, -w / 2 + 1);
    ctx.moveTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, h / 2 - 1.5, -w / 2 + 1);
    ctx.lineTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, h / 2 - 1.5, w / 2 - 1);
    ctx.lineTo(pt.x, pt.y);
    pt = rotatePoint(px, py, cosA, sinA, -h / 2 + 1.5, w / 2 - 1);
    ctx.lineTo(pt.x, pt.y);
    ctx.closePath();
    ctx.fill();
}

// Draw watch face components
function drawWatchFace() {
    const cx = canvas.width / 2;
    const cy = canvas.height / 2;
    const rad = cx - 12;

    const theme = themes[state.colorTheme];
    const accent = theme[0];
    const accentDark = theme[1];
    const highlight = theme[2];
    const bgColor = "#05070A";

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // 1. Concentric Radial Sunburst Background (skip in simulated sleep AOD)
    if (!state.isSleep) {
        const grad = ctx.createRadialGradient(cx, cy, 5, cx, cy, rad + 10);
        grad.addColorStop(0, "#1c222e");
        grad.addColorStop(0.5, "#0d1117");
        grad.addColorStop(1, bgColor);
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(cx, cy, rad + 10, 0, Math.PI * 2);
        ctx.fill();
    } else {
        ctx.fillStyle = bgColor;
        ctx.beginPath();
        ctx.arc(cx, cy, rad + 10, 0, Math.PI * 2);
        ctx.fill();
    }

    // 2. Bezel and Fluting Details (Skip in sleep mode)
    if (!state.isSleep) {
        ctx.strokeStyle = accent;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(cx, cy, rad + 1, 0, Math.PI * 2);
        ctx.stroke();

        ctx.lineWidth = 1;
        ctx.strokeStyle = accent;
        for (let i = 0; i < 60; i += 2) {
            const angle = (i * 6 * Math.PI) / 180.0;
            const cosA = Math.cos(angle);
            const sinA = Math.sin(angle);
            const x1 = cx + (rad + 1) * cosA;
            const y1 = cy + (rad + 1) * sinA;
            const x2 = cx + (rad + 5) * cosA;
            const y2 = cy + (rad + 5) * sinA;
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.stroke();
        }
    }

    // 3. Baton Indices and Crown Logo
    const rDist = rad * 0.81;
    const lumColor = state.isSleep ? "#00A8B5" : "#E6F0E6"; // Chromalight blue in sleep mode, off-white in active

    for (let i = 0; i < 12; i++) {
        const angle = i * 30 - 90;
        const radA = (angle * Math.PI) / 180.0;
        const px = cx + rDist * Math.cos(radA);
        const py = cy + rDist * Math.sin(radA);

        if (i === 0) {
            // 12 o'clock Crown
            drawCrown(ctx, cx, cy, px, py - 4, accent);
        } else if (i === 3 || i === 6 || i === 9) {
            // 3, 6, 9 batons suppressed for Date, Weather, and Steps windows
            continue;
        } else {
            drawBatonMarker(ctx, cx, cy, radA, rDist, 4.5, 12.0, accent, lumColor);
        }
    }

    // Outer ticks (skip in simulated sleep AOD)
    if (!state.isSleep) {
        ctx.strokeStyle = "#28303C";
        ctx.lineWidth = 1;
        const rInner = rad * 0.88;
        const rOuter = rad * 0.92;
        for (let i = 0; i < 60; i++) {
            if (i % 5 === 0) continue;
            const angle = (i * 6 * Math.PI) / 180.0;
            const cosA = Math.cos(angle);
            const sinA = Math.sin(angle);
            ctx.beginPath();
            ctx.moveTo(cx + rInner * cosA, cy + rInner * sinA);
            ctx.lineTo(cx + rOuter * cosA, cy + rOuter * sinA);
            ctx.stroke();
        }
    }

    // 4. Sub-Dials and Complications (Skip in simulated AOD)
    if (!state.isSleep) {
        // --- 9 O'clock Steps Count sub-dial ---
        const stepsX = cx - rad * 0.70;
        const stepsY = cy;
        ctx.fillStyle = bgColor;
        ctx.beginPath();
        ctx.arc(stepsX, stepsY, 19, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeStyle = accent;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(stepsX, stepsY, 18, 0, Math.PI * 2);
        ctx.stroke();

        ctx.fillStyle = "#8E9AAB";
        ctx.font = "9px 'Inter', sans-serif";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("STEPS", stepsX, stepsY - 6);

        ctx.fillStyle = "#FFFFFF";
        ctx.font = "bold 11px 'Roboto Condensed', sans-serif";
        let stepsStr = state.steps.toString();
        if (state.steps >= 10000) {
            stepsStr = (state.steps / 1000.0).toFixed(1) + "K";
        }
        ctx.fillText(stepsStr, stepsX, stepsY + 5);

        // --- 3 O'clock Date Window ---
        const dateX = cx + rad * 0.70;
        const dateY = cy;

        ctx.fillStyle = "#FFFFFF";
        ctx.fillRect(dateX - 13, dateY - 10, 26, 20);

        ctx.strokeStyle = accent;
        ctx.lineWidth = 1;
        ctx.strokeRect(dateX - 13, dateY - 10, 26, 20);

        ctx.fillStyle = "#000000";
        ctx.font = "bold 12px 'Roboto Condensed', sans-serif";
        const today = new Date();
        ctx.fillText(today.getDate().toString(), dateX, dateY);

        // Magnifying cyclops glass frame
        ctx.strokeStyle = accent;
        ctx.lineWidth = 1.5;
        // Rounded rectangle simulator
        ctx.beginPath();
        ctx.roundRect(dateX - 17, dateY - 13, 34, 26, 3);
        ctx.stroke();

        // Curved shiny reflection arc
        ctx.strokeStyle = "#D4E6F1";
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(dateX, dateY, 14, 0.75 * Math.PI, 1.25 * Math.PI);
        ctx.stroke();

        // --- 6 O'clock Weather Icon ---
        const weatherX = cx;
        const weatherY = cy + rad * 0.81;
        const isSunny = state.temperature > 60; // Sun for hot temps, Cloud for cold temps in this simulation

        ctx.font = "9px 'Inter', sans-serif";
        if (isSunny) {
            ctx.fillStyle = accent;
            ctx.beginPath();
            ctx.arc(weatherX, weatherY, 9, 0, Math.PI * 2);
            ctx.fill();

            // Text inside icon (opposite color)
            ctx.fillStyle = bgColor;
            ctx.fillText(state.temperature.toString(), weatherX, weatherY);
        } else {
            ctx.fillStyle = "#FFFFFF";
            // Procedural cloud shape
            ctx.beginPath();
            ctx.arc(weatherX - 5, weatherY + 2, 5, 0, Math.PI * 2);
            ctx.arc(weatherX + 5, weatherY + 2, 5, 0, Math.PI * 2);
            ctx.arc(weatherX, weatherY - 2, 7, 0, Math.PI * 2);
            ctx.fill();
            ctx.fillRect(weatherX - 5, weatherY + 1, 10, 6);

            // Text inside cloud
            ctx.fillStyle = bgColor;
            ctx.fillText(state.temperature.toString(), weatherX, weatherY + 1);
        }

        // --- Lower Center: Heart Rate ---
        const hrX = cx;
        const hrY = cy + rad * 0.20;
        ctx.fillStyle = "#FFFFFF";
        ctx.font = "14px 'Inter', sans-serif";
        ctx.fillText(state.heartRate.toString(), hrX, hrY);

        ctx.fillStyle = "#8E9AAB";
        ctx.font = "9px 'Inter', sans-serif";
        ctx.fillText("BPM", hrX, cy + rad * 0.29);

        // --- Header and Footer Branding texts ---
        ctx.fillStyle = accent;
        ctx.font = "bold 22px 'Roboto Condensed', sans-serif";
        ctx.fillText("A E T H E R", cx, cy - rad * 0.35);

        ctx.fillStyle = "#8E9AAB";
        ctx.font = "11px 'Inter', sans-serif";
        ctx.fillText("CHRONOMETER", cx, cy + rad * 0.42);

        ctx.font = "9px 'Inter', sans-serif";
        ctx.textAlign = "right";
        ctx.fillText("SWISS", cx - 13, weatherY);
        ctx.textAlign = "left";
        ctx.fillText("MADE", cx + 13, weatherY);
    }

    // 5. Hands Drawing
    const now = new Date();
    const hour = now.getHours();
    const minute = now.getMinutes();
    const second = now.getSeconds();

    const hrAngle = (((hour % 12) + minute / 60.0) * 30.0 - 90.0) * Math.PI / 180.0;
    const minAngle = ((minute + second / 60.0) * 6.0 - 90.0) * Math.PI / 180.0;
    const secAngle = (second * 6.0 - 90.0) * Math.PI / 180.0;

    // Draw hands (batons) helper function
    function drawBatonHandCanvas(angle, length, goldColor, lumColor) {
        const cosA = Math.cos(angle);
        const sinA = Math.sin(angle);

        // Gold frame
        ctx.fillStyle = goldColor;
        ctx.beginPath();
        let pt = rotatePoint(cx, cy, cosA, sinA, -12.0, -2.5);
        ctx.moveTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length * 0.90, -2.5);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length, 0.0);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length * 0.90, 2.5);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, -12.0, 2.5);
        ctx.lineTo(pt.x, pt.y);
        ctx.closePath();
        ctx.fill();

        // Luminous strip
        ctx.fillStyle = lumColor;
        ctx.beginPath();
        pt = rotatePoint(cx, cy, cosA, sinA, -8.0, -1.0);
        ctx.moveTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length * 0.88, -1.0);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length * 0.94, 0.0);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, length * 0.88, 1.0);
        ctx.lineTo(pt.x, pt.y);
        pt = rotatePoint(cx, cy, cosA, sinA, -8.0, 1.0);
        ctx.closePath();
        ctx.fill();
    }

    // Hour hand
    drawBatonHandCanvas(hrAngle, rad * 0.52, accent, lumColor);

    // Minute hand
    drawBatonHandCanvas(minAngle, rad * 0.80, accent, lumColor);

    // Seconds Hand (only if enabled, not in sleep mode, and not burnIn/AOD)
    if (state.showSeconds && !state.isSleep) {
        const cosA = Math.cos(secAngle);
        const sinA = Math.sin(secAngle);
        ctx.strokeStyle = accent;
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.moveTo(cx - rad * 0.15 * cosA, cy - rad * 0.15 * sinA);
        ctx.lineTo(cx + rad * 0.88 * cosA, cy + rad * 0.88 * sinA);
        ctx.stroke();
    }

    // Center Cap Pin
    ctx.fillStyle = accent;
    ctx.beginPath();
    ctx.arc(cx, cy, 5, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = "#05070A";
    ctx.beginPath();
    ctx.arc(cx, cy, 1.5, 0, Math.PI * 2);
    ctx.fill();
}

// Tick loop
function tick() {
    drawWatchFace();
    requestAnimationFrame(tick);
}

// Setup Event Listeners for UI
document.querySelectorAll(".theme-btn").forEach(btn => {
    btn.addEventListener("click", (e) => {
        document.querySelectorAll(".theme-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        state.colorTheme = parseInt(btn.getAttribute("data-theme"));
    });
});

const sleepCheckbox = document.getElementById("sleepMode");
sleepCheckbox.addEventListener("change", (e) => {
    state.isSleep = e.target.checked;
});

const secondsCheckbox = document.getElementById("showSeconds");
secondsCheckbox.addEventListener("change", (e) => {
    state.showSeconds = e.target.checked;
});

const stepsInput = document.getElementById("stepsInput");
const stepsVal = document.getElementById("stepsVal");
stepsInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.steps = val;
    stepsVal.textContent = val.toLocaleString();
});

const tempInput = document.getElementById("tempInput");
const tempVal = document.getElementById("tempVal");
tempInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.temperature = val;
    tempVal.textContent = val + "°F";
});

const hrInput = document.getElementById("hrInput");
const hrVal = document.getElementById("hrVal");
hrInput.addEventListener("input", (e) => {
    const val = parseInt(e.target.value);
    state.heartRate = val;
    hrVal.textContent = val + " BPM";
});

// Run
tick();
