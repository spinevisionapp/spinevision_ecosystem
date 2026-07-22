import json
import os

DATA_DIR = 'firebase/data'
OUTPUT_DIR = 'firebase/data/hierarchical'

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# Mapping of flat files to their new subcollection names
COLLECTION_MAP = {
    'Library.json': 'library',
    'Listings.json': 'listings',
    'Scans.json': 'scans',
    'CRM.json': 'crm',
    'Profit.json': 'sales', # Mapping Profit to sales for this example
    'Membership.json': 'settings' # Mapping Membership to settings
}

def migrate():
    hierarchical_data = {}

    for filename, subcollection in COLLECTION_MAP.items():
        file_path = os.path.join(DATA_DIR, filename)
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r') as f:
            records = json.load(f)
            
        for record in records:
            user_id = record.get('user_id')
            if not user_id:
                continue
                
            if user_id not in hierarchical_data:
                hierarchical_data[user_id] = {}
                
            if subcollection not in hierarchical_data[user_id]:
                hierarchical_data[user_id][subcollection] = []
                
            hierarchical_data[user_id][subcollection].append(record)

    # Save migrated data by user or as a master file
    for user_id, data in hierarchical_data.items():
        user_file = os.path.join(OUTPUT_DIR, f'{user_id}.json')
        with open(user_file, 'w') as f:
            json.dump(data, f, indent=2)
        print(f'Migrated data for {user_id} to {user_file}')

if __name__ == '__main__':
    migrate()
