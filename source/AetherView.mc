import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Application;
import Toybox.Weather;
import Toybox.SensorHistory;
import Toybox.Math;

class AetherView extends WatchUi.WatchFace {

    private var mScreenWidth as Number = 0;
    private var mScreenHeight as Number = 0;
    private var mCenterX as Number = 0;
    private var mCenterY as Number = 0;
    private var mRadius as Number = 0;
    private var mIsSleep as Boolean = true;

    // Settings (kept for compatibility)
    private var mShowSecondsSetting as Boolean = true;
    private var mShowDigitalTime as Boolean = true;
    private var mShowDate as Boolean = true;
    private var mShowWeather as Boolean = true;
    private var mLayoutStyle as Number = 0;
    private var mBgStyle as Number = 0;
    private var mColorTheme as Number = 3;  // default Midnight Gold

    private var mFontBrand as Graphics.FontType or Null = null;
    private var mFontSubBrand as Graphics.FontType or Null = null;
    private var mFontBottom as Graphics.FontType or Null = null;
    private var mFontSwiss as Graphics.FontType or Null = null;
    private var mFontDate as Graphics.FontType or Null = null;

    private var mThemes = [
        [0xE8B4A0, 0x8B5E4D, 0xF5D5C8, 0xD4A017], // 0 Rose Gold
        [0x5EB8B8, 0x2F6B6B, 0xA8E0E0, 0x3AA8A8], // 1 Arctic Teal
        [0xE07A3D, 0x8C4720, 0xF5B88A, 0xE85D04], // 2 Ember Orange
        [0xC5A26F, 0x6B5537, 0xE8D5A3, 0xF4A261], // 3 Midnight Gold (default)
        [0x5C8A5E, 0x2F4730, 0x9DC29E, 0x40916C], // 4 Forest Green
        [0xA78BBA, 0x5C4A6B, 0xD4C1E8, 0x9B7EBD], // 5 Lavender Mist
        [0xB8C4CE, 0x5F6B77, 0xE6EBF0, 0x8FA1B3], // 6 Pearl Silver
        [0xF4A261, 0x8C5C2E, 0xF8C58C, 0xE76F51]  // 7 Solar Amber
    ];

    function initialize() {
        WatchFace.initialize();
        updateSettings();
    }

    function updateSettings() as Void {
        try {
            var app = Application.getApp();
            if (Application has :Properties) {
                mShowSecondsSetting = Application.Properties.getValue("ShowSeconds");
                mShowDigitalTime = Application.Properties.getValue("ShowDigitalTime");
                mShowDate = Application.Properties.getValue("ShowDate");
                mShowWeather = Application.Properties.getValue("ShowWeather");
                mLayoutStyle = Application.Properties.getValue("LayoutStyle");
                mBgStyle = Application.Properties.getValue("BgStyle");
                mColorTheme = Application.Properties.getValue("ColorTheme");
            } else if (app != null) {
                mShowSecondsSetting = app.getProperty("ShowSeconds");
                mShowDigitalTime = app.getProperty("ShowDigitalTime");
                mShowDate = app.getProperty("ShowDate");
                mShowWeather = app.getProperty("ShowWeather");
                mLayoutStyle = app.getProperty("LayoutStyle");
                mBgStyle = app.getProperty("BgStyle");
                mColorTheme = app.getProperty("ColorTheme");
            }
        } catch (e) {
            // keep defaults
        }
        sanitizeSettings();
    }

    function sanitizeSettings() as Void {
        if (mColorTheme < 0 || mColorTheme >= mThemes.size()) { mColorTheme = 3; }
        if (mLayoutStyle < 0 || mLayoutStyle > 3) { mLayoutStyle = 0; }
        if (mBgStyle < 0 || mBgStyle > 2) { mBgStyle = 0; }
    }

    function onLayout(dc as Dc) as Void {
        mScreenWidth = dc.getWidth();
        mScreenHeight = dc.getHeight();
        mCenterX = mScreenWidth / 2;
        mCenterY = mScreenHeight / 2;
        mRadius = (mScreenWidth < mScreenHeight ? mScreenWidth : mScreenHeight) / 2 - 6;
        initFonts();
    }

