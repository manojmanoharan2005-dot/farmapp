"""
Direct Buyer Connect Routes
Handles farmer listings and buyer marketplace with live price integration
"""
from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, flash
from datetime import datetime, timedelta
from utils.auth import login_required
from utils.db import (
    create_crop_listing, 
    get_user_listings, 
    get_available_listings,
    confirm_purchase,
    get_live_market_price,
    update_listing_status,
    get_listing_by_id,
    find_user_by_id,
    get_db
)
import json
import os

buyer_connect_bp = Blueprint('buyer_connect', __name__, url_prefix='/buyer-connect')

# ============================================
# FARMER ROUTES - Create and Manage Listings
# ============================================

@buyer_connect_bp.route('/create-listing', methods=['GET', 'POST'])
@login_required
def create_listing():
    """Create a new crop listing for sale"""
    user_id = session.get('user_id')
    
    if request.method == 'GET':
        # Load user info for location
        user = find_user_by_id(user_id)
        
        # Get available crops from dataset - Complete commodity list matching market prices
        vegetables = [
            "Tomato", "Onion", "Potato", "Brinjal", "Cabbage", "Cauliflower",
            "Carrot", "Beetroot", "Green Chilli", "Capsicum (Green)", "Capsicum (Red)",
            "Capsicum (Yellow)", "Beans", "Cluster Beans", "Lady Finger", "Drumstick",
            "Bottle Gourd", "Ridge Gourd", "Snake Gourd", "Bitter Gourd", "Pumpkin",
            "Ash Gourd", "Radish", "Turnip", "Sweet Corn", "Peas", "Garlic",
            "Ginger", "Coriander Leaves", "Spinach"
        ]
        
        fruits = [
            "Apple", "Banana", "Orange", "Mosambi", "Grapes", "Pomegranate",
            "Papaya", "Pineapple", "Watermelon", "Muskmelon", "Mango", "Guava",
            "Lemon", "Custard Apple", "Sapota", "Strawberry", "Kiwi", "Pear",
            "Plum", "Peach"
        ]
        
        cereals = [
            "Paddy (Rice – Common)", "Paddy (Basmati)", "Wheat", "Maize (Corn)", "Barley",
            "Jowar (Sorghum)", "Bajra (Pearl Millet)", "Ragi (Finger Millet)"
        ]
        
        pulses = [
            "Red Gram (Tur/Arhar)", "Green Gram (Moong)", "Black Gram (Urad)", "Bengal Gram (Chana)",
            "Lentil (Masur)", "Horse Gram", "Field Pea"
        ]
        
        oilseeds = [
            "Groundnut", "Mustard Seed", "Soybean", "Sunflower Seed", "Sesame (Gingelly)",
            "Castor Seed", "Linseed"
        ]
        
        spices = [
            "Dry Chilli", "Turmeric", "Coriander Seed", "Cumin Seed (Jeera)", "Pepper (Black)",
            "Cardamom", "Clove"
        ]
        
        commercial = [
            "Sugarcane", "Cotton", "Jute", "Copra (Dry Coconut)", "Tobacco", "Tea Leaves", "Coffee Beans"
        ]
        
        dry_fruits = [
            "Coconut", "Cashew Nut", "Groundnut Kernel", "Almond", "Walnut", "Raisins"
        ]
        
        # Combine all crops with categories
        crops = {
            'Vegetables': vegetables,
            'Fruits': fruits,
            'Cereals': cereals,
            'Pulses': pulses,
            'Oilseeds': oilseeds,
            'Spices': spices,
            'Commercial Crops': commercial,
            'Dry Fruits': dry_fruits
        }
        
        try:
            states_file = os.path.join(os.path.dirname(__file__), '..', 'data', 'states_districts.json')
            if os.path.exists(states_file):
                with open(states_file, 'r', encoding='utf-8') as f:
                    states_districts = json.load(f)
            else:
                print(f"[WARNING] States file not found at {states_file}")
                states_districts = {}
        except Exception as e:
            print(f"[ERROR] Failed to load states: {e}")
            states_districts = {}
        
        return render_template('create_listing.html', 
                             user=user, 
                             crops=crops,
                             states_districts=states_districts,
                             current_date=datetime.now().strftime('%Y-%m-%d'))
    
    # POST: Create listing
    try:
        print("\n" + "="*60, flush=True)
        print("[CREATE LISTING] Starting new listing creation...", flush=True)
        print("="*60, flush=True)
        
        # Get form data
        form_data = request.form.to_dict()
        print(f"[DEBUG] Received Raw Form Data: {form_data}", flush=True)
        
        crop = request.form.get('crop', '').strip()
        quantity_str = request.form.get('quantity', '').strip()
        unit = request.form.get('unit', 'kg').strip()
        district = request.form.get('district', '').strip()
        state = request.form.get('state', '').strip()
        description = request.form.get('description', '').strip()
        price_str = request.form.get('price', '').strip()
        
        # Validation
        if not all([crop, quantity_str, district, state, price_str]):
            missing = [k for k, v in {'crop':crop, 'quantity':quantity_str, 'district':district, 'state':state, 'price':price_str}.items() if not v]
            print(f"[VALIDATION ERROR] Missing required fields: {missing}", flush=True)
            flash('❌ All required fields must be filled', 'error')
            return redirect(url_for('buyer_connect.create_listing'))
        
        try:
            quantity = float(quantity_str)
            farmer_price = float(price_str)
            print(f"[DEBUG] Numeric Validation Passed: Qty={quantity}, Price={farmer_price}", flush=True)
        except ValueError as e:
            print(f"[VALIDATION ERROR] Invalid number format: {e}", flush=True)
            flash('❌ Quantity and price must be valid numbers', 'error')
            return redirect(url_for('buyer_connect.create_listing'))
        
        # Get location coordinates
        latitude_str = request.form.get('latitude', '').strip()
        longitude_str = request.form.get('longitude', '').strip()
        
        try:
            latitude = float(latitude_str) if latitude_str else None
            longitude = float(longitude_str) if longitude_str else None
            print(f"[DEBUG] Coordinates: Lat={latitude}, Lon={longitude}", flush=True)
        except ValueError:
            latitude = None
            longitude = None
            print("[DEBUG] Coordinates invalid format", flush=True)
        
        # Validate location
        if not latitude or not longitude:
            print("[VALIDATION ERROR] Location coordinates missing or zero", flush=True)
            flash('❌ Please select your location on the map', 'error')
            return redirect(url_for('buyer_connect.create_listing'))
        
        # Get live market price
        print(f"[DEBUG] Fetching market price for: {crop} in {district}, {state}", flush=True)
        live_price_data = get_live_market_price(crop, district, state)
        
        if not live_price_data:
            print("[WARNING] Could not fetch live market price from database/file", flush=True)
            # We'll use the price the farmer entered but warn
            recommended_price = farmer_price
            min_allowed = farmer_price * 0.5 # Relaxed temporarily for testing
            max_allowed = farmer_price * 2.0
        else:
            recommended_price = live_price_data['recommended_price']
            min_allowed = live_price_data['min_price']
            max_allowed = live_price_data['max_price']
            print(f"[DEBUG] Market Data Found: Rec={recommended_price}, Range={min_allowed}-{max_allowed}", flush=True)
        
        # Relaxed validation for testing
        if farmer_price < (min_allowed * 0.5) or farmer_price > (max_allowed * 2.0):
            print(f"[VALIDATION ERROR] Price ₹{farmer_price} too far from market", flush=True)
            flash(f'❌ Price is too far from market average. Please adjust.', 'error')
            return redirect(url_for('buyer_connect.create_listing'))
        
        # Get farmer info
        print(f"[DEBUG] Looking up farmer with user_id: {user_id}", flush=True)
        farmer = find_user_by_id(user_id)
        print(f"[DEBUG] Farmer lookup result: {farmer}", flush=True)
        
        # Use database info first, then fallback to session data
        if farmer:
            farmer_name = farmer.get('name', session.get('user_name', 'Unknown'))
            farmer_phone = farmer.get('phone', session.get('user_phone', ''))
        else:
            # Fallback to session data if database lookup fails
            farmer_name = session.get('user_name', 'Unknown')
            farmer_phone = session.get('user_phone', '')
        
        print(f"[DEBUG] Farmer name: {farmer_name}, phone: {farmer_phone}", flush=True)
        
        # Create listing object
        listing_data = {
            'farmer_id': str(user_id),
            'farmer_name': farmer_name,
            'farmer_phone': farmer_phone,
            'crop': crop,
            'quantity': quantity,
            'unit': unit,
            'district': district,
            'state': state,
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
            'farmer_price': farmer_price,
            'recommended_price': recommended_price,
            'min_price': min_allowed,
            'max_price': max_allowed,
            'live_market_price': recommended_price,
            'status': 'active',  # Changed from 'available' to 'active' to match MongoDB schema
            'created_at': datetime.utcnow().isoformat(),
            'expires_at': (datetime.utcnow() + timedelta(days=30)).isoformat()
        }
        
        print("[DEBUG] Calling create_crop_listing...", flush=True)
        listing_id = create_crop_listing(listing_data)
        
        if listing_id:
            print(f"[SUCCESS] Listing created successfully! ID: {listing_id}", flush=True)
            print("="*60 + "\n", flush=True)
            flash('✅ Your crop listing has been created successfully!', 'success')
            return redirect(url_for('buyer_connect.my_listings'))
        else:
            print("[ERROR] Database function returned None", flush=True)
            print("="*60 + "\n", flush=True)
            flash('❌ Failed to create listing. Please try again.', 'error')
            return redirect(url_for('buyer_connect.create_listing'))
            
    except Exception as e:
        print(f"[CRITICAL ERROR in Route] {str(e)}", flush=True)
        import traceback
        traceback.print_exc()
        flash(f'❌ System error: {str(e)}', 'error')
        return redirect(url_for('buyer_connect.create_listing'))


