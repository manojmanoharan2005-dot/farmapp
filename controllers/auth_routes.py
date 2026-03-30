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
       # HTML version with high-end professional aesthetic
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background-color: #f9fafb;
                margin: 0; padding: 0;
            }}
            .container {{
                max-width: 600px;
                margin: 40px auto;
                background-color: #ffffff;
                border: 1px solid #e5e7eb;
                border-radius: 8px;
                overflow: hidden;
            }}
            .header {{
                background-color: #111827;
                padding: 32px;
                text-align: center;
            }}
            .header h1 {{
                color: #ffffff;
                font-size: 24px;
                margin: 0;
                font-weight: 700;
            }}
            .content {{
                padding: 48px;
            }}
            .title {{
                font-size: 20px;
                font-weight: 700;
                color: #111827;
                margin-bottom: 24px;
            }}
            .text {{
                font-size: 16px;
                color: #4b5563;
                line-height: 1.6;
                margin-bottom: 32px;
            }}
            .button-container {{
                text-align: center;
                margin: 40px 0;
            }}
            .button {{
                background-color: #111827;
                color: #ffffff !important;
                padding: 16px 32px;
                text-decoration: none;
                border-radius: 6px;
                font-weight: 600;
                display: inline-block;
            }}
            .notice {{
                font-size: 14px;
                color: #92400e;
                background-color: #fffbeb;
                padding: 16px;
                border-left: 4px solid #f59e0b;
                border-radius: 4px;
                margin: 32px 0;
            }}
            .footer {{
                padding: 32px;
                background-color: #f9fafb;
                text-align: center;
                border-top: 1px solid #e5e7eb;
            }}
            .footer p {{
                font-size: 12px;
                color: #9ca3af;
                margin: 4px 0;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Smart Farming Assistant</h1>
            </div>
            <div class="content">
                <p class="title">Secure Password Reset</p>
                <p class="text">
                    We received a request to reset your password. To ensure the security of your account, please click the button below to choose a new password. This link is unique and will expire shortly.
                </p>
                
                <div class="button-container">
                    <a href="{reset_link}" class="button">Reset Your Password</a>
                </div>
                
                <div class="notice">
                    <strong>Security Reminder:</strong> This link is active for <strong>15 minutes</strong>. If you did not initiate this request, please disregard this email.
                </div>
            </div>
            <div class="footer">
                <p>&copy; 2026 Smart Farming Assistant Inc. All rights reserved.</p>
                <p>123 Agri-Tech Square, Bangalore, KA, India</p>
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
    if not re.search(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?]', password):
        return False, "Password must contain at least one special character (!@#$%^&* etc.)"
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
            return render_template('login.html', email=email)
    
    return render_template('login.html')

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    # Load states and districts
    try:
        from utils.db import get_static_config
        states_districts = get_static_config('states_districts')
        if not states_districts:
            raise FileNotFoundError("Static config states_districts not found")
    except Exception as e:
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
        
        # Preserved form data to repopulate on errors
        form_data = {
            'name': name,
            'email': email,
            'phone': phone,
            'pincode': pincode,
            'state': state,
            'district': district,
            'village': village
        }
        
        # Check if passwords match
        if password != confirm_password:
            flash('🔒 Passwords do not match. Please try again.', 'error')
            return render_template('register.html', states_districts=states_districts, form_data=form_data)
        
        # Validate password strength
        is_strong, message = validate_password_strength(password)
        if not is_strong:
            flash(f'🔒 {message}', 'warning')
            return render_template('register.html', states_districts=states_districts, form_data=form_data)
        
        # Check if user already exists by email
        if find_user_by_email(email):
            flash('⚠️ Email already registered! Please use a different email or login.', 'warning')
            return render_template('register.html', states_districts=states_districts, form_data=form_data)
        
        # Check if phone number is already registered
        if find_user_by_phone(phone):
            flash('⚠️ Phone number already registered! Please use a different phone number or login.', 'warning')
            return render_template('register.html', states_districts=states_districts, form_data=form_data)
        
        # Check if email is verified via OTP
        if not is_email_verified(email):
            flash('⚠️ Please verify your email address with OTP first.', 'warning')
            return render_template('register.html', states_districts=states_districts, form_data=form_data)
        
        # Hash password and create user
        hashed_password = hash_password(password)
        user = create_user(name, email, hashed_password, phone, state, district, pincode, village)
        
        # Clean up OTP store
        clear_email_verification(email)
        
        # Auto-login: set session so user goes directly to dashboard
        db = get_db()
        if hasattr(db, 'users'):
            created_user = db.users.find_one({'email': email})
        else:
            created_user = find_user_by_email(email)
        
        if created_user:
            session['user_id'] = str(created_user['_id'])
            session['user_name'] = created_user['name']
            session['user_email'] = created_user['email']
            session['user_phone'] = created_user.get('phone', 'Not provided')
            session['user_state'] = created_user.get('state', 'Not provided')
            session['user_district'] = created_user.get('district', 'Not provided')
            session['user_village'] = created_user.get('village', '')
            session['user_pincode'] = created_user.get('pincode', '')
        
        flash('🎉 Registration successful! Welcome to Smart Farming Assistant.', 'success')
        return redirect(url_for('dashboard.dashboard'))
    
    return render_template('register.html', states_districts=states_districts)

@auth_bp.route('/logout')
def logout():
    user_name = session.get('user_name', 'User')
    clear_session()
    flash(f'👋 Goodbye {user_name}! You have been logged out successfully.', 'success')
    return redirect(url_for('index'))


