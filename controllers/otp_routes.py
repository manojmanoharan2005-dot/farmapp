"""
OTP Routes for Email Verification
Handles OTP sending and verification for registration via Brevo
OTPs are stored in MongoDB for multi-worker compatibility
"""
from flask import Blueprint, request, jsonify
from utils.otp_manager import OTPManager
from utils.email_gateway import EmailGateway
from utils.db import find_user_by_email, get_db
import os
import re
from datetime import datetime, timedelta

otp_bp = Blueprint('otp', __name__)


def _get_otp_collection():
    """Get the registration_otps collection from MongoDB"""
    db = get_db()
    return db.registration_otps


def is_email_verified(email):
    """Check if an email address has been verified via OTP (checks MongoDB)"""
    try:
        collection = _get_otp_collection()
        record = collection.find_one({'email': email})
        if record:
            return record.get('verified', False)
    except Exception as e:
        print(f"[ERROR] is_email_verified: {e}")
    return False


def clear_email_verification(email):
    """Clear verification data after successful registration (deletes from MongoDB)"""
    try:
        collection = _get_otp_collection()
        collection.delete_one({'email': email})
    except Exception as e:
        print(f"[ERROR] clear_email_verification: {e}")


@otp_bp.route('/api/register/send-otp', methods=['POST'])
def send_registration_otp():
    """Send OTP for email verification during registration"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip()
        
        # Validate email address
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not email or not re.match(email_regex, email):
            return jsonify({'success': False, 'message': 'Please enter a valid email address'}), 400
        
        # Check if email already exists in database
        if find_user_by_email(email):
            return jsonify({'success': False, 'message': 'Email already registered! Please login or use a different email.'}), 400
        
        # Check cooldown (30 seconds) from MongoDB
        collection = _get_otp_collection()
        existing = collection.find_one({'email': email})
        if existing:
            sent_at = existing.get('sent_at')
            if sent_at:
                if isinstance(sent_at, str):
                    sent_at = datetime.fromisoformat(sent_at)
                if (datetime.utcnow() - sent_at).total_seconds() < 30:
                    remaining = 30 - int((datetime.utcnow() - sent_at).total_seconds())
                    return jsonify({'success': False, 'message': f'Please wait {remaining} seconds before requesting another OTP'}), 429
        
        # Generate OTP
        otp = OTPManager.generate_otp()
        
        # Store OTP in MongoDB (upsert - insert or update)
        otp_data = {
            'email': email,
            'otp': otp,
            'sent_at': datetime.utcnow(),
            'expires_at': datetime.utcnow() + timedelta(minutes=5),
            'verified': False
        }
        
        if existing:
            collection.update_one({'email': email}, {'$set': otp_data})
        else:
            collection.insert_one(otp_data)
        
        # Debug logging
        print(f"[OTP Generated] Email: {email}, OTP: '{otp}' (stored in MongoDB)")
        
        # Send OTP via Email using Brevo
        email_success, email_message = EmailGateway.send_otp_email(email, otp, purpose="verification")
        
        # Check if in development mode
        is_dev_mode = not (os.getenv('FLASK_ENV') == 'production' or os.getenv('RENDER'))
        
        if email_success:
            print(f"[Registration OTP] Sent to {email}")
            if is_dev_mode:
                print(f"[DEV MODE] OTP for {email}: {otp}")
            return jsonify({'success': True, 'message': 'OTP sent successfully to your email'})
        else:
            print(f"[INFO] Email delivery failed for {email}, OTP stored in DB for verification")
            if is_dev_mode:
                return jsonify({
                    'success': True, 
                    'message': 'OTP sent! Please check your email.',
                    'dev_otp': otp
                })
            return jsonify({'success': True, 'message': 'OTP sent! Please check your email.'})
            
    except Exception as e:
        print(f"[Error] send_registration_otp: {e}")
        return jsonify({'success': False, 'message': 'Failed to send OTP. Please try again.'}), 500


@otp_bp.route('/api/register/verify-otp', methods=['POST'])
def verify_registration_otp():
    """Verify OTP for email verification during registration"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip()
        otp = data.get('otp', '').strip()
        
        # Validate inputs
        if not email or not otp:
            return jsonify({'success': False, 'message': 'Email and OTP are required'}), 400
        
        # Check if OTP exists in MongoDB
        collection = _get_otp_collection()
        otp_record = collection.find_one({'email': email})
        
        if not otp_record:
            return jsonify({'success': False, 'message': 'No OTP found. Please request a new one.'}), 400
        
        # Check expiry
        expires_at = otp_record.get('expires_at')
        if isinstance(expires_at, str):
            expires_at = datetime.fromisoformat(expires_at)
        
        if datetime.utcnow() > expires_at:
            collection.delete_one({'email': email})
            return jsonify({'success': False, 'message': 'OTP expired. Please request a new one.'}), 400
        
        # Compare OTPs
        stored_otp = str(otp_record['otp']).strip()
        entered_otp = str(otp).strip()
        print(f"[OTP Debug] Email: {email}")
        print(f"[OTP Debug] Stored OTP: '{stored_otp}' (len={len(stored_otp)})")
        print(f"[OTP Debug] Entered OTP: '{entered_otp}' (len={len(entered_otp)})")
        print(f"[OTP Debug] Match: {stored_otp == entered_otp}")
        
        # Verify OTP
        if stored_otp == entered_otp:
            # Mark as verified in MongoDB
            collection.update_one({'email': email}, {'$set': {'verified': True}})
            print(f"[OTP Success] Email {email} verified successfully (saved to DB)")
            return jsonify({'success': True, 'message': 'Email verified successfully!'})
        else:
            print(f"[OTP Failed] Invalid OTP for {email}")
            return jsonify({'success': False, 'message': 'Invalid OTP. Please check and try again.'}), 400
            
    except Exception as e:
        print(f"[Error] verify_registration_otp: {e}")
        return jsonify({'success': False, 'message': 'Verification failed. Please try again.'}), 500