    function initFonts() as Void {
        mFontBrand = Graphics.FONT_XTINY;
        mFontSubBrand = Graphics.FONT_XTINY;
        mFontBottom = Graphics.FONT_XTINY;
        mFontSwiss = Graphics.FONT_XTINY;
        mFontDate = Graphics.FONT_XTINY;

        if (Graphics has :getVectorFont) {
            var face = ["RobotoCondensedBold", "sans-serif"] as Array<String>;
            var faceRegular = ["RobotoCondensedRegular", "sans-serif"] as Array<String>;

            var fontBrand = Graphics.getVectorFont({
                :face => face,
                :size => 22
            });
            if (fontBrand != null) {
                mFontBrand = fontBrand;
            }

            var fontSubBrand = Graphics.getVectorFont({
                :face => faceRegular,
                :size => 14
            });
            if (fontSubBrand != null) {
                mFontSubBrand = fontSubBrand;
            }

            var fontBottom = Graphics.getVectorFont({
                :face => faceRegular,
                :size => 11
            });
            if (fontBottom != null) {
                mFontBottom = fontBottom;
            }

            var fontSwiss = Graphics.getVectorFont({
                :face => faceRegular,
                :size => 9
            });
            if (fontSwiss != null) {
                mFontSwiss = fontSwiss;
            }

            var fontDate = Graphics.getVectorFont({
                :face => face,
                :size => 12
            });
            if (fontDate != null) {
                mFontDate = fontDate;
            }
        }
    }

    function onShow() as Void {
        updateSettings();
    }

    function onUpdate(dc as Dc) as Void {
        updateSettings();

        var theme = mThemes[mColorTheme];
        var accent = theme[0];
        var accentDark = theme[1];
        var highlight = theme[2];

        // Base black background
        var bgColor = 0x05070A;
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // AMOLED burn-in shift
        var deviceSettings = System.getDeviceSettings();
        var burnInX = 0;
        var burnInY = 0;
        var burnInActive = false;
        if ((deviceSettings has :requiresBurnInProtection) && deviceSettings.requiresBurnInProtection && mIsSleep) {
            burnInActive = true;
            var clockTime = System.getClockTime();
            var shift = (clockTime.min % 4);
            if (shift == 1) { burnInX = 3; burnInY = 2; }
            else if (shift == 2) { burnInX = -2; burnInY = 3; }
            else if (shift == 3) { burnInX = 2; burnInY = -3; }
        }

        var cx = mCenterX + burnInX;
        var cy = mCenterY + burnInY;

        // Draw radial sunburst background & bezel (skip in AOD to save pixels)
        if (!burnInActive) {
            drawBackground(dc, mBgStyle, accent);
        }

        // Draw luxury gold indices (luminous batons / crown at 12)
        drawClockMarkers(dc, cx, cy, mRadius, accent, accentDark, burnInActive);

        // Get current local time
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;

        var is24 = deviceSettings.is24Hour;
        if (!is24) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        // Cyclops Date Window at 3 o'clock & Steps Sub-dial at 9 o'clock & Weather at 6 o'clock
        if (!burnInActive) {
            drawDateWindow(dc, cx, cy, mRadius, accent);
            drawStepsSubDial(dc, cx, cy, mRadius, accent, accentDark);
            drawWeather(dc, cx, cy, mRadius, accent, accentDark);
            drawHeartRate(dc, cx, cy, mRadius, accent, accentDark);
        }

        // Elegant Rolex-style Serif Branding
        if (!burnInActive) {
            drawBranding(dc, cx, cy, mRadius, accent, accentDark);
        }

        // Draw premium watch hands (luminous batons)
        drawAnalogHands(dc, cx, cy, mRadius, hour, minute, second, accent, highlight, mShowSecondsSetting && !mIsSleep && !burnInActive);

        // Center Pin
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        dc.setColor(0x05070A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 1.5);
    }

