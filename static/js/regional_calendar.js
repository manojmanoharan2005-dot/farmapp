/* ============================================
   Regional Calendar JS
   Used by: regional_calendar.html
   ============================================ */

// Indian States and Districts Data
const indianStatesData = {
    "Andhra Pradesh": ["Anantapur", "Chittoor", "East Godavari", "Guntur", "Krishna", "Kurnool", "Prakasam", "Srikakulam", "Sri Potti Sriramulu Nellore", "Visakhapatnam", "Vizianagaram", "West Godavari", "YSR District, Kadapa (Cuddapah)"],
    "Arunachal Pradesh": ["Anjaw", "Changlang", "Dibang Valley", "East Kameng", "East Siang", "Kamle", "Kra Daadi", "Kurung Kumey", "Lepa Rada", "Lohit", "Longding", "Lower Dibang Valley", "Lower Siang", "Lower Subansiri", "Namsai", "Pakke Kessang", "Papum Pare", "Shi Yomi", "Siang", "Tawang", "Tirap", "Upper Siang", "Upper Subansiri", "West Kameng", "West Siang"],
    "Assam": ["Baksa", "Barpeta", "Biswanath", "Bongaigaon", "Cachar", "Charaideo", "Chirang", "Darrang", "Dhemaji", "Dhubri", "Dibrugarh", "Dima Hasao (North Cachar Hills)", "Goalpara", "Golaghat", "Hailakandi", "Hojai", "Jorhat", "Kamrup", "Kamrup Metropolitan", "Karbi Anglong", "Karimganz", "Kokrajhar", "Lakhimpur", "Majuli", "Morigaon", "Nagaon", "Nalbari", "Sivasagar", "Sonitpur", "South Salmara-Mankachar", "Tinsukia", "Udalguri", "West Karbi Anglong"],
    "Bihar": ["Araria", "Arwal", "Aurangabad", "Banka", "Begusarai", "Bhagalpur", "Bhojpur", "Buxar", "Darbhanga", "East Champaran (Motihari)", "Gaya", "Gopalganj", "Jamui", "Jehanabad", "Kaimur (Bhabua)", "Katihar", "Khagaria", "Kishanganj", "Lakhisarai", "Madhepura", "Madhubani", "Munger (Monghyr)", "Muzaffarpur", "Nalanda", "Nawada", "Patna", "Purnia (Purnea)", "Rohtas", "Saharsa", "Samastipur", "Saran", "Sheikhpura", "Sheohar", "Sitamarhi", "Siwan", "Supaul", "Vaishali", "West Champaran"],
    "Chhattisgarh": ["Balod", "Baloda Bazar", "Balrampur", "Bastar", "Bemetara", "Bijapur", "Bilaspur", "Dantewada (South Bastar)", "Dhamtari", "Durg", "Gariyaband", "Janjgir-Champa", "Jashpur", "Kabirdham (Kawardha)", "Kanker (North Bastar)", "Kondagaon", "Korba", "Koriya", "Mahasamund", "Mungeli", "Narayanpur", "Raigarh", "Raipur", "Rajnandgaon", "Sukma", "Surajpur", "Surguja"],
    "Goa": ["North Goa", "South Goa"],
    "Gujarat": ["Ahmedabad", "Amreli", "Anand", "Aravalli", "Banaskantha (Palanpur)", "Bharuch", "Bhavnagar", "Botad", "Chhota Udepur", "Dahod", "Dangs (Ahwa)", "Devbhoomi Dwarka", "Gandhinagar", "Gir Somnath", "Jamnagar", "Junagadh", "Kachchh", "Kheda (Nadiad)", "Mahisagar", "Mehsana", "Morbi", "Narmada (Rajpipla)", "Navsari", "Panchmahal (Godhra)", "Patan", "Porbandar", "Rajkot", "Sabarkantha (Himmatnagar)", "Surat", "Surendranagar", "Tapi (Vyara)", "Vadodara", "Valsad"],
    "Haryana": ["Ambala", "Bhiwani", "Charkhi Dadri", "Faridabad", "Fatehabad", "Gurugram (Gurgaon)", "Hisar", "Jhajjar", "Jind", "Kaithal", "Karnal", "Kurukshetra", "Mahendragarh", "Nuh", "Palwal", "Panchkula", "Panipat", "Rewari", "Rohtak", "Sirsa", "Sonipat", "Yamunanagar"],
    "Himachal Pradesh": ["Bilaspur", "Chamba", "Hamirpur", "Kangra", "Kinnaur", "Kullu", "Lahaul & Spiti", "Mandi", "Shimla", "Sirmaur (Sirmour)", "Solan", "Una"],
    "Jharkhand": ["Bokaro", "Chatra", "Deoghar", "Dhanbad", "Dumka", "East Singhbhum (Jamshedpur)", "Garhwa", "Giridih", "Godda", "Gumla", "Hazaribag", "Jamtara", "Khunti", "Koderma", "Latehar", "Lohardaga", "Pakur", "Palamu", "Ramgarh", "Ranchi", "Sahibganj", "Seraikela-Kharsawan", "Simdega", "West Singhbhum (Chaibasa)"],
    "Karnataka": ["Bagalkot", "Ballari (Bellary)", "Belagavi (Belgaum)", "Bengaluru (Bangalore) Rural", "Bengaluru (Bangalore) Urban", "Bidar", "Chamarajanagar", "Chikballapur", "Chikkamagaluru (Chikmagalur)", "Chitradurga", "Dakshina Kannada", "Davangere", "Dharwad", "Gadag", "Hassan", "Haveri", "Kalaburagi (Gulbarga)", "Kodagu", "Kolar", "Koppal", "Mandya", "Mysuru (Mysore)", "Raichur", "Ramanagara", "Shivamogga (Shimoga)", "Tumakuru (Tumkur)", "Udupi", "Uttara Kannada (Karwar)", "Vijayapura (Bijapur)", "Yadgir"],
    "Kerala": ["Alappuzha", "Ernakulam", "Idukki", "Kannur", "Kasaragod", "Kollam", "Kottayam", "Kozhikode", "Malappuram", "Palakkad", "Pathanamthitta", "Thiruvananthapuram", "Thrissur", "Wayanad"],
    "Madhya Pradesh": ["Agar Malwa", "Alirajpur", "Anuppur", "Ashoknagar", "Balaghat", "Barwani", "Betul", "Bhind", "Bhopal", "Burhanpur", "Chhatarpur", "Chhindwara", "Damoh", "Datia", "Dewas", "Dhar", "Dindori", "Guna", "Gwalior", "Harda", "Hoshangabad", "Indore", "Jabalpur", "Jhabua", "Katni", "Khandwa", "Khargone", "Mandla", "Mandsaur", "Morena", "Narsinghpur", "Neemuch", "Panna", "Raisen", "Rajgarh", "Ratlam", "Rewa", "Sagar", "Satna", "Sehore", "Seoni", "Shahdol", "Shajapur", "Sheopur", "Shivpuri", "Sidhi", "Singrauli", "Tikamgarh", "Ujjain", "Umaria", "Vidisha"],
    "Maharashtra": ["Ahmednagar", "Akola", "Amravati", "Aurangabad", "Beed", "Bhandara", "Buldhana", "Chandrapur", "Dhule", "Gadchiroli", "Gondia", "Hingoli", "Jalgaon", "Jalna", "Kolhapur", "Latur", "Mumbai City", "Mumbai Suburban", "Nagpur", "Nanded", "Nandurbar", "Nashik", "Osmanabad", "Palghar", "Parbhani", "Pune", "Raigad", "Ratnagiri", "Sangli", "Satara", "Sindhudurg", "Solapur", "Thane", "Wardha", "Washim", "Yavatmal"],
    "Manipur": ["Bishnupur", "Chandel", "Churachandpur", "Imphal East", "Imphal West", "Jiribam", "Kakching", "Kamjong", "Kangpokpi", "Noney", "Pherzawl", "Senapati", "Tamenglong", "Tengnoupal", "Thoubal", "Ukhrul"],
    "Meghalaya": ["East Garo Hills", "East Jaintia Hills", "East Khasi Hills", "North Garo Hills", "Ri Bhoi", "South Garo Hills", "South West Garo Hills", "South West Khasi Hills", "West Garo Hills", "West Jaintia Hills", "West Khasi Hills"],
    "Mizoram": ["Aizawl", "Champhai", "Kolasib", "Lawngtlai", "Lunglei", "Mamit", "Saiha", "Serchhip"],
    "Nagaland": ["Dimapur", "Kiphire", "Kohima", "Longleng", "Mokokchung", "Mon", "Peren", "Phek", "Tuensang", "Wokha", "Zunheboto"],
    "Odisha": ["Angul", "Balangir", "Balasore", "Bargarh", "Bhadrak", "Boudh", "Cuttack", "Deogarh", "Dhenkanal", "Gajapati", "Ganjam", "Jagatsinghapur", "Jajpur", "Jharsuguda", "Kalahandi", "Kandhamal", "Kendrapara", "Kendujhar (Keonjhar)", "Khordha", "Koraput", "Malkangiri", "Mayurbhanj", "Nabarangpur", "Nayagarh", "Nuapada", "Puri", "Rayagada", "Sambalpur", "Subarnapur", "Sundargarh"],
    "Punjab": ["Amritsar", "Barnala", "Bathinda", "Faridkot", "Fatehgarh Sahib", "Fazilka", "Ferozepur", "Gurdaspur", "Hoshiarpur", "Jalandhar", "Kapurthala", "Ludhiana", "Mansa", "Moga", "Muktsar", "Nawanshahr (Shahid Bhagat Singh Nagar)", "Pathankot", "Patiala", "Rupnagar", "Sahibzada Ajit Singh Nagar (Mohali)", "Sangrur", "Tarn Taran"],
    "Rajasthan": ["Ajmer", "Alwar", "Banswara", "Baran", "Barmer", "Bharatpur", "Bhilwara", "Bikaner", "Bundi", "Chittorgarh", "Churu", "Dausa", "Dholpur", "Dungarpur", "Hanumangarh", "Jaipur", "Jaisalmer", "Jalore", "Jhalawar", "Jhunjhunu", "Jodhpur", "Karauli", "Kota", "Nagaur", "Pali", "Pratapgarh", "Rajsamand", "Sawai Madhopur", "Sikar", "Sirohi", "Sri Ganganagar", "Tonk", "Udaipur"],
    "Sikkim": ["East Sikkim", "North Sikkim", "South Sikkim", "West Sikkim"],
    "Tamil Nadu": ["Ariyalur", "Chennai", "Coimbatore", "Cuddalore", "Dharmapuri", "Dindigul", "Erode", "Kanchipuram", "Kanyakumari", "Karur", "Krishnagiri", "Madurai", "Nagapattinam", "Namakkal", "Nilgiris", "Perambalur", "Pudukkottai", "Ramanathapuram", "Salem", "Sivaganga", "Thanjavur", "Theni", "Thoothukudi (Tuticorin)", "Tiruchirappalli", "Tirunelveli", "Tiruppur", "Tiruvallur", "Tiruvannamalai", "Tiruvarur", "Vellore", "Viluppuram", "Virudhunagar"],
    "Telangana": ["Adilabad", "Bhadradri Kothagudem", "Hyderabad", "Jagtial", "Jangaon", "Jayashankar Bhoopalpally", "Jogulamba Gadwal", "Kamareddy", "Karimnagar", "Khammam", "Komaram Bheem Asifabad", "Mahabubabad", "Mahabubnagar", "Mancherial", "Medak", "Medchal", "Nagarkurnool", "Nalgonda", "Nirmal", "Nizamabad", "Peddapalli", "Rajanna Sircilla", "Rangareddy", "Sangareddy", "Siddipet", "Suryapet", "Vikarabad", "Wanaparthy", "Warangal (Rural)", "Warangal (Urban)", "Yadadri Bhuvanagiri"],
    "Tripura": ["Dhalai", "Gomati", "Khowai", "North Tripura", "Sepahijala", "South Tripura", "Unakoti", "West Tripura"],
    "Uttar Pradesh": ["Agra", "Aligarh", "Allahabad", "Ambedkar Nagar", "Amethi (Chatrapati Sahuji Mahraj Nagar)", "Amroha (J.P. Nagar)", "Auraiya", "Azamgarh", "Baghpat", "Bahraich", "Ballia", "Balrampur", "Banda", "Barabanki", "Bareilly", "Basti", "Bhadohi", "Bijnor", "Budaun", "Bulandshahr", "Chandauli", "Chitrakoot", "Deoria", "Etah", "Etawah", "Faizabad", "Farrukhabad", "Fatehpur", "Firozabad", "Gautam Buddha Nagar", "Ghaziabad", "Ghazipur", "Gonda", "Gorakhpur", "Hamirpur", "Hapur (Panchsheel Nagar)", "Hardoi", "Hathras", "Jalaun", "Jaunpur", "Jhansi", "Kannauj", "Kanpur Dehat", "Kanpur Nagar", "Kasganj (Kanshiram Nagar)", "Kaushambi", "Kheri", "Kushinagar", "Lalitpur", "Lucknow", "Maharajganj", "Mahoba", "Mainpuri", "Mathura", "Mau", "Meerut", "Mirzapur", "Moradabad", "Muzaffarnagar", "Pilibhit", "Pratapgarh", "Raebareli", "Rampur", "Saharanpur", "Sambhal (Bhim Nagar)", "Sant Kabir Nagar", "Shahjahanpur", "Shamli", "Shravasti", "Siddharthnagar", "Sitapur", "Sonbhadra", "Sultanpur", "Unnao", "Varanasi"],
    "Uttarakhand": ["Almora", "Bageshwar", "Chamoli", "Champawat", "Dehradun", "Haridwar", "Nainital", "Pauri Garhwal", "Pithoragarh", "Rudraprayag", "Tehri Garhwal", "Udham Singh Nagar", "Uttarkashi"],
    "West Bengal": ["Alipurduar", "Bankura", "Birbhum", "Cooch Behar", "Dakshin Dinajpur (South Dinajpur)", "Darjeeling", "Hooghly", "Howrah", "Jalpaiguri", "Jhargram", "Kalimpong", "Kolkata", "Malda", "Murshidabad", "Nadia", "North 24 Parganas", "Paschim Medinipur (West Medinipur)", "Purba Medinipur (East Medinipur)", "Purulia", "South 24 Parganas", "Uttar Dinajpur (North Dinajpur)"]
};

