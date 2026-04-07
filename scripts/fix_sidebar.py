import glob
import re

MISSING_SECTIONS = """
            <div class="nav-section">
                <div class="nav-section-title">Buyer Connect</div>
                <a href="{{ url_for('buyer_connect.create_listing') }}" class="nav-link">
                    <i class="fas fa-plus-circle"></i>
                    <span>Sell My Crop</span>
                </a>
                <a href="{{ url_for('buyer_connect.my_listings') }}" class="nav-link">
                    <i class="fas fa-list-alt"></i>
                    <span>My Listings</span>
                </a>
                <a href="{{ url_for('buyer_connect.marketplace') }}" class="nav-link">
                    <i class="fas fa-store"></i>
                    <span>Buy from Farmers</span>
                    <span class="badge badge-blue">New</span>
                </a>
                <a href="{{ url_for('buyer_connect.purchase_history') }}" class="nav-link">
                    <i class="fas fa-history"></i>
                    <span>Purchase History</span>
                </a>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Tools</div>
                <a href="#" class="nav-link" onclick="openCalculatorModal(); return false;">
                    <i class="fas fa-calculator"></i>
                    <span>Expense Calculator</span>
                </a>
                <a href="#" class="nav-link" onclick="openWeatherModal(); return false;">
                    <i class="fas fa-cloud-sun"></i>
                    <span>Weather Forecast</span>
                </a>
                <a href="#" class="nav-link" onclick="openGovtSchemesModal(); return false;">
                    <i class="fas fa-landmark"></i>
                    <span>Govt. Schemes</span>
                </a>
                <a href="#" class="nav-link" onclick="openFarmersManualModal(); return false;">
                    <i class="fas fa-book"></i>
                    <span>Farmer's Manual</span>
                </a>
            </div>

            <div class="nav-section">
                <div class="nav-section-title">Equipment Sharing</div>
                <a href="{{ url_for('equipment_sharing.create_listing') }}" class="nav-link">
                    <i class="fas fa-plus-circle"></i>
                    <span>List My Equipment</span>
                </a>
                <a href="{{ url_for('equipment_sharing.my_listings') }}" class="nav-link">
                    <i class="fas fa-list-alt"></i>
                    <span>My Equipment</span>
                </a>
                <a href="{{ url_for('equipment_sharing.marketplace') }}" class="nav-link">
                    <i class="fas fa-store"></i>
                    <span>Rent Equipment</span>
                    <span class="badge badge-green">Live</span>
                </a>
                <a href="{{ url_for('equipment_sharing.rental_history') }}" class="nav-link">
                    <i class="fas fa-history"></i>
                    <span>Rental History</span>
                </a>
            </div>
"""

paths = glob.glob('templates/**/*.html', recursive=True)

count = 0
for path in paths:
    try:
        content = open(path, encoding='utf-8').read()
        if 'nav-section-title">Main Menu' in content and 'nav-section-title">Tools' not in content:
            # It has a sidebar but is missing the Tools section
            # We insert before </nav>
            new_content = re.sub(
                r'(</nav>)',
                MISSING_SECTIONS + r'\n        \1',
                content,
                count=1
            )
            if new_content != content:
                open(path, 'w', encoding='utf-8').write(new_content)
                print(f'Updated {path}')
                count += 1
    except Exception as e:
        print(f'Error reading {path}: {e}')

print(f'\nTotal files updated: {count}')
