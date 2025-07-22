from flask import Flask, render_template, jsonify, request
import os
import json
from datetime import datetime

# Flask App
app = Flask(__name__)

# Configuration
LOG_DIR = "session_logs"
os.makedirs(LOG_DIR, exist_ok=True)

def log_message(message):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}")

# Route: Homepage
@app.route('/')
def index():
    return render_template("index.html")

# Route: Serve All Logs
@app.route('/logs')
def list_logs():
    logs = []
    try:
        log_files = sorted(
            [f for f in os.listdir(LOG_DIR) if f.endswith(".json")],
            key=lambda x: os.path.getmtime(os.path.join(LOG_DIR, x)),
            reverse=True
        )
        for fname in log_files:
            path = os.path.join(LOG_DIR, fname)
            try:
                with open(path) as f:
                    content = json.load(f)
                logs.append({
                    "filename": fname,
                    "content": content,
                    "mtime": os.path.getmtime(path)
                })
                log_message(f"📄 Loaded: {fname}")
            except Exception as e:
                logs.append({
                    "filename": fname,
                    "content": {"error": str(e)},
                    "mtime": os.path.getmtime(path)
                })
                log_message(f"❌ Error loading {fname}: {e}")
    except Exception as e:
        log_message(f"❌ Listing logs failed: {str(e)}")
        return jsonify({"error": str(e)}), 500

    return jsonify(logs)

# Route: Upload Session Log from Mobile App
@app.route('/upload', methods=['POST'])
def upload_log():
    try:
        data = request.get_json()
        # Updated filename format: session_log_2025-07-20T18-21-45.981302.json
        timestamp = datetime.now().isoformat().replace(":", "-")
        filename = f"session_log_{timestamp}.json"
        filepath = os.path.join(LOG_DIR, filename)
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        log_message(f"✅ Received and saved: {filename}")
        return jsonify({"status": "success", "filename": filename})
    except Exception as e:
        log_message(f"❌ Upload failed: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# Route: Delete Selected Logs
@app.route('/delete_logs', methods=['POST'])
def delete_logs():
    try:
        data = request.get_json()
        filenames = data.get("filenames", [])

        log_message(f"🔍 Delete request received for: {filenames}")

        deleted = []
        not_found = []
        errors = []

        for fname in filenames:
            if not fname or '..' in fname or '/' in fname or '\\' in fname:
                log_message(f"⚠️ Skipping invalid filename: {fname}")
                continue

            path = os.path.join(LOG_DIR, fname)
            try:
                if os.path.exists(path):
                    os.remove(path)
                    deleted.append(fname)
                    log_message(f"🗑️ Deleted: {fname}")
                else:
                    not_found.append(fname)
                    log_message(f"⚠️ Not found: {fname}")
            except Exception as e:
                errors.append(fname)
                log_message(f"❌ Error deleting {fname}: {e}")

        return jsonify({
            "status": "success",
            "deleted": deleted,
            "not_found": not_found,
            "errors": errors
        })

    except Exception as e:
        log_message(f"❌ Deletion failed: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# Run the Flask app
if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5020))
    log_message("🚀 Starting PhishSafe Analytics Flask Server (HTTP Upload Mode)")
    app.run(debug=True, host='0.0.0.0', port=port)