// Crop emoji map
const emojiMap = {
    'Tomato': '🍅', 'Onion': '🧅', 'Potato': '🥔', 'Brinjal': '🍆', 'Eggplant': '🍆',
    'Cabbage': '🥬', 'Cauliflower': '🥦', 'Carrot': '🥕', 'Beetroot': '🍠',
    'Green Chilli': '🌶️', 'Chilli': '🌶️', 'Capsicum': '🫑', 'Beans': '🫘', 'Lady Finger': '🖐️', 'Okra': '🖐️',
    'Drumstick': '🥢', 'Bottle Gourd': '🥒', 'Pumpkin': '🎃', 'Radish': '🥗',
    'Sweet Corn': '🌽', 'Maize': '🌽', 'Corn': '🌽', 'Peas': '🫛', 'Garlic': '🧄', 'Ginger': '🫚',
    'Spinach': '🥬', 'Mushroom': '🍄', 'Cucumber': '🥒', 'Lemon': '🍋',
    'Bitter Gourd': '🥒', 'Ridge Gourd': '🥒', 'Snake Gourd': '🐍', 'Ash Gourd': '⚪',
    'Turnip': '🥔', 'Colocasia': '🥔', 'Jack Fruit': '🍈', 'Pointed Gourd': '🥒',
    'Apple': '🍎', 'Banana': '🍌', 'Orange': '🍊', 'Mosambi': '🍋',
    'Grapes': '🍇', 'Pomegranate': '🪀', 'Papaya': '🍈', 'Pineapple': '🍍',
    'Watermelon': '🍉', 'Muskmelon': '🍈', 'Mango': '🥭', 'Guava': '🍐',
    'Custard Apple': '🍏', 'Sapota': '🥔', 'Strawberry': '🍓',
    'Kiwi': '🥝', 'Pear': '🍐', 'Plum': '🫐', 'Peach': '🍑',
    'Litchi': '🍒', 'Cherry': '🍒', 'Apricot': '🍑', 'Ber': '🍒', 'Amla': '🍏',
    'Paddy': '🍚', 'Rice': '🍚', 'Wheat': '🌾',
    'Barley': '🌾', 'Bajra': '🌾', 'Jowar': '🌾', 'Ragi': '🌾', 'Sorghum': '🌾', 'Millet': '🌾', 'Oats': '🥣',
    'Bengal Gram': '🟤', 'Gram': '🟤', 'Black Gram': '⚫', 'Urad': '⚫',
    'Green Gram': '🟢', 'Moong': '🟢', 'Red Gram': '🟡', 'Arhar': '🟡', 'Tur': '🟡',
    'Lentil': '🔴', 'Masur': '🔴', 'Horse Gram': '🟤',
    'Cowpea': '🫘', 'Lobia': '🫘', 'Chickpea': '🧆', 'Rajmah': '🫘', 'Kidney Beans': '🫘',
    'Groundnut': '🥜', 'Peanut': '🥜', 'Mustard': '🌼', 'Soyabean': '🫘', 'Soybean': '🫘', 'Sunflower': '🌻',
    'Sesamum': '🥯', 'Sesame': '🥯', 'Castor': '🌿', 'Linseed': '🌸',
    'Niger': '🌿', 'Safflower': '🌺', 'Coconut': '🥥', 'Copra': '🥥', 'Palm': '🌴',
    'Turmeric': '🟡', 'Coriander': '🌿', 'Cumin': '🧂', 'Jeera': '🧂',
    'Black Pepper': '⚫', 'Cardamom': '🌿', 'Tamarind': '🟤', 'Arecanut': '🌰', 'Betelnut': '🌰', 'Ajwan': '🌿',
    'Cotton': '☁️', 'Sugarcane': '🎋', 'Tea': '🍵', 'Coffee': '☕',
    'Jute': '🧶', 'Rubber': '🌳', 'Tobacco': '🍂', 'Mesta': '🧶',
    'Cashewnut': '🥜', 'Cashew': '🥜', 'Almond': '🌰', 'Raisin': '🍇', 'Walnut': '🌰',
    'Milk': '🥛', 'Egg': '🥚', 'Poultry': '🐔', 'Chicken': '🐔',
    'Fish': '🐟', 'Mutton': '🥩', 'Goat': '🐐', 'Sheep': '🐑'
};

