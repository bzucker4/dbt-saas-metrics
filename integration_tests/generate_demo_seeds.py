"""Write synthetic Segment-style seeds for the DuckDB demo.

Run from the repo root:

    python integration_tests/generate_demo_seeds.py
"""

import csv
from pathlib import Path

OUT = Path(__file__).resolve().parent / "seeds"


def write_csv(name, fieldnames, rows):
    path = OUT / name
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    # user_id, anonymous_id, account_id, email, signup_at, activated_at, account_name, plan
    users = [
        ("user_anna", "anon_anna", "acct_acme", "anna@acme.example", "2025-01-02 09:00:00", "2025-01-03 11:00:00", "Acme Robotics", "growth"),
        ("user_adam", "anon_adam", "acct_acme", "adam@acme.example", "2025-01-10 14:00:00", "2025-01-12 16:00:00", "Acme Robotics", "growth"),
        ("user_ben", "anon_ben", "acct_beta", "ben@beta.example", "2025-01-06 10:00:00", "2025-01-09 15:00:00", "Beta Logistics", "starter"),
        ("user_eva", "anon_eva", "acct_echo", "eva@echo.example", "2025-01-08 11:30:00", "2025-01-20 09:00:00", "Echo Media", "growth"),
        ("user_hana", "anon_hana", "acct_hotel", "hana@hotelops.example", "2025-01-12 08:00:00", "2025-01-13 08:30:00", "HotelOps", "starter"),
        ("user_jon", "anon_jon", "acct_jon", "jon@example.com", "2025-01-20 12:00:00", None, "Jon Solo", "free"),
        ("user_gina", "anon_gina", "acct_gamma", "gina@gamma.example", "2025-02-03 10:00:00", "2025-02-05 10:00:00", "Gamma Health", "growth"),
        ("user_late", "anon_late", "acct_late", "late@example.com", "2025-02-01 09:00:00", "2025-02-20 09:00:00", "Late Co", "free"),
        ("user_dan", "anon_dan", "acct_delta", "dan@delta.example", "2025-03-04 13:00:00", "2025-03-04 13:20:00", "Delta Finance", "scale"),
        ("user_dina", "anon_dina", "acct_delta", "dina@delta.example", "2025-03-15 10:00:00", "2025-04-10 10:00:00", "Delta Finance", "scale"),
        ("user_fay", "anon_fay", "acct_free", "fay@northwind.example", "2025-03-05 11:00:00", "2025-03-06 11:00:00", "Northwind Trial", "free"),
        ("user_sam", "anon_sam", "acct_sam", "sam@example.com", "2025-03-01 15:00:00", None, "Sam Experiments", "free"),
        ("user_frank", "anon_frank", "acct_foxtrot", "frank@foxtrot.example", "2025-04-02 09:30:00", "2025-04-04 12:00:00", "Foxtrot AI", "starter"),
        ("user_ian", "anon_ian", "acct_india", "ian@indiapay.example", "2025-05-06 10:00:00", "2025-05-08 10:00:00", "IndiaPay", "growth"),
        ("user_june", "anon_june", "acct_june", "june@example.com", "2025-06-10 16:00:00", None, "June Labs", "trial"),
    ]

    # Primary user on each paying account fires subscription_started.
    paid_starts = {
        "user_anna": "2025-01-02 09:05:00",
        "user_ben": "2025-01-06 10:05:00",
        "user_eva": "2025-01-08 11:35:00",
        "user_hana": "2025-01-12 08:05:00",
        "user_gina": "2025-02-03 10:05:00",
        "user_dan": "2025-03-04 13:05:00",
        "user_frank": "2025-04-02 09:35:00",
        "user_ian": "2025-05-06 10:05:00",
    }

    # Extra product usage. June rows drive customer health as of 2025-06-30.
    feature_events = [
        ("user_anna", "acct_acme", "2025-01-15 10:00:00"),
        ("user_anna", "acct_acme", "2025-06-04 10:00:00"),
        ("user_anna", "acct_acme", "2025-06-11 10:00:00"),
        ("user_anna", "acct_acme", "2025-06-18 10:00:00"),
        ("user_anna", "acct_acme", "2025-06-25 10:00:00"),
        ("user_anna", "acct_acme", "2025-06-28 15:00:00"),
        ("user_adam", "acct_acme", "2025-06-06 11:00:00"),
        ("user_adam", "acct_acme", "2025-06-16 11:00:00"),
        ("user_adam", "acct_acme", "2025-06-27 11:00:00"),
        ("user_ben", "acct_beta", "2025-02-12 09:00:00"),
        ("user_ben", "acct_beta", "2025-06-15 09:00:00"),
        ("user_ben", "acct_beta", "2025-06-22 09:00:00"),
        ("user_ben", "acct_beta", "2025-06-28 17:00:00"),
        ("user_eva", "acct_echo", "2025-03-03 12:00:00"),
        ("user_eva", "acct_echo", "2025-06-02 12:00:00"),
        ("user_eva", "acct_echo", "2025-06-20 12:00:00"),
        ("user_hana", "acct_hotel", "2025-02-02 08:00:00"),
        ("user_hana", "acct_hotel", "2025-06-08 08:00:00"),
        ("user_gina", "acct_gamma", "2025-03-11 10:00:00"),
        ("user_gina", "acct_gamma", "2025-04-20 10:00:00"),
        ("user_dan", "acct_delta", "2025-04-08 13:00:00"),
        ("user_dan", "acct_delta", "2025-06-05 13:00:00"),
        ("user_dan", "acct_delta", "2025-06-19 13:00:00"),
        ("user_dan", "acct_delta", "2025-06-26 13:00:00"),
        ("user_dina", "acct_delta", "2025-06-08 10:00:00"),
        ("user_fay", "acct_free", "2025-06-18 11:00:00"),
        ("user_fay", "acct_free", "2025-06-27 11:00:00"),
        ("user_frank", "acct_foxtrot", "2025-05-07 09:00:00"),
        ("user_frank", "acct_foxtrot", "2025-06-10 09:00:00"),
        ("user_frank", "acct_foxtrot", "2025-06-21 09:00:00"),
        ("user_ian", "acct_india", "2025-06-09 10:00:00"),
        ("user_ian", "acct_india", "2025-06-16 10:00:00"),
        ("user_ian", "acct_india", "2025-06-29 18:00:00"),
    ]

    bounces = [
        ("anon_bounce1", "2025-01-15 13:00:00", "/pricing"),
        ("anon_bounce2", "2025-04-18 16:20:00", "/blog/nrr"),
        ("anon_bounce3", "2025-06-02 08:40:00", "/"),
    ]

    pages = []
    identifies = []
    tracks = []
    groups = []

    for user_id, anon, account_id, email, signup_at, activated_at, account_name, plan in users:
        day, clock = signup_at.split(" ")
        landing_at = f"{day} {shift_minutes(clock, -20)}"
        pages.append(
            {
                "id": f"pg_{anon}_land",
                "anonymous_id": anon,
                "user_id": "",
                "timestamp": landing_at,
                "url": "https://app.example.com/",
                "path": "/",
                "context_group_id": "",
            }
        )
        identifies.append(
            {
                "id": f"id_{user_id}",
                "anonymous_id": anon,
                "user_id": user_id,
                "timestamp": signup_at,
                "email": email,
                "context_group_id": account_id,
            }
        )
        tracks.append(
            {
                "id": f"trk_{user_id}_signup",
                "anonymous_id": anon,
                "user_id": user_id,
                "event": "signed_up",
                "timestamp": signup_at,
                "context_group_id": account_id,
            }
        )
        groups.append(
            {
                "id": f"grp_{user_id}",
                "group_id": account_id,
                "user_id": user_id,
                "timestamp": signup_at,
                "name": account_name,
                "plan": plan,
            }
        )
        if activated_at:
            pages.append(
                {
                    "id": f"pg_{user_id}_app",
                    "anonymous_id": anon,
                    "user_id": user_id,
                    "timestamp": activated_at,
                    "url": "https://app.example.com/projects",
                    "path": "/projects",
                    "context_group_id": account_id,
                }
            )
            tracks.append(
                {
                    "id": f"trk_{user_id}_activated",
                    "anonymous_id": anon,
                    "user_id": user_id,
                    "event": "activated",
                    "timestamp": activated_at,
                    "context_group_id": account_id,
                }
            )
        if user_id in paid_starts:
            tracks.append(
                {
                    "id": f"trk_{user_id}_paid",
                    "anonymous_id": anon,
                    "user_id": user_id,
                    "event": "subscription_started",
                    "timestamp": paid_starts[user_id],
                    "context_group_id": account_id,
                }
            )

    user_anon = {user_id: anon for user_id, anon, *_ in users}
    for index, (user_id, account_id, occurred_at) in enumerate(feature_events, start=1):
        tracks.append(
            {
                "id": f"trk_feat_{index:03d}",
                "anonymous_id": user_anon[user_id],
                "user_id": user_id,
                "event": "feature_used",
                "timestamp": occurred_at,
                "context_group_id": account_id,
            }
        )

    for anon, occurred_at, path in bounces:
        pages.append(
            {
                "id": f"pg_{anon}",
                "anonymous_id": anon,
                "user_id": "",
                "timestamp": occurred_at,
                "url": f"https://www.example.com{path}",
                "path": path,
                "context_group_id": "",
            }
        )

    subscriptions = []
    # account, plan, seats, and monthly MRR for Jan..Jun 2025. None skips the month
    # before the account exists. 0 is an explicit churn or dormant month.
    book = {
        "acct_acme": ("growth", 8, [500, 500, 800, 800, 800, 800], ["active"] * 6),
        "acct_beta": ("starter", 4, [200, 200, 200, 100, 100, 100], ["active"] * 6),
        "acct_gamma": ("growth", 6, [None, 300, 300, 300, 0, 0], [None, "active", "active", "active", "canceled", "canceled"]),
        "acct_delta": ("scale", 25, [None, None, 1000, 1000, 1000, 1500], [None, None, "active", "active", "active", "active"]),
        "acct_echo": ("growth", 5, [400, 400, 400, 400, 400, 400], ["active", "active", "active", "active", "active", "past_due"]),
        "acct_foxtrot": ("starter", 3, [None, None, None, 250, 250, 250], [None, None, None, "active", "active", "active"]),
        "acct_hotel": ("starter", 2, [150, 150, 0, 0, 150, 150], ["active", "active", "canceled", "canceled", "active", "active"]),
        "acct_india": ("growth", 10, [None, None, None, None, 600, 600], [None, None, None, None, "active", "active"]),
    }
    months = ["2025-01-01", "2025-02-01", "2025-03-01", "2025-04-01", "2025-05-01", "2025-06-01"]
    plan_override = {
        ("acct_acme", "2025-03-01"): ("scale", 15),
        ("acct_acme", "2025-04-01"): ("scale", 15),
        ("acct_acme", "2025-05-01"): ("scale", 15),
        ("acct_acme", "2025-06-01"): ("scale", 15),
        ("acct_beta", "2025-04-01"): ("starter", 2),
        ("acct_beta", "2025-05-01"): ("starter", 2),
        ("acct_beta", "2025-06-01"): ("starter", 2),
        ("acct_delta", "2025-06-01"): ("scale", 40),
    }
    for account_id, (plan, seats, amounts, statuses) in book.items():
        for month, amount, status in zip(months, amounts, statuses):
            if amount is None:
                continue
            override = plan_override.get((account_id, month))
            row_plan, row_seats = override if override else (plan, seats)
            if amount == 0:
                row_seats = 0
            subscriptions.append(
                {
                    "subscription_id": f"sub_{account_id}_{month.replace('-', '')}",
                    "account_id": account_id,
                    "month_start": month,
                    "mrr": amount,
                    "status": status,
                    "plan_name": row_plan,
                    "seats": row_seats,
                }
            )

    write_csv(
        "raw_identifies.csv",
        ["id", "anonymous_id", "user_id", "timestamp", "email", "context_group_id"],
        identifies,
    )
    write_csv(
        "raw_tracks.csv",
        ["id", "anonymous_id", "user_id", "event", "timestamp", "context_group_id"],
        tracks,
    )
    write_csv(
        "raw_pages.csv",
        ["id", "anonymous_id", "user_id", "timestamp", "url", "path", "context_group_id"],
        pages,
    )
    write_csv(
        "raw_groups.csv",
        ["id", "group_id", "user_id", "timestamp", "name", "plan"],
        groups,
    )
    write_csv(
        "raw_subscriptions.csv",
        ["subscription_id", "account_id", "month_start", "mrr", "status", "plan_name", "seats"],
        subscriptions,
    )
    print(f"identifies={len(identifies)} tracks={len(tracks)} pages={len(pages)} groups={len(groups)} subscriptions={len(subscriptions)}")


def shift_minutes(clock, minutes):
    hours, mins, secs = [int(part) for part in clock.split(":")]
    total = hours * 60 + mins + minutes
    return f"{total // 60:02d}:{total % 60:02d}:{secs:02d}"


if __name__ == "__main__":
    main()
