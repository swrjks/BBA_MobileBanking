import pandas as pd
import numpy as np
import os

# --- CONFIGURATION ---
TEST_DIR = "C:/Users/swara/Desktop/fraud_sdk_ml_demo/model/test/test_data"
OUTPUT_DIR = os.path.join(TEST_DIR, "noisy")
NOISE_STD_FRACTION = 0.12  # 12% of std dev for numeric features
NOISE_COLUMNS = [  # columns to apply numeric noise
    "session_duration_seconds",
    "mean_tap_duration_ms",
    "std_tap_duration_ms",
    "tap_frequency_per_sec",
    "mean_swipe_speed",
    "std_swipe_speed",
    "mean_swipe_distance",
    "std_swipe_distance",
    "tap_zone_x",
    "tap_zone_y",
    "swipe_zone_x",
    "swipe_zone_y",
    "mean_screen_duration",
    "std_screen_duration",
    "time_from_login_to_fd",
    "time_from_login_to_loan",
    "time_from_login_transaction"
]

# --- Ensure output directory exists ---
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Add noise function ---
def add_noise(df: pd.DataFrame, noise_level: float) -> pd.DataFrame:
    noisy_df = df.copy()
    for col in NOISE_COLUMNS:
        if col in df.columns:
            std_dev = df[col].std()
            noise = np.random.normal(loc=0, scale=noise_level * std_dev, size=len(df))
            noisy_df[col] = df[col] + noise
            # Ensure no negative values for certain features
            if col in ["session_duration_seconds", "mean_tap_duration_ms", "tap_frequency_per_sec"]:
                noisy_df[col] = noisy_df[col].clip(lower=0)
    return noisy_df

# --- Process all test files ---
for file in os.listdir(TEST_DIR):
    if file.endswith(".csv") and not file.startswith("noisy_"):
        file_path = os.path.join(TEST_DIR, file)
        df = pd.read_csv(file_path)

        noisy_df = add_noise(df, NOISE_STD_FRACTION)

        # Optional: Round for realism
        noisy_df[NOISE_COLUMNS] = noisy_df[NOISE_COLUMNS].round(2)

        output_file = os.path.join(OUTPUT_DIR, f"noisy_{file}")
        noisy_df.to_csv(output_file, index=False)
        print(f"✅ Noisy file created: {output_file}")
