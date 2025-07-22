import json
from dateutil import parser
from collections import Counter
import numpy as np

def parse_time(ts):
    return parser.parse(ts).timestamp()

def extract_features_from_session_json(data):
    features = {}

    # 1. Session duration
    try:
        session_start = parse_time(data['session']['start'])
        session_end = parse_time(data['session']['end'])
        features['session_duration'] = session_end - session_start
    except:
        features['session_duration'] = None

    # 2. Tap stats
    tap_durations = data.get('tap_durations_ms', [])
    features['mean_tap_duration'] = np.mean(tap_durations) if tap_durations else 0
    features['tap_speed'] = len(tap_durations) / features['session_duration'] if features['session_duration'] and len(tap_durations) > 0 else 0

    # 3. Swipe stats
    swipe_events = data.get('swipe_events', [])
    if swipe_events:
        speeds = [e['speed_px_per_ms'] for e in swipe_events]
        distances = [e['distance_px'] for e in swipe_events]
        features['swipe_speed'] = np.mean(speeds) if speeds else 0
        features['swipe_distance'] = np.mean(distances) if distances else 0
    else:
        features['swipe_speed'] = 0
        features['swipe_distance'] = 0

    # 4. Navigation speed
    nav_times = [parse_time(e['timestamp']) for e in data.get('tap_events', [])]
    if len(nav_times) >= 2:
        navigation_durations = [t2 - t1 for t1, t2 in zip(nav_times, nav_times[1:])]
        features['navigation_speed'] = np.mean(navigation_durations)
    else:
        features['navigation_speed'] = 0

    # 5. FD / Loan time from login
    input_data = data.get('session_input', {})
    features['time_from_login_to_fd'] = input_data.get('time_from_login_to_fd') or 0
    features['time_from_login_to_loan'] = input_data.get('time_from_login_to_loan') or 0

    # 6. Most common navigation flow
    screens = [e['screen'] for e in data.get('tap_events', [])]
    flow = ' -> '.join(screens[:5]) if screens else 'unknown'
    features['navigation_flow'] = flow

    return features
