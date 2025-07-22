import numpy as np
import pandas as pd
import os
import joblib
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

# === Config ===
DATA_PATH = "C:/Users/swara/Desktop/fraud_sdk_ml_demo/data_generation/labeled_session_data.csv"
MODEL_PATH = "C:/Users/swara/Desktop/fraud_sdk_ml_demo/inference/models/fraud_classifier.pkl"
USE_MLP = True  # Set to False to use Logistic Regression
VERBOSE = True  # Toggle detailed logs

# === Load Dataset ===
if not os.path.exists(DATA_PATH):
    raise FileNotFoundError(f"❌ Dataset not found at: {DATA_PATH}")

df = pd.read_csv(DATA_PATH)

if VERBOSE:
    print("📊 Sample data:")
    print(df.head())

    print("\n🧩 Feature columns:", df.drop(['fraud_label'], axis=1).columns.tolist())

    print("\n📊 Class distribution:")
    print(df['fraud_label'].value_counts())

# === Features and Labels ===
X = df.drop(['fraud_label'], axis=1).values
y = df['fraud_label'].values

# === Train/Test Split ===
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)

# === Define Classifier ===
if USE_MLP:
    clf = MLPClassifier(hidden_layer_sizes=(16, 8), max_iter=100, solver='adam', random_state=42)
    print("🔧 Using Feedforward Neural Net (MLPClassifier)")
else:
    clf = LogisticRegression(max_iter=1000)
    print("🔧 Using Logistic Regression")

# === Train the Model ===
clf.fit(X_train, y_train)
print("✅ Model training complete.")

# === Evaluate Model ===
y_pred = clf.predict(X_test)
y_proba = clf.predict_proba(X_test)[:, 1] if hasattr(clf, "predict_proba") else y_pred

print("\n📈 Classification Report:")
print(classification_report(y_test, y_pred, digits=3))

print("📊 Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))

roc_auc = roc_auc_score(y_test, y_proba)
print(f"🏁 ROC-AUC Score: {roc_auc:.3f}")

# === Save Model ===
os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
joblib.dump(clf, MODEL_PATH)
print(f"💾 Model saved to: {MODEL_PATH}")
