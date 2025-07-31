import tensorflow as tf

# Load your model
model = tf.keras.models.load_model("model_light.h5")

# Convert to TFLite format
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the TFLite model
with open("model_light.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Converted and saved as model_light.tflite")
