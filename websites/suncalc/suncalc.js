// SunCalc library
(function () {
    'use strict';

    // shortcuts for easier to read formulas
    var PI = Math.PI,
        sin = Math.sin,
        cos = Math.cos,
        tan = Math.tan,
        asin = Math.asin,
        atan = Math.atan2,
        acos = Math.acos,
        rad = PI / 180;

    // date/time constants and conversions
    var dayMs = 1000 * 60 * 60 * 24,
        J1970 = 2440588,
        J2000 = 2451545;

    function toJulian(date) {
        return date.valueOf() / dayMs - 0.5 + J1970;
    }
    function fromJulian(j) {
        return new Date((j + 0.5 - J1970) * dayMs);
    }
    function toDays(date) {
        return toJulian(date) - J2000;
    }

    // general calculations for position
    var e = rad * 23.4397; // obliquity of the Earth

    function rightAscension(l, b) {
        return atan(sin(l) * cos(e) - tan(b) * sin(e), cos(l));
    }
    function declination(l, b) {
        return asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l));
    }
    function azimuth(H, phi, dec) {
        return atan(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi));
    }
    function altitude(H, phi, dec) {
        return asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H));
    }
    function siderealTime(d, lw) {
        return rad * (280.16 + 360.9856235 * d) - lw;
    }
    function astroRefraction(h) {
        if (h < 0) h = 0;
        return 0.0002967 / Math.tan(h + 0.00312536 / (h + 0.08901179));
    }

    // general sun calculations
    function solarMeanAnomaly(d) {
        return rad * (357.5291 + 0.98560028 * d);
    }
    function eclipticLongitude(M) {
        var C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M)),
            P = rad * 102.9372;
        return M + C + P + PI;
    }
    function sunCoords(d) {
        var M = solarMeanAnomaly(d),
            L = eclipticLongitude(M);
        return {
            dec: declination(L, 0),
            ra: rightAscension(L, 0)
        };
    }

    var SunCalc = {};

    SunCalc.getPosition = function (date, lat, lng) {
        var lw = rad * -lng,
            phi = rad * lat,
            d = toDays(date),
            c = sunCoords(d),
            H = siderealTime(d, lw) - c.ra;

        return {
            azimuth: azimuth(H, phi, c.dec),
            altitude: altitude(H, phi, c.dec)
        };
    };

    // sun times configuration
    var times = SunCalc.times = [
        [-0.833, 'sunrise', 'sunset'],
        [-0.3, 'sunriseEnd', 'sunsetStart'],
        [-6, 'dawn', 'dusk'],
        [-12, 'nauticalDawn', 'nauticalDusk'],
        [-18, 'nightEnd', 'night'],
        [6, 'goldenHourEnd', 'goldenHour']
    ];

    SunCalc.addTime = function (angle, riseName, setName) {
        times.push([angle, riseName, setName]);
    };

    // calculations for sun times
    var J0 = 0.0009;

    function julianCycle(d, lw) {
        return Math.round(d - J0 - lw / (2 * PI));
    }
    function approxTransit(Ht, lw, n) {
        return J0 + (Ht + lw) / (2 * PI) + n;
    }
    function solarTransitJ(ds, M, L) {
        return J2000 + ds + 0.0053 * sin(M) - 0.0069 * sin(2 * L);
    }
    function hourAngle(h, phi, d) {
        return acos((sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d)));
    }
    function observerAngle(height) {
        return -2.076 * Math.sqrt(height) / 60;
    }
    function getSetJ(h, lw, phi, dec, n, M, L) {
        var w = hourAngle(h, phi, dec),
            a = approxTransit(w, lw, n);
        return solarTransitJ(a, M, L);
    }

    SunCalc.getTimes = function (date, lat, lng, height) {
        height = height || 0;
        var lw = rad * -lng,
            phi = rad * lat,
            dh = observerAngle(height),
            d = toDays(date),
            n = julianCycle(d, lw),
            ds = approxTransit(0, lw, n),
            M = solarMeanAnomaly(ds),
            L = eclipticLongitude(M),
            dec = declination(L, 0),
            Jnoon = solarTransitJ(ds, M, L),
            i, len, time, h0, Jset, Jrise;

        var result = {
            solarNoon: fromJulian(Jnoon),
            nadir: fromJulian(Jnoon - 0.5)
        };

        for (i = 0, len = times.length; i < len; i += 1) {
            time = times[i];
            h0 = (time[0] + dh) * rad;
            Jset = getSetJ(h0, lw, phi, dec, n, M, L);
            Jrise = Jnoon - (Jset - Jnoon);
            result[time[1]] = fromJulian(Jrise);
            result[time[2]] = fromJulian(Jset);
        }

        return result;
    };

    // moon calculations
    function moonCoords(d) {
        var L = rad * (218.316 + 13.176396 * d),
            M = rad * (134.963 + 13.064993 * d),
            F = rad * (93.272 + 13.229350 * d),
            l = L + rad * 6.289 * sin(M),
            b = rad * 5.128 * sin(F),
            dt = 385001 - 20905 * cos(M);

        return {
            ra: rightAscension(l, b),
            dec: declination(l, b),
            dist: dt
        };
    }

    SunCalc.getMoonPosition = function (date, lat, lng) {
        var lw = rad * -lng,
            phi = rad * lat,
            d = toDays(date),
            c = moonCoords(d),
            H = siderealTime(d, lw) - c.ra,
            h = altitude(H, phi, c.dec),
            pa = atan(sin(H), tan(phi) * cos(c.dec) - sin(c.dec) * cos(H));

        h = h + astroRefraction(h);

        return {
            azimuth: azimuth(H, phi, c.dec),
            altitude: h,
            distance: c.dist,
            parallacticAngle: pa
        };
    };

    SunCalc.getMoonIllumination = function (date) {
        var d = toDays(date || new Date()),
            s = sunCoords(d),
            m = moonCoords(d),
            sdist = 149598000,
            phi = acos(sin(s.dec) * sin(m.dec) + cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra)),
            inc = atan(sdist * sin(phi), m.dist - sdist * cos(phi)),
            angle = atan(cos(s.dec) * sin(s.ra - m.ra), sin(s.dec) * cos(m.dec) -
                cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra));

        return {
            fraction: (1 + cos(inc)) / 2,
            phase: 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Math.PI,
            angle: angle
        };
    };

    function hoursLater(date, h) {
        return new Date(date.valueOf() + h * dayMs / 24);
    }

    SunCalc.getMoonTimes = function (date, lat, lng, inUTC) {
        var t = new Date(date);
        if (inUTC) t.setUTCHours(0, 0, 0, 0);
        else t.setHours(0, 0, 0, 0);

        var hc = 0.133 * rad,
            h0 = SunCalc.getMoonPosition(t, lat, lng).altitude - hc,
            h1, h2, rise, set, a, b, xe, ye, d, roots, x1, x2, dx;

        for (var i = 1; i <= 24; i += 2) {
            h1 = SunCalc.getMoonPosition(hoursLater(t, i), lat, lng).altitude - hc;
            h2 = SunCalc.getMoonPosition(hoursLater(t, i + 1), lat, lng).altitude - hc;

            a = (h0 + h2) / 2 - h1;
            b = (h2 - h0) / 2;
            xe = -b / (2 * a);
            ye = (a * xe + b) * xe + h1;
            d = b * b - 4 * a * h1;
            roots = 0;

            if (d >= 0) {
                dx = Math.sqrt(d) / (Math.abs(a) * 2);
                x1 = xe - dx;
                x2 = xe + dx;
                if (Math.abs(x1) <= 1) roots++;
                if (Math.abs(x2) <= 1) roots++;
                if (x1 < -1) x1 = x2;
            }

            if (roots === 1) {
                if (h0 < 0) rise = i + x1;
                else set = i + x1;
            } else if (roots === 2) {
                rise = i + (ye < 0 ? x2 : x1);
                set = i + (ye < 0 ? x1 : x2);
            }

            if (rise && set) break;
            h0 = h2;
        }

        var result = {};
        if (rise) result.rise = hoursLater(t, rise);
        if (set) result.set = hoursLater(t, set);
        if (!rise && !set) result[ye > 0 ? 'alwaysUp' : 'alwaysDown'] = true;

        return result;
    };

    window.SunCalc = SunCalc;
}());

