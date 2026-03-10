/* ============================================
   Create Listing - Map & Price JS
   Used by: create_listing.html
   ============================================ */

let currentMinPrice = 0;
let currentMaxPrice = 0;
let currentRecommendedPrice = 0;

// Map variables
let map;
let marker;
let selectedLat = null;
let selectedLng = null;

// States and districts data from data island
const statesDistricts = JSON.parse(document.getElementById('states-districts-data').textContent);

// Initialize map with optimized settings
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
        const lat = e.latlng.lat;
        const lng = e.latlng.lng;

        if (marker) {
            marker.setLatLng(e.latlng);
        } else {
            marker = L.marker(e.latlng, {
                draggable: true,
                icon: L.icon({
                    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
                    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                    iconSize: [25, 41],
                    iconAnchor: [12, 41],
                    popupAnchor: [1, -34],
                    shadowSize: [41, 41]
                })
            }).addTo(map);

            marker.on('dragend', function (e) {
                const position = marker.getLatLng();
                updateLocationDetails(position.lat, position.lng);
            });
        }

        updateLocationDetails(lat, lng);
    });

    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function (position) {
            const userLat = position.coords.latitude;
            const userLng = position.coords.longitude;
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
        .then(function(response) { return response.json(); })
        .then(function(data) {
            var address = data.address || {};
            var village = address.town || address.city || address.municipality || address.suburb || address.state_district || 'Selected Location';
            var displayName = data.display_name || 'Location details not available';
            var detectedState = (address.state || '').replace(/^State of /i, '').trim();
            var detectedDistrict = address.state_district || address.county || address.city_district || '';

            document.getElementById('state').value = detectedState;
            document.getElementById('district').value = detectedDistrict;

            document.getElementById('locationDetails').innerHTML =
                '<div class="location-pin-row"><i class="fas fa-map-pin location-pin-icon"></i> <strong class="location-name">' + village + '</strong></div>' +
                '<div class="location-address">' + displayName + '</div>' +
                '<div class="location-coords-grid">' +
                    '<strong>Coordinates:</strong> <span>' + lat.toFixed(6) + ', ' + lng.toFixed(6) + '</span>' +
                    '<strong>District:</strong> <span class="location-highlight">' + (detectedDistrict || 'Detecting...') + '</span>' +
                    '<strong>State:</strong> <span class="location-highlight">' + (detectedState || 'Detecting...') + '</span>' +
                '</div>';

            var crop = document.getElementById('cropSelect').value;
            if (crop && detectedState && detectedDistrict) {
                fetchLivePrice();
            }
        })
        .catch(function(error) {
            console.error('Geocoding error:', error);
            document.getElementById('locationDetails').innerHTML =
                '<strong>Coordinates:</strong> ' + lat.toFixed(6) + ', ' + lng.toFixed(6) + '<br>' +
                '<strong>District:</strong> ' + (document.getElementById('district').value || 'Not selected') + '<br>' +
                '<strong>State:</strong> ' + (document.getElementById('state').value || 'Not selected') + '<br>' +
                '<small class="text-danger">Could not fetch location name. Please ensure internet connection.</small>';
        });
}

// Auto-fetch live price when crop and location are selected
function fetchLivePrice() {
    var crop = document.getElementById('cropSelect').value;
    var district = document.getElementById('district').value;
    var state = document.getElementById('state').value;
    var apiUrl = document.getElementById('listing-config').getAttribute('data-live-price-url');

    if (!crop) return;
    if (!district || !state) {
        document.getElementById('priceInfoBox').style.display = 'none';
        return;
    }

    document.getElementById('priceInfoBox').style.display = 'block';
    document.getElementById('marketName').textContent = 'Fetching live price...';

    fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ crop: crop, district: district, state: state })
    })
    .then(function(res) { return res.json(); })
    .then(function(data) {
        if (data.success) {
            currentRecommendedPrice = data.recommended_price;
            currentMinPrice = data.min_price;
            currentMaxPrice = data.max_price;

            document.getElementById('recommendedPrice').textContent = '\u20B9' + currentRecommendedPrice.toFixed(2) + '/kg';
            document.getElementById('minPrice').textContent = '\u20B9' + currentMinPrice.toFixed(2) + '/kg';
            document.getElementById('maxPrice').textContent = '\u20B9' + currentMaxPrice.toFixed(2) + '/kg';
            document.getElementById('marketName').textContent = data.market_name + ' \u2022 ' + data.price_date;

            document.getElementById('farmerPrice').value = currentRecommendedPrice.toFixed(2);
            validatePrice();
        } else {
            document.getElementById('marketName').textContent = 'No live price data available for this crop/location';
        }
    })
    .catch(function(error) {
        console.error('Error fetching live price:', error);
        document.getElementById('marketName').textContent = 'Error fetching live price. Please try again.';
    });
}

