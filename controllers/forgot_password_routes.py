"""
Forgot Password Routes
Handles password reset flow with OTP verification
"""
from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, flash
from datetime import datetime, timedelta
import re
import time
import os

from utils.otp_manager import OTPManager
from utils.email_gateway import EmailGateway
from utils.auth import hash_password

forgot_password_bp = Blueprint('forgot_password', __name__)

# --- Helper Functions ---

def validate_password_strength(password):
    """Validate password strength"""
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    if not re.search(r'[0-9]', password):
        return False, "Password must contain at least one number"
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain at least one special character"
    return True, "Password is strong"

# --- Routes ---

@forgot_password_bp.route('/forgot-password', methods=['GET'])
def forgot_password_page():
    return render_template('forgot_password.html')

@forgot_password_bp.route('/api/forgot-password/request-otp', methods=['POST'])
def request_otp():
    """
    Step 1: Request OTP
    - Validates inputs
    - Checks User existence
    - Enforces 30s Cooldown
    - Generates & Stores OTP in Session
    - Sends via SMS (Fast2SMS) -> Fallback to Email
    """
    try:
        data = request.get_json()
        identifier = data.get('identifier') or data.get('email') or data.get('mobile_number')
        
        if not identifier:
            return jsonify({'success': False, 'message': 'Please provide email or mobile number'}), 400

        identifier = identifier.strip()
        is_email = '@' in identifier
        
        # 1. 30-Second Cooldown Check
        last_sent = session.get('otp_last_sent_time', 0)
        if time.time() - last_sent < 30:
            remaining = int(30 - (time.time() - last_sent))
            return jsonify({'success': False, 'message': f'Please wait {remaining} seconds before resending OTP'}), 429

        # 2. Validate Input (Email or Mobile Number)
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        mobile_regex = r'^\d{10}$'
        if is_email:
            if not re.match(email_regex, identifier):
                return jsonify({'success': False, 'message': 'Please enter a valid email address'}), 400
        else:
            if not re.match(mobile_regex, identifier):
                return jsonify({'success': False, 'message': 'Please enter a valid email or 10-digit mobile number'}), 400
        
        # 3. Check User Existence
        from utils.db import get_db
        db = get_db()
        
        user = None
        if is_email:
            if hasattr(db, 'users'):
                user = db.users.find_one({'email': identifier})
            else:
                from utils.db import find_user_by_email
                user = find_user_by_email(identifier)
        else:
            # Look up user by mobile/phone number
            if hasattr(db, 'users'):
                user = db.users.find_one({'phone': identifier})
            if not user:
                from utils.db import find_user_by_phone
                user = find_user_by_phone(identifier)

        if user:
            user_email = user.get('email')
            print(f"✅ User found: {user_email}")
            
            # 4. Generate OTP
            otp = OTPManager.generate_otp()
            otp_hash = OTPManager.hash_otp(otp)
            expiry_timestamp = time.time() + (3 * 60) # 3 minutes from now
            
            # ALWAYS PRINT OTP FOR DEBUGGING
            print(f"\n{'='*40}")
            print(f"🔐 GENERATED OTP: {otp}")
            print(f"{'='*40}\n")
            
            # 5. Store in Session (Securely)
            session['reset_otp_hash'] = otp_hash
            session['reset_otp_expiry'] = expiry_timestamp
            session['reset_identifier'] = identifier 
            session['reset_user_id'] = str(user['_id']) # Store ID for final reset
            session['otp_last_sent_time'] = time.time()
            
            # 6. Send OTP to user's registered email
            print(f"📧 Attempting to send Email to {user_email}...")
            success, msg = EmailGateway.send_otp_email(user_email, otp, purpose="reset")
            
            if success:
                print(f"✅ Email sent successfully: {msg}")
                # Mask email for display (e.g. f***r@example.com)
                masked = user_email[0] + '***' + user_email[user_email.index('@')-1:]
                response_msg = f"OTP sent to {masked}"
            else:
                print(f"❌ Email failed: {msg}")
                # Still proceed (OTP is stored in session for verification)
                print(f"[INFO] OTP delivery failed for {user_email}, OTP stored for manual verification")
                response_msg = "OTP has been generated. Please check your email."
                
            return jsonify({
                'success': True,
                'message': response_msg,
                'identifier': identifier
            })
            
        # Security: Fake success if user not found
        return jsonify({
            'success': True,
            'message': 'If account exists, OTP has been sent.',
            'identifier': identifier
        })

    except Exception as e:
        print(f"Error in request_otp: {e}")
        return jsonify({'success': False, 'message': 'An error occurred'}), 500