// Application logic
let map;
let previousMarker = null;
let userMarker = null;

// Get user's current location
async function getUserLocation() {
    try {
        const response = await fetch('https://ipinfo.io/json');
        if (!response.ok) {
            throw new Error(`Error ${response.status}: ${response.statusText}`);
        }
        const data = await response.json();
        const coords = data.loc.split(",");
        return {
            lat: parseFloat(coords[0]),
            lng: parseFloat(coords[1])
        };
    } catch (error) {
        console.error('Error getting location from IP:', error);
        // Fallback to default location
        return { lat: 43.192903797812946, lng: -77.79589784284259 };
    }
}

// Get Google Maps API key from server
async function getApiKey() {
    try {
        const response = await fetch('/api/maps-key');
        if (!response.ok) {
            throw new Error('Failed to get API key');
        }
        const data = await response.json();
        return data.apiKey;
    } catch (error) {
        console.error('Error getting API key:', error);
        showError('Failed to load Google Maps API key');
        return null;
    }
}

// Show error message
function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error';
    errorDiv.textContent = message;
    document.body.insertBefore(errorDiv, document.body.firstChild);
}

// Show loading message
function showLoading() {
    const loadingDiv = document.createElement('div');
    loadingDiv.className = 'loading';
    loadingDiv.textContent = 'Loading map...';
    loadingDiv.id = 'loading';
    document.body.insertBefore(loadingDiv, document.body.firstChild);
}

