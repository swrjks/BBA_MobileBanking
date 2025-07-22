import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.model_selection import train_test_split
import joblib
import json
import hashlib
from datetime import datetime, timedelta
from collections import defaultdict
import warnings
import os
import math
from scipy import stats
from typing import List, Dict, Any

# Suppress warnings
warnings.filterwarnings("ignore")

# Enhanced Configuration with behavioral thresholds
CONFIG = {
    "data_columns": [
        # Tap behavior (6 features)
        "tap_duration_mean", "tap_duration_std", 
        "tap_interval_mean", "tap_interval_std",
        "tap_consistency_score", "tap_outliers",
        
        # Swipe behavior (3 features)
        "swipe_speed_mean", "swipe_speed_std", 
        "swipe_angle_variance",
        
        # Navigation (4 features)
        "screen_transitions", "unique_screens",
        "screen_duration_mean", "screen_duration_std",
        
        # Context (3 features)
        "time_of_day_sin", "time_of_day_cos",
        "transaction_risk_score"
    ],
    "model_params": {
        "input_dim": 16,
        "hidden_dim": 12,
        "output_dim": 1,
        "lr": 0.001,
        "epochs": 50,
        "batch_size": 64,
        "dropout": 0.2
    },
    "behavior_thresholds": {
        # Tap thresholds (in milliseconds)
        "min_tap_duration": 50,
        "max_tap_duration": 2000,
        "max_tap_interval": 5000,
        
        # Swipe thresholds
        "min_swipe_speed": 0.3,  # px/ms
        "max_swipe_speed": 2.5,
        
        # Model thresholds
        "trust_threshold": 0.35,
        "z_score_threshold": 2.0
    }
}

class UserProfile:
    """Enhanced user profile with behavioral baselines"""
    def __init__(self, user_id):
        self.user_id = user_id
        self.behavior_baselines = {
            "tap_duration": {"mean": 300, "std": 50},
            "tap_intervals": {"mean": 800, "std": 200},
            "swipe_speed": {"mean": 1.2, "std": 0.3}
        }
        self.update_count = 0
        
    def update_behavior(self, new_session):
        """Exponentially weighted moving average for behavioral metrics"""
        alpha = 0.2  # Learning rate
        
        for metric in ["tap_duration", "tap_intervals", "swipe_speed"]:
            current_mean = new_session.get(f"{metric}_mean", 0)
            current_std = new_session.get(f"{metric}_std", 0)
            
            if self.update_count == 0:
                self.behavior_baselines[metric]["mean"] = current_mean
                self.behavior_baselines[metric]["std"] = current_std
            else:
                self.behavior_baselines[metric]["mean"] = alpha * current_mean + (1-alpha) * self.behavior_baselines[metric]["mean"]
                self.behavior_baselines[metric]["std"] = alpha * current_std + (1-alpha) * self.behavior_baselines[metric]["std"]
        
        self.update_count += 1

