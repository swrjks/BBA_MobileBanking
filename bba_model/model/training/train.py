import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix
import tensorflow as tf
import matplotlib.pyplot as plt
import joblib

# === Load Data ===
df = pd.read_csv("C:/Users/swara/Desktop/fraud_sdk_ml_demo/model/training/train_data.csv") 
df.fillna(0, inplace=True)

# Separate features and labels
X = df.drop(columns=["label"])
y = df["label"]

# Normalize
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
joblib.dump(scaler, "scaler.joblib")

# Split
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y, test_size=0.2, stratify=y, random_state=42
)

# === Tiny Neural Network ===
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(X.shape[1],)),   # Input layer (18 features)
    tf.keras.layers.Dense(8, activation='relu'),  # Only 8 neurons
    tf.keras.layers.Dense(1, activation='sigmoid')
])

model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])

# === Train ===
history = model.fit(
    X_train, y_train,
    validation_data=(X_test, y_test),
    epochs=10, batch_size=32, verbose=1
)

# === Evaluate ===
y_pred = (model.predict(X_test) > 0.5).astype("int32")
print("\nConfusion Matrix:\n", confusion_matrix(y_test, y_pred))
print("\nClassification Report:\n", classification_report(y_test, y_pred))

# === Plot ===
plt.plot(history.history["loss"], label="Train Loss")
plt.plot(history.history["val_loss"], label="Val Loss")
plt.title("Loss")
plt.legend()
plt.grid(True)
plt.show()

plt.plot(history.history["accuracy"], label="Train Acc")
plt.plot(history.history["val_accuracy"], label="Val Acc")
plt.title("Accuracy")
plt.legend()
plt.grid(True)
plt.show()

# === Export Model ===
model.save("model_light.h5")
print("✅ Saved model as model_light.h5")