// Remove loading message
function removeLoading() {
    const loadingDiv = document.getElementById('loading');
    if (loadingDiv) {
        loadingDiv.remove();
    }
}

// Format time from Date object
function formatTime(date) {
    if (!date || isNaN(date.getTime())) {
        return 'N/A';
    }
    return date.toTimeString().substring(0, 8);
}

// Show sun times
function showSunTimes(lat, lng) {
    const times = SunCalc.getTimes(new Date(), lat, lng);
    
    document.getElementById("sun").innerHTML = `
        <table>
            <tr>
                <th style="width:70%">Sun</th>
                <th style="width:30%">Time</th>
            </tr>
            <tr><td>Nadir</td><td>${formatTime(times.nadir)}</td></tr>
            <tr><td>Night End</td><td>${formatTime(times.nightEnd)}</td></tr>
            <tr><td>Nautical Dawn</td><td>${formatTime(times.nauticalDawn)}</td></tr>
            <tr><td>Dawn</td><td>${formatTime(times.dawn)}</td></tr>
            <tr><td><b>Sunrise</b></td><td><b>${formatTime(times.sunrise)}</b></td></tr>
            <tr><td>Sunrise End</td><td>${formatTime(times.sunriseEnd)}</td></tr>
            <tr><td>Golden Hour End</td><td>${formatTime(times.goldenHourEnd)}</td></tr>
            <tr><td>Solar Noon</td><td>${formatTime(times.solarNoon)}</td></tr>
            <tr><td>Golden Hour</td><td>${formatTime(times.goldenHour)}</td></tr>
            <tr><td>Sunset Start</td><td>${formatTime(times.sunsetStart)}</td></tr>
            <tr><td><b>Sunset</b></td><td><b>${formatTime(times.sunset)}</b></td></tr>
            <tr><td>Dusk</td><td>${formatTime(times.dusk)}</td></tr>
            <tr><td>Nautical Dusk</td><td>${formatTime(times.nauticalDusk)}</td></tr>
            <tr><td>Night</td><td>${formatTime(times.night)}</td></tr>
        </table>
    `;
}

