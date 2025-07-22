# Updated imports (add these at the top)
import random
from faker import Faker
fake = Faker()

# Enhanced configuration
CONFIG.update({
    "human_behavior": {
        # Real human tap duration ranges (ms)
        "tap_duration": {"smartphone": (80, 600), "tablet": (100, 800)},
        
        # Real swipe speed ranges (px/ms)
        "swipe_speed": {"smartphone": (0.5, 2.0), "tablet": (0.3, 1.8)},
        
        # Screen transition times (seconds)
        "screen_dwell_time": {
            "home": (3, 15),
            "products": (5, 30),
            "checkout": (10, 60)
        }
    }
})

# Enhanced UserProfile class
class UserProfile:
    def __init__(self, user_id, device_type="smartphone"):
        self.user_id = user_id
        self.device_type = device_type
        self.update_count = 0
        
        # Initialize with device-specific baselines
        self.behavior_baselines = {
            "tap_duration": {
                "mean": np.mean(CONFIG["human_behavior"]["tap_duration"][device_type]),
                "std": np.diff(CONFIG["human_behavior"]["tap_duration"][device_type])[0]/4
            },
            "swipe_speed": {
                "mean": np.mean(CONFIG["human_behavior"]["swipe_speed"][device_type]),
                "std": np.diff(CONFIG["human_behavior"]["swipe_speed"][device_type])[0]/4
            }
        }

# Enhanced synthetic data generation
def _generate_synthetic_fraud(self, normal_sessions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Generates 5 distinct fraud patterns with realistic parameters"""
    fraud_sessions = []
    
    for session in normal_sessions[:min(20, len(normal_sessions))]:  # Use up to 20 sessions as base
        # Pattern 1: Bot-like behavior (perfect timing)
        bot_session = self._clone_session(session)
        if bot_session["tap_durations_ms"]:
            perfect_duration = 300  # Exactly 300ms taps
            bot_session["tap_durations_ms"] = [perfect_duration] * len(bot_session["tap_durations_ms"])
            bot_session["swipe_events"] = []  # Bots often don't swipe
        fraud_sessions.append(bot_session)
        
        # Pattern 2: Rapid screen transitions
        rapid_session = self._clone_session(session)
        if rapid_session["screen_durations"]:
            rapid_session["screen_durations"] = {
                k: max(1, int(v * random.uniform(0.1, 0.3)))
                for k,v in rapid_session["screen_durations"].items()
            }
        fraud_sessions.append(rapid_session)
        
        # Pattern 3: Human-like but abnormal timing
        abnormal_session = self._clone_session(session)
        if abnormal_session["tap_durations_ms"]:
            abnormal_session["tap_durations_ms"] = [
                int(d * random.uniform(1.8, 2.5)) if random.random() > 0.7 else d
                for d in abnormal_session["tap_durations_ms"]
            ]
        fraud_sessions.append(abnormal_session)
        
        # Pattern 4: Overly consistent swipe angles (card skimmer pattern)
        if session["swipe_events"]:
            skimmer_session = self._clone_session(session)
            for swipe in skimmer_session["swipe_events"]:
                swipe["angle"] = 90  # Perfect vertical swipes
                swipe["speed_px_per_ms"] = 1.8  # Consistent fast speed
            fraud_sessions.append(skimmer_session)
        
        # Pattern 5: Mixed abnormal behaviors
        mixed_session = self._clone_session(session)
        if mixed_session["tap_durations_ms"]:
            mixed_session["tap_durations_ms"] = [
                random.choice([50, 2000]) if random.random() > 0.8 else d
                for d in mixed_session["tap_durations_ms"]
            ]
        fraud_sessions.append(mixed_session)
    
    return fraud_sessions

def _clone_session(self, session: Dict[str, Any]) -> Dict[str, Any]:
    """Deep clone session with some randomized elements"""
    cloned = json.loads(json.dumps(session))
    
    # Randomize timestamps while maintaining sequence
    start_time = datetime.fromisoformat(cloned["session"]["start"])
    time_offset = random.uniform(-2, 2)  # Hours
    
    # Update all timestamps
    for tap in cloned["tap_events"]:
        original = datetime.fromisoformat(tap["timestamp"])
        tap["timestamp"] = (original + timedelta(hours=time_offset)).isoformat()
    
    cloned["session"]["is_suspicious"] = True
    return cloned

# Enhanced normal session generation
def generate_normal_session(user_id: str, device_type: str = "smartphone") -> Dict[str, Any]:
    """Generates realistic normal session data"""
    # Session metadata
    start_time = fake.date_time_this_month()
    duration = random.randint(60, 300)  # 1-5 minute session
    end_time = start_time + timedelta(seconds=duration)
    
    # Generate realistic tap patterns
    num_taps = random.randint(5, 30)
    tap_durations = [
        random.randint(*CONFIG["human_behavior"]["tap_duration"][device_type])
        for _ in range(num_taps)
    ]
    
    # Generate realistic swipe patterns
    num_swipes = random.randint(0, 5)
    swipe_events = []
    for _ in range(num_swipes):
        swipe_events.append({
            "start_x": random.randint(0, 400),
            "start_y": random.randint(0, 800),
            "end_x": random.randint(0, 400),
            "end_y": random.randint(0, 800),
            "duration_ms": random.randint(200, 1000),
            "speed_px_per_ms": random.uniform(*CONFIG["human_behavior"]["swipe_speed"][device_type]),
            "angle": random.randint(0, 360)
        })
    
    # Generate realistic screen flow
    screens = ["home", "products", "cart", "checkout", "payment"]
    visited_screens = random.sample(screens, random.randint(2, 4))
    screen_durations = {
        screen: random.randint(*CONFIG["human_behavior"]["screen_dwell_time"].get(screen, (3, 15)))
        for screen in visited_screens
    }
    
    return {
        "session": {
            "id": f"sess_{fake.uuid4()[:8]}",
            "start": start_time.isoformat(),
            "end": end_time.isoformat(),
            "device_id": f"device_{device_type}_{random.randint(1000, 9999)}",
            "ip_address": fake.ipv4()
        },
        "tap_events": [{"timestamp": (start_time + timedelta(seconds=random.randint(0, duration))).isoformat(),
                       "x": random.randint(0, 400), "y": random.randint(0, 800)} 
                      for _ in range(num_taps)],
        "tap_durations_ms": tap_durations,
        "swipe_events": swipe_events,
        "screens_visited": [{"screen": s, "timestamp": (start_time + timedelta(seconds=sum(
            list(screen_durations.values())[:i]))).isoformat()}
            for i, s in enumerate(visited_screens)],
        "screen_durations": screen_durations,
        "session_input": {
            "transaction_amount": f"{random.uniform(10, 500):.2f}",
            "items": [f"prod_{random.randint(1000, 9999)}" 
                     for _ in range(random.randint(1, 5))]
        },
        "is_suspicious": False
    }