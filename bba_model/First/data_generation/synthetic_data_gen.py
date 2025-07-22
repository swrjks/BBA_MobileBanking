import numpy as np
import csv
import os
import random

# === Configs ===

OUTPUT_PATH = "labeled_session_data.csv"
NUM_SAMPLES = 50000
FRAUD_RATIO = 0.12  # 12% fraud examples

# Define min-max ranges for normalization
FEATURE_RANGES = {
    "session_duration": (30, 600),
    "mean_tap_duration": (100, 10000),
    "swipe_speed": (10, 1000),
    "swipe_distance": (50, 1000),
    "time_from_login_to_fd": (0, 120),
    "time_from_login_to_loan": (0, 120),
    "tap_speed": (0.01, 1.5),  # taps/sec
    "navigation_speed": (0.01, 0.3),  # screens/sec
}

def normalize(value, min_val, max_val):
    return np.clip((value - min_val) / (max_val - min_val), 0.0, 1.0) if max_val > min_val else 0.0

def generate_synthetic_session(is_fraud=False):
    session_duration = np.clip(np.random.normal(100 if is_fraud else 160, 30), 30, 600)
    mean_tap_duration = np.clip(np.random.normal(2500 if is_fraud else 3800, 700), 100, 10000)

    # Use tap speed instead of count (simulates interaction pace)
    tap_speed = np.clip(np.random.normal(0.5 if is_fraud else 0.2, 0.15), 0.01, 1.5)

    swipe_speed = np.clip(np.random.normal(380 if is_fraud else 260, 100), 10, 1000)
    swipe_distance = np.clip(np.random.normal(220 if is_fraud else 430, 110), 50, 1000)

    if is_fraud:
        time_to_fd = random.uniform(2, 28)
        time_to_loan = random.uniform(3, 24)
    else:
        time_to_fd = np.clip(np.random.normal(60, 20), 15, 120)
        time_to_loan = np.clip(np.random.normal(70, 22), 15, 120)

    screens_visited = random.randint(3, 7 if is_fraud else 9)
    navigation_speed = screens_visited / session_duration

    # Label logic: stronger if risky timing is used
    fraud_label = int(
        is_fraud or
        (time_to_fd < 22 and random.random() < 0.65) or
        (time_to_loan < 20 and random.random() < 0.65)
    )

    return [
        normalize(session_duration, *FEATURE_RANGES["session_duration"]),
        normalize(mean_tap_duration, *FEATURE_RANGES["mean_tap_duration"]),
        normalize(tap_speed, *FEATURE_RANGES["tap_speed"]),
        normalize(swipe_speed, *FEATURE_RANGES["swipe_speed"]),
        normalize(swipe_distance, *FEATURE_RANGES["swipe_distance"]),
        normalize(time_to_fd, *FEATURE_RANGES["time_from_login_to_fd"]),
        normalize(time_to_loan, *FEATURE_RANGES["time_from_login_to_loan"]),
        normalize(navigation_speed, *FEATURE_RANGES["navigation_speed"]),
        fraud_label
    ]

def generate_dataset(num_samples=NUM_SAMPLES):
    output_dir = os.path.dirname(OUTPUT_PATH)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    header = [
        "session_duration",
        "mean_tap_duration",
        "tap_speed",
        "swipe_speed",
        "swipe_distance",
        "time_from_login_to_fd",
        "time_from_login_to_loan",
        "navigation_speed",
        "fraud_label"
    ]

    with open(OUTPUT_PATH, mode='w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for _ in range(num_samples):
            is_fraud = random.random() < FRAUD_RATIO
            writer.writerow(generate_synthetic_session(is_fraud))
    print(f"✅ Generated {num_samples} labeled sessions to: {OUTPUT_PATH}")

if __name__ == "__main__":
    generate_dataset()