    function drawBackground(dc as Dc, style as Number, goldColor as Number) as Void {
        // Draw concentric metallic radial sunburst gradient
        var maxR = mRadius + 6;
        var step = 4;
        for (var r = maxR; r > 0; r -= step) {
            var ratio = r.toFloat() / maxR.toFloat();
            var rC = (0x03 + (ratio * 0x13)).toNumber();
            var gC = (0x05 + (ratio * 0x15)).toNumber();
            var bC = (0x07 + (ratio * 0x1B)).toNumber();
            var col = (rC << 16) | (gC << 8) | bC;
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(mCenterX, mCenterY, r);
        }

        // Gold fluted luxury bezel ring
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(mCenterX, mCenterY, mRadius + 1);

        dc.setPenWidth(1);
        for (var i = 0; i < 60; i += 2) {
            var angle = i * 6 * Math.PI / 180.0;
            var x1 = mCenterX + ((mRadius + 1) * Math.cos(angle)).toNumber();
            var y1 = mCenterY + ((mRadius + 1) * Math.sin(angle)).toNumber();
            var x2 = mCenterX + ((mRadius + 4) * Math.cos(angle)).toNumber();
            var y2 = mCenterY + ((mRadius + 4) * Math.sin(angle)).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }
    }

    function drawClockMarkers(dc as Dc, cx as Number, cy as Number, rad as Number, accent as Number, accentDark as Number, burnIn as Boolean) as Void {
        var rDist = rad * 0.81; // Distance from center
        var goldColor = accent;
        var lumColor = mIsSleep ? 0x00A8B5 : 0xE6F0E6; // Chromalight cyan in AOD, warm white in active

        for (var i = 0; i < 12; i++) {
            var angle = (i * 30) - 90;
            var radA = angle * Math.PI / 180.0;
            var cosA = Math.cos(radA);
            var sinA = Math.sin(radA);
            var px = cx + (rDist * cosA).toNumber();
            var py = cy + (rDist * sinA).toNumber();

            if (i == 0) {
                // 12 o'clock: Luxury Gold Crown logo
                drawCrown(dc, cx, cy, px, py - 4, goldColor);
            } else if (i == 3 || i == 6 || i == 9) {
                // 3, 6, and 9 o'clock: Suppressed for Date, Weather, and Steps Windows
                continue;
            } else {
                // Other hours: Regular batons
                drawBatonMarker(dc, cx, cy, radA, rDist, 4.5, 12.0, goldColor, lumColor);
            }
        }

        // Ticks on the outer dial (skip in AOD to save pixels)
        if (!burnIn) {
            dc.setPenWidth(1);
            dc.setColor(0x28303C, Graphics.COLOR_TRANSPARENT);
            var rInner = rad * 0.88;
            var rOuter = rad * 0.92;
            for (var i = 0; i < 60; i++) {
                if (i % 5 == 0) { continue; }
                var angle = i * 6 * Math.PI / 180.0;
                var cosA = Math.cos(angle);
                var sinA = Math.sin(angle);
                var x1 = cx + (rInner * cosA).toNumber();
                var y1 = cy + (rInner * sinA).toNumber();
                var x2 = cx + (rOuter * cosA).toNumber();
                var y2 = cy + (rOuter * sinA).toNumber();
                dc.drawLine(x1, y1, x2, y2);
            }
        }
    }

    function drawCrown(dc as Dc, cx as Number, cy as Number, px as Number, py as Number, goldColor as Number) as Void {
        // Stylized 3-point crown (to avoid legal ramifications)
        // Base structure
        var basePts = [
            [px - 5, py + 8],
            [px + 5, py + 8],
            [px + 6, py + 5],
            [px + 4, py + 4],
            [px - 4, py + 4],
            [px - 6, py + 5]
        ];
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(basePts);

        // 3 Spikes (instead of 5)
        dc.fillPolygon([[px - 1.5, py + 4], [px + 1.5, py + 4], [px, py - 4]]); // Middle spike
        dc.fillPolygon([[px - 5.0, py + 4], [px - 3.0, py + 4], [px - 6, py - 1]]); // Left spike
        dc.fillPolygon([[px + 3.0, py + 4], [px + 5.0, py + 4], [px + 6, py - 1]]); // Right spike

        // 3 Dots on tips
        dc.fillCircle(px, py - 4, 1.5); // Middle dot
        dc.fillCircle(px - 6, py - 1, 1.5); // Left dot
        dc.fillCircle(px + 6, py - 1, 1.5); // Right dot

        // Circular cutout inside the base
        dc.setColor(0x05070A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px, py + 6, 2.5);
    }

