import os
import json
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()
MONGODB_URI = os.getenv('MONGODB_URI')
if not MONGODB_URI:
    raise SystemExit("MONGODB_URI not set in environment or .env file")

with open(os.path.join(os.path.dirname(__file__), '..', 'data', 'states_districts.json'), 'r', encoding='utf-8') as f:
    data = json.load(f)

client = MongoClient(MONGODB_URI)
# Determine DB name from URI or use 'smartfarming'
db_name = 'smartfarming'
try:
    db_name = MONGODB_URI.split('mongodb.net/')[-1].split('?')[0].strip('/') or db_name
except Exception:
    pass

db = client[db_name]

result = db.static_configs.replace_one({'_id': 'states_districts'}, {'_id': 'states_districts', 'data': data}, upsert=True)
print(f"Inserted/updated states_districts in DB '{db_name}'. matched_count={getattr(result, 'matched_count', 'N/A')} modified_count={getattr(result, 'modified_count', 'N/A')}")
client.close()
