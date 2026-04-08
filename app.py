import os
import sys
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables FIRST before any other imports
load_dotenv()

# Fix WinError 10038 on Windows: prevent werkzeug from using watchdog reloader
if sys.platform == 'win32':
    try:
        sys.modules['watchdog'] = None
        sys.modules['watchdog.observers'] = None
        sys.modules['watchdog.events'] = None
    except Exception:
        pass

# Console colors and formatting
class ConsoleColors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_banner():
    """Print a nice startup banner"""
    banner = f"""{ConsoleColors.OKCYAN}{ConsoleColors.BOLD}
    ╔══════════════════════════════════════════════╗
    ║        🌱 Smart Farming Assistant 🌱        ║
    ║                  v2.0.0                      ║
    ╚══════════════════════════════════════════════╝{ConsoleColors.ENDC}
    """
    print(banner)
    print(f"{ConsoleColors.HEADER}🚀 Starting application...{ConsoleColors.ENDC}\n")

def log_success(message):
    """Print success message with formatting"""
    print(f"{ConsoleColors.OKGREEN}✅ [SUCCESS]{ConsoleColors.ENDC} {message}")

def log_warning(message):
    """Print warning message with formatting"""
    print(f"{ConsoleColors.WARNING}⚠️  [WARNING]{ConsoleColors.ENDC} {message}")

def log_error(message):
    """Print error message with formatting"""
    print(f"{ConsoleColors.FAIL}❌ [ERROR]{ConsoleColors.ENDC} {message}")

def log_info(message):
    """Print info message with formatting"""
    print(f"{ConsoleColors.OKBLUE}ℹ️  [INFO]{ConsoleColors.ENDC} {message}")

from flask import Flask, render_template, session, redirect, url_for, request
from flask_cors import CORS
from controllers.auth_routes import auth_bp
from controllers.otp_routes import otp_bp
from controllers.dashboard_routes import dashboard_bp
from controllers.crop_routes import crop_bp
from controllers.fertilizer_routes import fertilizer_bp
from controllers.growing_routes import growing_bp
from controllers.market_routes import market_bp
from controllers.chat_routes import chat_bp
from controllers.report_routes import report_bp
from controllers.forgot_password_routes import forgot_password_bp
from controllers.buyer_connect_routes import buyer_connect_bp
from controllers.equipment_sharing_routes import equipment_sharing_bp
from controllers.resources_routes import resources_bp
from controllers.market_scheduler import init_scheduler
from utils.db import init_db

# Print startup banner
print_banner()

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'smart_farming_assistant_2024_secret_key')
app.config['UPLOAD_FOLDER'] = 'static/uploads'

# Detect environment
IS_PRODUCTION = os.environ.get('FLASK_ENV') == 'production' or os.environ.get('RENDER')

if IS_PRODUCTION:
    # Production: cache static assets for 1 day
    app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 86400
    app.config['TEMPLATES_AUTO_RELOAD'] = False
    # Required for cross-site session cookies (Flutter web localhost -> Render).
    app.config['SESSION_COOKIE_SECURE'] = True
    app.config['SESSION_COOKIE_SAMESITE'] = 'None'
else:
    # Development: no caching
    app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
    app.config['TEMPLATES_AUTO_RELOAD'] = True
    app.config['SESSION_COOKIE_SECURE'] = False
    app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

app.config['SESSION_COOKIE_HTTPONLY'] = True

# Enable CORS for Flutter web clients (localhost during development) and
# allow cookies/session credentials to flow in cross-origin requests.
allowed_origins = [
    origin.strip()
    for origin in os.environ.get(
        'CORS_ALLOWED_ORIGINS',
        'http://localhost:3000,http://localhost:5000,http://localhost:8080',
    ).split(',')
    if origin.strip()
]

CORS(
    app,
    resources={
        r"/*": {
            "origins": allowed_origins
            + [
                r"http://localhost:\d+",
                r"http://127\.0\.0\.1:\d+",
                r"https://localhost:\d+",
                r"https://127\.0\.0\.1:\d+",
            ],
            "methods": ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
        }
    },
    supports_credentials=True,
)

# Enable gzip compression
try:
    from flask_compress import Compress
    Compress(app)
except ImportError:
    pass

@app.after_request
def add_header(response):
    if IS_PRODUCTION:
        # Cache static assets (CSS, JS, fonts, images) for 1 day
        if response.content_type and any(
            ct in response.content_type
            for ct in ['text/css', 'javascript', 'font', 'image/', 'application/octet-stream']
        ):
            response.headers['Cache-Control'] = 'public, max-age=86400'
        else:
            # Don't cache HTML/API responses
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    else:
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'

    # Extra CORS safety for dynamic localhost ports used by Flutter web.
    origin = request.headers.get('Origin', '')
    localhost_origin = (
        origin.startswith('http://localhost:')
        or origin.startswith('https://localhost:')
        or origin.startswith('http://127.0.0.1:')
        or origin.startswith('https://127.0.0.1:')
    )
    configured_origin = origin in allowed_origins

    if origin and (localhost_origin or configured_origin):
        response.headers['Access-Control-Allow-Origin'] = origin
        response.headers['Access-Control-Allow-Credentials'] = 'true'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = request.headers.get(
            'Access-Control-Request-Headers',
            'Content-Type, Authorization',
        )
    return response

log_info(f"Flask application initialized with secret key")
log_info(f"Upload folder: {app.config['UPLOAD_FOLDER']}")

