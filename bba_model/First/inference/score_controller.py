import os
import json
import joblib
from collections import Counter
from feature_extraction import extract_features_from_session_json

# === Constants ===
MODEL_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "models", "fraud_classifier.pkl"))
USER_PROFILE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../user_profiles"))

FEATURE_ORDER = [
    "session_duration",
    "mean_tap_duration",
    "tap_speed",
    "swipe_speed",
    "swipe_distance",
    "time_from_login_to_fd",
    "time_from_login_to_loan",
    "navigation_speed"
]

# === Utility: Load Model ===
def load_model():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Model not found at {MODEL_PATH}")
    return joblib.load(MODEL_PATH)

# === Utility: Load User Profile ===
def load_user_profile(user_id):
    profile_path = os.path.join(USER_PROFILE_DIR, f"{user_id}_profile.json")
    if not os.path.exists(profile_path):
        return None
    with open(profile_path, "r") as f:
        return json.load(f)

# === Utility: Compute Similarity (Euclidean) ===
def compute_behavior_similarity(session_features, profile_features):
    diffs = []
    for key in FEATURE_ORDER:
        if key in session_features and key in profile_features:
            diffs.append((session_features[key] - profile_features[key]) ** 2)
    distance = sum(diffs) ** 0.5
    return 1 / (1 + distance)  # Closer = higher similarity

# === Environment Score ===
def get_environment_score(session_data):
    env_flags = session_data.get("environment", {})
    suspicious = env_flags.get("is_screen_recording", False) or \
                 env_flags.get("is_emulator", False) or \
                 env_flags.get("is_device_rooted", False)
    return 0.0 if suspicious else 1.0

# === Extract Navigation Flow ===
def extract_most_common_navigation_flow(session_data):
    pages = session_data.get("navigation_log", [])
    flow = [page["page"] for page in pages]
    return " -> ".join(flow) if flow else None

# === Main Evaluation Logic ===
def evaluate_session(session_path, user_id):
    # --- Load model ---
    model = load_model()

    # --- Load session JSON & extract features ---
    with open(session_path, "r") as f:
        session_data = json.load(f)

    features = extract_features_from_session_json(session_data)
    feature_vector = [features.get(k, 0) for k in FEATURE_ORDER]

    # --- Predict with model ---
    model_proba = model.predict_proba([feature_vector])[0][1]

    # --- Environment trust score ---
    environment_score = get_environment_score(session_data)

    # --- Load profile & calculate similarity ---
    user_profile = load_user_profile(user_id)
    if user_profile:
        similarity = compute_behavior_similarity(features, user_profile)
        trust_score = (
            0.5 * similarity +
            0.3 * environment_score +
            0.2 * (1 - model_proba)
        )
    else:
        similarity = None
        trust_score = 0.3 * environment_score + 0.7 * (1 - model_proba)

    trust_score_100 = trust_score * 100

    # --- Final decision ---
    if trust_score_100 < 40:
        action = "LOCK"
    elif trust_score_100 < 60:
        action = "OTP"
    else:
        action = "ALLOW"

    # === Heuristic Override (FD fraud case) ===
    input_data = session_data.get("session_input", {})
    if input_data.get("fd_broken", False):
        time_to_fd = features.get("time_from_login_to_fd", 9999)
        if time_to_fd is not None and time_to_fd < 15:
            action = "OTP"
            print("⚠️  Override: FD broken too quickly — forcing OTP")

    return {
        "model_score": model_proba,
        "behavior_similarity": similarity,
        "environment_score": environment_score,
        "trust_score": trust_score_100,
        "action": action,
        "navigation_flow": extract_most_common_navigation_flow(session_data)
    }

# === CLI Entry Point ===
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Evaluate session trust score")
    parser.add_argument("--session", required=True, help="Path to session JSON")
    parser.add_argument("--user_id", required=False, help="User ID for profile lookup (optional)")
    args = parser.parse_args()

    user_id = args.user_id or "unknown_user"
    result = evaluate_session(args.session, user_id)

    print("\n🧠 Inference Decision:")
    print(f"Model Probability       : {result['model_score']:.4f}")
    if result["behavior_similarity"] is not None:
        print(f"Behavior Similarity     : {result['behavior_similarity']:.4f}")
    else:
        print("Behavior Similarity     : N/A (no profile)")
    print(f"Environment Score       : {result['environment_score']:.2f}")
    print(f"Final Trust Score       : {result['trust_score']:.2f} / 100")

    print(f"\n🚦 Action Taken         : {result['action']}")
    if result.get("navigation_flow"):
        print(f"📌 Navigation Flow      : {result['navigation_flow']}")
