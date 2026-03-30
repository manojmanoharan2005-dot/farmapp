from datetime import datetime
import os
import json
from pymongo import MongoClient
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# MongoDB Atlas connection string from environment variable
MONGODB_URI = os.getenv('MONGODB_URI')

# Local file-based storage directory and file paths (used when MongoDB is not available)
DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data')
DATA_DIR = os.path.abspath(DATA_DIR)

USERS_FILE = os.path.join(DATA_DIR, 'users.json')
CROPS_FILE = os.path.join(DATA_DIR, 'crops.json')
FERTILIZERS_FILE = os.path.join(DATA_DIR, 'fertilizers.json')
DISEASES_FILE = os.path.join(DATA_DIR, 'diseases.json')
GROWING_FILE = os.path.join(DATA_DIR, 'growing_activities.json')
EQUIPMENT_FILE = os.path.join(DATA_DIR, 'equipment.json')
NOTIFICATIONS_FILE = os.path.join(DATA_DIR, 'notifications.json')
EXPENSES_FILE = os.path.join(DATA_DIR, 'expenses.json')

client = None
db = None

def init_db(app):
    global client, db
    
    # Create data directory for backups (optional)
    os.makedirs(DATA_DIR, exist_ok=True)
    
    # MongoDB is REQUIRED - attempt connection
    if not MONGODB_URI or MONGODB_URI == 'your-mongodb-connection-string-here':
        print("\n" + "="*60)
        print("⚠️  WARNING: MongoDB URI not configured!")
        print("="*60)
        print("Please update your .env file with a valid MONGODB_URI")
        print("All data will be stored in MongoDB collections, not JSON files.")
        print("="*60 + "\n")
        # Use mock database as fallback for development
        db = MockDatabase()
        return
    
    try:
        print("[INFO] 🔌 Connecting to MongoDB Atlas...")
        client = MongoClient(MONGODB_URI, 
                           serverSelectionTimeoutMS=5000,
                           connectTimeoutMS=5000,
                           socketTimeoutMS=10000,
                           retryWrites=True,
                           maxPoolSize=10,
                           minPoolSize=1)
        
        # Extract database name from URI or use default
        db_name = 'smartfarming'
        if '/' in MONGODB_URI.split('mongodb.net/')[-1]:
            db_name = MONGODB_URI.split('mongodb.net/')[-1].split('?')[0].strip('/')
        
        db = client[db_name]
        
        # Test the connection
        client.admin.command('ping')
        print(f"✅ Successfully connected to MongoDB Atlas!")
        print(f"📊 Using database: {db_name}")
        print(f"📁 Collections will store all data (users, crops, equipment, etc.)")
        
        # Create indexes for better performance
        try:
            # Create unique index on email
            try:
                db.users.create_index("email", unique=True)
                print("✅ Email index created successfully")
            except Exception as e:
                print(f"ℹ️  Email index note: {e}")
            
            # Create index on phone (not unique to avoid conflicts)
            try:
                db.users.create_index("phone")
                print("✅ Phone index created successfully")
            except Exception as e:
                print(f"ℹ️  Phone index note: {e}")
                
        except Exception as e:
            print(f"ℹ️  Index creation note: {e}")
            
    except Exception as e:
        print("\n" + "="*60)
        print(f"❌ MongoDB connection failed: {e}")
        print("="*60)
        print("Common issues:")
        print("  1. Check if your IP address is whitelisted in MongoDB Atlas")
        print("  2. Verify the connection string in .env file")
        print("  3. Ensure network connectivity")
        print("  4. Check username and password are correct")
        print("="*60 + "\n")
        # Use mock database as fallback
        db = MockDatabase()
        print("⚠️  Using fallback file-based storage for development")

class MockDatabase:
    """Enhanced Mock database that persists to JSON files when MongoDB is not available"""
    def __init__(self):
        print("[INFO] Mock database initializing with persistent file storage")
    
    @property
    def users(self):
        return MockCollection('users', USERS_FILE, is_dict=True)
    
    @property 
    def crops(self):
        return MockCollection('crops', CROPS_FILE)
    
    @property
    def crop_listings(self):
        return MockCollection('crop_listings', LISTINGS_FILE)
        
    @property
    def fertilizers(self):
        return MockCollection('fertilizers', FERTILIZERS_FILE)
        
    @property
    def diseases(self):
        return MockCollection('diseases', DISEASES_FILE)

    @property
    def equipment_listings(self):
        return MockCollection('equipment_listings', EQUIPMENT_LISTINGS_FILE)

    @property
    def notifications(self):
        return MockCollection('notifications', NOTIFICATIONS_FILE)

    @property
    def expenses(self):
        return MockCollection('expenses', EXPENSES_FILE)

    @property
    def otps(self):
        OTPS_FILE = os.path.join(DATA_DIR, 'otps.json')
        return MockCollection('otps', OTPS_FILE)

    @property
    def market_prices(self):
        MARKET_FILE = os.path.join(DATA_DIR, 'market_prices.json')
        return MockCollection('market_prices', MARKET_FILE)

    @property
    def growing_activities(self):
        GROWING_FILE = os.path.join(DATA_DIR, 'growing_activities.json')
        return MockCollection('growing_activities', GROWING_FILE)

    @property
    def static_configs(self):
        CONFIGS_FILE = os.path.join(DATA_DIR, 'static_configs.json')
        return MockCollection('static_configs', CONFIGS_FILE, is_dict=True)

    @property
    def password_reset_tokens(self):
        TOKENS_FILE = os.path.join(DATA_DIR, 'reset_tokens.json')
        return MockCollection('password_reset_tokens', TOKENS_FILE)

    @property
    def registration_otps(self):
        REG_OTPS_FILE = os.path.join(DATA_DIR, 'registration_otps.json')
        return MockCollection('registration_otps', REG_OTPS_FILE)

