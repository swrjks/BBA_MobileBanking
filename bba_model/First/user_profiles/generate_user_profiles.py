import os
import json
from glob import glob
import numpy as np
from collections import Counter

# Set normalization ranges
FEATURE_RANGES = {
    "session_duration": (30, 600),
    "mean_tap_duration": (100, 10000),
    "std_tap_duration": (0, 5000),
    "tap_count": (0, 50),
    "mean_swipe_speed": (10, 1000),
    "std_swipe_speed": (0, 600),
    "mean_swipe_distance": (50, 1000),
    "std_swipe_distance": (0, 500),
    "swipe_count": (0, 20),
    "unique_screens_count": (1, 20),
    "time_from_login_to_fd": (0, 120),
    "time_from_login_to_loan": (0, 120),
    "time_between_fd_and_loan": (0, 120),
    "transaction_amount": (0, 100000)
}

def normalize(value, min_val, max_val):
    return (value - min_val) / (max_val - min_val) if max_val > min_val else 0.0

def extract_navigation_flow(session):
    screens = session.get("screens_visited", [])
    return tuple(s.get("screen") for s in screens if "screen" in s)

def extract_features_from_session_json(session):
    f = {}
    try:
        f["session_duration"] = normalize(
            session.get("session", {}).get("duration_seconds", 0),
            *FEATURE_RANGES["session_duration"]
        )
        taps = session.get("tap_durations_ms", [])
        f["mean_tap_duration"] = normalize(np.mean(taps) if taps else 0, *FEATURE_RANGES["mean_tap_duration"])
        f["std_tap_duration"] = normalize(np.std(taps) if taps else 0, *FEATURE_RANGES["std_tap_duration"])
        f["tap_count"] = normalize(len(taps), *FEATURE_RANGES["tap_count"])

        swipes = session.get("swipe_events", [])
        swipe_speeds = [s.get("speed_px_per_ms", 0) for s in swipes]
        swipe_dists = [s.get("distance_px", 0) for s in swipes]
        f["mean_swipe_speed"] = normalize(np.mean(swipe_speeds) if swipe_speeds else 0, *FEATURE_RANGES["mean_swipe_speed"])
        f["std_swipe_speed"] = normalize(np.std(swipe_speeds) if swipe_speeds else 0, *FEATURE_RANGES["std_swipe_speed"])
        f["mean_swipe_distance"] = normalize(np.mean(swipe_dists) if swipe_dists else 0, *FEATURE_RANGES["mean_swipe_distance"])
        f["std_swipe_distance"] = normalize(np.std(swipe_dists) if swipe_dists else 0, *FEATURE_RANGES["std_swipe_distance"])
        f["swipe_count"] = normalize(len(swipes), *FEATURE_RANGES["swipe_count"])

        screens = session.get("screens_visited", [])
        screen_names = [s.get("screen") for s in screens if "screen" in s]
        f["unique_screens_count"] = normalize(len(set(screen_names)), *FEATURE_RANGES["unique_screens_count"])

        f["fd_broken"] = int(session.get("session_input", {}).get("fd_broken", False))
        f["loan_taken"] = int(session.get("session_input", {}).get("loan_taken", False))
        f["screen_recording_detected"] = int(session.get("screen_recording_detected", False))
        f["transaction_amount"] = normalize(
            float(session.get("session_input", {}).get("transaction_amount", 0)) or 0,
            *FEATURE_RANGES["transaction_amount"]
        )
        f["time_from_login_to_fd"] = normalize(
            session.get("session_input", {}).get("time_from_login_to_fd") or 0,
            *FEATURE_RANGES["time_from_login_to_fd"]
        )
        f["time_from_login_to_loan"] = normalize(
            session.get("session_input", {}).get("time_from_login_to_loan") or 0,
            *FEATURE_RANGES["time_from_login_to_loan"]
        )
        f["time_between_fd_and_loan"] = normalize(
            session.get("session_input", {}).get("time_between_fd_and_loan") or 0,
            *FEATURE_RANGES["time_between_fd_and_loan"]
        )
    except Exception as e:
        print(f"❌ Error extracting features: {e}")
        return {}, ()

    nav_flow = extract_navigation_flow(session)
    return f, nav_flow

def generate_user_profiles(user_sessions_dir, output_path):
    user_data = {}
    nav_flow_counter = Counter()
    files = glob(os.path.join(user_sessions_dir, "*.json"))
    print(f"📂 Found {len(files)} session files.")

    for file_path in files:
        try:
            with open(file_path, 'r') as f:
                session = json.load(f)
            features, nav_flow = extract_features_from_session_json(session)
            if not features:
                print(f"⚠️ Skipped {file_path} due to empty features.")
                continue
            user_id = "user_001"
            user_data.setdefault(user_id, []).append(features)
            if nav_flow:
                nav_flow_counter[nav_flow] += 1
            print(f"✅ Processed: {file_path}")
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")

    user_profiles = {}
    for user_id, sessions in user_data.items():
        if not sessions:
            continue
        feature_keys = sessions[0].keys()
        aggregated = {}
        for key in feature_keys:
            vals = [sess[key] for sess in sessions if key in sess]
            aggregated[key] = {
                "mean": float(np.mean(vals)),
                "std": float(np.std(vals)),
                "min": float(np.min(vals)),
                "max": float(np.max(vals))
            }
        most_common_flow = nav_flow_counter.most_common(1)
        aggregated["most_common_navigation_flow"] = list(most_common_flow[0][0]) if most_common_flow else []
        user_profiles[user_id] = aggregated

    if not user_profiles:
        print("⚠️ No valid user profiles to save.")
        return

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(user_profiles, f, indent=2)
    print(f"\n✅ User profile saved to: {output_path}")

if __name__ == "__main__":
    USER_SESSIONS_DIR = r"C:\Users\swara\Desktop\fraud_sdk_ml_demo\user_sessions"
    OUTPUT_PROFILE_PATH = r"C:\Users\swara\Desktop\fraud_sdk_ml_demo\user_profiles\user_001_profile.json"
    generate_user_profiles(USER_SESSIONS_DIR, OUTPUT_PROFILE_PATH)
