import json
import os
import pandas as pd
import joblib  # <-- NEW: Tool to load Member 3's ML model
from flask import Flask, request, jsonify
from flask_cors import CORS

# --- CONFIGURATION ---
app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE_PATH = os.path.join(BASE_DIR, '..', 'etl_pipeline', 'processed_metrics.json')
# Path to the new ML brain merged from Member 3
MODEL_PATH = os.path.join(BASE_DIR, '..', 'model', 'load_forecast.pkl')

# --- ML MODEL LOADER ---
# Load the brain once when the server starts so it stays fast
try:
    forecast_model = joblib.load(MODEL_PATH)
    print("✅ ML Forecasting Model loaded successfully.")
except Exception as e:
    forecast_model = None
    print(f"⚠️ Warning: Could not load ML model: {e}")

# --- DATA LOADER ---
def load_data():
    if not os.path.exists(DATA_FILE_PATH):
        print(f"[ERROR] Could not find data file at: {DATA_FILE_PATH}")
        return None
    try:
        with open(DATA_FILE_PATH, 'r') as f:
            data = json.load(f)
        
        if isinstance(data, dict) and 'records' in data:
            record_list = data['records']
        else:
            record_list = data 
            
        return pd.DataFrame(record_list)
    except Exception as e:
        print(f"[ERROR] Failed to read JSON: {e}")
        return None

# --- INTELLIGENCE LOGIC ---
def analyze_district(record, model):
    metrics = record
    
    # 1. SECURITY LOGIC
    mobile_updates = metrics.get('Mobile_Number_Updates', 0)
    if mobile_updates > 1000:
        sec_status, sec_msg = "CRITICAL", f"High Anomaly: {mobile_updates} updates detected."
    else:
        sec_status, sec_msg = "SAFE", "Normal activity."

    # 2. INCLUSIVITY LOGIC
    female = metrics.get('Gender_Female', 0)
    total = metrics.get('Total_Enrolment', 1)
    ratio = female / total if total > 0 else 0
    inc_status = "WARNING" if ratio < 0.40 else "SAFE"
    inc_msg = f"Low Female Enrolment ({int(ratio*100)}%)" if ratio < 0.40 else "Gender Ratio Healthy."

    # 3. EFFICIENCY LOGIC (AI FORECASTING)
    # Default forecast if the model is missing
    forecast_values = metrics.get('Biometric_Updates', [])[-3:] 
    
    if model:
        try:
            # Ask the AI to look 3 months into the future
            future = model.make_future_dataframe(periods=3, freq='MS')
            forecast = model.predict(future)
            # 'yhat' is the AI's predicted value
            forecast_values = forecast['yhat'].tail(3).astype(int).tolist()
        except Exception as e:
            print(f"Prediction Error: {e}")

    return {
        "security": { "status": sec_status, "message": sec_msg, "value": mobile_updates },
        "inclusivity": { "status": inc_status, "message": inc_msg, "value": ratio },
        "efficiency": { "status": "SAFE", "forecast": forecast_values }
    }

# --- API ENDPOINT ---
@app.route('/api/audit', methods=['GET'])
def get_audit_report():
    target_district = request.args.get('district')
    
    if not target_district:
        return jsonify({"status": "error", "message": "Please provide a district name"}), 400

    df = load_data()
    if df is None:
        return jsonify({"status": "error", "message": "Data Pipeline Not Ready"}), 503

    all_records = df.to_dict('records')
    match = next((item for item in all_records if item.get("District", "").lower() == target_district.lower()), None)

    if not match:
        return jsonify({"status": "error", "message": "District not found"}), 404

    # Pass the ML model into our analysis function
    cards_data = analyze_district(match, forecast_model)

    return jsonify({
        "status": "success",
        "district": match.get('District'),
        "state": match.get('State'),
        "cards": cards_data
    })

if __name__ == '__main__':
    print("🚀 Aadhaar Darpan Backend with AI Forecasting is Starting...")
    app.run(debug=True, host='0.0.0.0', port=5000)