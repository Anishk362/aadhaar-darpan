"""
Member 3: ML Forecaster
Project: Aadhaar Darpan

Input  : src/etl_pipeline/processed_metrics.json
Output : src/model/load_forecast.pkl

Forecasts Biometric_Updates for next 3 months
"""

import json
import pandas as pd
from prophet import Prophet
import joblib
from pathlib import Path

DATA_PATH = Path("src/etl_pipeline/processed_metrics.json")
MODEL_PATH = Path("src/model/load_forecast.pkl")


def load_processed_metrics():
    with open(DATA_PATH, "r") as f:
        return json.load(f)


def prepare_timeseries(data):
    """
    JSON structure:
    {
      "records": [
        {
          "District": "Lucknow",
          "Biometric_Updates": [1200, 1350, 1420, 1600, 1550]
        }
      ]
    }
    """

    records = []

    for district_record in data["records"]:
        biometric_series = district_record["Biometric_Updates"]

        for i, value in enumerate(biometric_series):
            records.append({
                "ds": pd.Timestamp("2025-01-01") + pd.DateOffset(months=i),
                "y": value
            })

    df = pd.DataFrame(records)

    # Aggregate across districts (system-wide load)
    df = df.groupby("ds", as_index=False)["y"].sum()

    return df


def train_prophet(df):
    model = Prophet(
        yearly_seasonality=False,
        weekly_seasonality=False,
        daily_seasonality=False
    )
    model.fit(df)
    return model


def main():
    print("Loading processed metrics...")
    data = load_processed_metrics()

    print("Preparing time-series data...")
    ts_df = prepare_timeseries(data)

    print("Training forecasting model...")
    model = train_prophet(ts_df)

    print("Saving model...")
    joblib.dump(model, MODEL_PATH)

    print("✅ load_forecast.pkl created successfully")


if __name__ == "__main__":
    main()
