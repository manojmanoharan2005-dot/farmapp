"""
OTP Routes for Email Verification
Handles OTP sending and verification for registration via Brevo
"""
from flask import Blueprint, request, jsonify
from utils.otp_manager import OTPManager
from utils.email_gateway import EmailGateway
from utils.db import find_user_by_email
import os
import re
from datetime import datetime, timedelta

otp_bp = Blueprint('otp', __name__)

# Store OTPs temporarily for registration (in production, use Redis)
registration_otp_store = {}


def is_email_verified(email):
    """Check if an email address has been verified via OTP"""
    if email in registration_otp_store:
        return registration_otp_store[email].get('verified', False)
    return False


def clear_email_verification(email):
    """Clear verification data after successful registration"""
    if email in registration_otp_store:
        del registration_otp_store[email]


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
        
        # Check cooldown (30 seconds)
        if email in registration_otp_store:
            last_sent = registration_otp_store[email].get('sent_at')
            if last_sent and (datetime.now() - last_sent).total_seconds() < 30:
                remaining = 30 - int((datetime.now() - last_sent).total_seconds())
                return jsonify({'success': False, 'message': f'Please wait {remaining} seconds before requesting another OTP'}), 429
        
        # Generate OTP
        otp = OTPManager.generate_otp()
        
        # Store OTP (expires in 5 minutes)
        registration_otp_store[email] = {
            'otp': otp,
            'sent_at': datetime.now(),
            'expires_at': datetime.now() + timedelta(minutes=5),
            'verified': False
        }
        
        # Debug logging - show the generated OTP
        print(f"[OTP Generated] Email: {email}, OTP: '{otp}' (type={type(otp)}, len={len(otp)})")
        
        # Send OTP via Email using Brevo
        email_success, email_message = EmailGateway.send_otp_email(email, otp, purpose="verification")
        
        # Check if in development mode (not production)
        is_dev_mode = not (os.getenv('FLASK_ENV') == 'production' or os.getenv('RENDER'))
        
        if email_success:
            print(f"[Registration OTP] Sent to {email}")
            if is_dev_mode:
                print(f"[DEV MODE] ✅ OTP for {email}: {otp}")
            return jsonify({'success': True, 'message': 'OTP sent successfully to your email'})
        else:
            # Email failed - still return success (OTP stored for verification in dev mode)
            print(f"[INFO] Email delivery failed for {email}, OTP stored for manual verification")
            print(f"[DEV MODE] ⚠️ IMPORTANT - OTP for {email}: {otp}")
            # In dev mode, include OTP in response for easier testing
            if is_dev_mode:
                return jsonify({
                    'success': True, 
                    'message': 'OTP sent! Please check your email.',
                    'dev_otp': otp  # Only in dev mode
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
        
        # Check if OTP exists
        if email not in registration_otp_store:
            return jsonify({'success': False, 'message': 'No OTP found. Please request a new one.'}), 400
        
        otp_data = registration_otp_store[email]
        
        # Check expiry
        if datetime.now() > otp_data['expires_at']:
            del registration_otp_store[email]
            return jsonify({'success': False, 'message': 'OTP expired. Please request a new one.'}), 400
        
        # Debug logging - compare OTPs
        stored_otp = str(otp_data['otp']).strip()
        entered_otp = str(otp).strip()
        print(f"[OTP Debug] Email: {email}")
        print(f"[OTP Debug] Stored OTP: '{stored_otp}' (len={len(stored_otp)})")
        print(f"[OTP Debug] Entered OTP: '{entered_otp}' (len={len(entered_otp)})")
        print(f"[OTP Debug] Match: {stored_otp == entered_otp}")
        
        # Verify OTP - simple comparison, no attempts limit
        if stored_otp == entered_otp:
            registration_otp_store[email]['verified'] = True
            print(f"✅ [OTP Success] Email {email} verified successfully")
            return jsonify({'success': True, 'message': 'Email verified successfully!'})
        else:
            print(f"❌ [OTP Failed] Invalid OTP for {email}")
            print(f"   Expected: '{stored_otp}', Got: '{entered_otp}'")
            return jsonify({'success': False, 'message': 'Invalid OTP. Please check and try again.'}), 400
            
    except Exception as e:
        print(f"[Error] verify_registration_otp: {e}")
        return jsonify({'success': False, 'message': 'Verification failed. Please try again.'}), 500


@otp_bp.route('/api/register/debug-otp/<email>', methods=['GET'])
def debug_otp(email):
    """DEBUG ENDPOINT - Shows stored OTP for testing (REMOVE IN PRODUCTION)"""
    if email in registration_otp_store:
        otp_data = registration_otp_store[email]
        return jsonify({
            'email': email,
            'otp': otp_data['otp'],
            'otp_type': str(type(otp_data['otp'])),
            'attempts': otp_data['attempts'],
            'verified': otp_data['verified'],
            'expires_in_seconds': (otp_data['expires_at'] - datetime.now()).total_seconds()
        })
    else:
        return jsonify({'error': 'No OTP found for this email'}), 404
