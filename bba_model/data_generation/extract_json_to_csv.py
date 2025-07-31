import os
import json
import numpy as np
import pandas as pd
from glob import glob

def calculate_stats(lst):
    """Calculate mean and std; return NaN if empty list."""
    if not lst:
        return np.nan, np.nan
    return np.mean(lst), np.std(lst)

def zone_to_xy(zone_str):
    """Convert zone string (e.g., 'top_left') into numeric (x,y) coords in a 3x3 grid."""
    y_mapping = {"top": 0, "middle": 1, "bottom": 2}
    x_mapping = {"left": 0, "center": 1, "right": 2}
    try:
        parts = zone_str.split("_")
        if len(parts) == 2:
            y_part, x_part = parts[0], parts[1]
            return x_mapping.get(x_part, np.nan), y_mapping.get(y_part, np.nan)
    except:
        pass
    return np.nan, np.nan

def extract_features_from_custom_json(data):
    session_duration = data.get("session", {}).get("duration_seconds", np.nan)

    tap_durations = data.get("tap_durations_ms", [])
    mean_tap_duration, std_tap_duration = calculate_stats(tap_durations)

    tap_events = data.get("tap_events", [])
    tap_freq = len(tap_events) / session_duration if session_duration > 0 else np.nan

    # Tap zones: convert zone strings to numeric coords and get mean for x and y
    tap_zones = [tap.get("zone", "") for tap in tap_events]
    tap_zone_x_coords = []
    tap_zone_y_coords = []
    for z in tap_zones:
        x, y = zone_to_xy(z)
        if x == x and y == y:  # not NaN
            tap_zone_x_coords.append(x)
            tap_zone_y_coords.append(y)
    tap_zone_x, _ = calculate_stats(tap_zone_x_coords)
    tap_zone_y, _ = calculate_stats(tap_zone_y_coords)

    # Swipe features
    swipe_events = data.get("swipe_events", [])
    swipe_speeds = [s.get("speed_px_per_ms", np.nan) for s in swipe_events]
    swipe_distances = [s.get("distance_px", np.nan) for s in swipe_events]
    swipe_speeds = [s for s in swipe_speeds if s == s]  # filter nan
    swipe_distances = [d for d in swipe_distances if d == d]
    mean_swipe_speed, std_swipe_speed = calculate_stats(swipe_speeds)
    mean_swipe_distance, std_swipe_distance = calculate_stats(swipe_distances)

    # Swipe zones: estimated from tap zones on the same screens where swipes occur
    swipe_zone_x_vals = []
    swipe_zone_y_vals = []
    swipe_screens = set(s.get("screen") for s in swipe_events if s.get("screen"))
    for screen in swipe_screens:
        screen_taps = [tap for tap in tap_events if tap.get("screen") == screen]
        screen_zone_x_coords = []
        screen_zone_y_coords = []
        for tap in screen_taps:
            z = tap.get("zone", "")
            x, y = zone_to_xy(z)
            if x == x and y == y:
                screen_zone_x_coords.append(x)
                screen_zone_y_coords.append(y)
        swipe_zone_x_vals.extend(screen_zone_x_coords)
        swipe_zone_y_vals.extend(screen_zone_y_coords)
    swipe_zone_x, _ = calculate_stats(swipe_zone_x_vals)
    swipe_zone_y, _ = calculate_stats(swipe_zone_y_vals)

    # Screen durations
    screen_durations = data.get("screen_durations", {})
    screen_duration_values = list(screen_durations.values())
    mean_screen_duration, std_screen_duration = calculate_stats(screen_duration_values)

    # Session flags and times
    session_input = data.get("session_input", {})
    fd_broken_bool = session_input.get("fd_broken", False)
    loan_taken_bool = session_input.get("loan_taken", False)

    # Convert booleans to ints
    fd_broken = int(fd_broken_bool)
    loan_taken = int(loan_taken_bool)

    time_from_login_to_fd = session_input.get("time_from_login_to_fd", np.nan)
    time_from_login_to_loan = session_input.get("time_from_login_to_loan", np.nan)
    time_from_login_transaction = session_input.get("time_from_login_to_transaction", np.nan)

    label = np.nan  # Modify here if your JSON contains a label field

    return {
        "session_duration_seconds": session_duration,
        "mean_tap_duration_ms": mean_tap_duration,
        "std_tap_duration_ms": std_tap_duration,
        "tap_frequency_per_sec": tap_freq,
        "mean_swipe_speed": mean_swipe_speed,
        "std_swipe_speed": std_swipe_speed,
        "mean_swipe_distance": mean_swipe_distance,
        "std_swipe_distance": std_swipe_distance,
        "tap_zone_x": tap_zone_x,
        "tap_zone_y": tap_zone_y,
        "swipe_zone_x": swipe_zone_x,
        "swipe_zone_y": swipe_zone_y,
        "mean_screen_duration": mean_screen_duration,
        "std_screen_duration": std_screen_duration,
        "fd_broken": fd_broken,
        "loan_taken": loan_taken,
        "time_from_login_to_fd": time_from_login_to_fd,
        "time_from_login_to_loan": time_from_login_to_loan,
        "time_from_login_transaction": time_from_login_transaction,
        "label": 1
    }

def process_json_folder(json_folder, output_csv_path):
    json_files = glob(os.path.join(json_folder, "*.json"))
    rows = []
    for file_path in json_files:
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
            features = extract_features_from_custom_json(data)
            rows.append(features)
        except Exception as e:
            print(f"⚠️ Error processing {file_path}: {e}")

    df = pd.DataFrame(rows)

    # Enforce the required column order:
    columns_order = [
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
        "fd_broken",
        "loan_taken",
        "time_from_login_to_fd",
        "time_from_login_to_loan",
        "time_from_login_transaction",
        "label"
    ]
    df = df[columns_order]

    df.to_csv(output_csv_path, index=False)
    print(f"✅ Features saved to {output_csv_path} ({len(df)} sessions)")

if __name__ == "__main__":
    # Provide your JSON folder path here:
    json_folder = r"C:\Users\swara\Desktop\fraud_sdk_ml_demo\data_generation\base_jsons"
    output_csv = "fraud_extracted_features.csv"
    process_json_folder(json_folder, output_csv)
