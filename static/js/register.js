function updateDistricts() {
    const statesDistrictsData = JSON.parse(document.getElementById('states-districts-data').textContent);
    const stateSelect = document.getElementById('state');
    const districtSelect = document.getElementById('district');
    const selectedState = stateSelect.value;

    districtSelect.innerHTML = '<option value="">Select district</option>';

    if (selectedState && statesDistrictsData[selectedState]) {
        statesDistrictsData[selectedState].forEach(function (district) {
            const option = document.createElement('option');
            option.value = district;
            option.textContent = district;
            districtSelect.appendChild(option);
        });
    }
}

// Debounce timer for pincode API calls
let pincodeTimer = null;

// Fetch pincode details from Indian Postal API
function fetchPincodeDetails() {
    const pincodeInput = document.getElementById('pincode');
    const pincode = pincodeInput.value.trim();
    const statusElement = document.getElementById('pincode-status');
    const villageSelect = document.getElementById('village');
    const stateSelect = document.getElementById('state');
    const districtSelect = document.getElementById('district');

    // Clear previous timer
    if (pincodeTimer) {
        clearTimeout(pincodeTimer);
    }

    // Validate pincode length
    if (pincode.length < 6) {
        statusElement.textContent = '';
        statusElement.className = 'pincode-status';
        villageSelect.innerHTML = '<option value="">Select your village/area</option>';
        return;
    }

    if (pincode.length !== 6 || !/^\d{6}$/.test(pincode)) {
        statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> Please enter a valid 6-digit pincode';
        statusElement.className = 'pincode-status error';
        return;
    }

    // Show loading status
    statusElement.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Fetching location...';
    statusElement.className = 'pincode-status loading loading-text';

    // Debounce API call (wait 500ms after user stops typing)
    pincodeTimer = setTimeout(function() {
        fetch(`https://api.postalpincode.in/pincode/${pincode}`)
            .then(response => response.json())
            .then(data => {
                if (data && data[0] && data[0].Status === 'Success') {
                    const postOffices = data[0].PostOffice;
                    
                    if (postOffices && postOffices.length > 0) {
                        // Get state and district from first post office
                        const firstPO = postOffices[0];
                        const apiState = firstPO.State;
                        const apiDistrict = firstPO.District;
                        
                        console.log('API Response - State:', apiState, 'District:', apiDistrict);

                        // Normalize for comparison
                        const normalize = (s) => s.toLowerCase().replace(/\s+/g, '').replace(/and/g, '').trim();
                        
                        // Find matching state
                        let stateFound = false;
                        for (let i = 0; i < stateSelect.options.length; i++) {
                            const opt = stateSelect.options[i];
                            if (!opt.value) continue;
                            
                            const optNorm = normalize(opt.value);
                            const apiNorm = normalize(apiState);
                            
                            if (optNorm === apiNorm || optNorm.includes(apiNorm) || apiNorm.includes(optNorm)) {
                                stateSelect.selectedIndex = i;
                                stateFound = true;
                                console.log('State matched:', opt.value);
                                
                                // Trigger change event to update districts
                                updateDistricts();
                                
                                // Auto-select district after districts are loaded
                                setTimeout(() => {
                                    for (let j = 0; j < districtSelect.options.length; j++) {
                                        const distOpt = districtSelect.options[j];
                                        if (!distOpt.value) continue;
                                        
                                        const distOptNorm = normalize(distOpt.value);
                                        const distApiNorm = normalize(apiDistrict);
                                        
                                        if (distOptNorm === distApiNorm || distOptNorm.includes(distApiNorm) || distApiNorm.includes(distOptNorm)) {
                                            districtSelect.selectedIndex = j;
                                            console.log('District matched:', distOpt.value);
                                            break;
                                        }
                                    }
                                }, 150);
                                
                                break;
                            }
                        }
                        
                        if (!stateFound) {
                            console.log('State not found in dropdown:', apiState);
                        }

                        // Populate villages dropdown
                        villageSelect.innerHTML = '<option value="">Select your village/area</option>';
                        
                        // Get unique village/area names
                        const uniqueVillages = [...new Set(postOffices.map(po => po.Name))];
                        uniqueVillages.sort(); // Sort alphabetically
                        
                        uniqueVillages.forEach(function(village) {
                            const option = document.createElement('option');
                            option.value = village;
                            option.textContent = village;
                            villageSelect.appendChild(option);
                        });

                        statusElement.innerHTML = '<i class="fas fa-check-circle"></i> Location found: ' + apiDistrict + ', ' + apiState;
                        statusElement.className = 'pincode-status success';
                        
                        // Clear success message after 3 seconds
                        setTimeout(() => {
                            statusElement.textContent = '';
                            statusElement.className = 'pincode-status';
                        }, 3000);
                    }
                } else {
                    statusElement.innerHTML = '<i class="fas fa-times-circle"></i> Invalid pincode';
                    statusElement.className = 'pincode-status error';
                    villageSelect.innerHTML = '<option value="">No villages found</option>';
                }
            })
            .catch(error => {
                console.error('Pincode API error:', error);
                statusElement.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Could not fetch. Select manually.';
                statusElement.className = 'pincode-status error';
            });
    }, 500);
}

// Globalize for safety
window.updateDistricts = updateDistricts;
window.fetchPincodeDetails = fetchPincodeDetails;
// ----- OTP Verification for Email Address -----

let otpCountdownInterval = null;
let emailVerified = false;

