"""
Aadhaar Darpan Backend v5.1
Bridge between Sanitized Data, ML Intelligence, and Flutter UI.
"""

import json, os, pandas as pd, joblib
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# --- DYNAMIC PATH CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE_PATH = os.path.join(BASE_DIR, '..', 'etl_pipeline', 'processed_metrics.json')
MODEL_PATH = os.path.join(BASE_DIR, '..', 'model', 'load_forecast.pkl')

def load_data():
    if not os.path.exists(DATA_FILE_PATH): 
        return None
    try:
        with open(DATA_FILE_PATH, 'r') as f: 
            data = json.load(f)
        df = pd.DataFrame(data)
        df['State'] = df['State'].astype(str).str.strip().str.upper()
        df['District'] = df['District'].astype(str).str.strip().str.upper()
        return df
    except Exception as e:
        print(f"❌ API Load Error: {e}")
        return None

def analyze_logic(volume, ratio, ml_intelligence):
    """
    Pillar Logic Engine:
    Calculates Inclusivity status and Service Access Risk.
    """
    # Safety Check: Extract values and ensure no negatives reach the UI
    raw_forecast = ml_intelligence.get('values', [int(volume * 1.05)] * 3)
    forecast_values = [max(0, int(v)) for v in raw_forecast]
    
    accuracy = ml_intelligence.get('accuracy', 92.5)
    trend = ml_intelligence.get('trend', 'STABLE')

    # Pillar 1: Generation Saturation (Inclusivity)
    sat_status = "CRITICAL" if ratio < 0.5 else ("WARNING" if ratio < 0.7 else "SAFE")
    
    # Pillar 2: Service Access Risk (Update Velocity)
    avg_forecast = sum(forecast_values) / len(forecast_values) if forecast_values else 0
    total_activity = volume + avg_forecast
    velocity = (volume / total_activity) if total_activity > 0 else 0
    
    acc_status = "CRITICAL" if velocity < 0.75 else ("WARNING" if velocity < 0.85 else "SAFE")
    
    return {
        "inclusivity": {
            "status": sat_status, 
            "value": round(ratio, 4)
        },
        "security": {
            "status": acc_status, 
            "value": round(velocity * 100, 2)
        },
        "efficiency": {
            "status": "SAFE", 
            "biometric_traffic_trend": forecast_values,
            "accuracy": accuracy,
            "trend": trend
        }
    }

@app.route('/api/heatmap', methods=['GET'])
def get_national_heatmap():
    df = load_data()
    if df is None: return jsonify({"status": "error"}), 503
    
    heatmap_data = {}
    states = df['State'].unique()
    
    for state in states:
        state_df = df[df['State'] == state]
        pop = state_df['total_enrolment'].sum()
        ratio = (state_df['ratio'] * state_df['total_enrolment']).sum() / pop if pop > 0 else 0
        status = "CRITICAL" if ratio < 0.5 else ("WARNING" if ratio < 0.7 else "SAFE")
        heatmap_data[state] = {
            "ratio": round(ratio, 2),
            "status": status
        }
    return jsonify({"status": "success", "data": heatmap_data})

@app.route('/api/metadata', methods=['GET'])
def get_metadata():
    df = load_data()
    if df is None: return jsonify({"status": "error"}), 503
    meta = {s: sorted(df[df['State'] == s]['District'].unique().tolist()) for s in sorted(df['State'].unique())}
    return jsonify({"status": "success", "metadata": meta})

@app.route('/api/audit', methods=['GET'])
def get_audit_report():
    t_state = request.args.get('state', '').strip().upper()
    t_dist = request.args.get('district', '').strip().upper()
    
    df = load_data()
    if df is None: return jsonify({"status": "error"}), 503

    state_df = df[df['State'] == t_state]
    if state_df.empty: return jsonify({"status": "error", "message": "State not found"}), 404

    if not t_dist:
        # State-Level Weighted Analysis
        total_pop = state_df['total_enrolment'].sum()
        weighted_youth = (state_df['ratio'] * state_df['total_enrolment']).sum()
        final_ratio = weighted_youth / total_pop if total_pop > 0 else 0
        final_volume = int(state_df['mobile_update_volume'].sum())
        location_label = t_state
    else:
        # District-Level Drilldown
        dist_df = state_df[state_df['District'] == t_dist]
        if dist_df.empty: return jsonify({"status": "error", "message": "District not found"}), 404
        final_ratio = float(dist_df.iloc[0]['ratio'])
        final_volume = int(dist_df.iloc[0]['mobile_update_volume'])
        location_label = t_dist

    # --- ML HANDSHAKE ---
    try:
        model_data = joblib.load(MODEL_PATH)
        ml_intelligence = model_data.get(t_state, {
            "values": [int(final_volume * 1.1)] * 3,
            "accuracy": 85.0,
            "trend": "STABLE"
        })
    except:
        ml_intelligence = {
            "values": [int(final_volume * 1.05)] * 3,
            "accuracy": 0.0,
            "trend": "UNKNOWN"
        }

    return jsonify({
        "status": "success", 
        "location": location_label, 
        "cards": analyze_logic(final_volume, final_ratio, ml_intelligence)
    })

if __name__ == '__main__':
    # Running on 0.0.0.0 to allow mobile testing over local Wi-Fi
    app.run(debug=True, host='0.0.0.0', port=5001)