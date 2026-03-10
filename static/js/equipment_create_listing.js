/* ============================================
   Equipment Create Listing - Map & Rent JS
   Used by: equipment_create_listing.html
   ============================================ */

let currentMinRent = 0;
let currentMaxRent = 0;
let currentRecommendedRent = 0;

// Map variables
let map;
let marker;
let selectedLat = null;
let selectedLng = null;

// Initialize map
function initializeMap() {
    if (map) {
        map.remove();
    }

    map = L.map('map', {
        center: [20.5937, 78.9629],
        zoom: 5,
        zoomControl: true,
        scrollWheelZoom: true,
        doubleClickZoom: true,
        touchZoom: true,
        boxZoom: true,
        keyboard: true,
        dragging: true,
        tap: true,
        zoomAnimation: true,
        fadeAnimation: true,
        markerZoomAnimation: true,
        inertia: true,
        inertiaDeceleration: 3000,
        inertiaMaxSpeed: 1500,
        worldCopyJump: false,
        maxBoundsViscosity: 1.0
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
        minZoom: 3
    }).addTo(map);

    map.on('click', function (e) {
        var lat = e.latlng.lat;
        var lng = e.latlng.lng;

        if (marker) {
            marker.setLatLng(e.latlng);
        } else {
            marker = L.marker(e.latlng, {
                draggable: true,
                icon: L.icon({
                    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
                    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                    iconSize: [25, 41],
                    iconAnchor: [12, 41],
                    popupAnchor: [1, -34],
                    shadowSize: [41, 41]
                })
            }).addTo(map);

            marker.on('dragend', function (e) {
                var position = marker.getLatLng();
                updateLocationDetails(position.lat, position.lng);
            });
        }

        updateLocationDetails(lat, lng);
    });

    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function (position) {
            var userLat = position.coords.latitude;
            var userLng = position.coords.longitude;
            map.setView([userLat, userLng], 13);

            L.circle([userLat, userLng], {
                color: '#3b82f6',
                fillColor: '#3b82f6',
                fillOpacity: 0.2,
                radius: 500
            }).addTo(map);
        });
    }
}

// Update location details via reverse geocoding
function updateLocationDetails(lat, lng) {
    selectedLat = lat;
    selectedLng = lng;

    document.getElementById('latitude').value = lat.toFixed(6);
    document.getElementById('longitude').value = lng.toFixed(6);

    document.getElementById('selectedLocation').style.display = 'block';
    document.getElementById('locationDetails').innerHTML =
        '<div class="flex-gap-12"><i class="fas fa-spinner fa-spin"></i><span>Fetching location name...</span></div>';

    fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat + '&lon=' + lng + '&zoom=18&addressdetails=1')
        .then(function (response) { return response.json(); })
        .then(function (data) {
            var address = data.address || {};
            var village = address.village || address.town || address.suburb || address.city || address.municipality || 'Unknown location';
            var locality = address.locality || address.neighbourhood || '';
            var displayName = data.display_name || 'Location details not available';
            var detectedState = (address.state || '').replace(/^State of /i, '').trim();
            var detectedDistrict = address.state_district || address.county || address.city_district || '';

            document.getElementById('state').value = detectedState;
            document.getElementById('district').value = detectedDistrict;

            document.getElementById('locationDetails').innerHTML =
                '<div class="location-pin-row"><i class="fas fa-map-pin location-pin-icon"></i> <strong class="location-name">' + village + '</strong>' +
                (locality ? ', ' + locality : '') + '</div>' +
                '<div class="location-address">' + displayName + '</div>' +
                '<div class="location-coords-grid">' +
                    '<strong>Coordinates:</strong> <span>' + lat.toFixed(6) + ', ' + lng.toFixed(6) + '</span>' +
                    '<strong>District:</strong> <span class="location-highlight">' + (detectedDistrict || 'Detecting...') + '</span>' +
                    '<strong>State:</strong> <span class="location-highlight">' + (detectedState || 'Detecting...') + '</span>' +
                '</div>';

            var equipment = document.getElementById('equipmentSelect').value;
            if (equipment && detectedState && detectedDistrict) {
                fetchLiveRent();
            }
        })
        .catch(function (error) {
            console.error('Geocoding error:', error);
            document.getElementById('locationDetails').innerHTML =
                '<strong>Coordinates:</strong> ' + lat.toFixed(6) + ', ' + lng.toFixed(6) + '<br>' +
                '<strong>District:</strong> ' + (document.getElementById('district').value || 'Not selected') + '<br>' +
                '<strong>State:</strong> ' + (document.getElementById('state').value || 'Not selected') + '<br>' +
                '<small class="text-danger">Could not fetch location name. Please ensure internet connection.</small>';
        });
}

