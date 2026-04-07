window.openProfileModal = function() {
    const modal = document.getElementById('profileModal');
    if (modal) modal.style.display = 'flex';
}

window.closeProfileModal = function() {
    const modal = document.getElementById('profileModal');
    if (modal) modal.style.display = 'none';
}

window.openWeatherModal = function() {
    const modal = document.getElementById('weatherModal');
    if (modal) modal.style.display = 'flex';
    fetchWeatherByLocation();
}

window.closeWeatherModal = function() {
    const modal = document.getElementById('weatherModal');
    if (modal) modal.style.display = 'none';
}

window.getWeatherIcon = function(conditionText) {
    const condition = conditionText.toLowerCase();
    if (condition.includes('sunny') || condition.includes('clear')) return '☀️';
    if (condition.includes('partly cloudy')) return '⛅';
    if (condition.includes('cloudy') || condition.includes('overcast')) return '☁️';
    if (condition.includes('mist') || condition.includes('fog')) return '🌫️';
    if (condition.includes('rain') && !condition.includes('heavy')) return '🌦️';
    if (condition.includes('heavy rain')) return '🌧️';
    if (condition.includes('thunder') || condition.includes('storm')) return '⛈️';
    if (condition.includes('snow')) return '❄️';
    return '🌤️';
}

window.displayWeather = function(data) {
    const current = data.current;
    const location = data.location;
    const forecast = data.forecast.forecastday;

    const weatherIcon = getWeatherIcon(current.condition.text);
    const locationName = `${location.name}, ${location.region || location.country}`;

    const content = document.getElementById('weatherModalContent');
    if (content) {
        content.innerHTML = `
            <div style="text-align: center; padding: 20px;">
                <div style="font-size: 64px;">${weatherIcon}</div>
                <h2 style="margin: 12px 0 4px 0;">${Math.round(current.temp_c)}°C</h2>
                <p style="color: var(--text-secondary); margin: 0 0 4px 0; font-weight: 500;">${current.condition.text}</p>
                <p style="color: var(--text-secondary); margin: 0; font-size: 14px;">
                    <i class="fas fa-map-marker-alt"></i> ${locationName}
                </p>
                <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-top: 20px;">
                    <div style="padding: 16px; background: var(--body-bg); border-radius: 8px;">
                        <div style="font-size: 24px;">💧</div>
                        <div style="font-weight: 700;">${current.humidity}%</div>
                        <div style="font-size: 12px; color: var(--text-secondary);">Humidity</div>
                    </div>
                    <div style="padding: 16px; background: var(--body-bg); border-radius: 8px;">
                        <div style="font-size: 24px;">💨</div>
                        <div style="font-weight: 700;">${Math.round(current.wind_kph)} km/h</div>
                        <div style="font-size: 12px; color: var(--text-secondary);">Wind</div>
                    </div>
                    <div style="padding: 16px; background: var(--body-bg); border-radius: 8px;">
                        <div style="font-size: 24px;">👁️</div>
                        <div style="font-weight: 700;">${current.vis_km} km</div>
                        <div style="font-size: 12px; color: var(--text-secondary);">Visibility</div>
                    </div>
                </div>
                
                <!-- 7-Day Forecast -->
                <div style="margin-top: 24px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                    <h3 style="margin: 0 0 16px 0; font-size: 16px; text-align: left; color: var(--text-primary);">
                        <i class="fas fa-calendar-alt"></i> 7-Day Forecast
                    </h3>
                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        ${forecast.map((day, index) => {
            const dayName = index === 0 ? 'Today' : index === 1 ? 'Tomorrow' : new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' });
            const dayIcon = getWeatherIcon(day.day.condition.text);
            return `
                                <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px; background: var(--body-bg); border-radius: 8px;">
                                    <div style="flex: 1; text-align: left; font-weight: 600;">${dayName}</div>
                                    <div style="flex: 1; text-align: center; font-size: 24px;">${dayIcon}</div>
                                    <div style="flex: 2; text-align: center; font-size: 13px; color: var(--text-secondary);">${day.day.condition.text}</div>
                                    <div style="flex: 1; text-align: right;">
                                        <span style="font-weight: 700;">${Math.round(day.day.maxtemp_c)}°</span>
                                        <span style="color: var(--text-secondary); margin-left: 4px;">${Math.round(day.day.mintemp_c)}°</span>
                                    </div>
                                    <div style="flex: 1; text-align: right; font-size: 12px; color: #3b82f6;">
                                        <i class="fas fa-tint"></i> ${day.day.daily_chance_of_rain}%
                                    </div>
                                </div>
                            `;
        }).join('')}
                    </div>
                </div>
            </div>
        `;
    }
}