@buyer_connect_bp.route('/my-listings')
@login_required
def my_listings():
    """View farmer's own listings"""
    user_id = session.get('user_id')
    print(f"\n[MY LISTINGS] Called for user_id: {user_id}", flush=True)
    listings = get_user_listings(user_id)
    print(f"[MY LISTINGS] Retrieved {len(listings)} listings", flush=True)
    if listings:
        print(f"[MY LISTINGS] First listing: {listings[0].get('crop')} - {listings[0].get('_id')}", flush=True)
    
    return render_template('my_listings.html', listings=listings)


@buyer_connect_bp.route('/api/get-live-price', methods=['POST'])
@login_required
def api_get_live_price():
    """API endpoint to fetch live market price for auto-fill"""
    try:
        data = request.get_json()
        crop = data.get('crop')
        district = data.get('district')
        state = data.get('state')
        
        if not all([crop, district, state]):
            return jsonify({'success': False, 'error': 'Missing required fields'}), 400
        
        price_data = get_live_market_price(crop, district, state)
        
        if price_data:
            return jsonify({
                'success': True,
                'recommended_price': price_data['recommended_price'],
                'min_price': price_data['min_price'],
                'max_price': price_data['max_price'],
                'market_name': price_data.get('market', 'Local Mandi'),
                'price_date': price_data.get('date', datetime.now().strftime('%Y-%m-%d'))
            })
        else:
            return jsonify({'success': False, 'error': 'No price data available for this crop and location'}), 404
            
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ============================================
# BUYER ROUTES - Marketplace and Purchase
# ============================================

