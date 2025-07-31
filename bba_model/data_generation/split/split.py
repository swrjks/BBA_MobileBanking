import pandas as pd
from sklearn.model_selection import train_test_split

# === Paths ===
INPUT_PATH = r"C:\Users\swara\Desktop\fraud_sdk_ml_demo\data_generation\combined_shuffled_data.csv"
BASE_DIR = r"C:\Users\swara\Desktop\fraud_sdk_ml_demo\data_generation"

# === Load dataset ===
df = pd.read_csv(INPUT_PATH)

# === Step 1: Split out 80% training data ===
train_df, temp_df = train_test_split(df, test_size=0.2, random_state=42, stratify=df["label"])

# === Step 2: Split remaining 20% into 4 equal 5% test splits ===
split_size = len(df) * 0.05 / len(temp_df)  # ratio for each test split from the 20%
test_1, temp = train_test_split(temp_df, test_size=1 - split_size, random_state=42, stratify=temp_df["label"])
test_2, temp = train_test_split(temp, test_size=1 - (split_size / (1 - split_size)), random_state=42, stratify=temp["label"])
test_3, test_4 = train_test_split(temp, test_size=0.5, random_state=42, stratify=temp["label"])

# === Save all splits ===
train_df.to_csv(f"{BASE_DIR}/train_data.csv", index=False)
test_1.to_csv(f"{BASE_DIR}/test_data_part1.csv", index=False)
test_2.to_csv(f"{BASE_DIR}/test_data_part2.csv", index=False)
test_3.to_csv(f"{BASE_DIR}/test_data_part3.csv", index=False)
test_4.to_csv(f"{BASE_DIR}/test_data_part4.csv", index=False)

# === Summary ===
print(f"[✓] Train data: {len(train_df)} rows")
print(f"[✓] Test Part 1: {len(test_1)} rows")
print(f"[✓] Test Part 2: {len(test_2)} rows")
print(f"[✓] Test Part 3: {len(test_3)} rows")
print(f"[✓] Test Part 4: {len(test_4)} rows")
