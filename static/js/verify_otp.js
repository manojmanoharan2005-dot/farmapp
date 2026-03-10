/* ============================================
   Verify OTP Page JS
   Used by: verify_otp.html
   ============================================ */

var identifier = document.getElementById('otp-config').getAttribute('data-identifier');
var timeLeft = 180;
var timerInterval;

// Auto-format OTP input to only accept numbers
document.getElementById('otpInput').addEventListener('input', function () {
    this.value = this.value.replace(/[^0-9]/g, '');
});

// Start countdown timer
function startTimer() {
    timerInterval = setInterval(function () {
        timeLeft--;

        var minutes = Math.floor(timeLeft / 60);
        var seconds = timeLeft % 60;

        document.getElementById('timer').textContent =
            String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');

        if (timeLeft <= 0) {
            clearInterval(timerInterval);
            document.querySelector('.otp-timer').innerHTML =
                '<i class="fas fa-exclamation-circle text-danger"></i> <span class="text-danger">OTP Expired</span>';
            enableResendButton();
        }
    }, 1000);
}

function enableResendButton() {
    var resendBtn = document.getElementById('resendBtn');
    resendBtn.disabled = false;
}

function resendOTP() {
    var resendBtn = document.getElementById('resendBtn');
    resendBtn.disabled = true;
    resendBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';

    fetch('/api/forgot-password/request-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier: identifier })
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            showAlert('New OTP sent successfully!', 'success');
            clearInterval(timerInterval);
            timeLeft = 180;
            startTimer();
            resendBtn.innerHTML = '<i class="fas fa-redo-alt"></i> Resend';
        } else {
            showAlert(data.message, 'error');
            resendBtn.disabled = false;
            resendBtn.innerHTML = '<i class="fas fa-redo-alt"></i> Resend';
        }
    })
    .catch(function () {
        showAlert('Failed to resend OTP. Please try again.', 'error');
        resendBtn.disabled = false;
        resendBtn.innerHTML = '<i class="fas fa-redo-alt"></i> Resend';
    });
}

document.getElementById('resendBtn').addEventListener('click', resendOTP);

document.getElementById('verifyOtpForm').addEventListener('submit', function (e) {
    e.preventDefault();

    var otp = document.getElementById('otpInput').value.trim();
    var submitBtn = document.getElementById('submitBtn');
    var btnText = document.getElementById('btnText');

    if (!/^\d{6}$/.test(otp)) {
        showAlert('Please enter a valid 6-digit OTP', 'error');
        return;
    }

    submitBtn.disabled = true;
    btnText.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Verifying...';

    fetch('/api/forgot-password/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier: identifier, otp: otp })
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            showAlert(data.message, 'success');
            clearInterval(timerInterval);
            setTimeout(function () {
                window.location.href = data.redirect_url;
            }, 1500);
        } else {
            showAlert(data.message, 'error');
            submitBtn.disabled = false;
            btnText.innerHTML = '<i class="fas fa-check-circle"></i> Verify OTP';
            document.getElementById('otpInput').value = '';
            document.getElementById('otpInput').focus();
        }
    })
    .catch(function (error) {
        console.error('Error:', error);
        showAlert('Network error. Please try again.', 'error');
        submitBtn.disabled = false;
        btnText.innerHTML = '<i class="fas fa-check-circle"></i> Verify OTP';
    });
});

function showAlert(message, type) {
    var alertContainer = document.getElementById('alertContainer');
    var icon = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';
    var alertClass = type === 'success' ? 'alert-success' : 'alert-error';

    alertContainer.innerHTML =
        '<div class="alert-box ' + alertClass + '">' +
        '<i class="fas ' + icon + '"></i>' +
        '<span>' + message + '</span>' +
        '</div>';

    setTimeout(function () {
        alertContainer.innerHTML = '';
    }, 5000);
}

// Auto-focus OTP input and start timer on page load
document.getElementById('otpInput').focus();
startTimer();
