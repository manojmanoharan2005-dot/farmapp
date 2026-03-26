from flask import Blueprint
from pymongo import ReplaceOne
import google.generativeai as genai
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
import json
import os
import random
import hashlib

scheduler_bp = Blueprint('scheduler', __name__)

# Configure Gemini API
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', 'YOUR_GEMINI_API_KEY_HERE')
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemma-3-4b-it')

# Market price data file
MARKET_DATA_FILE = 'data/market_prices.json'

# All Indian states
INDIAN_STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
]

# Crops by region (including vegetables and fruits)
CROPS_BY_REGION = {
    "North": ["Wheat", "Rice", "Potato", "Onion", "Tomato", "Cauliflower", "Cabbage", "Carrot", "Apple", "Mango", "Banana", "Sugarcane", "Mustard", "Cotton"],
    "South": ["Rice", "Coconut", "Banana", "Mango", "Papaya", "Tomato", "Brinjal", "Okra", "Drumstick", "Curry Leaves", "Groundnut", "Turmeric", "Coffee"],
    "East": ["Rice", "Potato", "Tomato", "Cabbage", "Cauliflower", "Brinjal", "Pumpkin", "Banana", "Papaya", "Litchi", "Tea", "Jute", "Mustard"],
    "West": ["Cotton", "Groundnut", "Onion", "Tomato", "Grapes", "Banana", "Mango", "Pomegranate", "Potato", "Brinjal", "Okra", "Sugarcane", "Wheat"],
    "Central": ["Wheat", "Soybean", "Potato", "Onion", "Tomato", "Brinjal", "Okra", "Mango", "Banana", "Orange", "Cotton", "Pulses", "Rice"]
}

