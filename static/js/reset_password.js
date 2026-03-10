/* ============================================
   Reset Password Page JS
   Used by: reset_password.html
   ============================================ */

function togglePassword(inputId, iconId) {
    var input = document.getElementById(inputId);
    var icon = document.getElementById(iconId);

    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

function checkPasswordStrength() {
    var password = document.getElementById('password').value;
    var indicator = document.getElementById('strengthIndicator');
    var bar = document.getElementById('strengthBar');
    var text = document.getElementById('strengthText');

    if (password.length === 0) {
        indicator.style.display = 'none';
        return;
    }

    indicator.style.display = 'block';

    var strength = 0;
    var strengthLabel = '';
    var color = '';

    if (password.length >= 8) strength += 20;
    if (password.length >= 12) strength += 10;
    if (/[a-z]/.test(password)) strength += 20;
    if (/[A-Z]/.test(password)) strength += 20;
    if (/\d/.test(password)) strength += 15;
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) strength += 15;

    if (strength < 40) {
        strengthLabel = 'Weak';
        color = '#ef4444';
    } else if (strength < 70) {
        strengthLabel = 'Medium';
        color = '#f59e0b';
    } else {
        strengthLabel = 'Strong';
        color = '#10b981';
    }

    bar.style.width = strength + '%';
    bar.style.backgroundColor = color;
    text.textContent = strengthLabel;
    text.style.color = color;
}

function submitReset() {
    var password = document.getElementById('password').value;
    var confirmPassword = document.getElementById('confirm_password').value;
    var submitBtn = document.getElementById('submitBtn');
    var btnText = document.getElementById('btnText');
    var btnLoader = document.getElementById('btnLoader');

    if (password !== confirmPassword) {
        showAlert('Passwords do not match!', 'error');
        return;
    }

    submitBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoader.style.display = 'inline-block';

    fetch('/api/forgot-password/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            password: password,
            confirm_password: confirmPassword
        })
    })
    .then(function (response) { return response.json(); })
    .then(function (data) {
        if (data.success) {
            showAlert(data.message, 'success');
            setTimeout(function () {
                window.location.href = data.redirect_url;
            }, 1500);
        } else {
            showAlert(data.message, 'error');
            submitBtn.disabled = false;
            btnText.style.display = 'inline-block';
            btnLoader.style.display = 'none';
        }
    })
    .catch(function (error) {
        console.error(error);
        showAlert('Something went wrong', 'error');
        submitBtn.disabled = false;
        btnText.style.display = 'inline-block';
        btnLoader.style.display = 'none';
    });
}

function showAlert(message, type) {
    var alertContainer = document.getElementById('alertContainer');
    var icon = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';
    var alertClass = type === 'success' ? 'alert-success' : 'alert-error';

    alertContainer.innerHTML =
        '<div class="alert-box ' + alertClass + '">' +
        '<i class="fas ' + icon + '"></i> ' + message +
        '</div>';

    window.scrollTo({ top: 0, behavior: 'smooth' });
}