window.searchWeatherByCity = function() {
    const cityInput = document.getElementById('citySearchInput');
    const city = cityInput.value.trim();
    if (!city) {
        alert('Please enter a city name');
        return;
    }

    const content = document.getElementById('weatherModalContent');
    if (content) {
        content.innerHTML = `
            <div style="text-align: center; padding: 30px;">
                <div class="loading-spinner"></div>
                <p style="margin-top: 16px; color: var(--text-secondary);">Searching for ${city}...</p>
            </div>
        `;
    }

    // Use weatherapi.com (same API as backend)
    const apiKey = 'f4f904e64c374434a87104606252811';
    fetch(`https://api.weatherapi.com/v1/forecast.json?key=${apiKey}&q=${encodeURIComponent(city)}&days=7&aqi=no`)
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                if (content) {
                    content.innerHTML = `
                        <div style="text-align: center; padding: 30px; color: #dc2626;">
                            <i class="fas fa-exclamation-circle" style="font-size: 48px; margin-bottom: 16px;"></i>
                            <p>${data.error.message || 'City not found. Please try another city name.'}</p>
                        </div>
                    `;
                }
                return;
            }
            displayWeather(data);
        })
        .catch(err => {
            if (content) content.innerHTML = `<div style="text-align: center; padding: 30px; color: #dc2626;"><p>Error searching for city.</p></div>`;
        });
}

window.fetchWeatherByLocation = function() {
    const content = document.getElementById('weatherModalContent');
    if (content) {
        content.innerHTML = `
            <div style="text-align: center; padding: 30px;">
                <div class="loading-spinner"></div>
                <p style="margin-top: 16px; color: var(--text-secondary);">Getting your location...</p>
            </div>
        `;
    }

    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            position => {
                const lat = position.coords.latitude;
                const lon = position.coords.longitude;
                // Use weatherapi.com with lat,lon
                const apiKey = 'f4f904e64c374434a87104606252811';
                fetch(`https://api.weatherapi.com/v1/forecast.json?key=${apiKey}&q=${lat},${lon}&days=7&aqi=no`)
                    .then(res => res.json())
                    .then(data => {
                        if (data.error) {
                            if (content) content.innerHTML = `<div style="text-align: center; padding: 30px; color: #dc2626;"><p>Error: ${data.error.message}</p></div>`;
                        } else {
                            displayWeather(data);
                        }
                    })
                    .catch(() => { if (content) content.innerHTML = '<p>Error fetching weather.</p>'; });
            },
            () => {
                if (content) {
                    content.innerHTML = `
                        <div style="text-align: center; padding: 30px; color: #dc2626;">
                            <i class="fas fa-location-arrow" style="font-size: 48px; margin-bottom: 16px;"></i>
                            <p>Please enable location access. Or search above.</p>
                        </div>
                    `;
                }
            }
        );
    }
}
window.openCalculatorModal = function() {
    const modal = document.getElementById('calculatorModal');
    if (modal) modal.style.display = 'flex';
    const input = document.getElementById('entryDate');
    if (input && !input.value) {
        input.value = new Date().toISOString().split('T')[0];
    }
    // Calculate total on modal open to initialize chart
    calculateTotal();
}

window.closeCalculatorModal = function() {
    const modal = document.getElementById('calculatorModal');
    if (modal) modal.style.display = 'none';
}

window.openGovtSchemesModal = function() {
    const modal = document.getElementById('govtSchemesModal');
    if (modal) modal.style.display = 'flex';
}

window.closeGovtSchemesModal = function() {
    const modal = document.getElementById('govtSchemesModal');
    if (modal) modal.style.display = 'none';
}

window.openEquipmentModal = function() {
    const modal = document.getElementById('equipmentModal');
    if (modal) modal.style.display = 'flex';
    fetchEquipmentings();
}

window.closeEquipmentModal = function() {
    const modal = document.getElementById('equipmentModal');
    if (modal) modal.style.display = 'none';

    // Reset to view mode
    const form = document.getElementById('equipmentListingForm');
    const list = document.getElementById('equipmentListContainer');
    const btn = document.getElementById('toggleEquipFormBtn');
    if (form) form.style.display = 'none';
    if (list) list.style.display = 'grid';
    if (btn) btn.innerHTML = '<i class="fas fa-plus"></i> List Your Equipment';
}

window.openFarmersManualModal = function() {
    const modal = document.getElementById('farmersManualModal');
    if (modal) modal.style.display = 'flex';
    showManualSection('soil');
}

window.closeFarmersManualModal = function() {
    const modal = document.getElementById('farmersManualModal');
    if (modal) modal.style.display = 'none';
}