// Auto-fetch live rental rate
function fetchLiveRent() {
    var equipment = document.getElementById('equipmentSelect').value;
    var district = document.getElementById('district').value;
    var state = document.getElementById('state').value;
    var apiUrl = document.getElementById('listing-config').getAttribute('data-live-rent-url');

    if (!equipment) return;
    if (!district || !state) {
        document.getElementById('priceInfoBox').style.display = 'none';
        return;
    }

    document.getElementById('priceInfoBox').style.display = 'block';
    document.getElementById('marketName').textContent = 'Fetching market rental rates...';

    fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ equipment_name: equipment, district: district, state: state })
    })
    .then(function (res) { return res.json(); })
    .then(function (data) {
        if (data.success) {
            currentRecommendedRent = data.recommended_rent;
            currentMinRent = data.min_rent;
            currentMaxRent = data.max_rent;

            document.getElementById('recommendedPrice').textContent = '\u20B9' + currentRecommendedRent.toFixed(2) + '/day';
            document.getElementById('minPrice').textContent = '\u20B9' + currentMinRent.toFixed(2) + '/day';
            document.getElementById('maxPrice').textContent = '\u20B9' + currentMaxRent.toFixed(2) + '/day';
            document.getElementById('marketName').textContent = (data.location || 'Market') + ' \u2022 ' + equipment;

            document.getElementById('equipmentRent').value = currentRecommendedRent.toFixed(2);
            validateRent();
        } else {
            document.getElementById('marketName').textContent = 'No rental rate data available for this equipment/location';
            currentRecommendedRent = 0;
            currentMinRent = 0;
            currentMaxRent = 999999;
        }
    })
    .catch(function (error) {
        console.error('Error fetching rental rate:', error);
        document.getElementById('marketName').textContent = 'Error fetching rental rate. You can still set your own rate.';
        currentRecommendedRent = 0;
        currentMinRent = 0;
        currentMaxRent = 999999;
    });
}

// Validate rent is within range
function validateRent() {
    var equipmentRent = parseFloat(document.getElementById('equipmentRent').value);
    var validationDiv = document.getElementById('rentValidation');
    var submitBtn = document.getElementById('submitBtn');

    if (isNaN(equipmentRent) || equipmentRent <= 0) {
        validationDiv.innerHTML = '';
        return;
    }

    if (currentRecommendedRent === 0) {
        validationDiv.innerHTML =
            '<div class="validation-message success"><i class="fas fa-check-circle"></i><span>Valid rental rate</span></div>';
        submitBtn.disabled = false;
        submitBtn.style.opacity = '1';
        submitBtn.style.cursor = 'pointer';
        return;
    }

    if (equipmentRent < currentMinRent || equipmentRent > currentMaxRent) {
        validationDiv.innerHTML =
            '<div class="validation-message error"><i class="fas fa-exclamation-triangle"></i>' +
            '<span>Recommended: \u20B9' + currentMinRent.toFixed(2) + ' - \u20B9' + currentMaxRent.toFixed(2) + '/day</span></div>';
        submitBtn.disabled = true;
        submitBtn.style.opacity = '0.5';
        submitBtn.style.cursor = 'not-allowed';
    } else {
        var diffPercent = ((equipmentRent - currentRecommendedRent) / currentRecommendedRent * 100).toFixed(1);
        var diffText = diffPercent > 0 ? '+' + diffPercent + '%' : diffPercent + '%';

        validationDiv.innerHTML =
            '<div class="validation-message success"><i class="fas fa-check-circle"></i>' +
            '<span>Valid rate (' + diffText + ' from market rate)</span></div>';
        submitBtn.disabled = false;
        submitBtn.style.opacity = '1';
        submitBtn.style.cursor = 'pointer';
    }
}

// Event listeners
document.getElementById('equipmentSelect').addEventListener('change', function () {
    var state = document.getElementById('state').value;
    var district = document.getElementById('district').value;
    if (state && district) {
        fetchLiveRent();
    }
});
document.getElementById('equipmentRent').addEventListener('input', validateRent);

// Validate date range
document.getElementById('availableFrom').addEventListener('change', validateDates);
document.getElementById('availableTo').addEventListener('change', validateDates);

function validateDates() {
    var fromDate = document.getElementById('availableFrom').value;
    var toDate = document.getElementById('availableTo').value;
    if (fromDate && toDate && new Date(fromDate) > new Date(toDate)) {
        alert('"Available From" date must be before "Available To" date');
        document.getElementById('availableTo').value = '';
    }
}

// Form validation
document.getElementById('listingForm').addEventListener('submit', function (e) {
    var equipmentRent = parseFloat(document.getElementById('equipmentRent').value);
    var latitude = document.getElementById('latitude').value;
    var longitude = document.getElementById('longitude').value;
    var description = document.getElementById('description').value.trim();
    var fromDate = document.getElementById('availableFrom').value;
    var toDate = document.getElementById('availableTo').value;

    if (!latitude || !longitude) {
        e.preventDefault();
        alert('Please select your location on the map by clicking on it');
        document.getElementById('map').scrollIntoView({ behavior: 'smooth', block: 'center' });
        return false;
    }

    if (isNaN(equipmentRent) || equipmentRent <= 0) {
        e.preventDefault();
        alert('Please enter a valid rental rate greater than 0');
        return false;
    }

    if (!description || description.length < 10) {
        e.preventDefault();
        alert('Please provide a detailed description (at least 10 characters)');
        return false;
    }

    if (!fromDate || !toDate) {
        e.preventDefault();
        alert('Please select availability dates');
        return false;
    }

    if (new Date(fromDate) > new Date(toDate)) {
        e.preventDefault();
        alert('"Available From" date must be before "Available To" date');
        return false;
    }

    return true;
});

