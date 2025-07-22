#!/bin/bash

DEVICE_DIR="/sdcard/Android/data/com.example.dummy_bank/files"
LOCAL_DIR="./session_logs"

mkdir -p "$LOCAL_DIR"

echo "📡 Syncing logs from device to $LOCAL_DIR..."

while true; do
  adb shell ls "$DEVICE_DIR" | grep "session_log_" | while read file; do
    if [ ! -f "$LOCAL_DIR/$file" ]; then
      echo "📥 Pulling $file..."
      adb pull "$DEVICE_DIR/$file" "$LOCAL_DIR/$file" > /dev/null
    fi
  done
  sleep 5
done