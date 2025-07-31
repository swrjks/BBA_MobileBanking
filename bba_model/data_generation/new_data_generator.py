import pandas as pd
import numpy as np
import os

# === Config ===
INPUT_CSV = "f_extracted_features.csv"
OUTPUT_CSV = "synthetic_f_data.csv"
SAMPLES_PER_ROW = 50  # 10,000 per legit row

# Define how much each feature is allowed to deviate (as a fraction)
DEVIATION_MAP = {
    "session_duration_seconds": 0.2,
    "mean_tap_duration_ms": 0.3,
    "std_tap_duration_ms": 0.4,
    "tap_frequency_per_sec": 0.2,
    "mean_swipe_speed": 0.3,
    "std_swipe_speed": 0.3,
    "mean_swipe_distance": 0.25,
    "std_swipe_distance": 0.3,
    "tap_zone_x": 0.1,
    "tap_zone_y": 0.1,
    "swipe_zone_x": 0.1,
    "swipe_zone_y": 0.1,
    "mean_screen_duration": 0.25,
    "std_screen_duration": 0.3,
    "fd_broken": 0,
    "loan_taken": 0,
    "time_from_login_to_fd": 0.3,
    "time_from_login_to_loan": 0.3,
    "time_from_login_transaction": 0.3,
}

# Load base legit sessions
df = pd.read_csv(INPUT_CSV)

synthetic_rows = []

for _, row in df.iterrows():
    for _ in range(SAMPLES_PER_ROW):
        new_row = {}
        for col in row.index:
            if col == "label":
                new_row[col] = 1  # legit
            elif col in ["fd_broken", "loan_taken"]:
                new_row[col] = int(row[col])  # Keep same as base
            elif col in DEVIATION_MAP:
                deviation = DEVIATION_MAP[col]
                base_val = float(row[col])
                noise = np.random.normal(0, base_val * deviation)
                new_row[col] = max(0, base_val + noise)  # Ensure no negatives
            else:
                new_row[col] = row[col]  # untouched if unexpected column
        synthetic_rows.append(new_row)

# Save to CSV
out_df = pd.DataFrame(synthetic_rows)
out_df.to_csv(OUTPUT_CSV, index=False)
print(f"[✓] Generated {len(synthetic_rows):,} legit samples → {OUTPUT_CSV}")
