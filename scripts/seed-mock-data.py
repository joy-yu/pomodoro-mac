#!/usr/bin/env python3
"""
seed-mock-data.py
-----------------
Replaces Pomodoro app's SwiftData database with realistic mock sessions
spanning 70 days, so every stats view (bar chart / trend / heatmap / donut)
has meaningful data to display.

Usage:
    python3 scripts/seed-mock-data.py           # seed with default pattern
    python3 scripts/seed-mock-data.py --clear   # only clear sessions, no insert
    python3 scripts/seed-mock-data.py --dry-run # print what would be inserted
"""

import argparse
import random
import shutil
import sqlite3
import subprocess
import sys
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

DB_PATH = Path.home() / "Library/Containers/com.joyyu.pomodoro/Data/Library/Application Support/default.store"
BACKUP_SUFFIX = ".seed-backup"

# Core Data epoch: 2001-01-01 00:00:00 UTC
CD_EPOCH = datetime(2001, 1, 1, tzinfo=timezone.utc)

def to_cd_timestamp(dt: datetime) -> float:
    """Convert a datetime to Core Data's seconds-since-2001 float."""
    return (dt - CD_EPOCH).total_seconds()

# ── Tag catalogue (must match what's already in the DB) ───────────────────────
# Each entry: (Z_PK, name, duration_minutes)
TAGS = [
    (6, "专注",  25),
    (4, "写作",  25),
    (3, "复盘",  15),
    (5, "阅读",  30),
    (1, "编码",  45),
    (2, "设计",  45),
]

# ── Session generation ────────────────────────────────────────────────────────

def make_sessions(days: int = 70, seed: int = 42) -> list[dict]:
    """
    Generate realistic-looking sessions for the past `days` days.

    Pattern:
    - ~75 % of days are active (rest days randomly sprinkled)
    - Active weekdays: 2–5 sessions; weekends: 0–3 sessions
    - Sessions cluster in morning (08–11), afternoon (13–17), evening (20–22)
    - Tag weights simulate a developer's typical focus split
    """
    rng = random.Random(seed)
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    sessions = []

    tag_weights = [0.20, 0.15, 0.10, 0.10, 0.30, 0.15]  # matches TAGS order

    time_slots = [
        (8, 11),   # morning block
        (13, 17),  # afternoon block
        (20, 22),  # evening block
    ]

    for day_offset in range(days - 1, -1, -1):
        day = today - timedelta(days=day_offset)
        weekday = day.weekday()  # 0=Mon … 6=Sun

        # Decide whether this day has any activity
        active_chance = 0.80 if weekday < 5 else 0.45
        if rng.random() > active_chance:
            continue

        # How many sessions today
        if weekday < 5:
            count = rng.randint(2, 5)
        else:
            count = rng.randint(1, 3)

        # Pick time slots (may repeat)
        slots_today = rng.choices(time_slots, k=count)
        slots_today.sort(key=lambda s: s[0])

        for (slot_start, slot_end) in slots_today:
            hour = rng.randint(slot_start, slot_end - 1)
            minute = rng.randint(0, 59)
            start_dt = day.replace(hour=hour, minute=minute)

            tag_pk, _, duration_min = rng.choices(TAGS, weights=tag_weights, k=1)[0]
            duration_sec = duration_min * 60
            end_dt = start_dt + timedelta(seconds=duration_sec)

            sessions.append({
                "id": uuid.uuid4(),
                "start": start_dt,
                "end": end_dt,
                "duration": duration_sec,
                "tag_pk": tag_pk,
            })

    return sessions

# ── Database helpers ──────────────────────────────────────────────────────────

def kill_app() -> None:
    subprocess.run(["pkill", "-x", "Pomodoro"], capture_output=True)

def backup_db(db_path: Path) -> Path:
    backup = db_path.with_suffix(db_path.suffix + BACKUP_SUFFIX)
    shutil.copy2(db_path, backup)
    return backup

def clear_sessions(conn: sqlite3.Connection) -> int:
    cur = conn.execute("SELECT COUNT(*) FROM ZPOMODOROSESSION")
    count = cur.fetchone()[0]
    conn.execute("DELETE FROM ZPOMODOROSESSION")
    # Reset Z_PRIMARYKEY max counter for PomodoroSession (Z_ENT = 1)
    conn.execute("UPDATE Z_PRIMARYKEY SET Z_MAX = 0 WHERE Z_ENT = 1")
    return count

def insert_sessions(conn: sqlite3.Connection, sessions: list[dict]) -> None:
    # Z_ENT = 1 for PomodoroSession (from Z_PRIMARYKEY table)
    ENT = 1
    for i, s in enumerate(sessions, start=1):
        conn.execute(
            """
            INSERT INTO ZPOMODOROSESSION
                (Z_PK, Z_ENT, Z_OPT, ZDURATION, ZISCOMPLETED, ZTAG,
                 ZSTARTTIME, ZENDTIME, ZPHASERAWVALUE, ZID)
            VALUES (?, ?, 1, ?, 1, ?,  ?, ?, 'work', ?)
            """,
            (
                i,
                ENT,
                s["duration"],
                s["tag_pk"],
                to_cd_timestamp(s["start"]),
                to_cd_timestamp(s["end"]),
                s["id"].bytes,
            ),
        )
    # Update max PK counter
    conn.execute(
        "UPDATE Z_PRIMARYKEY SET Z_MAX = ? WHERE Z_ENT = 1",
        (len(sessions),),
    )

# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Seed Pomodoro mock data")
    parser.add_argument("--clear",   action="store_true", help="Clear sessions only, don't insert")
    parser.add_argument("--dry-run", action="store_true", help="Print sessions without touching the DB")
    parser.add_argument("--days",    type=int, default=70, help="Number of days to cover (default: 70)")
    parser.add_argument("--seed",    type=int, default=47, help="Random seed for reproducibility")
    args = parser.parse_args()

    if not DB_PATH.exists():
        sys.exit(f"❌  Database not found: {DB_PATH}\n   Launch the app at least once first.")

    sessions = [] if args.clear else make_sessions(days=args.days, seed=args.seed)

    if args.dry_run:
        print(f"Would insert {len(sessions)} sessions over {args.days} days:\n")
        for s in sessions:
            tag_name = next(t[1] for t in TAGS if t[0] == s["tag_pk"])
            print(f"  {s['start'].strftime('%Y-%m-%d %H:%M')}  {s['duration']//60:2d} min  {tag_name}")
        return

    print(f"⏹  Stopping Pomodoro app...")
    kill_app()

    backup = backup_db(DB_PATH)
    print(f"💾  Backed up database → {backup.name}")

    with sqlite3.connect(DB_PATH) as conn:
        removed = clear_sessions(conn)
        print(f"🗑  Removed {removed} existing session(s)")

        if not args.clear:
            insert_sessions(conn, sessions)
            print(f"✅  Inserted {len(sessions)} mock sessions across {args.days} days")
        else:
            print("✅  Sessions cleared (--clear mode)")

    print("\nLaunch Pomodoro to see the stats dashboard.")

if __name__ == "__main__":
    main()
