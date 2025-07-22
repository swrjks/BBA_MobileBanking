import json
import joblib
import os
import sys
from argparse import ArgumentParser

# === Add 'inference/' to sys.path for importing ===
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
sys.path.append(os.path.join(BASE_DIR, "inference"))

from feature_extraction import extract_features_from_session_json

# === CLI Argument Parser ===
parser = ArgumentParser(description="Run fraud inference on a session JSON file")
parser.add_argument(
    "--session",
    type=str,
    required=True,
    help="Path to the session JSON (e.g. user_sessions/session1.json)"
)
args = parser.parse_args()

SESSION_PATH = args.session
MODEL_PATH = os.path.join(BASE_DIR, "models", "fraud_classifier.pkl")

# === Load model ===
if not os.path.exists(MODEL_PATH):
    print(f"❌ Model not found at: {MODEL_PATH}")
    sys.exit(1)

print(f"📥 Loading model from: {MODEL_PATH}")
model = joblib.load(MODEL_PATH)

# === Load session file ===
if not os.path.exists(SESSION_PATH):
    print(f"❌ Session file not found at: {SESSION_PATH}")
    sys.exit(1)

print(f"📄 Scoring session: {SESSION_PATH}")
# === Extract features ===
features = extract_features_from_session_json(SESSION_PATH)

# === Feature order must match training ===
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

# === Extract the vector ===
try:
    feature_vector = [features[k] for k in FEATURE_ORDER]
except KeyError as e:
    print(f"❌ Missing expected feature in session: {e}")
    print(f"Expected features: {FEATURE_ORDER}")
    print(f"Got features: {list(features.keys())}")
    sys.exit(1)

# === Debug print for verification ===
print("\n🧪 Final feature vector to model:")
for name, value in zip(FEATURE_ORDER, feature_vector):
    print(f"{name:25s}: {value}")

# === Validate shape ===
expected = getattr(model, "n_features_in_", None)
if expected is not None and len(feature_vector) != expected:
    print(f"❌ Feature length mismatch! Model expects {expected}, got {len(feature_vector)}")
    sys.exit(1)

# === Predict ===
pred = model.predict([feature_vector])[0]
proba = model.predict_proba([feature_vector])[0][1] if hasattr(model, "predict_proba") else None

# === Output ===
print("\n🎯 Prediction Results:")
print(f"Fraud prediction      : {'FRAUD' if pred == 1 else 'NORMAL'}")
if proba is not None:
    print(f"Fraud Probability     : {proba:.4f}")