// Show moon times
function showMoonTimes(lat, lng) {
    const times = SunCalc.getMoonTimes(new Date(), lat, lng);
    
    document.getElementById("moon").innerHTML = `
        <table>
            <tr>
                <th style="width:70%">Moon</th>
                <th style="width:30%">Time</th>
            </tr>
            <tr><td>Moonrise</td><td>${formatTime(times.rise)}</td></tr>
            <tr><td>Moonset</td><td>${formatTime(times.set)}</td></tr>
        </table>
    `;
}

// Show moon phase
function showMoonIllumination(lat, lng) {
    const moonPhase = SunCalc.getMoonIllumination(new Date());
    
    document.getElementById("moonphase").innerHTML = `
        <table>
            <tr>
                <th style="width:70%">Moon</th>
                <th style="width:30%">Phase</th>
            </tr>
            <tr><td>Moon Phase</td><td>${moonPhase.phase.toFixed(3)}</td></tr>
            <tr><td>Illumination</td><td>${(moonPhase.fraction * 100).toFixed(1)}%</td></tr>
        </table>
    `;
}

// Update all calculations and display
function updateCalculations(lat, lng) {
    const now = new Date();
    const displayTime = now.toString().substring(0, 24);
    
    document.getElementById("date").innerHTML = displayTime;
    document.getElementById("location").innerHTML = `
        <table>
            <tr>
                <td>Latitude</td>
                <td>${lat.toFixed(6)}</td>
            </tr>
            <tr>
                <td>Longitude</td>
                <td>${lng.toFixed(6)}</td>
            </tr>
        </table>
    `;
    
    showSunTimes(lat, lng);
    showMoonTimes(lat, lng);
    showMoonIllumination(lat, lng);
}

// Initialize Google Map
async function initMap() {
    showLoading();
    
    try {
        const apiKey = await getApiKey();
        if (!apiKey) {
            return;
        }

        // Load Google Maps API
        const script = document.createElement('script');
        script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=setupMap`;
        script.async = true;
        script.defer = true;
        document.head.appendChild(script);
        
    } catch (error) {
        console.error('Error initializing map:', error);
        showError('Failed to initialize map');
        removeLoading();
    }
}

// Setup map after Google Maps API loads
async function setupMap() {
    try {
        // Get user's current location
        const userLocation = await getUserLocation();
        
        // Try to get precise geolocation if available
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const preciseLocation = {
                        lat: position.coords.latitude,
                        lng: position.coords.longitude
                    };
                    createMap(preciseLocation);
                },
                (error) => {
                    console.log('Geolocation error:', error);
                    createMap(userLocation);
                }
            );
        } else {
            createMap(userLocation);
        }
        
    } catch (error) {
        console.error('Error setting up map:', error);
        showError('Failed to setup map');
    } finally {
        removeLoading();
    }
}

// Create the actual map
function createMap(initialLocation) {
    map = new google.maps.Map(document.getElementById("map"), {
        zoom: 10,
        center: initialLocation
    });

    // Add marker for initial location
    userMarker = new google.maps.Marker({
        position: initialLocation,
        map: map,
        title: "Your Location",
        icon: {
            path: google.maps.SymbolPath.CIRCLE,
            scale: 8,
            fillColor: "#4285F4",
            fillOpacity: 1,
            strokeColor: "#ffffff",
            strokeWeight: 2
        }
    });

    // Update calculations for initial location
    updateCalculations(initialLocation.lat, initialLocation.lng);

    // Add click listener for map
    google.maps.event.addListener(map, "click", function(event) {
        const lat = event.latLng.lat();
        const lng = event.latLng.lng();

        // Remove previous marker if exists
        if (previousMarker) {
            previousMarker.setMap(null);
        }

        // Add new marker
        previousMarker = new google.maps.Marker({
            position: event.latLng,
            map: map,
            title: "Selected Location"
        });

        // Update calculations
        updateCalculations(lat, lng);
    });
}

// Make setupMap globally available for Google Maps callback
window.setupMap = setupMap;

// Initialize when page loads
document.addEventListener('DOMContentLoaded', initMap);