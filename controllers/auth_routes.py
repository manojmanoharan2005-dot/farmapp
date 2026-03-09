from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db import create_user, find_user_by_email, get_db, find_user_by_phone, update_user_password
from utils.auth import hash_password, check_password, create_session, clear_session
from controllers.otp_routes import is_email_verified, clear_email_verification
import json
import os
import re
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta

auth_bp = Blueprint('auth', __name__)

# Rate limiting for password reset requests (in production, use Redis)
reset_request_tracker = {}

def rate_limit_reset_request(email, max_requests=3, time_window_minutes=15):
    """
    Rate limit password reset requests to prevent abuse
    Returns (allowed, message)
    """
    now = datetime.now()
    
    if email in reset_request_tracker:
        requests = reset_request_tracker[email]
        # Remove old requests outside time window
        requests = [req_time for req_time in requests 
                   if now - req_time < timedelta(minutes=time_window_minutes)]
        
        if len(requests) >= max_requests:
            return False, f"Too many reset requests. Please try again after {time_window_minutes} minutes."
        
        requests.append(now)
        reset_request_tracker[email] = requests
    else:
        reset_request_tracker[email] = [now]
    
    return True, None

def send_reset_email(to_email, reset_link):
    """
    Send password reset email via SMTP Gmail
    Returns True if email sent successfully, False otherwise
    """
    # Email configuration from environment variables
    smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
    smtp_port = int(os.getenv('SMTP_PORT', 587))
    sender_email = os.getenv('SMTP_EMAIL', '')
    sender_password = os.getenv('SMTP_PASSWORD', '')
    
    if not sender_email or not sender_password:
        print("[WARNING] Email not configured. Please set SMTP_EMAIL and SMTP_PASSWORD environment variables.")
        print(f"[DEV MODE] Reset link: {reset_link}")
        return False
    
    # Create email message
    message = MIMEMultipart("alternative")
    message["Subject"] = "🌾 Farming Assistant - Reset Your Password"
    message["From"] = f"Farming Assistant <{sender_email}>"
    message["To"] = to_email
    
    # Plain text version
    text = f"""
    Farming Assistant - Password Reset Request
    
    Hello,
    
    We received a request to reset your password. Click the link below to reset it:
    
    {reset_link}
    
    This link will expire in 15 minutes for security reasons.
    
    If you didn't request this password reset, please ignore this email. Your password will remain unchanged.
    
    Best regards,
    Farming Assistant Team
    """
    
    # HTML version with farmer-friendly green theme
    html = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background: #f0f9ff; margin: 0; padding: 40px;">
        <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 30px; text-align: center;">
                <h1 style="color: white; margin: 0; font-size: 28px;">🌾 Farming Assistant</h1>
            </div>
            
            <!-- Content -->
            <div style="padding: 40px;">
                <h2 style="color: #1f2937; margin: 0 0 20px 0;">Password Reset Request</h2>
                <p style="color: #4b5563; line-height: 1.6; font-size: 16px;">
                    Hello,
                </p>
                <p style="color: #4b5563; line-height: 1.6; font-size: 16px;">
                    We received a request to reset your password. Click the button below to create a new password:
                </p>
                
                <!-- Reset Button -->
                <div style="text-align: center; margin: 35px 0;">
                    <a href="{reset_link}" style="background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 16px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 18px; display: inline-block; box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);">
                        Reset Password
                    </a>
                </div>
                
                <!-- Security Notice -->
                <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 25px 0; border-radius: 4px;">
                    <p style="color: #92400e; margin: 0; font-size: 14px;">
                        <strong>⏰ Important:</strong> This link will expire in 15 minutes for your security.
                    </p>
                </div>
                
                <p style="color: #6b7280; font-size: 14px; line-height: 1.6;">
                    If you didn't request this password reset, please ignore this email. Your password will remain unchanged.
                </p>
                
                <!-- Alternative Link -->
                <p style="color: #9ca3af; font-size: 12px; margin-top: 30px;">
                    If the button doesn't work, copy and paste this link into your browser:<br>
                    <span style="color: #10b981; word-break: break-all;">{reset_link}</span>
                </p>
            </div>
            
            <!-- Footer -->
            <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
                <p style="color: #6b7280; font-size: 12px; margin: 0;">
                    © 2026 Farming Assistant | Helping Farmers Grow Better
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    part1 = MIMEText(text, "plain")
    part2 = MIMEText(html, "html")
    message.attach(part1)
    message.attach(part2)
    
    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, to_email, message.as_string())
        print(f"[SUCCESS] Password reset email sent to {to_email}")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to send email: {e}")
        return False

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
    return True, "Password is strong"

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        # Get database connection
        db = get_db()
        
        # Find user WITH password for authentication
        if hasattr(db, 'users'):
            users = db.users
            user_with_password = users.find_one({'email': email})
        else:
            # Handle mock database
            user_with_password = find_user_by_email(email)
        
        if user_with_password and check_password(password, user_with_password['password']):
            # Create session with user data (excluding password)
            session['user_id'] = str(user_with_password['_id'])
            session['user_name'] = user_with_password['name']
            session['user_email'] = user_with_password['email']
            session['user_phone'] = user_with_password.get('phone', 'Not provided')
            session['user_state'] = user_with_password.get('state', 'Not provided')
            session['user_district'] = user_with_password.get('district', 'Not provided')
            session['user_village'] = user_with_password.get('village', '')
            session['user_pincode'] = user_with_password.get('pincode', '')
            
            # Store last login time
            now = datetime.now()
            session['user_last_login'] = user_with_password.get('last_login')
            
            # Update last_login in database
            try:
                if hasattr(db, 'users'):
                    db.users.update_one(
                        {'_id': user_with_password['_id']},
                        {'$set': {'last_login': now}}
                    )
            except Exception as e:
                print(f"[Warning] Could not update last_login: {e}")
            
            flash('🎉 Login successful! Welcome back, ' + user_with_password['name'] + '!', 'success')
            return redirect(url_for('dashboard.dashboard'))
        else:
            flash('❌ Invalid email or password. Please try again.', 'error')
            return render_template('login.html')
    
    return render_template('login.html')

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    # Load states and districts
    try:
        # Load from data directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        filepath = os.path.join(script_dir, '..', 'data', 'states_districts.json')
        with open(filepath, 'r', encoding='utf-8') as f:
            states_districts = json.load(f)
    except FileNotFoundError as e:
        print(f"Warning: states_districts.json not found: {e}")
        # Fallback states and districts
        states_districts = {
            "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
            "Karnataka": ["Bangalore", "Mysore", "Mangalore", "Hubli"],
            "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Salem"]
        }
    
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        password = request.form['password']
        confirm_password = request.form.get('confirm_password', '')
        phone = request.form['phone']
        pincode = request.form.get('pincode', '')
        state = request.form['state']
        district = request.form['district']
        village = request.form.get('village', '')
        
        # Check if passwords match
        if password != confirm_password:
            flash('🔒 Passwords do not match. Please try again.', 'error')
            return render_template('register.html', states_districts=states_districts)
        
        # Check if user already exists by email
        if find_user_by_email(email):
            flash('⚠️ Email already registered! Please use a different email or login.', 'warning')
            return render_template('register.html', states_districts=states_districts)
        
        # Check if phone number is already registered
        if find_user_by_phone(phone):
            flash('⚠️ Phone number already registered! Please use a different phone number or login.', 'warning')
            return render_template('register.html', states_districts=states_districts)
        
        # Check if email is verified via OTP
        if not is_email_verified(email):
            flash('⚠️ Please verify your email address with OTP first.', 'warning')
            return render_template('register.html', states_districts=states_districts)
        
        # Validate password strength
        is_strong, message = validate_password_strength(password)
        if not is_strong:
            flash(f'🔒 {message}', 'warning')
            return render_template('register.html', states_districts=states_districts)
        
        # Hash password and create user
        hashed_password = hash_password(password)
        create_user(name, email, hashed_password, phone, state, district, pincode, village)
        
        # Clean up OTP store
        clear_email_verification(email)
        
        flash('✅ Registration successful! Welcome to Smart Farming Assistant. Please login.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('register.html', states_districts=states_districts)

@auth_bp.route('/logout')
def logout():
    user_name = session.get('user_name', 'User')
    clear_session()
    flash(f'👋 Goodbye {user_name}! You have been logged out successfully.', 'success')
    return redirect(url_for('index'))