// Initialize State Dropdown on Load
document.addEventListener('DOMContentLoaded', function () {
    var stateSelect = document.getElementById('state');
    var states = Object.keys(indianStatesData).sort();

    states.forEach(function (state) {
        var option = document.createElement('option');
        option.value = state;
        option.textContent = state;
        stateSelect.appendChild(option);
    });
});

function loadDistricts() {
    var stateSelect = document.getElementById('state');
    var districtSelect = document.getElementById('district');
    var selectedState = stateSelect.value;

    districtSelect.innerHTML = '<option value="">Select District</option>';

    if (selectedState && indianStatesData[selectedState]) {
        districtSelect.disabled = false;
        var districts = indianStatesData[selectedState].sort();

        districts.forEach(function (district) {
            var option = document.createElement('option');
            option.value = district;
            option.textContent = district;
            districtSelect.appendChild(option);
        });
    } else {
        districtSelect.disabled = true;
        districtSelect.innerHTML = '<option value="">Select State First</option>';
    }
}

async function generateCalendar(e) {
    e.preventDefault();

    var state = document.getElementById('state').value;
    var district = document.getElementById('district').value;
    var soilType = document.getElementById('soilTvpe').value;
    var prevCrop = document.getElementById('prevCrop').value;

    var loader = document.getElementById('loader');
    var results = document.getElementById('resultsContainer');

    loader.style.display = 'flex';
    results.classList.remove('active');

    try {
        var response = await fetch('/resources/calendar', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                state: state,
                district: district,
                soil_type: soilType,
                previous_crops: prevCrop
            })
        });

        var result = await response.json();

        if (result.success) {
            renderCalendar(result.data);
            results.classList.add('active');
            results.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else {
            alert('Error: ' + result.error);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('An unexpected error occurred. Please try again.');
    } finally {
        loader.style.display = 'none';
    }
}