@forgot_password_bp.route('/verify-otp', methods=['GET'])
def verify_otp_page():
    identifier = request.args.get('identifier')
    if not identifier: 
        return redirect(url_for('forgot_password.forgot_password_page'))
    return render_template('verify_otp.html', identifier=identifier)

@forgot_password_bp.route('/api/forgot-password/verify-otp', methods=['POST'])
def verify_otp():
    """
    Step 2: Verify OTP
    - Checks Session Data
    - Verifies Hash
    - Checks Expiry
    """
    try:
        data = request.get_json()
        otp_entered = data.get('otp', '').strip()
        
        # Check if session has OTP data
        if 'reset_otp_hash' not in session or 'reset_otp_expiry' not in session:
             return jsonify({'success': False, 'message': 'No OTP request found or session expired'}), 400
             
        # Check Expiry
        if time.time() > session['reset_otp_expiry']:
             return jsonify({'success': False, 'message': 'OTP has expired. Please request a new one.'}), 400
             
        # Verify Hash
        hashed_otp = session['reset_otp_hash']
        if OTPManager.verify_otp(otp_entered, hashed_otp):
            # Success!
            session['reset_verified'] = True
            # Clear OTP data to prevent reuse
            session.pop('reset_otp_hash', None)
            session.pop('reset_otp_expiry', None)
            
            return jsonify({
                'success': True,
                'message': 'OTP Verified Successfully',
                'redirect_url': url_for('forgot_password.reset_password_page')
            })
        else:
            return jsonify({'success': False, 'message': 'Invalid OTP'}), 400

    except Exception as e:
        print(f"Error verifying OTP: {e}")
        return jsonify({'success': False, 'message': 'Server error'}), 500

@forgot_password_bp.route('/reset-password', methods=['GET'])
def reset_password_page():
    if not session.get('reset_verified') or not session.get('reset_user_id'):
        flash('Session expired. Please start over.', 'error')
        return redirect(url_for('forgot_password.forgot_password_page'))
    return render_template('reset_password.html')

@forgot_password_bp.route('/api/forgot-password/reset-password', methods=['POST'])
def reset_password():
    """
    Step 3: Reset Password
    - Checks 'reset_verified' in session
    - Updates Password in DB
    - Clears Session
    """
    try:
        if not session.get('reset_verified') or not session.get('reset_user_id'):
             return jsonify({'success': False, 'message': 'Session expired'}), 401
             
        data = request.get_json()
        new_password = data.get('password')
        
        # Validate Strength
        is_strong, msg = validate_password_strength(new_password)
        if not is_strong:
            return jsonify({'success': False, 'message': msg}), 400
            
        # Hash Password (using bcrypt, same as registration)
        hashed_password = hash_password(new_password)
        user_id = session.get('reset_user_id')
        
        # Update DB
        from utils.db import get_db
        db = get_db()
        
        update_success = False
        if hasattr(db, 'users'):
            from bson.objectid import ObjectId
            try:
                uid = ObjectId(user_id)
            except:
                uid = user_id
            
            res = db.users.update_one({'_id': uid}, {'$set': {'password': hashed_password}})
            if res.modified_count > 0: update_success = True
        else:
            # File DB fallback (less critical if using Mongo)
            from utils.db import update_user_password, find_user_by_id
            user = find_user_by_id(user_id)
            if user:
                update_user_password(user['email'], hashed_password)
                update_success = True

        if update_success:
            # Clear all reset session data
            session.pop('reset_user_id', None)
            session.pop('reset_verified', None)
            session.pop('reset_identifier', None)
            
            return jsonify({
                'success': True,
                'message': 'Password reset successfully',
                'redirect_url': url_for('auth.login')
            })
        else:
             return jsonify({'success': False, 'message': 'Failed to update password'}), 500

    except Exception as e:
        print(f"Error resetting password: {e}")
        return jsonify({'success': False, 'message': 'Server error'}), 500