class MockCollection:
    def __init__(self, name, file_path, is_dict=False):
        self.name = name
        self.file_path = file_path
        self.is_dict = is_dict
        self._ensure_file()
        
    def _ensure_file(self):
        if not os.path.exists(self.file_path):
            os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
            with open(self.file_path, 'w', encoding='utf-8') as f:
                json.dump({} if self.is_dict else [], f)

    def _load(self):
        try:
            if os.path.exists(self.file_path):
                with open(self.file_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except Exception as e:
            print(f"[MOCK DB ERROR] Failed to load {self.name}: {e}")
        return {} if self.is_dict else []

    def _save(self, data):
        try:
            # Create a separate process or lock if possible? For now, simple write.
            with open(self.file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, default=str, ensure_ascii=False)
        except Exception as e:
            print(f"[MOCK DB ERROR] Failed to save {self.name}: {e}")

    def find_one(self, query):
        data = self._load()
        if self.is_dict:
            if 'email' in query:
                return data.get(query['email'])
            elif 'mobile_number' in query:
                for user in data.values():
                    if user.get('mobile_number') == query['mobile_number']:
                        return user
        
        items = data.values() if self.is_dict else data
        for item in items:
            match = True
            for key, val in query.items():
                if key == '_id':
                    if str(item.get('_id')) != str(val):
                        match = False
                        break
                elif item.get(key) != val:
                    match = False
                    break
            if match:
                return item
        return None
    
    def insert_one(self, data):
        all_data = self._load()
        import uuid
        if '_id' not in data:
            data['_id'] = str(uuid.uuid4())
        
        if self.is_dict:
            key = data.get('email', data['_id'])
            all_data[key] = data
        else:
            all_data.append(data)
            
        self._save(all_data)
        return type('MockResult', (), {'inserted_id': data['_id']})()

    def insert_many(self, data_list):
        all_data = self._load()
        import uuid
        ids = []
        for data in data_list:
            if '_id' not in data:
                data['_id'] = str(uuid.uuid4())
            ids.append(data['_id'])
            if self.is_dict:
                key = data.get('email', data['_id'])
                all_data[key] = data
            else:
                all_data.append(data)
        
        self._save(all_data)
        return type('MockResult', (), {'inserted_ids': ids})()
    
    def find(self, query=None, sort=None):
        data = self._load()
        items = list(data.values()) if self.is_dict else list(data)
        
        if query:
            filtered = []
            for item in items:
                match = True
                for key, val in query.items():
                    if key == '$or':
                        or_match = False
                        for cond in val:
                            if all(item.get(k) == v for k, v in cond.items()):
                                or_match = True
                                break
                        if not or_match:
                            match = False
                            break
                    elif key == '_id':
                        if str(item.get('_id')) != str(val):
                            match = False
                            break
                    elif item.get(key) != val:
                        match = False
                        break
                if match:
                    filtered.append(item)
            items = filtered

        class SortableList(list):
            def sort(self, key_name, direction=-1):
                # Mock behavior: sort by key_name
                super().sort(key=lambda x: x.get(key_name, '') if x.get(key_name) is not None else '', reverse=(direction == -1))
                return self
            
            def limit(self, count):
                return self[:count]
        
        result_list = SortableList(items)
        if sort:
            # Handle list of tuples like [('created_at', -1)]
            for field, direction in sort:
                result_list.sort(field, direction)
        
        return result_list
    
    def update_one(self, query, update):
        all_data = self._load()
        items = all_data.values() if self.is_dict else all_data
        
        found = False
        for item in items:
            match = True
            for key, val in query.items():
                if key == '_id':
                    if str(item.get('_id')) != str(val):
                        match = False
                        break
                elif item.get(key) != val:
                    match = False
                    break
            
            if match:
                if '$set' in update:
                    item.update(update['$set'])
                if '$unset' in update:
                    for k in update['$unset']:
                        item.pop(k, None)
                if '$inc' in update:
                    for k, v in update['$inc'].items():
                        item[k] = item.get(k, 0) + v
                found = True
                break
        
        if found:
            self._save(all_data)
            return type('MockResult', (), {'modified_count': 1})()
        
        return type('MockResult', (), {'modified_count': 0})()

    def update_many(self, query, update):
        all_data = self._load()
        items = all_data.values() if self.is_dict else all_data
        modified_count = 0
        
        for item in items:
            match = True
            for key, val in query.items():
                if item.get(key) != val:
                    match = False
                    break
            
            if match:
                if '$set' in update:
                    item.update(update['$set'])
                modified_count += 1
        
        if modified_count > 0:
            self._save(all_data)
        return type('MockResult', (), {'modified_count': modified_count})()
    
    def delete_one(self, query):
        all_data = self._load()
        if self.is_dict:
            if 'email' in query and query['email'] in all_data:
                del all_data[query['email']]
                self._save(all_data)
                return type('MockResult', (), {'deleted_count': 1})()
        else:
            new_data = []
            deleted = False
            for item in all_data:
                match = True
                for key, val in query.items():
                    if str(item.get(key)) != str(val):
                        match = False
                        break
                if match and not deleted:
                    deleted = True
                else:
                    new_data.append(item)
            
            if deleted:
                self._save(new_data)
                return type('MockResult', (), {'deleted_count': 1})()
        
        return type('MockResult', (), {'deleted_count': 0})()

    def delete_many(self, query):
        all_data = self._load()
        if self.is_dict:
            return type('MockResult', (), {'deleted_count': 0})()
            
        new_data = []
        deleted_count = 0
        for item in all_data:
            match = True
            for key, val in query.items():
                if isinstance(val, dict) and '$lt' in val:
                    item_val = item.get(key)
                    if isinstance(item_val, str):
                        try:
                            item_val = datetime.fromisoformat(item_val)
                        except: pass
                    if item_val >= val['$lt']:
                        match = False
                elif item.get(key) != val:
                    match = False
                
            if match:
                deleted_count += 1
            else:
                new_data.append(item)
        
        if deleted_count > 0:
            self._save(new_data)
        return type('MockResult', (), {'deleted_count': deleted_count})()
    
    def create_index(self, field, unique=False):
        print(f"Mock index created for {field} (unique: {unique})")

def get_db():
    return db

def get_static_config(config_id):
    """Get a static config document from MongoDB"""
    try:
        if db is not None:
            doc = db.static_configs.find_one({"_id": config_id})
            if doc and "data" in doc:
                return doc["data"]
        
        # Fallback for legacy local JSON
        import json
        fallback_file = os.path.join(DATA_DIR, f"{config_id}.json")
        if os.path.exists(fallback_file):
            with open(fallback_file, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception as e:
        print(f"[ERROR] Error loading static config {config_id}: {e}")
    return {}


# User model functions
def create_user(name, email, password, phone, state, district, pincode='', village=''):
    """Create a new user and save to MongoDB database"""
    import uuid
    from bson import ObjectId
    
    # Generate unique ID
    user_id = str(uuid.uuid4())
    
    user_data = {
        'name': name,
        'email': email,
        'password': password.decode('utf-8') if isinstance(password, bytes) else password,
        'phone': phone,
        'pincode': pincode,
        'state': state,
        'district': district,
        'village': village,
        'created_at': datetime.utcnow(),
        'saved_crops': [],
        'saved_fertilizers': [],
        'disease_history': []
    }
    
    # Use MongoDB database
    if db is not None and hasattr(db, 'users'):
        try:
            result = db.users.insert_one(user_data.copy())
            print(f"✅ User created in MongoDB: {name} ({email}) - ID: {result.inserted_id}")
            return result
        except Exception as e:
            print(f"[MONGODB ERROR] Failed to create user: {e}")
            raise e
    else:
        print("[ERROR] MongoDB database not connected! Please check MONGODB_URI in .env file")
        raise Exception("Database not available. Please configure MongoDB connection.")

def find_user_by_email(email):
    """Find user by email - searches MongoDB database"""
    # Use MongoDB database
    if db is not None and hasattr(db, 'users'):
        try:
            users = db.users
            user = users.find_one({'email': email})
            if user:
                print(f"🔍 User found in MongoDB: {email}")
                return user
            else:
                print(f"❌ User not found in MongoDB: {email}")
                return None
        except Exception as e:
            print(f"[ERROR] find_user_by_email MongoDB error: {e}")
            raise e
    else:
        print("[ERROR] MongoDB database not connected! Please check MONGODB_URI in .env file")
        return None

def find_user_by_phone(phone):
    """Find user by phone number in MongoDB database"""
    if db is not None and hasattr(db, 'users'):
        try:
            users = db.users
            user = users.find_one({'phone': phone})
            if user:
                print(f"🔍 User found with phone: {phone}")
                return user
            else:
                print(f"❌ User not found with phone: {phone}")
                return None
        except Exception as e:
            print(f"[ERROR] find_user_by_phone MongoDB error: {e}")
            return None
    else:
        print("[ERROR] MongoDB database not connected!")
        return None

def update_user_password(email, new_password):
    """Update user password by email in MongoDB database"""
    if db is not None and hasattr(db, 'users'):
        try:
            result = db.users.update_one(
                {'email': email},
                {'$set': {'password': new_password}}
            )
            if result.modified_count > 0:
                print(f"✅ Password updated for user: {email}")
                return True
            else:
                print(f"⚠️ User not found: {email}")
                return False
        except Exception as e:
            print(f"[ERROR] Error updating password in MongoDB: {e}")
            return False
    else:
        print("[ERROR] MongoDB database not connected!")
        return False

def find_user_by_id(user_id):
    print(f"[DEBUG find_user_by_id] Searching for user_id: {user_id}", flush=True)
    try:
        if db is not None and hasattr(db, 'users'):
            users = db.users
            
            # Try with ObjectId first (for MongoDB native ObjectIds)
            try:
                from bson.objectid import ObjectId
                if len(str(user_id)) == 24:  # ObjectId is 24 hex chars
                    user = users.find_one(
                        {'_id': ObjectId(user_id)}, 
                        {'password': 0}  # Exclude password field
                    )
                    if user:
                        print(f"[DEBUG find_user_by_id] Found user via ObjectId: {user.get('name')}", flush=True)
                        return user
            except Exception as e:
                print(f"[DEBUG find_user_by_id] ObjectId lookup failed: {e}", flush=True)
            
            # Try with string ID (for UUID-based IDs stored as strings)
            user = users.find_one({'_id': str(user_id)})
            if user:
                print(f"[DEBUG find_user_by_id] Found user via string _id: {user.get('name')}", flush=True)
                # Remove password from result
                user_copy = dict(user)
                user_copy.pop('password', None)
                return user_copy
            
            # Also try searching by user_id field (in case stored differently)
            user = users.find_one({'user_id': str(user_id)})
            if user:
                print(f"[DEBUG find_user_by_id] Found user via user_id field: {user.get('name')}", flush=True)
                user_copy = dict(user)
                user_copy.pop('password', None)
                return user_copy
            
            print(f"[DEBUG find_user_by_id] User not found in MongoDB", flush=True)
        
        # File-based fallback - search through users.json
        if os.path.exists(USERS_FILE):
            with open(USERS_FILE, 'r', encoding='utf-8') as f:
                users_dict = json.load(f)
            
            # Search through all users for matching _id
            for email, user_data in users_dict.items():
                if user_data.get('_id') == str(user_id):
                    # Remove password from result
                    user_copy = user_data.copy()
                    user_copy.pop('password', None)
                    return user_copy
                    
    except Exception as e:
        print(f"Error fetching user by ID: {e}")
    
    # If user not found, return None
    return None

# Alias for backward compatibility
get_user_by_id = find_user_by_id

# Crop functions
def save_crop_recommendation(user_id, crop_data, timeline_data=None):
    """Save crop recommendation to file and MongoDB"""
    import uuid
    try:
        # Generate unique ID
        crop_id = str(uuid.uuid4())
        
        crop_record = {
            '_id': crop_id,
            'user_id': user_id,
            'crop_name': crop_data.get('crop_name', crop_data.get('name', 'Unknown')),
            'probability': crop_data.get('probability', 0),
            'sowing_date': crop_data.get('sowing_date', datetime.utcnow().strftime('%Y-%m-%d')),
            'status': crop_data.get('status', 'planned'),
            'timeline': timeline_data or [],
            'saved_at': datetime.utcnow().isoformat()
        }
        
        # Save to MongoDB if available
        if db is not None and hasattr(db, 'crops'):
            try:
                db.crops.insert_one(crop_record.copy())
                print(f"🌱 Crop saved to MongoDB: {crop_record['crop_name']}")
                return type('MockResult', (), {'inserted_id': crop_id})()
            except Exception as e:
                print(f"[MongoDB] Could not save crop: {e}")
        else:
            # Fallback to save to file storage if MongoDB is unavailable
            try:
                with open(CROPS_FILE, 'r') as f:
                    crops_db = json.load(f)
            except:
                crops_db = {}
            
            if user_id not in crops_db:
                crops_db[user_id] = []
            
            crops_db[user_id].append(crop_record)
            
            with open(CROPS_FILE, 'w') as f:
                json.dump(crops_db, f, indent=2)
            
            print(f"🌱 Crop recommendation saved for user {user_id}: {crop_record['crop_name']}")
            return type('MockResult', (), {'inserted_id': crop_id})()
    except Exception as e:
        print(f"Error saving crop: {e}")
        return None

def get_user_crops(user_id):
    """Get user's saved crops from MongoDB or file fallback"""
    try:
        # Try MongoDB first
        if db is not None:
            try:
                crops = list(db.crops.find({'user_id': user_id}))
                return crops # Return result (even if empty) if DB query worked
            except Exception as e:
                print(f"[MongoDB] Could not fetch crops: {e}")
        
        # Fallback to file storage ONLY if MongoDB fails or is unavailable
        if os.path.exists(CROPS_FILE):
             with open(CROPS_FILE, 'r') as f:
                crops_db = json.load(f)
             return crops_db.get(user_id, [])
             
        return []
    except Exception as e:
        print(f"Error fetching crops: {e}")
        return []

def delete_crop(crop_id):
    """Delete a crop from file and MongoDB"""
    try:
        # Delete from MongoDB
        if db is not None and hasattr(db, 'crops'):
            try:
                db.crops.delete_one({'_id': crop_id})
                print(f"🗑️ Crop deleted from MongoDB: {crop_id}")
                return type('MockResult', (), {'deleted_count': 1})()
            except:
                pass
        else:
            # Delete from file storage
            with open(CROPS_FILE, 'r') as f:
                crops_db = json.load(f)
            
            for user_id in crops_db:
                crops_db[user_id] = [c for c in crops_db[user_id] if c.get('_id') != crop_id]
            
            with open(CROPS_FILE, 'w') as f:
                json.dump(crops_db, f, indent=2)
            
            print(f"🗑️ Crop deleted from local files: {crop_id}")
            return type('MockResult', (), {'deleted_count': 1})()
    except Exception as e:
        print(f"Error deleting crop: {e}")
        return None

def save_fertilizer_recommendation(user_id, fertilizer_data):
    """Save fertilizer recommendation to file and MongoDB"""
    import uuid
    try:
        # Generate unique ID
        fertilizer_id = str(uuid.uuid4())
        fertilizer_data['_id'] = fertilizer_id
        fertilizer_data['user_id'] = user_id
        fertilizer_data['saved_at'] = datetime.utcnow().isoformat()
        
        # Save to MongoDB if available
        if db is not None and hasattr(db, 'fertilizers'):
            try:
                db.fertilizers.insert_one(fertilizer_data.copy())
                print(f"🧪 Fertilizer saved to MongoDB: {fertilizer_data.get('name')}")
                return type('MockResult', (), {'inserted_id': fertilizer_id})()
            except Exception as e:
                print(f"[MongoDB] Could not save fertilizer: {e}")
        else:
            # Also save to file storage
            try:
                with open(FERTILIZERS_FILE, 'r') as f:
                    fertilizer_db = json.load(f)
            except:
                fertilizer_db = {}
            
            # Save fertilizer
            if user_id not in fertilizer_db:
                fertilizer_db[user_id] = []
            
            fertilizer_db[user_id].append(fertilizer_data)
            
            # Write back to file
            with open(FERTILIZERS_FILE, 'w') as f:
                json.dump(fertilizer_db, f, indent=2)
            
            print(f"🧪 Fertilizer recommendation saved from local files for user {user_id}: {fertilizer_data.get('name')}")
            return type('MockResult', (), {'inserted_id': fertilizer_id})()
    except Exception as e:
        print(f"Error saving fertilizer: {e}")
        return None

def get_user_fertilizers(user_id):
    """Get user's saved fertilizers from MongoDB or file fallback"""
    try:
        # Try MongoDB first
        if db is not None:
            try:
                fertilizers = list(db.fertilizers.find({'user_id': user_id}))
                if fertilizers:
                    return fertilizers
            except Exception as e:
                print(f"[MongoDB] Could not fetch fertilizers: {e}")
        
        # Fallback to file storage ONLY if MongoDB fails or has no data
        if not os.path.exists(FERTILIZERS_FILE):
            return []
            
        with open(FERTILIZERS_FILE, 'r') as f:
            fertilizer_db = json.load(f)
        
        # Get user's fertilizers
        user_fertilizers = fertilizer_db.get(user_id, [])
        return user_fertilizers
    except Exception as e:
        print(f"Error loading fertilizers: {e}")
        return []

def delete_fertilizer_recommendation(fertilizer_id, user_id):
    """Delete a fertilizer recommendation from MongoDB and file"""
    deleted = False
    
    # Try to delete from MongoDB first
    try:
        if db is not None:
            from bson import ObjectId
            try:
                obj_id = ObjectId(fertilizer_id)
                result = db.fertilizers.delete_one({'_id': obj_id, 'user_id': user_id})
            except:
                result = db.fertilizers.delete_one({'_id': fertilizer_id, 'user_id': user_id})
            
            if result.deleted_count > 0:
                print(f"[SUCCESS] Deleted fertilizer {fertilizer_id} from MongoDB for user {user_id}")
                deleted = True
                return deleted
        else:
            # Also delete from JSON file
            try:
                with open(FERTILIZERS_FILE, 'r') as f:
                    fertilizer_db = json.load(f)
                
                user_fertilizers = fertilizer_db.get(user_id, [])
                initial_count = len(user_fertilizers)
                user_fertilizers = [f for f in user_fertilizers if f.get('_id') != fertilizer_id]
                
                if len(user_fertilizers) < initial_count:
                    fertilizer_db[user_id] = user_fertilizers
                    with open(FERTILIZERS_FILE, 'w') as f:
                        json.dump(fertilizer_db, f, indent=2)
                    print(f"[SUCCESS] Deleted fertilizer {fertilizer_id} from JSON for user {user_id}")
                    deleted = True
                    return deleted
                    
            except Exception as e:
                print(f"[WARNING] JSON delete error: {e}")
                
    except Exception as e:
        print(f"[WARNING] Delete error: {e}")
    
    return deleted

def save_disease_detection(user_id, disease_data):
    """Save a disease detection result to MongoDB"""
    try:
        disease_data['user_id'] = user_id
        disease_data['detected_at'] = datetime.utcnow()
        
        if db is not None:
            result = db.diseases.insert_one(disease_data)
            print(f"[SUCCESS] Disease detection saved to MongoDB for user {user_id}: {disease_data.get('disease_name')}")
            return result
        else:
            print(f"[DEV] Disease detection saved for user {user_id}: {disease_data.get('disease_name')}")
            return type('MockResult', (), {'inserted_id': 'mock_disease_id'})()
    except Exception as e:
        print(f"[ERROR] Failed to save disease detection: {e}")
        return None

def get_user_diseases(user_id):
    """Get all disease detections for a user from MongoDB"""
    try:
        if db is not None:
            diseases = list(db.diseases.find({'user_id': user_id}).sort('detected_at', -1))
            for d in diseases:
                d['_id'] = str(d['_id'])
            return diseases
        else:
            return []
    except Exception as e:
        print(f"[ERROR] Failed to get user diseases: {e}")
        return []

def save_growing_activity(activity_data):
    """Save a growing activity to MongoDB"""
    import uuid
    try:
        activity_id = str(uuid.uuid4())
        activity_data['_id'] = activity_id
        activity_data['created_at'] = datetime.utcnow()
        
        # Save to MongoDB
        if db is not None and not isinstance(db, MockDatabase):
            db.growing_activities.insert_one(activity_data)
            print(f"[SUCCESS] Growing activity saved to MongoDB: {activity_data.get('crop_display_name')} [ID: {activity_id}]")
        else:
            # Fallback to JSON file
            with open(GROWING_FILE, 'r') as f:
                growing_data = json.load(f)
            
            user_id = activity_data.get('user_id')
            if user_id not in growing_data:
                growing_data[user_id] = []
            
            growing_data[user_id].append(activity_data)
            
            with open(GROWING_FILE, 'w') as f:
                json.dump(growing_data, f, indent=2, default=str)
            
            print(f"[DEV] Growing activity saved to JSON: {activity_data.get('crop_display_name')} [ID: {activity_id}]")
        
        return type('MockResult', (), {'inserted_id': activity_id})()
    except Exception as e:
        print(f"Error saving growing activity: {e}")
        return None

def get_user_growing_activities(user_id, status='active'):
    """Get user's growing activities from MongoDB"""
    try:
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            query = {'user_id': user_id}
            if status:
                query['status'] = status
            
            activities = list(db.growing_activities.find(query).sort('created_at', -1))
            for a in activities:
                a['_id'] = str(a['_id'])
            return activities
        
        # Fallback to JSON file
        with open(GROWING_FILE, 'r') as f:
            growing_data = json.load(f)
        
        user_activities = growing_data.get(user_id, [])
        
        if status:
            user_activities = [a for a in user_activities if a.get('status') == status]
        
        return user_activities
    except Exception as e:
        print(f"Error loading growing activities: {e}")
        return []

def update_growing_activity(activity_id, user_id, update_data):
    """Update growing activity in MongoDB"""
    try:
        print(f"[INFO] Updating activity {activity_id} for user {user_id}")
        
        update_data['updated_at'] = datetime.utcnow()
        
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            from bson import ObjectId
            try:
                obj_id = ObjectId(activity_id)
                result = db.growing_activities.update_one(
                    {'_id': obj_id, 'user_id': user_id},
                    {'$set': update_data}
                )
            except:
                result = db.growing_activities.update_one(
                    {'_id': activity_id, 'user_id': user_id},
                    {'$set': update_data}
                )
            
            if result.modified_count > 0:
                print(f"[SUCCESS] Updated activity {activity_id} in MongoDB")
                return True
        
        # Fallback to JSON file
        with open(GROWING_FILE, 'r') as f:
            growing_data = json.load(f)
        
        user_activities = growing_data.get(user_id, [])
        
        activity_found = False
        for i, activity in enumerate(user_activities):
            if activity.get('_id') == activity_id or activity.get('id') == activity_id:
                for key, value in update_data.items():
                    user_activities[i][key] = value
                activity_found = True
                break
        
        if activity_found:
            growing_data[user_id] = user_activities
            with open(GROWING_FILE, 'w') as f:
                json.dump(growing_data, f, indent=2, default=str)
            print(f"[SUCCESS] Updated activity {activity_id} in JSON")
            return True
        
        print(f"[WARNING] Activity {activity_id} not found")
        return False
            
    except Exception as e:
        print(f"Error updating activity: {e}")
        import traceback
        traceback.print_exc()
        return False

def delete_growing_activity(activity_id, user_id):
    """Delete a growing activity from MongoDB"""
    try:
        deleted = False
        
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            from bson import ObjectId
            try:
                obj_id = ObjectId(activity_id)
                result = db.growing_activities.delete_one({'_id': obj_id, 'user_id': user_id})
            except:
                result = db.growing_activities.delete_one({'_id': activity_id, 'user_id': user_id})
            
            if result.deleted_count > 0:
                print(f"[SUCCESS] Deleted activity {activity_id} from MongoDB")
                deleted = True
        
        # Also try JSON file
        with open(GROWING_FILE, 'r') as f:
            growing_data = json.load(f)
        
        user_activities = growing_data.get(user_id, [])
        initial_count = len(user_activities)
        user_activities = [a for a in user_activities if a.get('_id') != activity_id]
        
        if len(user_activities) < initial_count:
            growing_data[user_id] = user_activities
            with open(GROWING_FILE, 'w') as f:
                json.dump(growing_data, f, indent=2)
            print(f"[SUCCESS] Deleted activity {activity_id} from JSON")
            deleted = True
        
        return deleted
            
    except Exception as e:
        print(f"Error deleting activity: {e}")
        return False

def get_dashboard_notifications(user_id):
    """Get notifications for dashboard"""
    from datetime import datetime, timedelta
    notifications = []
    
    # Get user's last read timestamp
    user = find_user_by_id(user_id)
    last_read_at = datetime.min
    if user and 'last_notification_read_at' in user:
        if isinstance(user['last_notification_read_at'], str):
            last_read_at = datetime.fromisoformat(user['last_notification_read_at'])
        else:
            last_read_at = user['last_notification_read_at']
    
    # Get active growing activities
    activities = get_user_growing_activities(user_id)
    
    for activity in activities:
        # Check for upcoming tasks (only if tasks have 'week' key - old structure)
        if 'tasks' in activity and activity['tasks']:
            # Check if it's the old task structure with 'week' key
            if isinstance(activity['tasks'], list) and len(activity['tasks']) > 0:
                first_task = activity['tasks'][0]
                if isinstance(first_task, dict) and 'week' in first_task:
                    # Old structure - process weekly tasks
                    start_date = datetime.fromisoformat(activity['created_at'])
                    days_passed = (datetime.now() - start_date).days
                    weeks_passed = days_passed // 7
                    
                    # Find pending tasks for current week
                    for task in activity['tasks']:
                        if task.get('week') == weeks_passed + 1:
                            # Deterministic timestamp: Start of the current week (approx)
                            notif_time = start_date + timedelta(weeks=weeks_passed)
                            if notif_time > last_read_at:
                                notifications.append({
                                    'type': 'task',
                                    'crop': activity.get('crop_display_name', activity.get('crop', 'Unknown')),
                                    'message': f"Week {task['week']} task: {task['task']}",
                                    'priority': 'high',
                                    'created_at': notif_time.isoformat(),
                                    'time_ago': 'This week'
                                })
                elif isinstance(first_task, dict) and 'date' in first_task:
                    # New structure - process date-based tasks
                    for task in activity['tasks']:
                        try:
                            task_date = datetime.strptime(task['date'], '%Y-%m-%d')
                        except:
                            try:
                                task_date = datetime.fromisoformat(task['date'])
                            except:
                                continue

                        days_until = (task_date.date() - datetime.now().date()).days
                        
                        # Notify for tasks within next 3 days
                        if 0 <= days_until <= 3 and not task.get('completed', False):
                            # Deterministic timestamp: 6 AM of the task date (or today if overdue/today)
                            # Actually, we want it to show up TODAY if it is due TODAY.
                            # So logical timestamp is: max(task_date - 3 days, today 00:00)?
                            # Simplest: notification timestamp is the start of today for this specific alert
                            # But if I read it at 8am, I don't want to see it at 9am.
                            # So consistent creation time = today 00:00:00.
                            today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
                            
                            # However, if the task was due yesterday (overdue), distinct alert?
                            # Let's use today_start. If user cleared after today_start, they won't see it.
                            if today_start > last_read_at:
                                notifications.append({
                                    'type': 'task',
                                    'crop': activity.get('crop_display_name', activity.get('crop', 'Unknown')),
                                    'message': f"{task['type']} scheduled for {task_date.strftime('%b %d')}",
                                    'priority': 'high' if days_until == 0 else 'medium',
                                    'created_at': today_start.isoformat(), 
                                    'time_ago': 'Today' if days_until == 0 else f'In {days_until} days'
                                })
                        
                        # Also check for OVERDUE tasks
                        if days_until < 0 and not task.get('completed', False) and days_until > -7:
                             today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
                             if today_start > last_read_at:
                                notifications.append({
                                    'type': 'warning',
                                    'crop': activity.get('crop_display_name', activity.get('crop', 'Unknown')),
                                    'message': f"Overdue: {task['type']} was due on {task_date.strftime('%b %d')}",
                                    'priority': 'high',
                                    'created_at': today_start.isoformat(),
                                    'time_ago': f'{abs(days_until)} days ago'
                                })

        
        # Check if harvest is near (within 7 days)
        if 'harvest_date' in activity or 'expected_harvest_date' in activity:
            harvest_date_str = activity.get('expected_harvest_date') or activity.get('harvest_date')
            if harvest_date_str:
                try:
                    harvest_date = datetime.fromisoformat(harvest_date_str) if 'T' in harvest_date_str else datetime.strptime(harvest_date_str, '%Y-%m-%d')
                    days_to_harvest = (harvest_date - datetime.now()).days
                    
                    if 0 <= days_to_harvest <= 7:
                         today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
                         if today_start > last_read_at:
                            notifications.append({
                                'type': 'harvest',
                                'crop': activity.get('crop_display_name', activity.get('crop', 'Unknown')),
                                'message': f"Harvest ready in {days_to_harvest} days!",
                                'priority': 'high',
                                'created_at': today_start.isoformat(),
                                'time_ago': f'In {days_to_harvest} days'
                            })
                except Exception as e:
                    print(f"Error parsing harvest date: {e}")
    
    # Add persistent notifications
    persistent = get_persistent_notifications(user_id)
    # Filter persistent ones that are not read
    unread_persistent = [n for n in persistent if not n.get('read', False)]
    notifications.extend(unread_persistent)
    
    # Sort by date
    notifications.sort(key=lambda x: x['created_at'], reverse=True)
    
    return notifications

def mark_user_notifications_read(user_id):
    """Mark all notifications as read for a user in MongoDB"""
    try:
        # Update notifications in MongoDB
        if db is not None and not isinstance(db, MockDatabase):
            db.notifications.update_many(
                {'user_id': str(user_id), 'read': False},
                {'$set': {'read': True}}
            )
        
        # Also update in JSON file for fallback
        if os.path.exists(NOTIFICATIONS_FILE):
             with open(NOTIFICATIONS_FILE, 'r') as f:
                all_notifs = json.load(f)
             
             updated = False
             for n in all_notifs:
                 if n.get('user_id') == str(user_id) and not n.get('read', False):
                     n['read'] = True
                     updated = True
             
             if updated:
                 with open(NOTIFICATIONS_FILE, 'w') as f:
                    json.dump(all_notifs, f, indent=2)

        # Update user's last_notification_read_at timestamp
        timestamp = datetime.now().isoformat()
        
        if db is not None and not isinstance(db, MockDatabase):
            db.users.update_one(
                {'_id': user_id}, 
                {'$set': {'last_notification_read_at': timestamp}}
            )

        return True
    except Exception as e:
        print(f"Error marking notifications read: {e}")
        return False
        
def add_notification(user_id, type, message, priority='medium', title=None, data=None):
    """Save a user notification to MongoDB"""
    try:
        # Determine title if not provided
        if not title:
            if type == 'equipment' or type == 'rental_request':
                title = 'Equipment Rental'
            elif type == 'system':
                title = 'System Alert'
            else:
                title = 'Notification'

        new_notif = {
            'id': str(datetime.now().timestamp()),
            'user_id': str(user_id),
            'type': type,
            'title': title,
            'message': message,
            'priority': priority,
            'created_at': datetime.now().isoformat(),
            'read': False,
            'data': data or {}
        }
        
        # Save to MongoDB
        if db is not None and not isinstance(db, MockDatabase):
            db.notifications.insert_one(new_notif)
            print(f"[SUCCESS] Notification saved to MongoDB for user {user_id}")
        else:
            # Fallback to JSON file
            notifications = []
            if os.path.exists(NOTIFICATIONS_FILE):
                with open(NOTIFICATIONS_FILE, 'r') as f:
                    notifications = json.load(f)
            notifications.append(new_notif)
            with open(NOTIFICATIONS_FILE, 'w') as f:
                json.dump(notifications, f, indent=2)
        
        return True
    except Exception as e:
        print(f"Error adding notification: {e}")
        return False
        
def delete_notification(notification_id):
    """Delete a notification by ID from MongoDB"""
    try:
        deleted = False
        
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            result = db.notifications.delete_one({'id': notification_id})
            if result.deleted_count > 0:
                print(f"[SUCCESS] Deleted notification {notification_id} from MongoDB")
                deleted = True
        
        # Also try JSON file
        if os.path.exists(NOTIFICATIONS_FILE):
            with open(NOTIFICATIONS_FILE, 'r') as f:
                notifications = json.load(f)
                
            initial_len = len(notifications)
            notifications = [n for n in notifications if n.get('id') != notification_id]
            
            if len(notifications) < initial_len:
                with open(NOTIFICATIONS_FILE, 'w') as f:
                    json.dump(notifications, f, indent=2)
                deleted = True
        
        return deleted
    except Exception as e:
        print(f"Error deleting notification: {e}")
        return False

def update_equipment(equipment_id, update_data):
    """Update generic equipment fields in MongoDB"""
    try:
        update_data['updated_at'] = datetime.now().isoformat()
        
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            from bson import ObjectId
            try:
                obj_id = ObjectId(equipment_id)
                result = db.equipment_listings.update_one({'_id': obj_id}, {'$set': update_data})
            except:
                result = db.equipment_listings.update_one({'_id': equipment_id}, {'$set': update_data})
            
            if result.modified_count > 0:
                print(f"[SUCCESS] Updated equipment {equipment_id} in MongoDB")
                return True
        
        # Fallback to JSON file
        with open(EQUIPMENT_FILE, 'r') as f:
            equipment = json.load(f)
        
        updated = False
        for item in equipment:
            if item.get('_id') == equipment_id:
                item.update(update_data)
                updated = True
                break
        
        if updated:
            with open(EQUIPMENT_FILE, 'w') as f:
                json.dump(equipment, f, indent=2)
            return True
        return False
    except Exception as e:
        print(f"Error updating equipment: {e}")
        return False

def get_persistent_notifications(user_id):
    """Retrieve saved notifications for a user from MongoDB"""
    try:
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            notifications = list(db.notifications.find({'user_id': str(user_id)}))
            for n in notifications:
                n['_id'] = str(n['_id'])
            return notifications
        
        # Fallback to JSON file
        if not os.path.exists(NOTIFICATIONS_FILE):
            return []
        with open(NOTIFICATIONS_FILE, 'r') as f:
            all_notifs = json.load(f)
            return [n for n in all_notifs if n.get('user_id') == str(user_id)]
    except Exception as e:
        print(f"Error loading notifications: {e}")
        return []

def get_all_equipment():
    """Get all listed equipment from MongoDB"""
    try:
        # Try MongoDB first
        if db is not None and not isinstance(db, MockDatabase):
            equipment = list(db.equipment_listings.find())
            for e in equipment:
                e['_id'] = str(e['_id'])
            return equipment
        
        # Fallback to JSON file
        if not os.path.exists(EQUIPMENT_FILE):
            return []
        with open(EQUIPMENT_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading equipment: {e}")
        return []

def save_equipment(equipment_data):
    """Save a new equipment listing to MongoDB"""
    import uuid
    try:
        equipment_id = str(uuid.uuid4())
        equipment_data['_id'] = equipment_id
        equipment_data['created_at'] = datetime.utcnow().isoformat()
        equipment_data['status'] = 'available'
        
        # Save to MongoDB
        if db is not None and not isinstance(db, MockDatabase):
            db.equipment_listings.insert_one(equipment_data)
            print(f"[SUCCESS] Equipment saved to MongoDB: {equipment_data.get('name')} [ID: {equipment_id}]")
        else:
            # Fallback to JSON file
            equipment = get_all_equipment()
            equipment.append(equipment_data)
            with open(EQUIPMENT_FILE, 'w') as f:
                json.dump(equipment, f, indent=2)
            print(f"[DEV] Equipment saved to JSON: {equipment_data.get('name')} [ID: {equipment_id}]")
            
        return equipment_id
    except Exception as e:
        print(f"Error saving equipment: {e}")
        return None

def update_equipment_status(equipment_id, status):
    """Update equipment listing status (available, booked, completed, cancelled)"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                from bson.objectid import ObjectId
                try:
                    obj_id = ObjectId(equipment_id)
                except:
                    obj_id = equipment_id
                
                result = db.equipment_listings.update_one(
                    {'_id': obj_id},
                    {'$set': {'status': status, 'updated_at': datetime.utcnow().isoformat()}}
                )
                if result.modified_count > 0:
                    print(f"[MONGODB] Equipment status updated: {equipment_id} -> {status}")
                    return True
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback - use equipment_listings.json
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            print(f"[ERROR] Equipment listings file not found: {EQUIPMENT_LISTINGS_FILE}")
            return False
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r', encoding='utf-8') as f:
            listings = json.load(f)
        
        updated = False
        for listing in listings:
            if listing.get('_id') == equipment_id:
                listing['status'] = status
                listing['updated_at'] = datetime.utcnow().isoformat()
                updated = True
                break
        
        if updated:
            with open(EQUIPMENT_LISTINGS_FILE, 'w', encoding='utf-8') as f:
                json.dump(listings, f, indent=2, ensure_ascii=False)
            print(f"[FILE] Equipment status updated: {equipment_id} -> {status}")
            return True
        else:
            print(f"[ERROR] Equipment listing not found: {equipment_id}")
            return False
        
    except Exception as e:
        print(f"[ERROR] Error updating equipment status: {e}")
        import traceback
        traceback.print_exc()
        return False

def save_expense(expense_data):
    """Save a new expense entry (supports both MongoDB and JSON file fallback)"""
    global db
    try:
        if db is not None:
            # Check if ObjectId is needed for user_id
            from bson import ObjectId
            if 'user_id' in expense_data and isinstance(expense_data['user_id'], str):
                try:
                    expense_data['user_id'] = ObjectId(expense_data['user_id'])
                except:
                    pass
            
            result = db.expenses.insert_one(expense_data)
            return str(result.inserted_id)
        else:
            # File fallback
            import uuid
            expense_id = str(uuid.uuid4())
            expense_data['_id'] = expense_id
            
            expenses = []
            if os.path.exists(EXPENSES_FILE):
                with open(EXPENSES_FILE, 'r') as f:
                    try:
                        expenses = json.load(f)
                    except:
                        expenses = []
            
            expenses.append(expense_data)
            with open(EXPENSES_FILE, 'w') as f:
                json.dump(expenses, f, indent=2)
            
            return expense_id
    except Exception as e:
        print(f"Error saving expense: {e}")
        return None

def get_user_expenses(user_id):
    """Get all expenses for a user (supports both MongoDB and JSON file fallback)"""
    global db
    try:
        if db is not None:
            from bson import ObjectId
            query = {'user_id': ObjectId(user_id) if isinstance(user_id, str) else user_id}
            return list(db.expenses.find(query).sort('entry_date', -1))
        else:
            # File fallback
            if os.path.exists(EXPENSES_FILE):
                with open(EXPENSES_FILE, 'r') as f:
                    try:
                        all_expenses = json.load(f)
                        return [exp for exp in all_expenses if str(exp.get('user_id')) == str(user_id)]
                    except:
                        return []
            return []
    except Exception as e:
        print(f"Error fetching expenses: {e}")
        return []


# ============================================
# BUYER CONNECT - Direct Buyer-Farmer Connect
# ============================================




def get_live_market_price(crop, district, state):
    """Fetch live market price for a crop from MongoDB market_prices collection"""
    try:
        from bson import Regex
        
        if db is None or not hasattr(db, 'market_prices'):
            return None
            
        crop_regex = {"$regex": f"^{crop}$", "$options": "i"}
        district_regex = {"$regex": f"^{district}$", "$options": "i"}
        state_regex = {"$regex": f"^{state}$", "$options": "i"}
        
        # Search for crop in user's district first
        item = db.market_prices.find_one({
            "commodity": crop_regex,
            "district": district_regex,
            "state": state_regex
        })
        
        # If not found in exact district, search in same state
        if not item:
            item = db.market_prices.find_one({
                "commodity": crop_regex,
                "state": state_regex
            })
            
        # If still not found, search nationwide
        if not item:
            item = db.market_prices.find_one({
                "commodity": crop_regex
            })

        
        if item:
            modal_price_quintal = item['modal_price']  # Price per quintal
            price_per_kg = round(modal_price_quintal / 100, 2)  # Convert to per kg
            
            # Calculate ±20% range
            min_price = round(price_per_kg * 0.8, 2)
            max_price = round(price_per_kg * 1.2, 2)
            
            return {
                'recommended_price': price_per_kg,
                'min_price': min_price,
                'max_price': max_price,
                'market': item.get('market', 'Local Mandi'),
                'date': item.get('price_date', datetime.now().strftime('%Y-%m-%d'))
            }
        
        return None
        
    except Exception as e:
        print(f"Error fetching live market price: {e}")
        return None


def create_crop_listing(listing_data):
    """Create a new crop listing for sale"""
    global db
    try:
        print(f"\n[DEBUG] Database status: db is {type(db)} (None: {db is None})", flush=True)
        print(f"[DEBUG] Listing data received: {listing_data}", flush=True)
        
        # MongoDB Atlas Path
        if db is not None:
            try:
                print("[DEBUG] Attempting MongoDB insertion...", flush=True)
                # Ensure we don't have a string _id if MongoDB expects ObjectId
                if '_id' in listing_data:
                    del listing_data['_id']
                
                result = db.crop_listings.insert_one(listing_data)
                if result.inserted_id:
                    print(f"[SUCCESS] Listing saved to MongoDB with ID: {result.inserted_id}", flush=True)
                    return str(result.inserted_id)
                else:
                    print("[ERROR] MongoDB insert_one returned no inserted_id", flush=True)
            except Exception as mongo_err:
                print(f"[MONGO ERROR] {str(mongo_err)}", flush=True)
                # If MongoDB fails, we continue to the file-based fallback
                print("[INFO] Falling back to file-based storage...", flush=True)
        
        # File-based Fallback Path
        print(f"[DEBUG] Attempting file-based storage to: {LISTINGS_FILE}", flush=True)
        print(f"[DEBUG] File exists: {os.path.exists(LISTINGS_FILE)}", flush=True)
        
        import uuid
        if '_id' not in listing_data:
            listing_data['_id'] = str(uuid.uuid4())
            print(f"[DEBUG] Generated listing ID: {listing_data['_id']}", flush=True)
            
        listings = []
        if os.path.exists(LISTINGS_FILE):
            try:
                with open(LISTINGS_FILE, 'r', encoding='utf-8') as f:
                    content = f.read().strip()
                    print(f"[DEBUG] File content: '{content}'", flush=True)
                    if content:
                        listings = json.loads(content)
                    else:
                        listings = []
                print(f"[DEBUG] Loaded {len(listings)} existing listings from file", flush=True)
            except json.JSONDecodeError as json_err:
                print(f"[FILE JSON ERROR] {str(json_err)}", flush=True)
                print("[DEBUG] Resetting file with empty array", flush=True)
                listings = []
            except Exception as read_err:
                print(f"[FILE READ ERROR] {str(read_err)}", flush=True)
                listings = []
        else:
            print("[DEBUG] File does not exist, creating new", flush=True)
        
        listings.append(listing_data)
        print(f"[DEBUG] Total listings to save: {len(listings)}", flush=True)
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(LISTINGS_FILE), exist_ok=True)
        
        with open(LISTINGS_FILE, 'w', encoding='utf-8') as f:
            json.dump(listings, f, indent=2, default=str)
        
        print(f"[SUCCESS] Listing saved to file with ID: {listing_data['_id']}", flush=True)
        return listing_data['_id']
        
    except Exception as e:
        print(f"[CRITICAL ERROR in create_crop_listing] {str(e)}", flush=True)
        import traceback
        traceback.print_exc()
        return None


def get_user_listings(user_id):
    """Get all listings by a specific farmer"""
    global db
    user_id_str = str(user_id)
    print(f"\n{'='*60}", flush=True)
    print(f"[GET_USER_LISTINGS] Starting fetch for User ID: {user_id}", flush=True)
    print(f"[GET_USER_LISTINGS] User ID String: {user_id_str}", flush=True)
    print(f"[GET_USER_LISTINGS] Database connection: db={type(db)}, is None: {db is None}", flush=True)
    print(f"{'='*60}\n", flush=True)
    
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                print(f"[GET_USER_LISTINGS] Attempting MongoDB query...", flush=True)
                # Try both original and string version of ID for robustness
                query = {'$or': [{'farmer_id': user_id}, {'farmer_id': user_id_str}]}
                print(f"[GET_USER_LISTINGS] Query: {query}", flush=True)
                
                cursor = db.crop_listings.find(query)
                listings = list(cursor.sort('created_at', -1))
                print(f"[GET_USER_LISTINGS] MongoDB returned {len(listings)} listings", flush=True)
                
                if listings:
                    print(f"[GET_USER_LISTINGS] First listing farmer_id: {listings[0].get('farmer_id')}", flush=True)
                    for listing in listings:
                        listing['_id'] = str(listing['_id'])
                        print(f"[GET_USER_LISTINGS] Listing: {listing.get('crop')} - ID: {listing['_id']}", flush=True)
                else:
                    print(f"[GET_USER_LISTINGS] No listings found in MongoDB", flush=True)
                    # Check if there are ANY listings for debugging
                    total_count = db.crop_listings.count_documents({})
                    print(f"[GET_USER_LISTINGS] Total listings in DB: {total_count}", flush=True)
                    if total_count > 0:
                        sample = db.crop_listings.find_one({})
                        print(f"[GET_USER_LISTINGS] Sample listing farmer_id: {sample.get('farmer_id')}", flush=True)
                
                return listings
            except Exception as e:
                print(f"[GET_USER_LISTINGS MONGODB ERROR] {str(e)}", flush=True)
                import traceback
                traceback.print_exc()
        else:
            print(f"[GET_USER_LISTINGS] MongoDB not available, using file fallback", flush=True)
        
        # File-based fallback
        print(f"[GET_USER_LISTINGS] Checking file: {LISTINGS_FILE}", flush=True)
        if os.path.exists(LISTINGS_FILE):
            with open(LISTINGS_FILE, 'r', encoding='utf-8') as f:
                all_listings = json.load(f)
            
            print(f"[GET_USER_LISTINGS] File has {len(all_listings)} total listings", flush=True)
            # Flexible matching for file fallback too
            user_listings = [l for l in all_listings if str(l.get('farmer_id')) == user_id_str]
            user_listings.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            print(f"[GET_USER_LISTINGS] File found {len(user_listings)} listings for user", flush=True)
            return user_listings
        
        print("[GET_USER_LISTINGS] No listings file found", flush=True)
        return []
        
    except Exception as e:
        print(f"[GET_USER_LISTINGS CRITICAL ERROR] {str(e)}", flush=True)
        import traceback
        traceback.print_exc()
        return []


def get_available_listings(crop='', district='', state='', sort_by='recent'):
    """Get all available listings for buyers (status='active')"""
    global db
    print(f"\n[DEBUG] Fetching available listings for {crop} in {district}, {state}", flush=True)
    
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                query = {'status': 'active'}
                if crop: query['crop'] = crop
                if district: query['district'] = district
                if state: query['state'] = state
                
                sort_order = [('created_at', -1)]  # Default: recent first
                if sort_by == 'price_low': sort_order = [('farmer_price', 1)]
                elif sort_by == 'price_high': sort_order = [('farmer_price', -1)]
                
                listings = list(db.crop_listings.find(query).sort(sort_order))
                print(f"[DEBUG] MongoDB found {len(listings)} available listings", flush=True)
                
                for listing in listings:
                    listing['_id'] = str(listing['_id'])
                    # Robust farmer detail fetching
                    f_id = listing.get('farmer_id')
                    if f_id:
                        farmer = find_user_by_id(f_id)
                        if farmer:
                            listing['farmer_name'] = farmer.get('name', 'Unknown')
                            listing['farmer_phone'] = farmer.get('phone', '')
                return listings
            except Exception as e:
                print(f"[MONGODB ERROR] {str(e)}", flush=True)
        
        # File-based fallback
        if os.path.exists(LISTINGS_FILE):
            with open(LISTINGS_FILE, 'r', encoding='utf-8') as f:
                all_listings = json.load(f)
            
            # Filter by status and criteria
            available = [l for l in all_listings if l.get('status') == 'active']
            print(f"[DEBUG] File found total {len(available)} available listings before filtering", flush=True)
            
            if crop: available = [l for l in available if l.get('crop', '').lower() == crop.lower()]
            if district: available = [l for l in available if l.get('district', '').lower() == district.lower()]
            if state: available = [l for l in available if l.get('state', '').lower() == state.lower()]
            
            # Sort
            if sort_by == 'price_low': available.sort(key=lambda x: x.get('farmer_price', 0))
            elif sort_by == 'price_high': available.sort(key=lambda x: x.get('farmer_price', 0), reverse=True)
            else: available.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            
            # Add farmer details
            for listing in available:
                f_id = listing.get('farmer_id')
                if f_id:
                    farmer = find_user_by_id(f_id)
                    if farmer:
                        listing['farmer_name'] = farmer.get('name', 'Unknown')
                        listing['farmer_phone'] = farmer.get('phone', '')
            
            print(f"[DEBUG] File-based retrieval complete, returning {len(available)} listings", flush=True)
            return available
        
        return []
        
    except Exception as e:
        print(f"[ERROR in get_available_listings] {str(e)}", flush=True)
        return []


def get_listing_by_id(listing_id):
    """Get a specific listing by ID"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                from bson.objectid import ObjectId
                # Try both ObjectId and string ID
                try:
                    listing = db.crop_listings.find_one({'_id': ObjectId(listing_id)})
                except:
                    listing = db.crop_listings.find_one({'_id': listing_id})
                
                if listing:
                    listing['_id'] = str(listing['_id'])
                    # Add farmer details if missing or "Unknown"
                    if not listing.get('farmer_name') or listing.get('farmer_name') == 'Unknown':
                        farmer = find_user_by_id(listing.get('farmer_id'))
                        if farmer:
                            listing['farmer_name'] = farmer.get('name', 'Unknown')
                            listing['farmer_phone'] = farmer.get('phone', '')
                    return listing
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        with open(LISTINGS_FILE, 'r') as f:
            listings = json.load(f)
        
        for listing in listings:
            if listing.get('_id') == listing_id:
                # Add farmer details if missing or "Unknown"
                if not listing.get('farmer_name') or listing.get('farmer_name') == 'Unknown':
                    farmer = find_user_by_id(listing.get('farmer_id'))
                    if farmer:
                        listing['farmer_name'] = farmer.get('name', 'Unknown')
                        listing['farmer_phone'] = farmer.get('phone', '')
                return listing
        
        return None
        
    except Exception as e:
        print(f"Error fetching listing: {e}")
        return None


def confirm_purchase(listing_id, purchase_data):
    """Confirm purchase and update listing status atomically"""
    try:
        # MongoDB Atlas - ATOMIC UPDATE
        if db is not None:
            try:
                from bson.objectid import ObjectId
                
                # Atomic update: only update if status is still 'active'
                # This prevents double-selling
                try:
                    obj_id = ObjectId(listing_id)
                except:
                    obj_id = listing_id
                
                result = db.crop_listings.find_one_and_update(
                    {'_id': obj_id, 'status': 'active'},  # Only if still active
                    {
                        '$set': {
                            'status': 'sold',
                            'buyer_id': purchase_data['buyer_id'],
                            'buyer_name': purchase_data['buyer_name'],
                            'buyer_phone': purchase_data['buyer_phone'],
                            'sold_at': purchase_data['purchased_at']
                        }
                    },
                    return_document=True
                )
                
                if result:
                    print(f"[MONGODB] Purchase confirmed for listing: {listing_id}")
                    return True, "Purchase confirmed successfully"
                else:
                    return False, "This listing is no longer available"
                    
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback (with lock to prevent race condition)
        try:
            import fcntl
            use_fcntl = True
        except ImportError:
            # Windows doesn't support fcntl
            use_fcntl = False
        
        with open(LISTINGS_FILE, 'r+') as f:
            # Lock file to prevent concurrent access (Unix/Linux only)
            if use_fcntl:
                try:
                    fcntl.flock(f.fileno(), fcntl.LOCK_EX)
                except:
                    pass
            
            try:
                listings = json.load(f)
                
                # Find listing and check if still active
                for listing in listings:
                    if listing.get('_id') == listing_id:
                        if listing.get('status') != 'active':
                            return False, "This listing is no longer available"
                        
                        # Update status
                        listing['status'] = 'sold'
                        listing['buyer_id'] = purchase_data['buyer_id']
                        listing['buyer_name'] = purchase_data['buyer_name']
                        listing['buyer_phone'] = purchase_data['buyer_phone']
                        listing['sold_at'] = purchase_data['purchased_at']
                        
                        # Write back
                        f.seek(0)
                        json.dump(listings, f, indent=2)
                        f.truncate()
                        
                        print(f"[FILE] Purchase confirmed for listing: {listing_id}")
                        return True, "Purchase confirmed successfully"
                
                return False, "Listing not found"
                
            finally:
                # Release lock
                if use_fcntl:
                    try:
                        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
                    except:
                        pass
        
    except Exception as e:
        print(f"Error confirming purchase: {e}")
        return False, str(e)


def update_listing_status(listing_id, new_status):
    """Update listing status (for cancellation, expiry, etc.)"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                from bson.objectid import ObjectId
                try:
                    obj_id = ObjectId(listing_id)
                except:
                    obj_id = listing_id
                
                result = db.crop_listings.update_one(
                    {'_id': obj_id},
                    {'$set': {'status': new_status, 'updated_at': datetime.utcnow().isoformat()}}
                )
                if result.modified_count > 0:
                    print(f"[MONGODB] Listing status updated: {listing_id} -> {new_status}")
                    return True
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(LISTINGS_FILE):
            print(f"[ERROR] Listings file not found: {LISTINGS_FILE}")
            return False
        
        with open(LISTINGS_FILE, 'r', encoding='utf-8') as f:
            listings = json.load(f)
        
        updated = False
        for listing in listings:
            if listing.get('_id') == listing_id:
                listing['status'] = new_status
                listing['updated_at'] = datetime.utcnow().isoformat()
                updated = True
                break
        
        if updated:
            with open(LISTINGS_FILE, 'w', encoding='utf-8') as f:
                json.dump(listings, f, indent=2, ensure_ascii=False)
            print(f"[FILE] Listing status updated: {listing_id} -> {new_status}")
            return True
        else:
            print(f"[ERROR] Listing not found: {listing_id}")
            return False
        
    except Exception as e:
        print(f"[ERROR] Error updating listing status: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================
# EQUIPMENT SHARING MARKETPLACE FUNCTIONS
# ============================================

EQUIPMENT_LISTINGS_FILE = os.path.join(DATA_DIR, 'equipment_listings.json')
EQUIPMENT_BASE_PRICES_FILE = os.path.join(DATA_DIR, 'equipment_base_prices.json')

def get_live_equipment_rent(equipment_name, district='', state=''):
    """
    Get live market rent for equipment
    Returns: {recommended_rent, min_rent, max_rent}
    """
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                query = {'equipment_name': equipment_name}
                # Try to match by state, fallback to generic
                if state:
                    query['location'] = {'$regex': state, '$options': 'i'}
                
                base_price = db.equipment_base_prices.find_one(query)
                
                if base_price:
                    avg_rent = base_price['avg_rent_per_day']
                    return {
                        'recommended_rent': avg_rent,
                        'min_rent': round(avg_rent * 0.85, 2),
                        'max_rent': round(avg_rent * 1.15, 2)
                    }
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_BASE_PRICES_FILE):
            return None
        
        with open(EQUIPMENT_BASE_PRICES_FILE, 'r') as f:
            base_prices = json.load(f)
        
        # Find matching equipment
        for price in base_prices:
            if price['equipment_name'].lower() == equipment_name.lower():
                # Try to match by state first, fallback to any location
                if state and state.lower() in price.get('location', '').lower():
                    avg_rent = price['avg_rent_per_day']
                    return {
                        'recommended_rent': avg_rent,
                        'min_rent': round(avg_rent * 0.85, 2),
                        'max_rent': round(avg_rent * 1.15, 2)
                    }
        
        # Fallback: return first matching equipment regardless of location
        for price in base_prices:
            if price['equipment_name'].lower() == equipment_name.lower():
                avg_rent = price['avg_rent_per_day']
                print(f"[DB] Found equipment rent: {equipment_name} = ₹{avg_rent}/day")
                return {
                    'recommended_rent': avg_rent,
                    'min_rent': round(avg_rent * 0.85, 2),
                    'max_rent': round(avg_rent * 1.15, 2)
                }
        
        print(f"[DB] No rental rate found for equipment: {equipment_name}, state: {state}")
        print(f"[DB] Available equipment in file: {[p['equipment_name'] for p in base_prices[:5]]}")
        return None
        
    except Exception as e:
        print(f"Error fetching live equipment rent: {e}")
        import traceback
        traceback.print_exc()
        return None


def create_equipment_listing(listing_data):
    """Create new equipment listing"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                result = db.equipment_listings.insert_one(listing_data)
                return str(result.inserted_id)
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            with open(EQUIPMENT_LISTINGS_FILE, 'w') as f:
                json.dump([], f)
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            listings = json.load(f)
        
        # Generate unique ID
        import uuid
        listing_data['_id'] = str(uuid.uuid4())
        
        listings.append(listing_data)
        
        with open(EQUIPMENT_LISTINGS_FILE, 'w') as f:
            json.dump(listings, f, indent=2)
        
        return listing_data['_id']
        
    except Exception as e:
        print(f"Error creating equipment listing: {e}")
        return None


def get_available_equipment(equipment_name='', district='', state='', sort_by='recent'):
    """Get all available equipment (status='available')"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                query = {'status': 'available'}
                if equipment_name:
                    query['equipment_name'] = equipment_name
                if district:
                    query['district'] = district
                if state:
                    query['state'] = state
                
                sort_order = [('created_at', -1)]  # Default: recent first
                if sort_by == 'price_low':
                    sort_order = [('owner_rent', 1)]
                elif sort_by == 'price_high':
                    sort_order = [('owner_rent', -1)]
                
                listings = list(db.equipment_listings.find(query).sort(sort_order))
                for listing in listings:
                    listing['_id'] = str(listing['_id'])
                return listings
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return []
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            all_listings = json.load(f)
        
        # Filter by status and criteria
        available = [l for l in all_listings if l.get('status') == 'available']
        
        if equipment_name:
            available = [l for l in available if l.get('equipment_name', '').lower() == equipment_name.lower()]
        if district:
            available = [l for l in available if l.get('district', '').lower() == district.lower()]
        if state:
            available = [l for l in available if l.get('state', '').lower() == state.lower()]
        
        # Sort
        if sort_by == 'price_low':
            available.sort(key=lambda x: x.get('owner_rent', 0))
        elif sort_by == 'price_high':
            available.sort(key=lambda x: x.get('owner_rent', 0), reverse=True)
        else:
            available.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        # Enrich listings with owner details if missing
        for listing in available:
            if not listing.get('owner_name') or listing.get('owner_name') == 'Unknown':
                owner = find_user_by_id(listing.get('owner_id'))
                if owner:
                    listing['owner_name'] = owner.get('name', 'Unknown')
                    listing['owner_phone'] = owner.get('phone', '')
        
        return available
        
    except Exception as e:
        print(f"Error fetching available equipment: {e}")
        return []


def get_equipment_listing_by_id(listing_id):
    """Get equipment listing by ID"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                from bson.objectid import ObjectId
                listing = db.equipment_listings.find_one({'_id': ObjectId(listing_id)})
                if listing:
                    listing['_id'] = str(listing['_id'])
                    # Add owner details if missing or "Unknown"
                    if not listing.get('owner_name') or listing.get('owner_name') == 'Unknown':
                        owner = find_user_by_id(listing.get('owner_id'))
                        if owner:
                            listing['owner_name'] = owner.get('name', 'Unknown')
                            listing['owner_phone'] = owner.get('phone', '')
                    return listing
            except:
                pass
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return None
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            listings = json.load(f)
        
        for listing in listings:
            if listing.get('_id') == listing_id:
                # Add owner details if missing or "Unknown"
                if not listing.get('owner_name') or listing.get('owner_name') == 'Unknown':
                    owner = find_user_by_id(listing.get('owner_id'))
                    if owner:
                        listing['owner_name'] = owner.get('name', 'Unknown')
                        listing['owner_phone'] = owner.get('phone', '')
                return listing
        
        return None
        
    except Exception as e:
        print(f"Error fetching equipment listing: {e}")
        return None


def book_equipment_atomic(listing_id, booking_data):
    """
    Atomically book equipment (prevents double booking)
    Returns: (success, message)
    """
    try:
        # MongoDB Atlas - ATOMIC UPDATE
        if db is not None:
            try:
                from bson.objectid import ObjectId
                
                # Atomic update: only update if status is 'available'
                result = db.equipment_listings.update_one(
                    {
                        '_id': ObjectId(listing_id),
                        'status': 'available'  # Critical: only update if still available
                    },
                    {
                        '$set': {
                            'status': 'booked',
                            'renter_id': booking_data['renter_id'],
                            'renter_name': booking_data['renter_name'],
                            'renter_phone': booking_data['renter_phone'],
                            'from_date': booking_data['from_date'],
                            'to_date': booking_data['to_date'],
                            'booked_at': booking_data['booked_at']
                        }
                    }
                )
                
                if result.modified_count > 0:
                    return (True, 'Equipment booked successfully')
                else:
                    return (False, 'Equipment is no longer available')
                    
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback with simple locking
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return (False, 'Equipment not found')
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            listings = json.load(f)
        
        for listing in listings:
            if listing.get('_id') == listing_id:
                if listing.get('status') != 'available':
                    return (False, 'Equipment is no longer available')
                
                # Update listing
                listing['status'] = 'booked'
                listing['renter_id'] = booking_data['renter_id']
                listing['renter_name'] = booking_data['renter_name']
                listing['renter_phone'] = booking_data['renter_phone']
                listing['from_date'] = booking_data['from_date']
                listing['to_date'] = booking_data['to_date']
                listing['booked_at'] = booking_data['booked_at']
                
                with open(EQUIPMENT_LISTINGS_FILE, 'w') as f:
                    json.dump(listings, f, indent=2)
                
                return (True, 'Equipment booked successfully')
        
        return (False, 'Equipment not found')
        
    except Exception as e:
        print(f"Error booking equipment: {e}")
        return (False, 'An error occurred')


def complete_equipment_rental(listing_id):
    """Mark equipment rental as completed"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                from bson.objectid import ObjectId
                
                result = db.equipment_listings.update_one(
                    {'_id': ObjectId(listing_id)},
                    {
                        '$set': {
                            'status': 'completed',
                            'completed_at': datetime.utcnow().isoformat()
                        }
                    }
                )
                
                if result.modified_count > 0:
                    return (True, 'Rental completed successfully')
                else:
                    return (False, 'Equipment not found')
                    
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return (False, 'Equipment not found')
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            listings = json.load(f)
        
        for listing in listings:
            if listing.get('_id') == listing_id:
                listing['status'] = 'completed'
                listing['completed_at'] = datetime.utcnow().isoformat()
                
                with open(EQUIPMENT_LISTINGS_FILE, 'w') as f:
                    json.dump(listings, f, indent=2)
                
                return (True, 'Rental completed successfully')
        
        return (False, 'Equipment not found')
        
    except Exception as e:
        print(f"Error completing rental: {e}")
        return (False, 'An error occurred')


def get_user_equipment_listings(user_id):
    """Get all equipment listings by a user"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                listings = list(db.equipment_listings.find({'owner_id': user_id}).sort('created_at', -1))
                for listing in listings:
                    listing['_id'] = str(listing['_id'])
                return listings
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return []
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            all_listings = json.load(f)
        
        user_listings = [l for l in all_listings if l.get('owner_id') == user_id]
        user_listings.sort(key=lambda x: x.get('created_at', ''), reverse=True)
        
        return user_listings
        
    except Exception as e:
        print(f"Error fetching user equipment listings: {e}")
        return []


def confirm_equipment_rental(listing_id, rental_data):
    """Confirm equipment rental and update listing status atomically"""
    try:
        # MongoDB Atlas - ATOMIC UPDATE
        if db is not None:
            try:
                from bson.objectid import ObjectId
                
                # Atomic update: only update if status is still 'available'
                # This prevents double-booking
                try:
                    obj_id = ObjectId(listing_id)
                except:
                    obj_id = listing_id
                
                result = db.equipment_listings.find_one_and_update(
                    {'_id': obj_id, 'status': 'available'},  # Only if still available
                    {
                        '$set': {
                            'status': 'booked',
                            'renter_id': rental_data['renter_id'],
                            'renter_name': rental_data['renter_name'],
                            'renter_phone': rental_data['renter_phone'],
                            'rental_from': rental_data['rental_from'],
                            'rental_to': rental_data['rental_to'],
                            'rental_days': rental_data['rental_days'],
                            'total_rent': rental_data['total_rent'],
                            'booked_at': rental_data['booked_at']
                        }
                    },
                    return_document=True
                )
                
                if result:
                    print(f"[MONGODB] Rental confirmed for listing: {listing_id}")
                    return True, "Rental confirmed successfully"
                else:
                    return False, "This equipment is no longer available"
                    
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback (with lock to prevent race condition)
        try:
            import fcntl
            use_fcntl = True
        except ImportError:
            # Windows doesn't support fcntl
            use_fcntl = False
        
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return False, "Listing not found"
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r+') as f:
            # Lock file to prevent concurrent access (Unix/Linux only)
            if use_fcntl:
                try:
                    fcntl.flock(f.fileno(), fcntl.LOCK_EX)
                except:
                    pass
            
            try:
                listings = json.load(f)
                
                # Find listing and check if still available
                for listing in listings:
                    if listing.get('_id') == listing_id:
                        if listing.get('status') != 'available':
                            return False, "This equipment is no longer available"
                        
                        # Update status
                        listing['status'] = 'booked'
                        listing['renter_id'] = rental_data['renter_id']
                        listing['renter_name'] = rental_data['renter_name']
                        listing['renter_phone'] = rental_data['renter_phone']
                        listing['rental_from'] = rental_data['rental_from']
                        listing['rental_to'] = rental_data['rental_to']
                        listing['rental_days'] = rental_data['rental_days']
                        listing['total_rent'] = rental_data['total_rent']
                        listing['booked_at'] = rental_data['booked_at']
                        
                        # Write back
                        f.seek(0)
                        f.truncate()
                        json.dump(listings, f, indent=4)
                        
                        return True, "Rental confirmed successfully"
                
                return False, "Listing not found"
                
            finally:
                if use_fcntl:
                    try:
                        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
                    except:
                        pass
        
    except Exception as e:
        print(f"Error confirming rental: {e}")
        return False, f"Error: {str(e)}"


def get_user_bookings(user_id):
    """Get all equipment bookings made by a user"""
    try:
        # MongoDB Atlas
        if db is not None:
            try:
                bookings = list(db.equipment_listings.find({'renter_id': user_id}).sort('booked_at', -1))
                for booking in bookings:
                    booking['_id'] = str(booking['_id'])
                return bookings
            except Exception as e:
                print(f"[MONGODB ERROR] {e}")
        
        # File-based fallback
        if not os.path.exists(EQUIPMENT_LISTINGS_FILE):
            return []
        
        with open(EQUIPMENT_LISTINGS_FILE, 'r') as f:
            all_listings = json.load(f)
        
        user_bookings = [l for l in all_listings if l.get('renter_id') == user_id]
        user_bookings.sort(key=lambda x: x.get('booked_at', ''), reverse=True)
        
        return user_bookings
        
    except Exception as e:
        print(f"Error fetching user bookings: {e}")
        return []
