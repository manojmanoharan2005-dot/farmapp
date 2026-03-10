const statesDistricts = JSON.parse(document.getElementById('states-data').textContent);

// All 50 commodities for autocomplete
const allCommodities = [
    // Vegetables (30)
    "Tomato", "Onion", "Potato", "Brinjal", "Cabbage", "Cauliflower",
    "Carrot", "Beetroot", "Green Chilli", "Capsicum (Green)", "Capsicum (Red)",
    "Capsicum (Yellow)", "Beans", "Cluster Beans", "Lady Finger", "Drumstick",
    "Bottle Gourd", "Ridge Gourd", "Snake Gourd", "Bitter Gourd", "Pumpkin",
    "Ash Gourd", "Radish", "Turnip", "Sweet Corn", "Peas", "Garlic",
    "Ginger", "Coriander Leaves", "Spinach",
    // Fruits (20)
    "Apple", "Banana", "Orange", "Mosambi", "Grapes", "Pomegranate",
    "Papaya", "Pineapple", "Watermelon", "Muskmelon", "Mango", "Guava",
    "Lemon", "Custard Apple", "Sapota", "Strawberry", "Kiwi", "Pear",
    "Plum", "Peach"
];

function updateDistricts() {
    const stateSelect = document.getElementById('stateSelect');
    const districtSelect = document.getElementById('districtSelect');
    const selectedState = stateSelect.value;

    districtSelect.innerHTML = '<option value="All Districts">All Districts</option>';

    if (selectedState && selectedState !== 'All States' && statesDistricts[selectedState]) {
        statesDistricts[selectedState].forEach(district => {
            const option = document.createElement('option');
            option.value = district;
            option.textContent = district;
            districtSelect.appendChild(option);
        });
    }
}

// Mobile Sidebar Toggle
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.querySelector('.sidebar-overlay');
    if (sidebar && overlay) {
        sidebar.classList.toggle('active');
        overlay.classList.toggle('active');
    }
}

// Initialize components
document.addEventListener('DOMContentLoaded', function () {
    const commoditySearch = document.getElementById('commoditySearch');
    const commoditySuggestions = document.getElementById('commoditySuggestions');
    const commoditySelect = document.getElementById('commoditySelect');
    const stateSelect = document.getElementById('stateSelect');

    if (stateSelect) {
        stateSelect.addEventListener('change', updateDistricts);
    }

    if (commoditySearch) {
        commoditySearch.addEventListener('input', function () {
            const query = this.value.toLowerCase().trim();
            commoditySuggestions.innerHTML = '';

            if (query.length < 1) {
                commoditySuggestions.style.display = 'none';
                return;
            }

            const matches = allCommodities.filter(c => c.toLowerCase().includes(query));

            if (matches.length > 0) {
                commoditySuggestions.style.display = 'block';
                matches.forEach(commodity => {
                    const div = document.createElement('div');
                    div.textContent = commodity;
                    div.style.padding = '10px 16px';
                    div.style.cursor = 'pointer';
                    div.style.borderBottom = '1px solid #e2e8f0';
                    div.addEventListener('mouseenter', function () {
                        this.style.background = '#f1f5f9';
                    });
                    div.addEventListener('mouseleave', function () {
                        this.style.background = 'white';
                    });
                    div.addEventListener('click', function () {
                        commoditySearch.value = commodity;
                        if (commoditySelect) commoditySelect.value = commodity;
                        commoditySuggestions.style.display = 'none';
                    });
                    commoditySuggestions.appendChild(div);
                });
            } else {
                commoditySuggestions.style.display = 'none';
            }
        });

        // Hide suggestions when clicking outside
        document.addEventListener('click', function (e) {
            if (!commoditySearch.contains(e.target) && !commoditySuggestions.contains(e.target)) {
                commoditySuggestions.style.display = 'none';
            }
        });

        // Clear dropdown when using search
        commoditySearch.addEventListener('focus', function () {
            if (this.value && commoditySelect) {
                commoditySelect.value = 'All';
            }
        });
    }

    // Clear search when using dropdown
    if (commoditySelect) {
        commoditySelect.addEventListener('change', function () {
            if (this.value !== 'All' && commoditySearch) {
                commoditySearch.value = '';
            }
        });
    }

    // Globalize toggleSidebar so it works with inline onclick
    window.toggleSidebar = toggleSidebar;
    window.updateDistricts = updateDistricts;
});

// ============================================
// Extracted from inline <script> in market_watch.html
// ============================================

// Horizontal scroll functionality for category sections
function scrollCategory(category, direction) {
    const container = document.getElementById(category + '-grid');
    if (!container) return;

    const scrollAmount = 300;
    const currentScroll = container.parentElement.scrollLeft;

    if (direction === 'left') {
        container.parentElement.scrollLeft = currentScroll - scrollAmount;
    } else {
        container.parentElement.scrollLeft = currentScroll + scrollAmount;
    }

    setTimeout(() => updateScrollButtons(category), 100);
}

// Update scroll button states based on scroll position
function updateScrollButtons(category) {
    const container = document.getElementById(category + '-grid');
    if (!container) return;

    const scrollContainer = container.parentElement;
    const leftBtn = document.querySelector(`button[onclick="scrollCategory('${category}', 'left')"]`);
    const rightBtn = document.querySelector(`button[onclick="scrollCategory('${category}', 'right')"]`);

    if (leftBtn && rightBtn) {
        leftBtn.disabled = scrollContainer.scrollLeft <= 0;

        const maxScroll = scrollContainer.scrollWidth - scrollContainer.clientWidth;
        rightBtn.disabled = scrollContainer.scrollLeft >= maxScroll - 1;
    }
}

// Initialize scroll button states on page load
document.addEventListener('DOMContentLoaded', function() {
    const categories = ['vegetables', 'fruits', 'cereals', 'pulses', 'oilseeds', 'spices', 'commercial', 'dry_fruits', 'animal'];

    categories.forEach(category => {
        updateScrollButtons(category);

        const container = document.getElementById(category + '-grid');
        if (container && container.parentElement) {
            container.parentElement.addEventListener('scroll', () => updateScrollButtons(category));
        }
    });
});