@buyer_connect_bp.route('/marketplace')
@login_required
def marketplace():
    """Buyer marketplace showing all available listings"""
    # Get current user ID
    user_id = str(session.get('user_id', ''))
    
    # Get filters from query params
    crop_filter = request.args.get('crop', '')
    district_filter = request.args.get('district', '')
    state_filter = request.args.get('state', '')
    sort_by = request.args.get('sort', 'recent')  # recent, price_low, price_high
    
    # Get all available listings (show globally)
    listings = get_available_listings(
        crop=crop_filter,
        district=district_filter,
        state=state_filter,
        sort_by=sort_by
    )
    
    # Get unique values for filters (from all listings, not filtered by user)
    all_available = get_available_listings()
    crops = sorted(set(l['crop'] for l in all_available))
    states = sorted(set(l['state'] for l in all_available))
    
    return render_template('buyer_marketplace.html',
                         listings=listings,
                         crops=crops,
                         states=states,
                         crop_filter=crop_filter,
                         district_filter=district_filter,
                         state_filter=state_filter,
                         sort_by=sort_by)


@buyer_connect_bp.route('/listing/<listing_id>')
@login_required
def view_listing(listing_id):
    """View detailed listing page"""
    listing = get_listing_by_id(listing_id)
    
    if not listing:
        flash('❌ Listing not found', 'error')
        return redirect(url_for('buyer_connect.marketplace'))
    
    # Don't show sold listings
    if listing['status'] != 'active':
        flash('❌ This listing is no longer available', 'error')
        return redirect(url_for('buyer_connect.marketplace'))
    
    return render_template('listing_detail.html', listing=listing)