// Send OTP to email address
function sendOTP() {
    const emailInput = document.getElementById('email');
    const email = emailInput.value.trim();
    const sendOtpBtn = document.getElementById('sendOtpBtn');
    const statusElement = document.getElementById('email-status');
    const otpSection = document.getElementById('otp-section');
    
    // Validate email
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!email || !emailRegex.test(email)) {
        statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> Enter a valid email address';
        statusElement.className = 'email-status error';
        return;
    }
    
    // Disable button and show loading
    sendOtpBtn.disabled = true;
    sendOtpBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
    statusElement.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending OTP to your email...';
    statusElement.className = 'email-status loading';
    
    // Call API to send OTP
    fetch('/api/register/send-otp', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email: email })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            statusElement.innerHTML = '<i class="fas fa-check-circle"></i> ' + data.message;
            statusElement.className = 'email-status success';
            
            // Show OTP input section
            otpSection.style.display = 'block';
            document.getElementById('otp').focus();
            
            // Start countdown timer (5 minutes)
            startOTPCountdown(300);
            
            // Disable email input after OTP sent
            emailInput.readOnly = true;
            emailInput.style.backgroundColor = '#f0f0f0';
            
            sendOtpBtn.innerHTML = '<i class="fas fa-clock"></i> OTP Sent';
        } else {
            statusElement.innerHTML = '<i class="fas fa-times-circle"></i> ' + data.message;
            statusElement.className = 'email-status error';
            sendOtpBtn.disabled = false;
            sendOtpBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Send OTP';
        }
    })
    .catch(error => {
        console.error('Send OTP error:', error);
        statusElement.innerHTML = '<i class="fas fa-times-circle"></i> Failed to send OTP. Please try again.';
        statusElement.className = 'email-status error';
        sendOtpBtn.disabled = false;
        sendOtpBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Send OTP';
    });
}

// Verify OTP
function verifyOTP() {
    const email = document.getElementById('email').value.trim();
    const otp = document.getElementById('otp').value.trim();
    const verifyBtn = document.getElementById('verifyOtpBtn');
    const statusElement = document.getElementById('email-status');
    const otpSection = document.getElementById('otp-section');
    const verifiedBadge = document.getElementById('email-verified');
    const sendOtpBtn = document.getElementById('sendOtpBtn');
    
    // Validate OTP format
    if (!otp || !/^[0-9]{6}$/.test(otp)) {
        statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> Enter the 6-digit OTP';
        statusElement.className = 'email-status error';
        return;
    }
    
    // Disable button and show loading
    verifyBtn.disabled = true;
    verifyBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    
    // Call API to verify OTP
    fetch('/api/register/verify-otp', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email: email, otp: otp })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Hide OTP section and show verified badge
            otpSection.style.display = 'none';
            verifiedBadge.style.display = 'flex';
            sendOtpBtn.style.display = 'none';
            statusElement.textContent = '';
            
            // Stop countdown
            if (otpCountdownInterval) {
                clearInterval(otpCountdownInterval);
            }
            
            emailVerified = true;
            
            // Clear success message after a moment
            setTimeout(() => {
                statusElement.className = 'email-status';
            }, 100);
        } else {
            statusElement.innerHTML = '<i class="fas fa-times-circle"></i> ' + data.message;
            statusElement.className = 'email-status error';
            verifyBtn.disabled = false;
            verifyBtn.innerHTML = '<i class="fas fa-check"></i> Verify';
            
            // Clear OTP input for retry
            document.getElementById('otp').value = '';
            document.getElementById('otp').focus();
        }
    })
    .catch(error => {
        console.error('Verify OTP error:', error);
        statusElement.innerHTML = '<i class="fas fa-times-circle"></i> Verification failed. Please try again.';
        statusElement.className = 'email-status error';
        verifyBtn.disabled = false;
        verifyBtn.innerHTML = '<i class="fas fa-check"></i> Verify';
    });
}

// Start OTP countdown timer
function startOTPCountdown(seconds) {
    const countdownElement = document.getElementById('otp-countdown');
    const timerText = document.getElementById('otp-timer-text');
    const resendBtn = document.getElementById('resendOtpBtn');
    const sendOtpBtn = document.getElementById('sendOtpBtn');
    
    // Clear existing interval
    if (otpCountdownInterval) {
        clearInterval(otpCountdownInterval);
    }
    
    let timeLeft = seconds;
    
    // Hide resend button initially
    resendBtn.style.display = 'none';
    timerText.style.display = 'inline';
    
    otpCountdownInterval = setInterval(() => {
        timeLeft--;
        
        const minutes = Math.floor(timeLeft / 60);
        const secs = timeLeft % 60;
        const formattedTime = `${minutes}:${secs.toString().padStart(2, '0')}`;
        
        countdownElement.textContent = formattedTime;
        
        if (timeLeft <= 0) {
            clearInterval(otpCountdownInterval);
            timerText.style.display = 'none';
            resendBtn.style.display = 'inline-flex';
            
            // Re-enable send OTP button for resend
            sendOtpBtn.disabled = false;
            sendOtpBtn.innerHTML = '<i class="fas fa-redo"></i> Resend';
            
            // Allow editing email again
            const emailInput = document.getElementById('email');
            emailInput.readOnly = false;
            emailInput.style.backgroundColor = '#fff';
        }
    }, 1000);
}

// Form submission validation
document.addEventListener('DOMContentLoaded', function() {
    const form = document.querySelector('.register-form');
    
    if (form) {
        form.addEventListener('submit', function(e) {
            if (!emailVerified) {
                e.preventDefault();
                const statusElement = document.getElementById('email-status');
                statusElement.innerHTML = '<i class="fas fa-exclamation-circle"></i> Please verify your email address first';
                statusElement.className = 'email-status error';
                
                // Scroll to email section
                document.getElementById('email').scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        });
    }
});

// Globalize OTP functions
window.sendOTP = sendOTP;
window.verifyOTP = verifyOTP;