// Validate price is within range
function validatePrice() {
    var farmerPrice = parseFloat(document.getElementById('farmerPrice').value);
    var validationDiv = document.getElementById('priceValidation');
    var submitBtn = document.getElementById('submitBtn');

    if (isNaN(farmerPrice) || farmerPrice <= 0) {
        validationDiv.innerHTML = '';
        return;
    }

    if (farmerPrice < currentMinPrice || farmerPrice > currentMaxPrice) {
        validationDiv.innerHTML =
            '<div class="validation-message error">' +
            '<i class="fas fa-exclamation-triangle"></i>' +
            '<span>Price must be between \u20B9' + currentMinPrice.toFixed(2) + '/kg and \u20B9' + currentMaxPrice.toFixed(2) + '/kg</span>' +
            '</div>';
        submitBtn.disabled = true;
        submitBtn.style.opacity = '0.5';
        submitBtn.style.cursor = 'not-allowed';
    } else {
        var diffPercent = ((farmerPrice - currentRecommendedPrice) / currentRecommendedPrice * 100).toFixed(1);
        var diffText = diffPercent > 0 ? '+' + diffPercent + '%' : diffPercent + '%';

        validationDiv.innerHTML =
            '<div class="validation-message success">' +
            '<i class="fas fa-check-circle"></i>' +
            '<span>Valid price (' + diffText + ' from market price)</span>' +
            '</div>';
        submitBtn.disabled = false;
        submitBtn.style.opacity = '1';
        submitBtn.style.cursor = 'pointer';
    }
}

// Event listeners
document.getElementById('cropSelect').addEventListener('change', function () {
    var state = document.getElementById('state').value;
    var district = document.getElementById('district').value;
    if (state && district) {
        fetchLivePrice();
    }
});
document.getElementById('farmerPrice').addEventListener('input', validatePrice);

// Form validation before submission
document.getElementById('listingForm').addEventListener('submit', function (e) {
    var quantity = parseFloat(document.getElementById('quantity').value);
    var farmerPrice = parseFloat(document.getElementById('farmerPrice').value);
    var latitude = document.getElementById('latitude').value;
    var longitude = document.getElementById('longitude').value;

    if (!latitude || !longitude) {
        e.preventDefault();
        alert('Please select your location on the map by clicking on it');
        document.getElementById('map').scrollIntoView({ behavior: 'smooth', block: 'center' });
        return false;
    }

    if (isNaN(quantity) || quantity <= 0) {
        e.preventDefault();
        alert('Please enter a valid quantity greater than 0');
        return false;
    }

    if (quantity > 100000) {
        e.preventDefault();
        alert('Quantity seems unreasonably high. Please check your input.');
        return false;
    }

    if (isNaN(farmerPrice) || farmerPrice <= 0) {
        e.preventDefault();
        alert('Please enter a valid price greater than 0');
        return false;
    }

    if (farmerPrice < currentMinPrice || farmerPrice > currentMaxPrice) {
        e.preventDefault();
        alert('Price must be between \u20B9' + currentMinPrice.toFixed(2) + '/kg and \u20B9' + currentMaxPrice.toFixed(2) + '/kg');
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
                            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
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
                setTimeout(function() {
                    btn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Current Location';
                }, 2000);
            },
            function (error) {
                alert('Could not get your location. Please click on the map manually or check location permissions.');
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

// Search Location Button
document.getElementById('searchLocationBtn').addEventListener('click', function () {
    var searchBox = document.getElementById('searchBox');
    searchBox.style.display = searchBox.style.display === 'none' ? 'block' : 'none';
});

// Search Location Function
document.getElementById('doSearchBtn').addEventListener('click', function () {
    var query = document.getElementById('searchInput').value.trim();

    if (!query) {
        alert('Please enter a location to search');
        return;
    }

    var btn = this;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Searching...';

    var fullQuery = query + ', India';

    fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(fullQuery) + '&limit=1')
        .then(function(response) { return response.json(); })
        .then(function(data) {
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
                            iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
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
                alert('Location not found. Try searching with different keywords or click on the map.');
            }

            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-search"></i> Search';
        })
        .catch(function(error) {
            console.error('Search error:', error);
            alert('Search failed. Please try again or click on the map manually.');
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-search"></i> Search';
        });
});

// Allow Enter key to search
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

    setTimeout(function() { map.invalidateSize(); }, 100);
});

// Exit fullscreen on ESC key
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
                setTimeout(function() { map.invalidateSize(); }, 100);
            }
        }
    }
});

// Initialize on page load
window.addEventListener('DOMContentLoaded', function () {
    initializeMap();
});