function renderCalendar(data) {
    document.getElementById('regionTitle').textContent = 'Farming Calendar for ' + data.region;
    document.getElementById('adviceText').textContent = data.general_advice || "Optimized based on local soil and climate.";

    var container = document.getElementById('seasonTrack');
    container.innerHTML = '';

    data.calendar.forEach(function (season) {
        var seasonCard = document.createElement('div');
        seasonCard.className = 'season-card';

        var cropsHtml = season.recommended_crops.map(function (crop) {
            var emoji = emojiMap[crop.crop_name] || emojiMap[crop.crop_name.split(' ')[0]] || '🌱';

            return '<div class="crop-item">' +
                '<div class="crop-name">' +
                    '<span style="font-size: 1.25em; margin-right: 8px;">' + emoji + '</span> ' + crop.crop_name +
                '</div>' +
                '<div class="crop-meta-grid">' +
                    '<div><div class="meta-label">Sowing</div><div class="meta-value">' + crop.sowing_period + '</div></div>' +
                    '<div><div class="meta-label">Harvest</div><div class="meta-value">' + crop.harvesting_period + '</div></div>' +
                    '<div style="grid-column: span 2;"><div class="meta-label">Fertilizer</div><div class="meta-value">' + crop.fertilizer_advice + '</div></div>' +
                    '<div><div class="meta-label">Water</div><div class="meta-value">' + crop.water_requirement + ' <i class="fas fa-tint" style="color:#60a5fa"></i></div></div>' +
                '</div>' +
            '</div>';
        }).join('');

        seasonCard.innerHTML =
            '<div class="season-header">' +
                '<div class="season-title">' + season.season + '</div>' +
                '<div class="season-months"><i class="far fa-clock"></i> ' + season.months + '</div>' +
            '</div>' +
            '<div class="crops-list">' +
                cropsHtml +
                '<div style="margin-top: 1rem; font-size: 0.85rem; color: var(--text-secondary); font-style: italic;">' +
                    '<i class="fas fa-info-circle"></i> ' + season.notes +
                '</div>' +
            '</div>';

        container.appendChild(seasonCard);
    });
}

function toggleSidebar() {
    var sidebar = document.getElementById('sidebar');
    var overlay = document.querySelector('.sidebar-overlay');
    if (sidebar) {
        sidebar.classList.toggle('active');
    }
    if (overlay) {
        overlay.classList.toggle('active');
    }
}