@buyer_connect_bp.route('/api/confirm-purchase', methods=['POST'])
@login_required
def api_confirm_purchase():
    """Confirm purchase and update listing status atomically"""
    try:
        buyer_id = session.get('user_id')
        data = request.get_json()
        listing_id = data.get('listing_id')
        buyer_name = data.get('buyer_name', '').strip()
        buyer_phone = data.get('buyer_phone', '').strip()
        
        # Validation
        if not all([listing_id, buyer_name, buyer_phone]):
            return jsonify({'success': False, 'error': 'All fields are required'}), 400
        
        # Validate phone number
        if not buyer_phone.isdigit() or len(buyer_phone) != 10:
            return jsonify({'success': False, 'error': 'Phone number must be 10 digits'}), 400
        
        # Get listing details
        listing = get_listing_by_id(listing_id)
        if not listing:
            return jsonify({'success': False, 'error': 'Listing not found'}), 404
        
        # Check if listing is available
        if listing['status'] != 'active':
            return jsonify({'success': False, 'error': 'This listing is no longer available'}), 400
        
        # Prevent farmers from buying their own crops
        if listing['farmer_id'] == buyer_id:
            return jsonify({'success': False, 'error': 'You cannot purchase your own listing'}), 400
        
        # Atomic update to prevent double-selling
        purchase_data = {
            'buyer_id': buyer_id,
            'buyer_name': buyer_name,
            'buyer_phone': buyer_phone,
            'purchased_at': datetime.utcnow().isoformat()
        }
        
        success, message = confirm_purchase(listing_id, purchase_data)
        
        if success:
            # Create notifications for both buyer and farmer
            from utils.db import add_notification
            
            # Notification for buyer
            add_notification(
                user_id=buyer_id,
                type='purchase_confirmed',
                title='🛒 Purchase Confirmed',
                message=f'Your purchase of {listing.get("crop")} ({listing.get("quantity")} {listing.get("unit")}) has been confirmed! The farmer will contact you at {buyer_phone}.',
                priority='high',
                data={'listing_id': listing_id, 'crop': listing.get('crop')}
            )
            
            # Notification for farmer
            farmer_id = listing.get('farmer_id')
            if farmer_id:
                add_notification(
                    user_id=farmer_id,
                    type='crop_sold',
                    title='💰 Crop Sold',
                    message=f'Great news! Your {listing.get("crop")} listing has been sold to {buyer_name}. Contact: {buyer_phone}',
                    priority='high',
                    data={'listing_id': listing_id, 'buyer_name': buyer_name, 'buyer_phone': buyer_phone}
                )
            
            return jsonify({
                'success': True,
                'message': 'Purchase confirmed! The farmer will contact you soon.'
            })
        else:
            return jsonify({'success': False, 'error': message}), 400
            
    except Exception as e:
        print(f"Purchase error: {str(e)}")
        return jsonify({'success': False, 'error': 'An error occurred. Please try again.'}), 500


