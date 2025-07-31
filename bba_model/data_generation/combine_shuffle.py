import pandas as pd
from sklearn.utils import shuffle

# === Paths ===
LEGIT_PATH = r"C:/Users/swara/Desktop/fraud_sdk_ml_demo/data_generation/synthetic_manya_data.csv"
FRAUD_PATH = r"C:/Users/swara/Desktop/fraud_sdk_ml_demo/data_generation/synthetic_f_data.csv"
OUTPUT_PATH = r"C:/Users/swara/Desktop/fraud_sdk_ml_demo/data_generation/new_test_data.csv"

# === Load both datasets ===
df_legit = pd.read_csv(LEGIT_PATH)
df_fraud = pd.read_csv(FRAUD_PATH)

# === Combine ===
combined_df = pd.concat([df_legit, df_fraud], ignore_index=True)

# === Shuffle ===
shuffled_df = shuffle(combined_df, random_state=42).reset_index(drop=True)

# === Save ===
shuffled_df.to_csv(OUTPUT_PATH, index=False)
print(f"[✓] Combined & shuffled dataset saved to → {OUTPUT_PATH}")
