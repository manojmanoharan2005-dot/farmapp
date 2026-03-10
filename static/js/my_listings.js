/* ============================================
   My Listings - Cancel Listing JS
   Used by: my_listings.html
   ============================================ */

function cancelListing(button) {
    var listingId = button.dataset.id;
    if (!listingId) {
        alert('Error: Invalid Listing ID');
        console.error('Missing listing ID');
        return;
    }

    if (!confirm('Are you sure you want to cancel this listing? This action cannot be undone.')) {
        return;
    }

    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Cancelling...';

    var apiBase = document.getElementById('listings-config').getAttribute('data-cancel-url');
    var url = apiBase.replace('0', listingId);

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
    })
    .then(function (response) {
        if (!response.ok) {
            return response.json().then(function (err) { throw err; }).catch(function () {
                throw new Error('Server error: ' + response.status);
            });
        }
        return response.json();
    })
    .then(function (data) {
        if (data.success) {
            if (window.showToast) {
                showToast('Listing cancelled successfully!', 'success');
            } else {
                alert('Listing cancelled successfully!');
            }
            setTimeout(function () { location.reload(); }, 1000);
        } else {
            throw new Error(data.message || 'Failed to cancel listing');
        }
    })
    .catch(function (error) {
        console.error('Cancel error:', error);
        var msg = error.message || 'Failed to cancel listing';
        if (window.showToast) {
            showToast(msg, 'error');
        } else {
            alert(msg);
        }
        button.disabled = false;
        button.innerHTML = '<i class="fas fa-trash-alt"></i> Cancel';
    });
}
