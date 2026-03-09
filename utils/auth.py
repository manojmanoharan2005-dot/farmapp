import bcrypt
from flask import session, redirect, url_for
from functools import wraps
from werkzeug.security import check_password_hash

def hash_password(password):
    """Hash a password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

def check_password(password, hashed):
    """Check if password matches hashed password (supports both bcrypt and pbkdf2)"""
    if isinstance(hashed, str):
        # Handle werkzeug/pbkdf2 hashes (e.g. from older password resets)
        if hashed.startswith('pbkdf2:') or hashed.startswith('scrypt:'):
            return check_password_hash(hashed, password)
        # Handle string representation of bytes (e.g. "b'$2b$...'")
        if hashed.startswith("b'") and hashed.endswith("'"):
            hashed = hashed[2:-1]
        hashed = hashed.encode('utf-8')
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed)
    except (ValueError, TypeError):
        return False

def login_required(f):
    """Decorator to require login for certain routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return decorated_function

def create_session(user):
    """Create user session"""
    session['user_id'] = str(user['_id'])
    session['user_name'] = user['name']
    session['user_email'] = user['email']
    session['user_phone'] = user.get('phone', '')

def clear_session():
    """Clear user session"""
    session.clear()
