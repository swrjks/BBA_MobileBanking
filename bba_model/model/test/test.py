import pandas as pd
import numpy as np
import joblib
import matplotlib.pyplot as plt
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_curve,
    roc_auc_score, precision_recall_curve, ConfusionMatrixDisplay,
    accuracy_score, recall_score
)

# --- Path to model --
# Use this if you saved model as a Keras .h5 file:
from tensorflow import keras
MODEL_PATH = r"C:/Users/swara/Desktop/fraud_sdk_ml_demo/model/training/model_light.h5"
TEST_CSV = "C:/Users/swara/Desktop/fraud_sdk_ml_demo/model/test/test_data/noisy/noisy_test_data_2.csv"
SCALER_PATH = r"C:/Users/swara/Desktop/fraud_sdk_ml_demo/model/training/scaler.joblib"
VALIDATION_THRESHOLD = 0.45  # Use 0.5 if you're unsure

FEATURE_COLS = [
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
    "time_from_login_transaction"
]

def main():
    # Load test data
    df_test = pd.read_csv(TEST_CSV)
    X_test = df_test[FEATURE_COLS]
    y_test = df_test["label"].values

    # Load scaler and preprocess features
    scaler = joblib.load(SCALER_PATH)
    X_test_scaled = scaler.transform(X_test)

    # --- Model loading ---
    # For Keras .h5 model:
    model = keras.models.load_model(MODEL_PATH)
    y_probs = model.predict(X_test_scaled).flatten()

    # # For SavedModel directory (uncomment if using this format)
    # import tensorflow as tf
    # model = tf.saved_model.load(MODEL_PATH)
    # infer = model.signatures["serve"]
    # import tensorflow as tf
    # X_tensor = tf.convert_to_tensor(X_test_scaled, dtype=tf.float32)
    # y_probs = infer(X_tensor)['output_0'].numpy().flatten()

    # --- Prediction and thresholding ---
    threshold = VALIDATION_THRESHOLD
    y_pred = (y_probs > threshold).astype(int)

    print(f"Using threshold = {threshold:.2f} for classification.\n")
    print("📊 Classification Report:\n")
    print(classification_report(y_test, y_pred))

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm)
    disp.plot(cmap='Blues')
    plt.title(f"Confusion Matrix (threshold={threshold:.2f})")
    plt.show()

    # ROC curve
    fpr, tpr, _ = roc_curve(y_test, y_probs)
    auc_score = roc_auc_score(y_test, y_probs)
    plt.figure()
    plt.plot(fpr, tpr, label=f"AUC = {auc_score:.2f}")
    plt.plot([0, 1], [0, 1], 'k--')
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curve")
    plt.legend()
    plt.grid()
    plt.show()

    # Precision-Recall curve
    precision, recall, _ = precision_recall_curve(y_test, y_probs)
    plt.figure()
    plt.plot(recall, precision, color='purple')
    plt.xlabel("Recall")
    plt.ylabel("Precision")
    plt.title("Precision-Recall Curve")
    plt.grid()
    plt.show()

    # Metrics summary
    overall_acc = accuracy_score(y_test, y_pred) * 100
    fraud_recall = recall_score(y_test, y_pred, pos_label=1) * 100
    legit_recall = recall_score(y_test, y_pred, pos_label=0) * 100

    print(f"\n=== Key Metrics (threshold={threshold:.2f}) ===")
    print(f"Overall Model Accuracy      : {overall_acc:.2f}%")
    print(f"Fraud Detection Rate (Recall): {fraud_recall:.2f}%")
    print(f"Legit User Detection Rate   : {legit_recall:.2f}%")
    print(f"AUC Score (ROC)             : {auc_score:.4f}")


    print(f"\nProbability range (min, max, mean): {y_probs.min():.5e}, {y_probs.max():.5f}, {y_probs.mean():.5f}")

if __name__ == "__main__":
    main()