class BehaviorTrustSDK:
    """Advanced fraud detection with behavioral analysis"""
    def __init__(self):
        self.model = None
        self.tflite_model = None  # TFLite model instance
        self.scaler = StandardScaler()
        self.normalizer = MinMaxScaler()
        self.user_profiles = {}  # Changed from defaultdict to regular dict
        self.is_trained = False
    
    def _analyze_taps(self, tap_durations: List[int], tap_timestamps: List[float]) -> Dict[str, float]:
        """Enhanced tap behavior analysis"""
        features = {}
        
        # Basic statistics
        features["tap_duration_mean"] = np.mean(tap_durations) if tap_durations else 0
        features["tap_duration_std"] = np.std(tap_durations) if tap_durations else 0
        
        # Tap intervals (time between taps)
        intervals = np.diff(tap_timestamps) if len(tap_timestamps) > 1 else np.array([0])
        features["tap_interval_mean"] = np.mean(intervals)
        features["tap_interval_std"] = np.std(intervals)
        
        # Consistency score (1 = perfect consistency, 0 = random)
        if len(tap_durations) > 2:
            features["tap_consistency_score"] = 1 - (np.std(tap_durations) / features["tap_duration_mean"])
        else:
            features["tap_consistency_score"] = 0.5
            
        # Outlier detection
        features["tap_outliers"] = sum(
            (d < CONFIG["behavior_thresholds"]["min_tap_duration"]) or 
            (d > CONFIG["behavior_thresholds"]["max_tap_duration"])
            for d in tap_durations
        ) if tap_durations else 0
        
        return features
    
    def _analyze_swipes(self, swipe_events: List[Dict[str, Any]]) -> Dict[str, float]:
        """Swipe dynamics analysis"""
        features = {
            "swipe_speed_mean": 0,
            "swipe_speed_std": 0,
            "swipe_angle_variance": 0
        }
        
        if not swipe_events:
            return features
            
        speeds = [s["speed_px_per_ms"] for s in swipe_events]
        angles = [s.get("angle", 0) for s in swipe_events]  # Angle in degrees
        
        features["swipe_speed_mean"] = np.mean(speeds)
        features["swipe_speed_std"] = np.std(speeds)
        features["swipe_angle_variance"] = np.var(angles)
        
        return features
    
    def _preprocess_session_data(self, raw_data: Dict[str, Any]) -> Dict[str, Any]:
        """Preprocess raw session data to extract timestamps and validate structure"""
        processed = raw_data.copy()
        
        # Extract tap timestamps from tap events
        processed["tap_timestamps"] = [
            datetime.fromisoformat(t["timestamp"]).timestamp()
            for t in processed["tap_events"]
        ] if "tap_events" in processed else []
        
        # Calculate session duration if not provided
        if "duration_seconds" not in processed["session"]:
            start_time = datetime.fromisoformat(processed["session"]["start"])
            end_time = datetime.fromisoformat(processed["session"]["end"])
            processed["session"]["duration_seconds"] = (end_time - start_time).total_seconds()
        
        return processed
    
    def _extract_features(self, raw_data: Dict[str, Any]) -> pd.DataFrame:
        """Feature engineering pipeline"""
        features = {}
        
        # Preprocess raw data
        processed_data = self._preprocess_session_data(raw_data)
        
        # 1. Tap Behavior Analysis
        tap_data = self._analyze_taps(
            processed_data["tap_durations_ms"],
            processed_data["tap_timestamps"]
        )
        features.update(tap_data)
        
        # 2. Swipe Analysis
        swipe_data = self._analyze_swipes(processed_data["swipe_events"])
        features.update(swipe_data)
        
        # 3. Navigation Patterns
        screens = processed_data["screens_visited"]
        features["screen_transitions"] = len(processed_data["tap_events"])
        features["unique_screens"] = len(set(s["screen"] for s in screens))
        
        # 4. Screen Duration Analysis
        if processed_data["screen_durations"]:
            durations = list(processed_data["screen_durations"].values())
            features["screen_duration_mean"] = np.mean(durations)
            features["screen_duration_std"] = np.std(durations)
        else:
            features["screen_duration_mean"] = 0
            features["screen_duration_std"] = 0
            
        # 5. Temporal Context
        start_time = datetime.fromisoformat(processed_data["session"]["start"])
        hour_of_day = start_time.hour + start_time.minute/60
        features["time_of_day_sin"] = math.sin(2 * math.pi * hour_of_day / 24)
        features["time_of_day_cos"] = math.cos(2 * math.pi * hour_of_day / 24)
        
        # 6. Transaction Risk
        tx_amount = float(processed_data.get("session_input", {}).get("transaction_amount", 0))
        features["transaction_risk_score"] = min(1.0, math.log1p(tx_amount) / 10)  # 0-1 scale
        
        return pd.DataFrame([features])[CONFIG["data_columns"]]
    
    def _detect_behavioral_anomalies(self, features_df: pd.DataFrame, user_id: str, raw_data: Dict[str, Any]) -> List[str]:
        """Rule-based anomaly detection"""
        # Create user profile if it doesn't exist
        if user_id not in self.user_profiles:
            self.user_profiles[user_id] = UserProfile(user_id)
            
        profile = self.user_profiles[user_id]
        features = features_df.iloc[0] if isinstance(features_df, pd.DataFrame) else features_df
        anomalies = []
        
        # 1. Tap Duration Anomalies
        tap_mean = features["tap_duration_mean"]
        baseline = profile.behavior_baselines["tap_duration"]
        if abs(tap_mean - baseline["mean"]) > 2 * baseline["std"]:
            anomalies.append("abnormal_tap_duration")
            
        # 2. Robotic Tap Pattern
        if (features["tap_consistency_score"] > 0.9 and 
            len(raw_data["tap_durations_ms"]) > 10):
            anomalies.append("overly_consistent_taps")
            
        # 3. Swipe Speed Anomalies
        swipe_speed = features["swipe_speed_mean"]
        if not (CONFIG["behavior_thresholds"]["min_swipe_speed"] <= swipe_speed <= CONFIG["behavior_thresholds"]["max_swipe_speed"]):
            anomalies.append("abnormal_swipe_speed")
            
        # 4. Tap Outliers
        if features["tap_outliers"] > 3:  # More than 3 outlier taps
            anomalies.append("excessive_tap_outliers")
            
        return anomalies
    
    def build_model(self) -> keras.Model:
        """Build the neural network model"""
        model = keras.Sequential([
            keras.layers.Dense(CONFIG["model_params"]["hidden_dim"], 
                              input_dim=CONFIG["model_params"]["input_dim"], 
                              activation='relu'),
            keras.layers.Dropout(CONFIG["model_params"]["dropout"]),
            keras.layers.Dense(CONFIG["model_params"]["hidden_dim"]//2, activation='relu'),
            keras.layers.Dense(CONFIG["model_params"]["output_dim"], activation='sigmoid')
        ])
        
        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=CONFIG["model_params"]["lr"]),
            loss='binary_crossentropy',
            metrics=['accuracy']
        )
        return model
    
    def preprocess_data(self, session_data: Dict[str, Any]) -> np.ndarray:
        """Normalize and scale features"""
        features = self._extract_features(session_data)
        scaled = self.scaler.fit_transform(features)
        normalized = self.normalizer.fit_transform(scaled)
        return normalized[0]  # Return first (and only) sample
    
    def train(self, normal_sessions: List[Dict[str, Any]], fraud_sessions: List[Dict[str, Any]] = None) -> None:
        """Train with enhanced synthetic fraud generation"""
        # Preprocess normal sessions
        X_normal = np.vstack([self.preprocess_data(s) for s in normal_sessions])
        y_normal = np.zeros(len(X_normal))
        
        # Generate synthetic fraud if not provided
        if not fraud_sessions:
            fraud_sessions = self._generate_synthetic_fraud(normal_sessions)
        
        X_fraud = np.vstack([self.preprocess_data(s) for s in fraud_sessions])
        y_fraud = np.ones(len(X_fraud))
        
        # Combine datasets
        X = np.vstack([X_normal, X_fraud])
        y = np.concatenate([y_normal, y_fraud])
        
        # Train model
        self.model = self.build_model()
        self.model.fit(X, y, 
                      epochs=CONFIG["model_params"]["epochs"], 
                      batch_size=CONFIG["model_params"]["batch_size"],
                      verbose=1)
        
        # Convert to TFLite model
        self.convert_to_tflite()
        self.is_trained = True
    
    def convert_to_tflite(self):
        """Convert the trained model to TFLite format"""
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        self.tflite_model = converter.convert()
    
    def _generate_synthetic_fraud(self, normal_sessions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate realistic fraud patterns"""
        fraud_sessions = []
        
        for session in normal_sessions[:len(normal_sessions)//5]:  # Use 20% for fraud generation
            # Clone session
            fraud = json.loads(json.dumps(session))
            
            # Pattern 1: Robotic taps (perfect timing)
            if fraud["tap_durations_ms"]:
                fraud["tap_durations_ms"] = [300] * len(fraud["tap_durations_ms"])  # All taps exactly 300ms
                
            # Pattern 2: Rapid screen transitions
            if fraud["screen_durations"]:
                fraud["screen_durations"] = {k: max(1, v//3) for k,v in fraud["screen_durations"].items()}
            
            # Pattern 3: Abnormal swipe speeds
            if fraud["swipe_events"]:
                for swipe in fraud["swipe_events"]:
                    swipe["speed_px_per_ms"] *= 3
                
            fraud_sessions.append(fraud)
            
        return fraud_sessions
    
    def evaluate_session(self, session_data: Dict[str, Any], user_id: str) -> Dict[str, Any]:
        """Enhanced evaluation with behavioral analysis"""
        if not self.is_trained:
            raise RuntimeError("Model must be trained before evaluation")
        
        # Preprocess raw data
        processed_data = self._preprocess_session_data(session_data)
        
        # Feature extraction
        features_df = self._extract_features(processed_data)
        X = self.preprocess_data(processed_data)
        
        # Behavioral anomaly detection
        anomalies = self._detect_behavioral_anomalies(features_df, user_id, processed_data)
        
        # Model prediction
        model_score = self.model.predict(X.reshape(1, -1), verbose=0)[0][0]
        trust_score = 1 - model_score
        
        # Update user profile
        self.user_profiles[user_id].update_behavior(features_df.iloc[0])
        
        # Determine risk
        is_suspicious = (
            trust_score < CONFIG["behavior_thresholds"]["trust_threshold"] or 
            bool(anomalies)
        )
        
        return {
            "trust_score": float(trust_score),
            "anomalies": anomalies,
            "is_suspicious": is_suspicious,
            "behavior_factors": {
                "tap_consistency": float(features_df["tap_consistency_score"].iloc[0]),
                "swipe_abnormality": float(abs(features_df["swipe_speed_mean"].iloc[0] - 1.2) / 0.3),
                "navigation_speed": float(features_df["screen_transitions"].iloc[0] / processed_data["session"]["duration_seconds"])
            }
        }
    
    def evaluate_with_tflite(self, session_data: Dict[str, Any]) -> float:
        """Evaluate using TFLite model for mobile/edge devices"""
        if not self.tflite_model:
            raise RuntimeError("TFLite model not available")
        
        # Preprocess the input data
        features = self._extract_features(session_data)
        X = self.scaler.transform(features)
        X = self.normalizer.transform(X)
        
        # Setup TFLite interpreter
        interpreter = tf.lite.Interpreter(model_content=self.tflite_model)
        interpreter.allocate_tensors()
        
        # Get input and output tensors
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        # Set input tensor
        interpreter.set_tensor(input_details[0]['index'], X.astype(np.float32))
        
        # Run inference
        interpreter.invoke()
        
        # Get output tensor
        output_data = interpreter.get_tensor(output_details[0]['index'])
        return float(1 - output_data[0][0])  # Return trust score

def load_sessions(file_path: str) -> List[Dict[str, Any]]:
    """Load sessions from JSON file"""
    with open(file_path) as f:
        return json.load(f)

def save_model(sdk: BehaviorTrustSDK, model_path: str) -> None:
    """Save trained model, scalers, and TFLite model"""
    os.makedirs(model_path, exist_ok=True)
    
    # Save Keras model
    sdk.model.save(f"{model_path}/model.keras")
    
    # Save scalers
    joblib.dump(sdk.scaler, f"{model_path}/scaler.joblib")
    joblib.dump(sdk.normalizer, f"{model_path}/normalizer.joblib")
    
    # Save TFLite model
    with open(f"{model_path}/model.tflite", "wb") as f:
        f.write(sdk.tflite_model)
    
    print(f"Saved all model artifacts to {model_path}")

def load_model(model_path: str) -> BehaviorTrustSDK:
    """Load trained model, scalers, and TFLite model"""
    sdk = BehaviorTrustSDK()
    
    # Load Keras model
    sdk.model = keras.models.load_model(f"{model_path}/model.keras")
    
    # Load scalers
    sdk.scaler = joblib.load(f"{model_path}/scaler.joblib")
    sdk.normalizer = joblib.load(f"{model_path}/normalizer.joblib")
    
    # Load TFLite model
    with open(f"{model_path}/model.tflite", "rb") as f:
        sdk.tflite_model = f.read()
    
    sdk.is_trained = True
    return sdk

def main():
    # Initialize SDK
    sdk = BehaviorTrustSDK()
    
    # Load sessions data
    try:
        sessions = load_sessions("sessions.json")
        print(f"Loaded {len(sessions)} sessions")
    except FileNotFoundError:
        print("Error: sessions.json not found. Please provide training data.")
        return
    
    # Split into normal and suspicious sessions
    normal_sessions = [s for s in sessions if not s.get("is_suspicious", False)]
    fraud_sessions = [s for s in sessions if s.get("is_suspicious", False)]
    
    # Train the model
    print(f"Training with {len(normal_sessions)} normal and {len(fraud_sessions)} fraud sessions")
    sdk.train(normal_sessions, fraud_sessions)
    
    # Save the trained model
    save_model(sdk, "model")
    print("Model trained and saved successfully")
    
    # Evaluate a sample session with both methods
    sample_session = sessions[0]
    
    # Standard evaluation
    result = sdk.evaluate_session(sample_session, "user_123")
    print("\nStandard Evaluation Results:")
    print(f"Trust Score: {result['trust_score']:.2f}")
    print(f"Anomalies Detected: {result['anomalies']}")
    print(f"Suspicious: {'Yes' if result['is_suspicious'] else 'No'}")
    
    # TFLite evaluation
    tflite_score = sdk.evaluate_with_tflite(sample_session)
    print(f"\nTFLite Evaluation Trust Score: {tflite_score:.2f}")
    
    # Compare results
    diff = abs(result['trust_score'] - tflite_score)
    print(f"\nDifference between models: {diff:.4f}")

if __name__ == "__main__":
    main()