// Use Current Location Button
document.getElementById('useCurrentLocationBtn').addEventListener('click', function () {
    var btn = this;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Getting location...';

    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            function (position) {
                var userLat = position.coords.latitude;
                var userLng = position.coords.longitude;
                map.setView([userLat, userLng], 16);

                if (marker) {
                    marker.setLatLng([userLat, userLng]);
                } else {
                    marker = L.marker([userLat, userLng], {
                        draggable: true,
                        icon: L.icon({
                            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
                            shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                            iconSize: [25, 41],
                            iconAnchor: [12, 41],
                            popupAnchor: [1, -34],
                            shadowSize: [41, 41]
                        })
                    }).addTo(map);

                    marker.on('dragend', function (e) {
                        var position = marker.getLatLng();
                        updateLocationDetails(position.lat, position.lng);
                    });
                }

                updateLocationDetails(userLat, userLng);

                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-check-circle"></i> Location Set!';
                setTimeout(function () {
                    btn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Current Location';
                }, 2000);
            },
            function (error) {
                alert('Could not get your location. Please click on the map manually.');
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Current Location';
            },
            { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
        );
    } else {
        alert('Geolocation is not supported by your browser');
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Current Location';
    }
});

// Search Location
document.getElementById('searchLocationBtn').addEventListener('click', function () {
    var searchBox = document.getElementById('searchBox');
    searchBox.style.display = searchBox.style.display === 'none' ? 'block' : 'none';
});

document.getElementById('doSearchBtn').addEventListener('click', function () {
    var query = document.getElementById('searchInput').value.trim();
    if (!query) {
        alert('Please enter a location to search');
        return;
    }

    var btn = this;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Searching...';

    fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(query + ', India') + '&limit=1')
        .then(function (response) { return response.json(); })
        .then(function (data) {
            if (data && data.length > 0) {
                var lat = parseFloat(data[0].lat);
                var lng = parseFloat(data[0].lon);
                map.setView([lat, lng], 16);

                if (marker) {
                    marker.setLatLng([lat, lng]);
                } else {
                    marker = L.marker([lat, lng], {
                        draggable: true,
                        icon: L.icon({
                            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
                            shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                            iconSize: [25, 41],
                            iconAnchor: [12, 41],
                            popupAnchor: [1, -34],
                            shadowSize: [41, 41]
                        })
                    }).addTo(map);

                    marker.on('dragend', function (e) {
                        var position = marker.getLatLng();
                        updateLocationDetails(position.lat, position.lng);
                    });
                }

                updateLocationDetails(lat, lng);
                document.getElementById('searchBox').style.display = 'none';
                document.getElementById('searchInput').value = '';
            } else {
                alert('Location not found. Try different keywords or click on the map.');
            }

            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-search"></i> Search';
        })
        .catch(function (error) {
            console.error('Search error:', error);
            alert('Search failed. Please try again.');
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-search"></i> Search';
        });
});

document.getElementById('searchInput').addEventListener('keypress', function (e) {
    if (e.key === 'Enter') {
        e.preventDefault();
        document.getElementById('doSearchBtn').click();
    }
});

// Fullscreen toggle
document.getElementById('fullscreenBtn').addEventListener('click', function () {
    var mapContainer = document.getElementById('mapContainer');
    var icon = this.querySelector('i');

    if (mapContainer.classList.contains('fullscreen')) {
        mapContainer.classList.remove('fullscreen');
        icon.classList.remove('fa-compress');
        icon.classList.add('fa-expand');
        this.title = 'Toggle Fullscreen';
    } else {
        mapContainer.classList.add('fullscreen');
        icon.classList.remove('fa-expand');
        icon.classList.add('fa-compress');
        this.title = 'Exit Fullscreen';
    }

    setTimeout(function () { map.invalidateSize(); }, 100);
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        var mapContainer = document.getElementById('mapContainer');
        var fullscreenBtn = document.getElementById('fullscreenBtn');
        if (fullscreenBtn) {
            var icon = fullscreenBtn.querySelector('i');
            if (mapContainer.classList.contains('fullscreen')) {
                mapContainer.classList.remove('fullscreen');
                icon.classList.remove('fa-compress');
                icon.classList.add('fa-expand');
                fullscreenBtn.title = 'Toggle Fullscreen';
                setTimeout(function () { map.invalidateSize(); }, 100);
            }
        }
    }
});

// Set minimum date to today
document.getElementById('availableFrom').min = new Date().toISOString().split('T')[0];
document.getElementById('availableTo').min = new Date().toISOString().split('T')[0];

// Initialize on page load
window.addEventListener('DOMContentLoaded', function () {
    initializeMap();
});