    function rotatePoint(cx as Number, cy as Number, cosA as Float, sinA as Float, xOffset as Float, yOffset as Float) as [Number, Number] {
        var rx = cx + (xOffset * cosA - yOffset * sinA).toNumber();
        var ry = cy + (xOffset * sinA + yOffset * cosA).toNumber();
        return [rx, ry];
    }

    function drawBatonMarker(dc as Dc, cx as Number, cy as Number, radA as Float, rDist as Float, w as Float, h as Float, goldColor as Number, lumColor as Number) as Void {
        var cosA = Math.cos(radA);
        var sinA = Math.sin(radA);
        var px = cx + (rDist * cosA).toNumber();
        var py = cy + (rDist * sinA).toNumber();

        var ptsGold = [
            rotatePoint(px, py, cosA, sinA, -h/2, -w/2),
            rotatePoint(px, py, cosA, sinA, h/2, -w/2),
            rotatePoint(px, py, cosA, sinA, h/2, w/2),
            rotatePoint(px, py, cosA, sinA, -h/2, w/2)
        ];
        var ptsLum = [
            rotatePoint(px, py, cosA, sinA, -h/2 + 1.5, -w/2 + 1),
            rotatePoint(px, py, cosA, sinA, h/2 - 1.5, -w/2 + 1),
            rotatePoint(px, py, cosA, sinA, h/2 - 1.5, w/2 - 1),
            rotatePoint(px, py, cosA, sinA, -h/2 + 1.5, w/2 - 1)
        ];

        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(ptsGold);
        dc.setColor(lumColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(ptsLum);
    }
    function drawStepsSubDial(dc as Dc, cx as Number, cy as Number, rad as Number, goldColor as Number, grayColor as Number) as Void {
        var x = cx - (rad * 0.70).toNumber();
        var y = cy;

        // Circular sub-dial background (filled with dial background color to clear any ticks)
        var bgColor = 0x05070A; // Base dial color
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 19);

        // Gold outer ring
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1.5);
        dc.drawCircle(x, y, 18);