# Major markets by state (5 main cities per state)
MARKETS_BY_STATE = {
    "Andhra Pradesh": ["Visakhapatnam - Maddilapalem", "Vijayawada - Rytu Bazaar", "Guntur - Rythu Bazaar", "Tirupati - Market", "Nellore - Vegetable Market"],
    "Bihar": ["Patna - Sabji Bagh", "Gaya - Rythu Bazaar", "Bhagalpur - Mandi", "Muzaffarpur - Market", "Darbhanga - Vegetable Market"],
    "Chhattisgarh": ["Raipur - Mandi", "Bhilai - Market", "Bilaspur - APMC", "Korba - Vegetable Market", "Durg - Market Yard"],
    "Gujarat": ["Ahmedabad - Khodiyar Market", "Surat - Kamela Darwaja", "Vadodara - Market Yard", "Rajkot - APMC Market", "Bhavnagar - Vegetable Market"],
    "Haryana": ["Faridabad - Mandi", "Gurugram - Market", "Panipat - Grain Market", "Ambala - Vegetable Market", "Karnal - Market Yard"],
    "Himachal Pradesh": ["Shimla - Sabzi Mandi", "Mandi - Fruit Market", "Solan - Market", "Kullu - Valley Market", "Dharamshala - Bazaar"],
    "Karnataka": ["Bangalore - KR Market", "Mysore - Devaraja Market", "Hubli - APMC Market", "Mangalore - Market Yard", "Belgaum - Vegetable Market"],
    "Kerala": ["Kochi - Market", "Thiruvananthapuram - Chalai", "Kozhikode - Mittayi Theruvu", "Thrissur - Market", "Kollam - Vegetable Market"],
    "Madhya Pradesh": ["Indore - Grain Market", "Bhopal - Mandi", "Jabalpur - Market Yard", "Gwalior - Vegetable Market", "Ujjain - Market"],
    "Maharashtra": ["Mumbai - Crawford Market", "Pune - Market Yard", "Nashik - APMC Market", "Nagpur - Vegetable Market", "Aurangabad - Market"],
    "Odisha": ["Bhubaneswar - Bapuji Nagar", "Cuttack - Choudwar", "Rourkela - Market", "Berhampur - Vegetable Market", "Sambalpur - Mandi"],
    "Punjab": ["Ludhiana - Grain Market", "Amritsar - Mandi", "Jalandhar - Market Yard", "Patiala - Vegetable Market", "Bathinda - Market"],
    "Rajasthan": ["Jaipur - Grain Market", "Jodhpur - Mandi", "Kota - Market Yard", "Udaipur - Vegetable Market", "Ajmer - Market"],
    "Tamil Nadu": ["Chennai - Koyambedu", "Coimbatore - Nethaji Market", "Madurai - Mattuthavani", "Salem - Market Yard", "Tiruchirappalli - Vegetable Market"],
    "Telangana": ["Hyderabad - Rythu Bazaar", "Warangal - Market", "Nizamabad - Grain Market", "Karimnagar - Vegetable Market", "Khammam - Market Yard"],
    "Uttar Pradesh": ["Lucknow - Yahiyaganj", "Kanpur - Mandi", "Ghaziabad - Market", "Agra - Vegetable Market", "Varanasi - Market Yard"],
    "Uttarakhand": ["Dehradun - Paltan Bazaar", "Haridwar - Mandi", "Haldwani - Market", "Roorkee - Vegetable Market", "Rishikesh - Market"],
    "West Bengal": ["Kolkata - Sealdah", "Howrah - Market", "Durgapur - Haat", "Siliguri - Vegetable Market", "Asansol - Market Yard"],
    "Assam": ["Guwahati - Fancy Bazaar", "Dibrugarh - Market", "Jorhat - Mandi", "Silchar - Vegetable Market", "Tezpur - Market"],
    "Jharkhand": ["Ranchi - Firayalal", "Jamshedpur - Sakchi", "Dhanbad - Market", "Bokaro - Vegetable Market", "Deoghar - Market Yard"],
    "Goa": ["Panaji - Market", "Margao - Municipal Market", "Vasco - Market", "Mapusa - Friday Market", "Ponda - Vegetable Market"],
    "Sikkim": ["Gangtok - Lal Market", "Namchi - Market", "Gyalshing - Bazaar", "Mangan - Market", "Rangpo - Vegetable Market"],
    "Arunachal Pradesh": ["Itanagar - Market", "Naharlagun - Main Market", "Pasighat - Bazaar", "Tawang - Market", "Bomdila - Vegetable Market"],
    "Manipur": ["Imphal - Ima Keithel", "Thoubal - Market", "Bishnupur - Bazaar", "Kakching - Market", "Churachandpur - Vegetable Market"],
    "Meghalaya": ["Shillong - Bara Bazaar", "Tura - Market", "Jowai - Market", "Nongstoin - Haat", "Nongpoh - Vegetable Market"],
    "Mizoram": ["Aizawl - Bara Bazar", "Lunglei - Market", "Champhai - Bazaar", "Serchhip - Market", "Kolasib - Vegetable Market"],
    "Nagaland": ["Kohima - New Market", "Dimapur - Market", "Mokokchung - Bazaar", "Wokha - Market", "Tuensang - Vegetable Market"],
    "Tripura": ["Agartala - Battala", "Udaipur - Market", "Dharmanagar - Bazaar", "Kailashahar - Market", "Ambassa - Vegetable Market"]
}

