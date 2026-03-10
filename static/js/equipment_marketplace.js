/* ============================================
   Equipment Marketplace - Booking Modal JS
   Used by: equipment_marketplace.html
   ============================================ */

let currentListingData = {};

function openBookingModal(listingId, equipmentName, rent, ownerName, ownerPhone, ownerId) {
    currentListingData = {
        listingId: listingId,
        equipmentName: equipmentName,
        rent: rent,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        ownerId: ownerId
    };

    document.getElementById('booking_listing_id').value = listingId;
    document.getElementById('equipmentDetails').innerHTML =
        '<div class="purchase-detail-row">' +
            '<div class="detail-label">EQUIPMENT</div>' +
            '<div class="detail-value-large">' + equipmentName + '</div>' +
        '</div>' +
        '<div class="purchase-detail-grid">' +
            '<div><div class="detail-label">RENT PER DAY</div><div class="detail-value-price text-success">\u20B9' + parseFloat(rent).toFixed(2) + '</div></div>' +
            '<div><div class="detail-label">OWNER</div><div class="detail-value">' + (ownerName || 'Owner') + '</div></div>' +
        '</div>';

    var today = new Date().toISOString().split('T')[0];
    document.getElementById('from_date').min = today;
    document.getElementById('to_date').min = today;

    document.getElementById('bookingModal').style.display = 'flex';
    document.getElementById('bookingMessage').style.display = 'none';
    document.getElementById('bookingForm').reset();
}

function closeBookingModal() {
    document.getElementById('bookingModal').style.display = 'none';
}

document.getElementById('from_date').addEventListener('change', function () {
    document.getElementById('to_date').min = this.value;
});

document.getElementById('bookingForm').addEventListener('submit', function (e) {
    e.preventDefault();

    var submitBtn = document.getElementById('confirmBookingBtn');
    var messageDiv = document.getElementById('bookingMessage');
    var apiUrl = document.getElementById('marketplace-config').getAttribute('data-book-url');

    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Booking...';

    var formData = {
        listing_id: document.getElementById('booking_listing_id').value,
        from_date: new Date(document.getElementById('from_date').value).toISOString(),
        to_date: new Date(document.getElementById('to_date').value).toISOString(),
        renter_name: document.getElementById('renter_name').value,
        renter_phone: document.getElementById('renter_phone').value
    };

    fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            messageDiv.className = 'booking-message success';
            messageDiv.innerHTML = '<i class="fas fa-check-circle"></i> ' + data.message;
            messageDiv.style.display = 'block';
            setTimeout(function () { window.location.reload(); }, 1500);
        } else {
            messageDiv.className = 'booking-message error';
            messageDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> ' + (data.error || 'Booking failed');
            messageDiv.style.display = 'block';
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-check-circle"></i> Confirm Booking';
        }
    })
    .catch(function (error) {
        console.error('Booking error:', error);
        messageDiv.className = 'booking-message error';
        messageDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> An error occurred. Please try again.';
        messageDiv.style.display = 'block';
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<i class="fas fa-check-circle"></i> Confirm Booking';
    });
});