@buyer_connect_bp.route('/api/cancel-listing/', defaults={'listing_id': None}, methods=['POST'])
@buyer_connect_bp.route('/api/cancel-listing/<listing_id>', methods=['POST'])
@login_required
def api_cancel_listing(listing_id):
    print(f"\n[API] Cancel Listing Request received. ID: {listing_id}", flush=True)
    if not listing_id:
        print("[APIError] Listing ID missing in URL", flush=True)
        return jsonify({'success': False, 'error': 'Listing ID is missing'}), 400
    """Cancel/delete a listing (farmer only)"""
    try:
        user_id = session.get('user_id')
        
        # Get listing and verify ownership
        listing = get_listing_by_id(listing_id)
        
        if not listing:
            return jsonify({'success': False, 'error': 'Listing not found'}), 404
        
        # Check ownership
        farmer_id = listing.get('farmer_id')
        if farmer_id != user_id:
            # Check if the farmer user still exists
            farmer_exists = find_user_by_id(farmer_id)
            if farmer_exists:
                # Farmer exists but it's not the current user
                return jsonify({'success': False, 'error': 'You can only cancel your own listings'}), 403
            else:
                # Orphaned listing (farmer doesn't exist) - allow admin/any user to cancel
                print(f"[INFO] Allowing cancellation of orphaned listing {listing_id} by user {user_id}")
        
        # Check if already sold
        if listing['status'] == 'sold':
            return jsonify({'success': False, 'error': 'This listing has already been sold and cannot be cancelled'}), 400
        
        # Check if already cancelled
        if listing['status'] == 'cancelled':
            return jsonify({'success': False, 'error': 'This listing is already cancelled'}), 400
        
        # Update status to cancelled
        success = update_listing_status(listing_id, 'cancelled')
        
        if success:
            # Create notification
            from utils.db import add_notification
            add_notification(
                user_id=user_id,
                type='listing_cancelled',
                title='🚫 Listing Cancelled',
                message=f'Your {listing.get("crop", "crop")} listing has been cancelled and removed from the marketplace.',
                priority='low',
                data={'listing_id': listing_id}
            )
            return jsonify({'success': True, 'message': 'Listing cancelled successfully'})
        else:
            return jsonify({'success': False, 'error': 'Failed to cancel listing. Please try again.'}), 500
            
    except Exception as e:
        print(f"Cancel listing error: {str(e)}")
        return jsonify({'success': False, 'error': 'An error occurred. Please try again.'}), 500


@buyer_connect_bp.route('/purchase-history')
@login_required
def purchase_history():
    """View purchase history for the logged-in user (as buyer and as seller)"""
    user_id = str(session.get('user_id', ''))
    
    try:
        db = get_db()
        bought = []
        sold = []
        
        if db is not None:
            # Listings bought by this user
            bought_cursor = db.crop_listings.find({'buyer_id': user_id, 'status': 'sold'}).sort('sold_at', -1)
            bought = list(bought_cursor)
            for l in bought:
                l['_id'] = str(l['_id'])
            
            # Listings sold by this user
            sold_cursor = db.crop_listings.find({'farmer_id': user_id, 'status': 'sold'}).sort('sold_at', -1)
            sold = list(sold_cursor)
            for l in sold:
                l['_id'] = str(l['_id'])
        
        return render_template('purchase_history.html', bought=bought, sold=sold)
    except Exception as e:
        print(f"Purchase history error: {e}")
        return render_template('purchase_history.html', bought=[], sold=[])