window.showManualSection = function(sectionName) {
    document.querySelectorAll('.manual-section').forEach(s => s.style.display = 'none');
    document.querySelectorAll('.manual-tab').forEach(t => {
        t.style.background = '#f1f5f9';
        t.style.color = '#64748b';
        t.classList.remove('active');
    });

    const sec = document.getElementById('section-' + sectionName);
    if (sec) sec.style.display = 'block';

    const tab = document.getElementById('tab-' + sectionName);
    if (tab) {
        tab.style.background = '#10b981';
        tab.style.color = 'white';
        tab.classList.add('active');
    }
}
const cropBenchmarks = {
    rice: { seed: 2000, fertilizer: 6000, pesticide: 2500, total: 35000 },
    wheat: { seed: 1500, fertilizer: 5000, pesticide: 2000, total: 28000 },
    maize: { seed: 1500, fertilizer: 5000, pesticide: 2000, total: 30000 },
    cotton: { seed: 3000, fertilizer: 7000, pesticide: 4000, total: 42000 },
    sugarcane: { seed: 8000, fertilizer: 10000, pesticide: 3000, total: 60000 },
    tomato: { seed: 5000, fertilizer: 10000, pesticide: 5000, total: 60000 },
    potato: { seed: 15000, fertilizer: 8000, pesticide: 4000, total: 55000 },
    onion: { seed: 4000, fertilizer: 8000, pesticide: 3500, total: 50000 }
    // More benchmarks can be added here
};

window.loadBenchmarkData = function() {
    const cropType = document.getElementById('cropType').value;
    const seedB = document.getElementById('seedBenchmark');
    const fertB = document.getElementById('fertilizerBenchmark');
    const pestB = document.getElementById('pesticideBenchmark');

    if (!cropType || !cropBenchmarks[cropType]) {
        if (seedB) seedB.textContent = '';
        if (fertB) fertB.textContent = '';
        if (pestB) pestB.textContent = '';
        return;
    }

    const b = cropBenchmarks[cropType];
    if (seedB) seedB.textContent = `Average: ₹${b.seed.toLocaleString('en-IN')}/acre`;
    if (fertB) fertB.textContent = `Average: ₹${b.fertilizer.toLocaleString('en-IN')}/acre`;
    if (pestB) pestB.textContent = `Average: ₹${b.pesticide.toLocaleString('en-IN')}/acre`;
}

window.calculateTotal = function() {
    const getVal = id => {
        const val = parseFloat(document.getElementById(id)?.value);
        return isNaN(val) ? 0 : val;
    };
    const expenses = {
        seed: getVal('seedCost'),
        fertilizer: getVal('fertilizerCost'),
        pesticide: getVal('pesticideCost'),
        irrigation: getVal('irrigationCost'),
        labor: getVal('laborCost'),
        machinery: getVal('machineryCost'),
        other: getVal('otherCost')
    };

    const total = Object.values(expenses).reduce((a, b) => a + b, 0);

    const setTxt = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.textContent = val;
    };

    setTxt('totalExpense', '₹' + total.toLocaleString('en-IN'));
    setTxt('seedDisplay', '₹' + expenses.seed.toLocaleString('en-IN'));
    setTxt('fertilizerDisplay', '₹' + expenses.fertilizer.toLocaleString('en-IN'));
    setTxt('pesticideDisplay', '₹' + expenses.pesticide.toLocaleString('en-IN'));
    setTxt('irrigationDisplay', '₹' + expenses.irrigation.toLocaleString('en-IN'));
    setTxt('laborDisplay', '₹' + expenses.labor.toLocaleString('en-IN'));
    setTxt('machineryDisplay', '₹' + expenses.machinery.toLocaleString('en-IN'));
    setTxt('otherDisplay', '₹' + expenses.other.toLocaleString('en-IN'));

    updateExpenseChart(Object.values(expenses));

    const area = getVal('landArea');
    if (area > 0) {
        const perAcre = total / area;
        setTxt('costPerAcre', '₹' + perAcre.toLocaleString('en-IN', { maximumFractionDigits: 0 }) + ' / acre');
    } else {
        setTxt('costPerAcre', '₹0 / acre');
    }

    const qty = getVal('expectedYield');
    const price = getVal('marketPrice');
    const revenue = qty * price;
    const profit = revenue - total;

    setTxt('totalRevenue', '₹' + revenue.toLocaleString('en-IN'));
    const profitEl = document.getElementById('netProfit');
    if (profitEl) {
        profitEl.textContent = '₹' + profit.toLocaleString('en-IN');
        profitEl.style.color = profit >= 0 ? '#16a34a' : '#dc2626';
    }
}

