"""
OTP Routes for Email Verification
Handles OTP sending and verification for registration via Brevo
"""
from flask import Blueprint, request, jsonify
from utils.otp_manager import OTPManager
from utils.email_gateway import EmailGateway
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
            'attempts': 0,
            'verified': False
        }
        
        # Send OTP via Email using Brevo
        email_success, email_message = EmailGateway.send_otp_email(email, otp, purpose="verification")
        
        if email_success:
            print(f"[Registration OTP] Sent to {email}")
            return jsonify({'success': True, 'message': 'OTP sent successfully to your email'})
        else:
            # Email failed - still return success (OTP stored for verification in dev mode)
            print(f"[INFO] Email delivery failed for {email}, OTP stored for manual verification")
            print(f"[DEV MODE] OTP for {email}: {otp}")
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
        
        # Check attempts
        if otp_data['attempts'] >= 3:
            del registration_otp_store[email]
            return jsonify({'success': False, 'message': 'Too many failed attempts. Please request a new OTP.'}), 400
        
        # Verify OTP
        if otp_data['otp'] == otp:
            registration_otp_store[email]['verified'] = True
            return jsonify({'success': True, 'message': 'Email verified successfully!'})
        else:
            registration_otp_store[email]['attempts'] += 1
            remaining = 3 - registration_otp_store[email]['attempts']
            return jsonify({'success': False, 'message': f'Invalid OTP. {remaining} attempts remaining.'}), 400
            
    except Exception as e:
        print(f"[Error] verify_registration_otp: {e}")
        return jsonify({'success': False, 'message': 'Verification failed. Please try again.'}), 500
