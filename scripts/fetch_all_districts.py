import requests
import sys
sys.path.append('.')
from utils.db import get_static_config, init_db
import utils.db 

def update_all_districts():
    print("Initiating DB...")
    init_db(None)
    db_instance = utils.db.db
    
    print("Fetching Indian states and districts from github...")
    url = "https://raw.githubusercontent.com/sab99r/Indian-States-And-Districts/master/states-and-districts.json"
    resp = requests.get(url)
    data = resp.json()
    
    formatted_data = {}
    for entry in data.get('states', []):
        state_name = entry.get('state')
        districts = entry.get('districts', [])
        formatted_data[state_name] = districts
        
    print(f"Loaded {len(formatted_data)} states and {sum(len(v) for v in formatted_data.values())} districts.")
    
    result = db_instance.static_configs.replace_one(
        {'_id': 'states_districts'}, 
        {'_id': 'states_districts', 'data': formatted_data}, 
        upsert=True
    )
    print("MongoDB updated successfully!")
    
    print("Triggering market data update...")
    # Import scheduler and run update
    from controllers.market_scheduler import update_market_prices_job
    update_market_prices_job()
    print("All done!")

if __name__ == "__main__":
    update_all_districts()
