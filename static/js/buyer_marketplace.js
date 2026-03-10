/* ============================================
   Buyer Marketplace - Purchase Modal JS
   Used by: buyer_marketplace.html
   ============================================ */

let currentListingData = {};
let purchaseMap = null;

function openPurchaseModal(btn) {
    var dataset = btn.dataset;
    var listingId = dataset.id;
    var crop = dataset.crop;
    var price = dataset.price;
    var quantity = dataset.quantity;
    var unit = dataset.unit;
    var farmerName = dataset.farmerName;
    var farmerPhone = dataset.farmerPhone;
    var lat = parseFloat(dataset.lat);
    var lng = parseFloat(dataset.lng);
    var farmerId = dataset.farmerId;

    currentListingData = { listingId: listingId, crop: crop, price: price, quantity: quantity, unit: unit, farmerName: farmerName, farmerPhone: farmerPhone, lat: lat, lng: lng, farmerId: farmerId };

    document.getElementById('purchase_listing_id').value = listingId;
    document.getElementById('purchaseDetails').innerHTML =
        '<div class="purchase-detail-row">' +
            '<div class="detail-label">CROP</div>' +
            '<div class="detail-value-large">' + crop + '</div>' +
        '</div>' +
        '<div class="purchase-detail-grid">' +
            '<div><div class="detail-label">QUANTITY</div><div class="detail-value">' + quantity + ' ' + unit + '</div></div>' +
            '<div><div class="detail-label">PRICE</div><div class="detail-value-price text-success">\u20B9' + parseFloat(price).toFixed(2) + '/kg</div></div>' +
        '</div>' +
        '<div><div class="detail-label">FARMER</div><div class="detail-value">' + (farmerName || 'Farmer') + '</div></div>';

    document.getElementById('purchaseModal').style.display = 'flex';
    document.getElementById('purchaseMessage').style.display = 'none';

    // Initialize map with farm location
    setTimeout(function () {
        if (lat && lng && lat !== 0 && lng !== 0) {
            if (purchaseMap) {
                purchaseMap.remove();
            }

            purchaseMap = L.map('purchaseMap').setView([lat, lng], 13);

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; OpenStreetMap contributors',
                maxZoom: 19
            }).addTo(purchaseMap);

            L.marker([lat, lng], {
                icon: L.icon({
                    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
                    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
                    iconSize: [25, 41],
                    iconAnchor: [12, 41],
                    popupAnchor: [1, -34],
                    shadowSize: [41, 41]
                })
            }).addTo(purchaseMap).bindPopup('<strong>' + crop + ' Farm</strong><br>' + farmerName).openPopup();
        } else {
            document.getElementById('purchaseMap').innerHTML =
                '<div class="map-unavailable"><i class="fas fa-map-marked-alt"></i>&nbsp; Location not available</div>';
        }
    }, 100);
}

function closePurchaseModal() {
    document.getElementById('purchaseModal').style.display = 'none';
    document.getElementById('purchaseForm').reset();
    document.getElementById('purchaseMessage').style.display = 'none';

    if (purchaseMap) {
        purchaseMap.remove();
        purchaseMap = null;
    }
}

document.getElementById('purchaseForm').addEventListener('submit', function (e) {
    e.preventDefault();

    var submitBtn = document.getElementById('confirmPurchaseBtn');
    var messageDiv = document.getElementById('purchaseMessage');
    var apiUrl = document.getElementById('marketplace-config').getAttribute('data-confirm-purchase-url');

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    messageDiv.style.display = 'none';

    var formData = {
        listing_id: document.getElementById('purchase_listing_id').value,
        buyer_name: document.getElementById('buyer_name').value,
        buyer_phone: document.getElementById('buyer_phone').value
    };

    fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            messageDiv.className = 'validation-message success';
            messageDiv.innerHTML = '<i class="fas fa-check-circle"></i> ' + data.message;
            messageDiv.style.display = 'block';
            setTimeout(function () { window.location.reload(); }, 1500);
        } else {
            messageDiv.className = 'validation-message error';
            messageDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> ' + (data.error || data.message || 'Failed to confirm purchase');
            messageDiv.style.display = 'block';
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-check-circle"></i> Confirm';
        }
    })
    .catch(function (error) {
        console.error('Purchase error:', error);
        messageDiv.className = 'validation-message error';
        messageDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> An error occurred. Please try again.';
        messageDiv.style.display = 'block';
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<i class="fas fa-check-circle"></i> Confirm';
    });
});

// Close modal on outside click
document.getElementById('purchaseModal').addEventListener('click', function (e) {
    if (e.target === this) {
        closePurchaseModal();
    }
});