def get_state_region(state):
    """Determine region for a state"""
    north = ["Punjab", "Haryana", "Himachal Pradesh", "Uttarakhand", "Uttar Pradesh"]
    south = ["Tamil Nadu", "Kerala", "Karnataka", "Andhra Pradesh", "Telangana"]
    east = ["West Bengal", "Odisha", "Bihar", "Jharkhand", "Assam", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Tripura", "Arunachal Pradesh", "Sikkim"]
    west = ["Gujarat", "Maharashtra", "Goa", "Rajasthan"]
    central = ["Madhya Pradesh", "Chhattisgarh"]
    
    if state in north: return "North"
    if state in south: return "South"
    if state in east: return "East"
    if state in west: return "West"
    if state in central: return "Central"
    return "Central"

def generate_realistic_prices_with_ai():
    """Use Gemini AI to generate realistic market prices for all Indian states"""
    try:
        prompt = f"""Generate realistic current agricultural market prices for major Indian states as of {datetime.now().strftime('%Y-%m-%d')}.

Generate data for ALL major Indian states including: Punjab, Haryana, Uttar Pradesh, Bihar, West Bengal, Maharashtra, Gujarat, Karnataka, Tamil Nadu, Andhra Pradesh, Telangana, Madhya Pradesh, Rajasthan, Odisha, Kerala, Chhattisgarh, Assam, Jharkhand, and others.

For each state, include their major crops:
- North: Wheat, Rice, Sugarcane, Mustard, Potato, Onion, Cotton
- South: Rice, Paddy, Coconut, Banana, Groundnut, Turmeric, Coffee
- East: Rice, Jute, Tea, Potato, Maize, Vegetables
- West: Cotton, Groundnut, Sugarcane, Wheat, Bajra, Soybean
- Central: Wheat, Soybean, Cotton, Pulses, Rice

Provide realistic prices in ₹/quintal:
- Modal Price (average market price)
- Minimum Price
- Maximum Price

Format as JSON array. Generate at least 50 records covering all major states. Example:
[{{"commodity":"Wheat","variety":"Sharbati","market":"Ludhiana - Grain Market","state":"Punjab","district":"Ludhiana","min_price":2300,"max_price":2700,"modal_price":2500,"price_date":"{datetime.now().strftime('%Y-%m-%d')}","arrival":"250 quintals","unit":"Quintal"}}]

Keep prices realistic for December 2025."""

        response = model.generate_content(prompt)
        response_text = response.text
        
        # Extract JSON from response
        start_idx = response_text.find('[')
        end_idx = response_text.rfind(']') + 1
        
        if start_idx != -1 and end_idx > start_idx:
            json_text = response_text[start_idx:end_idx]
            market_data = json.loads(json_text)
            print(f"[SUCCESS] AI generated {len(market_data)} market records for all India")
            return market_data
        else:
            print("Could not extract JSON from AI response, using fallback data")
            return generate_fallback_prices()
            
    except Exception as e:
        print(f"Error generating prices with AI: {str(e)}")
        return generate_fallback_prices()

def load_states_districts():
    """Load all states and districts from MongoDB static configs"""
    try:
        from utils.db import get_static_config
        states = get_static_config('states_districts')
        return states if states else {}
    except Exception as e:
        print(f"Error loading states_districts: {str(e)}")
        return {}

def generate_fallback_prices():
    """Fallback realistic prices - ALL vegetables and fruits for EACH district (28,400 entries)"""
    
    # Load all states and districts from JSON file
    states_districts = load_states_districts()
    
    # Base prices (in ₹/quintal) - 30 Vegetables + 20 Fruits = 50 commodities
    base_prices = {
        # 🥕 Vegetables (30 types)
        "Tomato": (1000, 4000, ["Local", "Hybrid", "Cherry"]),
        "Onion": (1200, 3500, ["Red", "White", "Pink"]),
        "Potato": (800, 2000, ["Local", "Hybrid", "Imported"]),
        "Brinjal": (1200, 3000, ["Long", "Round", "Green"]),
        "Cabbage": (800, 2000, ["Green", "Red", "Grade A"]),
        "Cauliflower": (1000, 2500, ["Local", "Grade A", "Premium"]),
        "Carrot": (1500, 3000, ["Local", "Hybrid", "Ooty"]),
        "Beetroot": (1200, 2800, ["Local", "Organic", "Grade A"]),
        "Green Chilli": (2500, 6000, ["Local", "Hybrid", "Long"]),
        "Capsicum (Green)": (2000, 5000, ["Local", "Hybrid", "Premium"]),
        "Capsicum (Red)": (3000, 7000, ["Local", "Hybrid", "Premium"]),
        "Capsicum (Yellow)": (3000, 7000, ["Local", "Hybrid", "Premium"]),
        "Beans": (2000, 4500, ["French", "Cluster", "Local"]),
        "Cluster Beans": (1800, 4000, ["Local", "Hybrid", "Premium"]),
        "Lady Finger": (1500, 3500, ["Local", "Hybrid", "Premium"]),
        "Drumstick": (2000, 5000, ["Local", "Hybrid", "Long"]),
        "Bottle Gourd": (800, 2000, ["Local", "Long", "Round"]),
        "Ridge Gourd": (1200, 2800, ["Local", "Long", "Short"]),
        "Snake Gourd": (1000, 2500, ["Local", "Long", "Green"]),
        "Bitter Gourd": (1500, 3500, ["Local", "Green", "White"]),
        "Pumpkin": (600, 1500, ["Local", "Sweet", "Yellow"]),
        "Ash Gourd": (700, 1800, ["Local", "Large", "Medium"]),
        "Radish": (800, 2000, ["White", "Red", "Local"]),
        "Turnip": (900, 2200, ["White", "Purple", "Local"]),
        "Sweet Corn": (1800, 4000, ["Yellow", "White", "Hybrid"]),
        "Peas": (3000, 6000, ["Local", "Frozen", "Premium"]),
        "Garlic": (4000, 10000, ["Local", "Kashmiri", "Chinese"]),
        "Ginger": (3000, 8000, ["Local", "Organic", "Premium"]),
        "Coriander Leaves": (2000, 5000, ["Local", "Organic", "Fresh"]),
        "Spinach": (1000, 2500, ["Local", "Organic", "Premium"]),
        
        # 🍎 Fruits (20 types)
        "Apple": (5000, 12000, ["Shimla", "Kashmiri", "Imported"]),
        "Banana": (1500, 3500, ["Robusta", "Yelakki", "Nendran"]),
        "Orange": (2500, 5000, ["Nagpur", "Kinnow", "Mandarin"]),
        "Mosambi": (2000, 4500, ["Local", "Hybrid", "Premium"]),
        "Grapes": (4000, 10000, ["Green", "Black", "Red"]),
        "Pomegranate": (5000, 12000, ["Bhagwa", "Arakta", "Ganesh"]),
        "Papaya": (1500, 3500, ["Local", "Taiwan", "Hybrid"]),
        "Pineapple": (2000, 4500, ["Queen", "Giant Kew", "Mauritius"]),
        "Watermelon": (800, 2000, ["Striped", "Black", "Seedless"]),
        "Muskmelon": (1500, 3500, ["Local", "Netted", "Honeydew"]),
        "Mango": (3000, 10000, ["Alphonso", "Kesar", "Langra"]),
        "Guava": (2000, 4000, ["Allahabad", "Pink", "White"]),
        "Lemon": (2000, 5000, ["Kagzi", "Galgal", "Sweet"]),
        "Custard Apple": (3000, 7000, ["Local", "Balanagar", "Arka Sahan"]),
        "Sapota": (2500, 5500, ["Cricket Ball", "Oval", "Local"]),
        "Strawberry": (10000, 25000, ["Camarosa", "Chandler", "Local"]),
        "Kiwi": (12000, 25000, ["Green", "Golden", "Imported"]),
        "Pear": (4000, 8000, ["Kashmir", "Chinese", "Bartlett"]),
        "Plum": (4000, 9000, ["Black", "Red", "Yellow"]),
        "Peach": (5000, 10000, ["Local", "Imported", "Yellow"]),
        # 🌾 Cereals
        "Paddy (Rice – Common)": (2000, 2500, ["Common", "Grade A"]),
        "Paddy (Basmati)": (3500, 6000, ["Pusa", "1121", "Traditional"]),
        "Wheat": (2200, 3000, ["Sharbati", "Lokwan", "Dara"]),
        "Maize (Corn)": (1800, 2600, ["Yellow", "White", "Hybrid"]),
        "Barley": (1600, 2200, ["Malt", "Feed"]),
        "Jowar (Sorghum)": (2500, 4000, ["White", "Yellow", "Hybrid"]),
        "Bajra (Pearl Millet)": (2000, 3000, ["Hybrid", "Desi"]),
        "Ragi (Finger Millet)": (3000, 4500, ["Local", "Hybrid"]),

        # 🌱 Pulses
        "Red Gram (Tur/Arhar)": (6000, 11000, ["Desi", "Hybrid", "Lemon"]),
        "Green Gram (Moong)": (7000, 10000, ["Shiny", "Medium", "Bold"]),
        "Black Gram (Urad)": (6500, 9500, ["FAQ", "SQ", "Bold"]),
        "Bengal Gram (Chana)": (5000, 7000, ["Desi", "Kabuli", "Kantola"]),
        "Lentil (Masur)": (6000, 8500, ["Small", "Bold", "Canadian"]),
        "Horse Gram": (4000, 6500, ["Red", "Brown"]),
        "Field Pea": (3500, 5500, ["Green", "Yellow", "White"]),

        # 🌰 Oilseeds
        "Groundnut": (5500, 8000, ["Java", "Bold", "Runner"]),
        "Mustard Seed": (4500, 6500, ["Black", "Yellow", "Mustard"]),
        "Soybean": (4000, 6000, ["Yellow", "Black", "Mixed"]),
        "Sunflower Seed": (4500, 6500, ["Hybrid", "Local"]),
        "Sesame (Gingelly)": (10000, 16000, ["White", "Black", "Red"]),
        "Castor Seed": (5000, 7000, ["Small", "Bold"]),
        "Linseed": (5500, 7500, ["Brown", "Yellow"]),

        # 🧂 Spices
        "Dry Chilli": (12000, 25000, ["Teja", "Byadgi", "Guntur"]),
        "Turmeric": (6000, 12000, ["Finger", "Bulb", "Powder"]),
        "Coriander Seed": (7000, 11000, ["Eagle", "Scooter", "Badami"]),
        "Cumin Seed (Jeera)": (25000, 55000, ["Ordinary", "Best", "Singapore"]),
        "Pepper (Black)": (30000, 50000, ["Garbled", "Ungarbled", "Tellicherry"]),
        "Cardamom": (100000, 250000, ["Small", "Bold", "Green"]),
        "Clove": (60000, 90000, ["Zanzibar", "Madagascar"]),

        # 🍬 Commercial
        "Sugarcane": (300, 500, ["Co 0238", "Co 86032"]),
        "Cotton": (5500, 9000, ["H-4", "Shanker-6", "Bunny"]),
        "Jute": (4000, 6500, ["TD-5", "W-5", "Mesta"]),
        "Copra (Dry Coconut)": (9000, 14000, ["Milling", "Edible"]),
        "Tobacco": (4000, 15000, ["Flue Cured", "Burley"]),
        "Tea Leaves": (15000, 40000, ["Darjeeling", "Assam", "Nilgiri"]),
        "Coffee Beans": (20000, 45000, ["Arabica", "Robusta"]),

        # 🥜 Dry Fruits
        "Coconut": (1500, 3000, ["Large", "Medium", "Small"]),
        "Cashew Nut": (80000, 120000, ["W320", "W240", "Splits"]),
        "Groundnut Kernel": (8000, 12000, ["Bold", "Java"]),
        "Almond": (60000, 90000, ["California", "Gurbandi", "Mamra"]),
        "Walnut": (30000, 60000, ["Inshell", "Kernels"]),
        "Raisins": (15000, 30000, ["Indian", "Afghan", "Black"]),

        # 🐄 Animal
        "Milk": (4000, 6500, ["Cow", "Buffalo", "Mixed"]),
        "Cow Ghee": (45000, 70000, ["Desi", "Pure", "A2"]),
        "Buffalo Ghee": (40000, 60000, ["Pure", "Mixed"]),
        "Egg": (400, 700, ["White", "Brown"]),
        "Poultry Chicken": (8000, 14000, ["Broiler", "Layer", "Cockerel"]),
        "Fish (Common Varieties)": (10000, 25000, ["Rohu", "Catla", "Mrigal"])
    }
    
    market_data = []
    date_today = datetime.now().strftime('%Y-%m-%d')
    
    # Use date-based seed for deterministic random values (same date = same prices everywhere)
    date_seed = int(hashlib.md5(date_today.encode()).hexdigest()[:8], 16)
    random.seed(date_seed)
    
    # Generate data for ALL states and ALL districts from states_districts.json
    for state, districts in states_districts.items():
        for district in districts:
            # Generate ALL 40 commodities for this district
            for commodity, (min_base, max_base, varieties) in base_prices.items():
                # Add regional price variation (±20%) - now deterministic based on date
                regional_factor = random.uniform(0.8, 1.2)
                min_price = int(min_base * regional_factor * random.uniform(0.9, 1.0))
                max_price = int(max_base * regional_factor * random.uniform(1.0, 1.1))
                modal_price = int((min_price + max_price) / 2 * random.uniform(0.95, 1.05))
                
                # Random date within last 7 days
                days_ago = random.randint(0, 6)
                from datetime import timedelta
                price_date = (datetime.now() - timedelta(days=days_ago)).strftime("%Y-%m-%d")
                
                market_data.append({
                    "commodity": commodity,
                    "variety": random.choice(varieties),
                    "market": f"{district} Mandi",
                    "state": state,
                    "district": district,
                    "min_price": min_price,
                    "max_price": max_price,
                    "modal_price": modal_price,
                    "price_date": price_date,
                    "arrival": f"{random.randint(50, 1000)} quintals",
                    "unit": "Quintal"
                })
    
    # Reset random seed to avoid affecting other random operations
    random.seed()
    
    print(f"[SUCCESS] Generated {len(market_data)} records covering 50 commodities for {len(states_districts)} states and all districts")
    return market_data

from utils.db import get_db

def save_market_data(data):
    """Overwrite market data in MongoDB using ReplaceOne with upsert (no drop)"""
    try:
        db = get_db()
        if db is not None and hasattr(db, 'market_prices'):
            # Prepare bulk write operations for overwrite (upsert=True)
            # This identifies a unique record by its commodity, market, state, and district
            # and overwrites the prices and other fields.
            
            chunk_size = 1000 # Smaller chunk size for complex bulk writes
            for i in range(0, len(data), chunk_size):
                chunk = data[i:i + chunk_size]
                operations = []
                for record in chunk:
                    # Define the matching filter (unique key for overwriting)
                    filter_query = {
                        "commodity": record.get("commodity"),
                        "market": record.get("market"),
                        "state": record.get("state"),
                        "district": record.get("district")
                    }
                    # ReplaceOne with upsert=True will update existing or insert new
                    operations.append(ReplaceOne(filter_query, record, upsert=True))
                
                # Execute bulk operation
                db.market_prices.bulk_write(operations, ordered=False)
                
            db.collection_metadata.update_one(
                {"collection": "market_prices"}, 
                {"$set": {"last_updated": datetime.now().isoformat()}}, 
                upsert=True
            )
            print(f"[SUCCESS] Market data overwritten in MongoDB: {len(data)} records processed")
            return True
        else:
            print("[ERROR] MongoDB not connected, unable to save market data")
            return False
    except Exception as e:
        print(f"Error saving market data: {str(e)}")
        return False

def load_market_data():
    """Load market data from JSON file or MongoDB"""
    try:
        db = get_db()
        if db is not None and hasattr(db, 'market_prices'):
            metadata = db.collection_metadata.find_one({"collection": "market_prices"})
            last_updated = metadata.get("last_updated") if metadata else None
            data = list(db.market_prices.find({}, {'_id': 0}))
            if data:
                return data, last_updated
                
        if os.path.exists(MARKET_DATA_FILE):
            with open(MARKET_DATA_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('data', []), data.get('last_updated')
        return [], None
    except Exception as e:
        print(f"Error loading market data: {str(e)}")
        return [], None

def update_market_prices_job():
    """Background job to update market prices daily"""
    print(f"🔄 Running daily market price update for ALL INDIA at {datetime.now()}")
    try:
        # Use fallback method for reliable all-India coverage
        new_prices = generate_fallback_prices()
        if new_prices:
            save_market_data(new_prices)
            print(f"[SUCCESS] All India prices updated! Total: {len(new_prices)} records for {len(INDIAN_STATES)} states")
    except Exception as e:
        print(f"[ERROR] Error in update job: {str(e)}")

def is_data_stale(last_updated):
    """Check if market data is stale (older than today)"""
    if not last_updated:
        return True
    try:
        last_date = datetime.fromisoformat(last_updated).date()
        today = datetime.now().date()
        return last_date < today
    except Exception:
        return True

def init_scheduler(app):
    """Initialize scheduler for daily updates at 9:00 AM"""
    scheduler = BackgroundScheduler()
    
    scheduler.add_job(
        func=update_market_prices_job,
        trigger='cron',
        hour=9,
        minute=0,
        id='daily_market_update',
        name='Update All India Market Prices',
        replace_existing=True
    )
    
    # Run at startup if no data OR if data is stale (from a previous day)
    data, last_updated = load_market_data()
    if not data:
        print("[INFO] Generating initial market data for all India...")
        update_market_prices_job()
    elif is_data_stale(last_updated):
        print(f"[INFO] Market data is stale (last updated: {last_updated}). Updating now...")
        update_market_prices_job()
    else:
        print(f"[INFO] Loaded {len(data)} records for all India, updated: {last_updated}")
    
    scheduler.start()
    print("[INFO] Scheduler started - Updates ALL INDIA prices daily at 9:00 AM")
    return scheduler
