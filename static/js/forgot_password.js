/* ============================================
   Forgot Password Page JS
   Used by: forgot_password.html
   ============================================ */

function requestOTP() {
    var identifier = document.getElementById('identifier').value.trim();
    var submitBtn = document.getElementById('submitBtn');
    var btnText = document.getElementById('btnText');
    var btnLoader = document.getElementById('btnLoader');
    var alertContainer = document.getElementById('alertContainer');

    if (!identifier) {
        showAlert('Please enter your email or mobile number', 'error');
        return;
    }

    submitBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoader.style.display = 'inline-block';
    alertContainer.innerHTML = '';

    fetch('/api/forgot-password/request-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier: identifier })
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            showAlert(data.message, 'success');
            setTimeout(function () {
                window.location.href = '/verify-otp?identifier=' + encodeURIComponent(identifier);
            }, 1500);
        } else {
            showAlert(data.message, 'error');
            resetBtn();
        }
    })
    .catch(function (error) {
        console.error('Error:', error);
        showAlert('Something went wrong. Please try again.', 'error');
        resetBtn();
    });
}

function resetBtn() {
    var submitBtn = document.getElementById('submitBtn');
    var btnText = document.getElementById('btnText');
    var btnLoader = document.getElementById('btnLoader');
    submitBtn.disabled = false;
    btnText.style.display = 'inline-block';
    btnLoader.style.display = 'none';
}

function showAlert(message, type) {
    var alertContainer = document.getElementById('alertContainer');
    var bgColor = type === 'success' ? '#dcfce7' : '#fee2e2';
    var textColor = type === 'success' ? '#166534' : '#991b1b';
    var borderColor = type === 'success' ? '#bbf7d0' : '#fecaca';
    var icon = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';

    alertContainer.innerHTML =
        '<div class="alert-box ' + (type === 'success' ? 'alert-success' : 'alert-error') + '">' +
        '<i class="fas ' + icon + '"></i> ' + message +
        '</div>';
}