# Initialize MongoDB connection
log_info("Initializing database connection...")
try:
    init_db(app)
    log_success("Database initialized successfully!")
except Exception as e:
    log_warning(f"Database initialization warning: {e}")
    log_warning("App will run with limited functionality")

# Initialize market price scheduler for daily auto-updates
log_info("Initializing market price scheduler...")
try:
    scheduler = init_scheduler(app)
    log_success("Market price scheduler initialized!")
except Exception as e:
    log_warning(f"Scheduler initialization failed: {e}")

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(otp_bp)
app.register_blueprint(dashboard_bp)
app.register_blueprint(crop_bp)
app.register_blueprint(fertilizer_bp)
app.register_blueprint(growing_bp)
app.register_blueprint(market_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(report_bp)
app.register_blueprint(forgot_password_bp)
app.register_blueprint(buyer_connect_bp)
app.register_blueprint(equipment_sharing_bp)
app.register_blueprint(resources_bp)
# app.register_blueprint(community_bp)

# Global context processor for date and user info
@app.context_processor
def inject_globals():
    user = None
    stats = None
    if 'user_id' in session:
        try:
            from utils.db import find_user_by_id, get_user_crops, get_user_fertilizers, get_user_growing_activities
            user_id = session['user_id']
            user = find_user_by_id(user_id)
            
            if user:
                # Handle datetime fields
                if 'created_at' in user and isinstance(user['created_at'], str):
                    try: 
                        user['created_at'] = datetime.fromisoformat(user['created_at'].replace('Z', '+00:00'))
                    except: pass
                
                # Fetch minimal stats for the global profile modal
                crops = get_user_crops(user_id)
                ferts = get_user_fertilizers(user_id)
                activities = get_user_growing_activities(user_id)
                
                stats = {
                    'crops_suggested': len(crops) if crops else 0,
                    'fertilizers_saved': len(ferts) if ferts else 0,
                    'active_crops': len(activities) if activities else 0
                }
        except Exception as e:
            print(f"Error in global context processor: {e}")

    return {
        'current_date': datetime.now().strftime('%Y-%m-%d'),
        'current_time': datetime.now().strftime('%H:%M'),
        'user_logged_in': 'user_id' in session,
        'user_name': session.get('user_name', ''),
        'user': user,
        'stats': stats
    }

# Helper function for forgot password routes to access database
def get_db():
    from pymongo import MongoClient
    client = MongoClient(os.environ.get('MONGODB_URI'))
    return client.smartfarming

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/features')
def features():
    return render_template('features.html')

# Create upload directory
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Vercel serverless function handler
def handler(request):
    return app(request)

def print_route_summary():
    """Print a summary of registered routes"""
    print(f"\n{ConsoleColors.OKCYAN}{ConsoleColors.BOLD}📋 REGISTERED ROUTES SUMMARY:{ConsoleColors.ENDC}")
    route_count = 0
    endpoints = []
    
    for rule in app.url_map.iter_rules():
        if rule.endpoint not in ['static']:
            route_count += 1
            endpoints.append(f"  🔗 {rule.rule} [{', '.join(rule.methods - {'HEAD', 'OPTIONS'})}]")
    
    # Group by blueprint
    blueprints = ['auth', 'dashboard', 'crop', 'fertilizer', 'growing', 'market', 'chat', 'report']
    for bp in blueprints:
        bp_routes = [e for e in endpoints if f'/{bp}/' in e]
        if bp_routes:
            print(f"\n{ConsoleColors.OKBLUE}📁 {bp.upper()} Routes:{ConsoleColors.ENDC}")
            for route in bp_routes[:3]:  # Show first 3 routes per blueprint
                print(route)
            if len(bp_routes) > 3:
                print(f"    ... and {len(bp_routes) - 3} more")
    
    print(f"\n{ConsoleColors.OKGREEN}✨ Total routes registered: {route_count}{ConsoleColors.ENDC}")

def print_startup_complete():
    """Print startup completion message"""
    port = int(os.environ.get('PORT', 5000))
    print(f"\n{ConsoleColors.OKGREEN}{ConsoleColors.BOLD}" + "="*50)
    print(f"🎉 SMART FARMING ASSISTANT READY! 🎉")
    print(f"📡 Server running on: http://0.0.0.0:{port}")
    print(f"🌐 Access the application in your browser")
    print(f"🔧 Debug mode: {'ON' if app.debug else 'OFF'}")
    print(f"📅 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*50 + f"{ConsoleColors.ENDC}")
    print(f"\n{ConsoleColors.OKCYAN}💡 Tips:{ConsoleColors.ENDC}")
    print(f"  • Use Ctrl+C to stop the server")
    print(f"  • Visit /about for application info")
    print(f"  • Check /dashboard after login\n")

if __name__ == '__main__':
    # Setup complete - show route summary
    print_route_summary()
    
    # Show startup complete message
    print_startup_complete()
    
    # Get port from environment variable (Render sets this)
    port = int(os.environ.get('PORT', 5000))
    
    # Start the Flask development server with DEBUG enabled
    try:
        app.run(debug=True, host='0.0.0.0', port=port)
    except KeyboardInterrupt:
        print(f"\n{ConsoleColors.WARNING}🛑 Server stopped by user{ConsoleColors.ENDC}")
        print(f"{ConsoleColors.OKBLUE}👋 Thank you for using Smart Farming Assistant!{ConsoleColors.ENDC}")
    except Exception as e:
        log_error(f"Failed to start server: {e}")