window.updateExpenseChart = function(data) {
    const ctx = document.getElementById('expenseChart');
    if (!ctx) return;

    if (typeof Chart === 'undefined') {
        ctx.parentElement.innerHTML = '<div style="display:flex; align-items:center; justify-content:center; height:100%; color:#94a3b8; font-size:13px; text-align:center;">' +
            '<div><i class="fas fa-chart-pie" style="font-size:24px; margin-bottom:8px; opacity:0.5;"></i><br>Charts library is loading...</div></div>';
        return;
    }

    // Check if data is all zeros
    const allZeros = data.every(v => v === 0);
    if (allZeros) {
        // Clear existing chart if any
        if (expenseChart) {
            expenseChart.destroy();
            expenseChart = null;
        }
        // Could show a placeholder but doughnut looks better with data
        return;
    }

    if (expenseChart) expenseChart.destroy();

    expenseChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Seeds', 'Fertilizers', 'Pesticides', 'Irrigation', 'Labor', 'Machinery', 'Other'],
            datasets: [{
                data: data,
                backgroundColor: [
                    '#4caf50', // Seeds - Green
                    '#2196f3', // Fertilizers - Blue
                    '#ff9800', // Pesticides - Orange
                    '#00bcd4', // Irrigation - Cyan
                    '#9c27b0', // Labor - Purple
                    '#f44336', // Machinery - Red
                    '#607d8b'  // Other - Blue Grey
                ],
                hoverOffset: 15,
                borderWidth: 2,
                borderColor: '#ffffff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '70%',
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            let label = context.label || '';
                            if (label) label += ': ';
                            if (context.parsed !== null) label += '₹' + context.parsed.toLocaleString('en-IN');
                            return label;
                        }
                    }
                }
            },
            animation: {
                duration: 1000,
                easing: 'easeOutQuart'
            }
        }
    });
}

window.calculateLoan = function() {
    const p = parseFloat(document.getElementById('loanAmount')?.value) || 0;
    const r = parseFloat(document.getElementById('interestRate')?.value) || 0;
    const m = parseFloat(document.getElementById('loanPeriod')?.value) || 0;

    if (p > 0 && r > 0 && m > 0) {
        const mr = (r / 12) / 100;
        const emi = (p * mr * Math.pow(1 + mr, m)) / (Math.pow(1 + mr, m) - 1);
        const total = emi * m;
        document.getElementById('monthlyEMI').textContent = '₹' + Math.round(emi).toLocaleString('en-IN');
        document.getElementById('totalAmount').textContent = '₹' + Math.round(total).toLocaleString('en-IN');
    }
}

window.saveExpenseEntry = async function() {
    const getVal = id => {
        const val = parseFloat(document.getElementById(id)?.value);
        return isNaN(val) ? 0 : val;
    };
    
    const entryDate = document.getElementById('entryDate')?.value;
    const cropType = document.getElementById('cropType')?.value;
    
    if (!entryDate) {
        showToast('Please select a date', 'warning');
        return;
    }

    const saveBtn = document.querySelector('button[onclick="saveExpenseEntry()"]');
    const originalText = saveBtn ? saveBtn.innerHTML : '';
    if (saveBtn) {
        saveBtn.disabled = true;
        saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
    }

    const entry = {
        date: entryDate,
        cropType: cropType,
        expenses: {
            seed: getVal('seedCost'),
            fertilizer: getVal('fertilizerCost'),
            pesticide: getVal('pesticideCost'),
            irrigation: getVal('irrigationCost'),
            labor: getVal('laborCost'),
            machinery: getVal('machineryCost'),
            other: getVal('otherCost')
        },
        landArea: getVal('landArea'),
        expectedYield: getVal('expectedYield'),
        marketPrice: getVal('marketPrice'),
        total_expense: Object.values({
            seed: getVal('seedCost'),
            fertilizer: getVal('fertilizerCost'),
            pesticide: getVal('pesticideCost'),
            irrigation: getVal('irrigationCost'),
            labor: getVal('laborCost'),
            machinery: getVal('machineryCost'),
            other: getVal('otherCost')
        }).reduce((a, b) => a + b, 0)
    };

    try {
        const res = await fetch('/api/expenses', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(entry)
        });
        const result = await res.json();
        
        if (result.success) {
            showToast('Expense entry saved successfully!', 'success');
        } else {
            showToast('Failed to save: ' + (result.message || 'Unknown error'), 'error');
        }
    } catch (e) {
        console.error('Error saving expense:', e);
        showToast('Network error while saving.', 'error');
    } finally {
        if (saveBtn) {
            saveBtn.disabled = false;
            saveBtn.innerHTML = originalText;
        }
    }
}