        // Get steps
        var steps = 0;
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            steps = info.steps;
        }

        var stepsStr = steps.toString();
        if (steps >= 10000) {
            var kSteps = steps.toFloat() / 1000.0;
            stepsStr = kSteps.format("%.1f") + "K";
        }

        var fontSwiss = mFontSwiss;
        var fontBottom = mFontBottom;

        if (fontSwiss == null || fontBottom == null) {
            return;
        }

        // Draw "STEPS" label in gray/gold at the top half
        dc.setColor(grayColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y - 6, fontSwiss, "STEPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw step value in white/gold at the bottom half
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + 5, fontBottom, stepsStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawWeather(dc as Dc, cx as Number, cy as Number, rad as Number, goldColor as Number, grayColor as Number) as Void {
        // Get weather data
        var temp = null;
        var cond = null;
        if (Toybox has :Weather) {
            var weatherInfo = Weather.getCurrentConditions();
            if (weatherInfo != null) {
                temp = weatherInfo.temperature;
                cond = weatherInfo.condition;
            }
        }

        var systemSettings = System.getDeviceSettings();
        var tempVal = temp;
        if (tempVal != null) {
            if (systemSettings.temperatureUnits == System.UNIT_STATUTE) {
                tempVal = (tempVal * 9.0 / 5.0) + 32.0;
            }
            tempVal = tempVal.toNumber();
        }
        var tempStr = (tempVal != null) ? tempVal.toString() : "--";

        // Position at 6 o'clock (replacing the baton)
        var x = cx;
        var y = cy + (rad * 0.81).toNumber();

        // Check if sunny
        var isSunny = true;
        if (cond != null) {
            if (cond != Weather.CONDITION_CLEAR && cond != Weather.CONDITION_PARTLY_CLEAR && cond != Weather.CONDITION_MOSTLY_CLEAR) {
                isSunny = false;
            }
        }

        var fontSwiss = mFontSwiss;
        if (fontSwiss == null) {
            return;
        }

        // Draw icon
        if (isSunny) {
            // Gold sun circle
            dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, 9);
            // Opposite color text (dark background color of watch face)
            dc.setColor(0x05070A, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, fontSwiss, tempStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            // White cloud
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            // Procedural cloud shape
            dc.fillCircle(x - 5, y + 2, 5);
            dc.fillCircle(x + 5, y + 2, 5);
            dc.fillCircle(x, y - 2, 7);
            dc.fillRectangle(x - 5, y + 1, 10, 6);

            // Opposite color text
            dc.setColor(0x05070A, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y + 1, fontSwiss, tempStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawDateWindow(dc as Dc, cx as Number, cy as Number, rad as Number, goldColor as Number) as Void {
        var x = cx + (rad * 0.70).toNumber();
        var y = cy;

        // White date box
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillRectangle(x - 13, y - 10, 26, 20);

        // Gold frame
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(x - 13, y - 10, 26, 20);

        // Day of month number
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dayStr = info.day.toString();
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        if (mFontDate != null) {
            dc.drawText(x, y, mFontDate, dayStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(x, y - 9, Graphics.FONT_XTINY, dayStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Magnifying Cyclops glass bubble
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1.5);
        dc.drawRoundedRectangle(x - 17, y - 13, 34, 26, 3);

        // Curved reflection shine
        dc.setColor(0xD4E6F1, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1.5);
        dc.drawArc(x, y, 14, Graphics.ARC_CLOCKWISE, 140, 220);
    }

    function drawBranding(dc as Dc, cx as Number, cy as Number, rad as Number, goldColor as Number, grayColor as Number) as Void {
        if (mFontBrand == null) {
            initFonts();
        }

        var fontBrand = mFontBrand;
        var fontSubBrand = mFontSubBrand;
        var fontBottom = mFontBottom;
        var fontSwiss = mFontSwiss;

        if (fontBrand == null || fontSubBrand == null || fontBottom == null || fontSwiss == null) {
            return;
        }

        var hasVector = (Graphics has :getVectorFont) && (fontBrand instanceof Graphics.VectorFont);

        // Top text blocks
        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        if (hasVector) {
            dc.drawText(cx, cy - (rad * 0.35).toNumber(), fontBrand, "A E T H E R", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy - (rad * 0.35).toNumber() - 8, fontBrand, "A E T H E R", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Bottom text blocks
        if (hasVector) {
            dc.drawText(cx, cy + (rad * 0.42).toNumber(), fontBottom, "CHRONOMETER", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy + (rad * 0.40).toNumber() - 8, fontBottom, "CHRONOMETER", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Swiss Made flanking the 6 o'clock marker if vector, or at the bottom if bitmap
        if (hasVector) {
            var swissY = cy + (rad * 0.81).toNumber();
            dc.drawText(cx - 13, swissY, fontSwiss, "SWISS", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(cx + 13, swissY, fontSwiss, "MADE", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy + (rad * 0.86).toNumber() - 8, fontSwiss, "SWISS  •  MADE", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawBatonHand(dc as Dc, cx as Number, cy as Number, angle as Float, length as Float, goldColor as Number, lumColor as Number) as Void {
        var cosA = Math.cos(angle);
        var sinA = Math.sin(angle);

        var ptsGold = [
            rotatePoint(cx, cy, cosA, sinA, -12.0, -2.5),
            rotatePoint(cx, cy, cosA, sinA, length * 0.90, -2.5),
            rotatePoint(cx, cy, cosA, sinA, length, 0.0),
            rotatePoint(cx, cy, cosA, sinA, length * 0.90, 2.5),
            rotatePoint(cx, cy, cosA, sinA, -12.0, 2.5)
        ];
        var ptsLum = [
            rotatePoint(cx, cy, cosA, sinA, -8.0, -1.0),
            rotatePoint(cx, cy, cosA, sinA, length * 0.88, -1.0),
            rotatePoint(cx, cy, cosA, sinA, length * 0.94, 0.0),
            rotatePoint(cx, cy, cosA, sinA, length * 0.88, 1.0),
            rotatePoint(cx, cy, cosA, sinA, -8.0, 1.0)
        ];

        dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(ptsGold);
        dc.setColor(lumColor, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(ptsLum);
    }

    function drawAnalogHands(dc as Dc, cx as Number, cy as Number, rad as Number, hour as Number, minute as Number, second as Number, accent as Number, highlight as Number, showSec as Boolean) as Void {
        var hourAngle = (((hour % 12) + (minute / 60.0)) * 30.0 - 90.0) * Math.PI / 180.0;
        var minAngle = ((minute + (second / 60.0)) * 6.0 - 90.0) * Math.PI / 180.0;
        var secAngle = (second * 6.0 - 90.0) * Math.PI / 180.0;

        var goldColor = accent;
        var lumColor = mIsSleep ? 0x00A8B5 : 0xE6F0E6;

        // Hour hand
        drawBatonHand(dc, cx, cy, hourAngle, rad * 0.52, goldColor, lumColor);

        // Minute hand
        drawBatonHand(dc, cx, cy, minAngle, rad * 0.80, goldColor, lumColor);

        // Elegant second hand
        if (showSec) {
            var cosA = Math.cos(secAngle);
            var sinA = Math.sin(secAngle);
            dc.setPenWidth(1);
            dc.setColor(goldColor, Graphics.COLOR_TRANSPARENT);
            var x1 = cx - (rad * 0.15 * cosA).toNumber();
            var y1 = cy - (rad * 0.15 * sinA).toNumber();
            var x2 = cx + (rad * 0.88 * cosA).toNumber();
            var y2 = cy + (rad * 0.88 * sinA).toNumber();
            dc.drawLine(x1, y1, x2, y2);
        }
    }

    function getHeartRate() as Number or Null {
        try {
            var hr = null;
            if (Activity has :getActivityInfo) {
                var info = Activity.getActivityInfo();
                if (info != null) {
                    hr = info.currentHeartRate;
                }
            }

            if (hr == null && (Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
                var hrHistory = SensorHistory.getHeartRateHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (hrHistory != null) {
                    var sample = hrHistory.next();
                    if (sample != null && sample.data != null) {
                        hr = sample.data;
                    }
                }
            }
            return hr;
        } catch (e) {
            return null;
        }
    }

    function drawHeartRate(dc as Dc, cx as Number, cy as Number, rad as Number, goldColor as Number, grayColor as Number) as Void {
        if (mFontSubBrand == null || mFontSwiss == null) {
            initFonts();
        }

        var hr = getHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";

        var fontSubBrand = mFontSubBrand;
        var fontSwiss = mFontSwiss;
        if (fontSubBrand == null || fontSwiss == null) {
            return;
        }

        var hasVector = (Graphics has :getVectorFont) && (fontSubBrand instanceof Graphics.VectorFont);

        // Value centered at cy + rad * 0.20
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (hasVector) {
            dc.drawText(cx, cy + (rad * 0.20).toNumber(), fontSubBrand, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy + (rad * 0.20).toNumber() - 8, fontSubBrand, hrStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Label "BPM" centered at cy + rad * 0.28
        dc.setColor(grayColor, Graphics.COLOR_TRANSPARENT);
        if (hasVector) {
            dc.drawText(cx, cy + (rad * 0.29).toNumber(), fontSwiss, "BPM", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, cy + (rad * 0.29).toNumber() - 6, fontSwiss, "BPM", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onHide() as Void {}
    function onExitSleep() as Void { mIsSleep = false; WatchUi.requestUpdate(); }
    function onEnterSleep() as Void { mIsSleep = true; WatchUi.requestUpdate(); }
}
