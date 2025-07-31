from flask import Flask, request, jsonify
from flask_cors import CORS
import datetime

app = Flask(__name__)
CORS(app)  # Allow requests from Flutter or mobile apps

# 🔹 Utility to print with timestamp
def log_event(event_type, data):
    print(f"✅ {event_type} Received at {datetime.datetime.now().isoformat()}: {data}")

# 1. Tap Event
@app.route('/tap_event', methods=['POST'])
def tap_event():
    data = request.json
    if isinstance(data, dict) and 'position' in data:
        screen = data.get('screen', 'unknown')
        pos = data.get('position', {})
        zone = data.get('tap_zone', 'unknown')
        timestamp = data.get('timestamp', '')
        print(f"✅ Tap with Position Received at {timestamp}: Screen={screen}, X={pos.get('x')}, Y={pos.get('y')}, Zone={zone}")
    else:
        log_event("Tap", data)
    return jsonify({"message": "Tap received"}), 200

# 2. Swipe Event
@app.route('/swipe_event', methods=['POST'])
def swipe_event():
    data = request.json
    log_event("Swipe", data)
    return jsonify({"message": "Swipe received"}), 200

# 3. Input Event (e.g. typing, form entries)
@app.route('/input_event', methods=['POST'])
def input_event():
    data = request.json
    log_event("Input Event", data)
    return jsonify({"message": "Input event received"}), 200

# 4. Screen Visit
@app.route('/screen_visit', methods=['POST'])
def screen_visit():
    data = request.json
    log_event("Screen Visit", data)
    return jsonify({"message": "Screen visit received"}), 200

# 5. Session Start
@app.route('/session_start', methods=['POST'])
def session_start():
    data = request.json
    log_event("Session Start", data)
    return jsonify({"message": "Session started"}), 200

# 6. Session End
@app.route('/session_end', methods=['POST'])
def session_end():
    data = request.json
    log_event("Session End", data)
    return jsonify({"message": "Session ended"}), 200

# 7. Screen Recording Status
@app.route('/screen_recording', methods=['POST'])
def screen_recording():
    data = request.json
    log_event("Screen Recording", data)
    return jsonify({"message": "Screen recording status received"}), 200

# 8. Device Info
@app.route('/device_info', methods=['POST'])
def device_info():
    data = request.json
    log_event("Device Info", data)
    return jsonify({"message": "Device info received"}), 200

# 9. Location Info
@app.route('/location_info', methods=['POST'])
def location_info():
    data = request.json
    log_event("Location Info", data)
    return jsonify({"message": "Location info received"}), 200

# 10. Transaction Amount
@app.route('/transaction_amount', methods=['POST'])
def transaction_amount():
    data = request.json
    log_event("Transaction Amount", data)
    return jsonify({"message": "Transaction amount received"}), 200

# 11. FD Broken
@app.route('/fd_broken', methods=['POST'])
def fd_broken():
    data = request.json
    log_event("FD Broken", data)
    return jsonify({"message": "FD break event received"}), 200

# 12. Loan Taken
@app.route('/loan_taken', methods=['POST'])
def loan_taken():
    data = request.json
    log_event("Loan Taken", data)
    return jsonify({"message": "Loan taken event received"}), 200

# 13. Screen Durations
@app.route('/screen_duration', methods=['POST'])
def screen_duration():
    data = request.json
    log_event("Screen Duration", data)
    return jsonify({"message": "Screen duration received"}), 200

# 14. Tap Duration (in milliseconds)
@app.route('/tap_durations', methods=['POST'])
def tap_durations():
    data = request.json
    log_event("Tap Durations", data)
    return jsonify({"message": "Tap durations received"}), 200

# 15. Swipe Speed/Direction Data
@app.route('/swipe_metrics', methods=['POST'])
def swipe_metrics():
    data = request.json
    log_event("Swipe Metrics", data)
    return jsonify({"message": "Swipe metrics received"}), 200

# 16. Input Timing Data (login -> FD, loan, etc.)
@app.route('/input_timing', methods=['POST'])
def input_timing():
    data = request.json
    log_event("Input Timing", data)
    return jsonify({"message": "Input timing received"}), 200

# 17. Final Export / Aggregated JSON
@app.route('/export_session', methods=['POST'])
def export_session():
    data = request.json
    log_event("Session Export", data)
    return jsonify({"message": "Session data exported"}), 200

# 18. Custom Event (if needed for future use)
@app.route('/custom_event', methods=['POST'])
def custom_event():
    data = request.json
    log_event("Custom Event", data)
    return jsonify({"message": "Custom event received"}), 200

# Run the server
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5018, debug=True)
