/* ============================================
   Equipment List Form JS
   Used by: equipment_list_form.html
   ============================================ */

document.addEventListener('DOMContentLoaded', function () {
    const statesDistricts = JSON.parse(
        document.getElementById('states-districts-data').textContent
    );
    let currentMinRent = 0;
    let currentMaxRent = 0;

    const stateSelect = document.getElementById('stateSelect');
    const districtSelect = document.getElementById('districtSelect');
    const equipmentSelect = document.getElementById('equipmentSelect');
    const ownerRent = document.getElementById('ownerRent');
    const rentInfoBox = document.getElementById('rentInfoBox');
    const equipmentForm = document.getElementById('equipmentForm');

    // State/District selection
    stateSelect.addEventListener('change', function () {
        const state = this.value;
        districtSelect.innerHTML = '<option value="">-- Select District --</option>';

        if (state && statesDistricts[state]) {
            statesDistricts[state].forEach(function (district) {
                const option = document.createElement('option');
                option.value = district;
                option.textContent = district;
                districtSelect.appendChild(option);
            });
        }

        fetchLiveRent();
    });

    districtSelect.addEventListener('change', fetchLiveRent);
    equipmentSelect.addEventListener('change', fetchLiveRent);

    // Fetch live rent
    async function fetchLiveRent() {
        const equipment = equipmentSelect.value;
        const district = districtSelect.value;

        if (!equipment || !district) {
            rentInfoBox.style.display = 'none';
            return;
        }

        try {
            const response = await fetch('/equipment-sharing/api/get-live-rent', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ equipment: equipment, location: district })
            });

            const data = await response.json();

            if (data.success) {
                document.getElementById('recommendedRent').textContent = data.recommended_rent.toFixed(2);
                document.getElementById('minRent').textContent = data.min_rent.toFixed(2);
                document.getElementById('maxRent').textContent = data.max_rent.toFixed(2);
                ownerRent.value = data.recommended_rent.toFixed(2);
                rentInfoBox.style.display = 'block';

                currentMinRent = data.min_rent;
                currentMaxRent = data.max_rent;
            }
        } catch (error) {
            console.error('Error fetching live rent:', error);
        }
    }

    // Validate rent
    ownerRent.addEventListener('input', function () {
        const rent = parseFloat(this.value);
        if (rent && (rent < currentMinRent || rent > currentMaxRent)) {
            this.style.borderColor = '#ef4444';
        } else {
            this.style.borderColor = '#10b981';
        }
    });

    // Form validation
    equipmentForm.addEventListener('submit', function (e) {
        const rent = parseFloat(ownerRent.value);
        if (rent < currentMinRent || rent > currentMaxRent) {
            e.preventDefault();
            alert('\u26a0\ufe0f Rent must be between \u20b9' + currentMinRent.toFixed(2) + ' and \u20b9' + currentMaxRent.toFixed(2));
            return false;
        }
    });
});
