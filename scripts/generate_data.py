"""
generate_data.py - fills the food_delivery database with realistic sample data.

Run this AFTER schema.sql and BEFORE creating triggers, so the historical rows
are loaded without firing any trigger logic. Safe to re-run: it empties the
tables first.
"""
import os
import random
from datetime import datetime, timedelta

import mysql.connector
from dotenv import load_dotenv
from faker import Faker

load_dotenv()
random.seed(42)
Faker.seed(42)
fake = Faker("en_IN")

# ----------------------------- configuration ------------------------------
N_CUSTOMERS = 2000
N_RESTAURANTS = 200
N_PARTNERS = 150
N_ORDERS = 30000
N_ACTIVE_ORDERS = 150          # newest orders left in-progress, for testing procedures

CITIES = ["Hyderabad", "Bengaluru", "Chennai", "Mumbai",
          "Delhi", "Pune", "Visakhapatnam", "Kolkata"]

MENU = {
    "North Indian": ["Butter Chicken", "Paneer Butter Masala", "Dal Makhani", "Garlic Naan",
                     "Butter Naan", "Chicken Tikka", "Rajma Chawal", "Chole Bhature",
                     "Palak Paneer", "Tandoori Roti", "Jeera Rice", "Kadai Paneer"],
    "South Indian": ["Masala Dosa", "Idli Sambar", "Medu Vada", "Pongal", "Rava Dosa",
                     "Uttapam", "Curd Rice", "Lemon Rice", "Filter Coffee", "Podi Idli",
                     "Onion Dosa", "Bisi Bele Bath"],
    "Biryani": ["Hyderabadi Chicken Biryani", "Mutton Biryani", "Veg Biryani", "Egg Biryani",
                "Chicken 65", "Mirchi Ka Salan", "Double Ka Meetha", "Raita",
                "Paneer Biryani", "Prawn Biryani", "Chicken Dum Biryani", "Qubani Ka Meetha"],
    "Chinese": ["Veg Hakka Noodles", "Chicken Fried Rice", "Gobi Manchurian", "Chilli Chicken",
                "Schezwan Noodles", "Veg Manchow Soup", "Spring Rolls", "Paneer Chilli",
                "Chicken Momos", "Veg Momos", "Hot and Sour Soup", "Triple Schezwan Rice"],
    "Fast Food": ["Veg Burger", "Chicken Burger", "French Fries", "Chicken Wrap", "Veg Pizza",
                  "Pepperoni Pizza", "Cheese Sandwich", "Peri Peri Fries", "Chicken Nuggets",
                  "Cold Coffee", "Chocolate Shake", "Garlic Bread"],
    "Desserts": ["Gulab Jamun", "Rasmalai", "Brownie with Ice Cream", "Chocolate Lava Cake",
                 "Mango Lassi", "Fresh Lime Soda", "Kulfi", "Ice Cream Sundae",
                 "Oreo Shake", "Falooda", "Tiramisu", "Rabri"],
}
NAME_SUFFIX = ["Kitchen", "Biryani House", "Bistro", "Tiffins", "Dhaba", "Cafe", "Grill", "Express"]

NOW = datetime.now().replace(microsecond=0)
FLOW = ["placed", "confirmed", "preparing", "out_for_delivery", "delivered"]


def bulk(cur, sql, rows, batch=5000):
    for i in range(0, len(rows), batch):
        cur.executemany(sql, rows[i:i + batch])


def random_order_time():
    """A time in the last 365 days, weighted toward lunch and dinner hours."""
    day = NOW - timedelta(days=random.randint(3, 365))
    hour = random.choices(range(24),
                          weights=[1, 1, 0, 0, 0, 1, 2, 3, 4, 4, 5, 8,
                                   12, 12, 8, 5, 5, 6, 9, 12, 13, 11, 6, 3])[0]
    return day.replace(hour=hour, minute=random.randint(0, 59), second=random.randint(0, 59))


def main():
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME", "food_delivery"),
    )
    cur = conn.cursor()
    cur.execute("SET @skip_triggers = 1")


    # ---- reset (FK checks off so TRUNCATE works) ----
    cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    for t in ["stock_alerts", "order_status_log", "payments", "order_items", "orders",
              "delivery_partners", "menu_items", "restaurants", "customers"]:
        cur.execute(f"TRUNCATE TABLE {t}")
    cur.execute("SET FOREIGN_KEY_CHECKS = 1")

    # ---- customers ----
    phones, customers = set(), []
    for cid in range(1, N_CUSTOMERS + 1):
        while True:
            phone = random.choice("6789") + "".join(random.choices("0123456789", k=9))
            if phone not in phones:
                phones.add(phone)
                break
        created = NOW - timedelta(days=random.randint(30, 700))
        customers.append((cid, fake.name(), phone, f"{fake.user_name()}{cid}@example.com",
                          random.choice(CITIES), created))
    bulk(cur, "INSERT INTO customers (customer_id, name, phone, email, city, created_at) "
              "VALUES (%s,%s,%s,%s,%s,%s)", customers)

    # ---- restaurants + menu_items ----
    restaurants, menu_rows = [], []
    rest_by_city, menu_by_rest = {c: [] for c in CITIES}, {}
    used_names, item_id = set(), 0
    for rid in range(1, N_RESTAURANTS + 1):
        city = CITIES[rid % len(CITIES)]
        cuisine = random.choice(list(MENU))
        while True:
            name = f"{fake.last_name()} {random.choice(NAME_SUFFIX)}"
            if (name, city) not in used_names:
                used_names.add((name, city))
                break
        restaurants.append((rid, name, city, cuisine, 1 if random.random() < 0.9 else 0,
                            NOW - timedelta(days=random.randint(60, 900))))
        rest_by_city[city].append(rid)
        menu_by_rest[rid] = []
        for dish in random.sample(MENU[cuisine], random.randint(9, 12)):
            item_id += 1
            price = round(random.uniform(60, 450) / 5) * 5
            stock = random.choice([0, 3, 4, 5]) if random.random() < 0.03 else random.randint(20, 200)
            menu_rows.append((item_id, rid, dish, price, stock, 1 if stock > 0 else 0))
            menu_by_rest[rid].append((item_id, price))
    bulk(cur, "INSERT INTO restaurants (restaurant_id, name, city, cuisine, is_open, created_at) "
              "VALUES (%s,%s,%s,%s,%s,%s)", restaurants)
    bulk(cur, "INSERT INTO menu_items (item_id, restaurant_id, name, price, stock_qty, is_available) "
              "VALUES (%s,%s,%s,%s,%s,%s)", menu_rows)

    # ---- delivery partners ----
    partners, partners_by_city = [], {c: [] for c in CITIES}
    for pid in range(1, N_PARTNERS + 1):
        city = CITIES[pid % len(CITIES)]
        status = random.choices(["available", "busy", "offline"], weights=[55, 0, 45])[0]
        partners.append([pid, fake.name(), "9" + "".join(random.choices("0123456789", k=9)),
                         city, status])
        partners_by_city[city].append(pid)
    seen = set()
    for p in partners:
        while p[2] in seen:
            p[2] = "9" + "".join(random.choices("0123456789", k=9))
        seen.add(p[2])

    # ---- orders, order_items, payments, status log ----
    times = sorted(random_order_time() for _ in range(N_ORDERS))
    for i in range(N_ORDERS - N_ACTIVE_ORDERS, N_ORDERS):          # newest ones: still active
        times[i] = NOW - timedelta(minutes=random.randint(5, 120))
    times[N_ORDERS - N_ACTIVE_ORDERS:] = sorted(times[N_ORDERS - N_ACTIVE_ORDERS:])

    orders, items, payments, logs = [], [], [], []
    busy_partners, pay_id, oi_id, log_id = set(), 0, 0, 0
    for oid in range(1, N_ORDERS + 1):
        created = times[oid - 1]
        cust = random.choice(customers)
        rid = random.choice(rest_by_city[cust[4]])
        menu = menu_by_rest[rid]

        # final status
        if oid > N_ORDERS - N_ACTIVE_ORDERS:
            final = random.choice(["placed", "confirmed", "preparing", "out_for_delivery"])
        else:
            final = random.choices(["delivered", "cancelled"], weights=[92, 8])[0]

        # status history
        if final == "cancelled":
            steps = ["placed", "confirmed", "cancelled"] if random.random() < 0.3 else ["placed", "cancelled"]
        else:
            steps = FLOW[:FLOW.index(final) + 1]
        ts, last_ts = created, created
        for k, st in enumerate(steps):
            if k > 0:
                ts = ts + timedelta(minutes=random.randint(1, 20), seconds=random.randint(0, 59))
            log_id += 1
            logs.append((log_id, oid, steps[k - 1] if k > 0 else None, st, ts))
            last_ts = ts

        # partner
        partner = None
        if final in ("preparing", "out_for_delivery", "delivered"):
            partner = random.choice(partners_by_city[cust[4]])
            if final in ("preparing", "out_for_delivery"):
                busy_partners.add(partner)

        # lines
        chosen = random.sample(menu, random.randint(1, min(4, len(menu))))
        total = 0
        for it_id, price in chosen:
            qty = random.randint(1, 3)
            oi_id += 1
            items.append((oi_id, oid, it_id, qty, price))
            total += qty * price

        orders.append((oid, cust[0], rid, partner, final, total, created, last_ts))

        # payment
        method = random.choices(["upi", "card", "cod", "wallet"], weights=[50, 20, 20, 10])[0]
        if final == "delivered":
            pstatus = "paid"
        elif final == "cancelled":
            pstatus = "failed" if method == "cod" else "refunded"
        else:
            pstatus = "pending" if method == "cod" else "paid"
        paid_at = created + timedelta(minutes=random.randint(1, 5)) if pstatus in ("paid", "refunded") else None
        pay_id += 1
        payments.append((pay_id, oid, total, method, pstatus, paid_at, created))

    for p in partners:                                     # partners on active orders are busy
        if p[0] in busy_partners:
            p[4] = "busy"
    bulk(cur, "INSERT INTO delivery_partners (partner_id, name, phone, city, status) "
              "VALUES (%s,%s,%s,%s,%s)", [tuple(p) for p in partners])
    bulk(cur, "INSERT INTO orders (order_id, customer_id, restaurant_id, partner_id, status, "
              "total_amount, created_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)", orders)
    bulk(cur, "INSERT INTO order_items (order_item_id, order_id, item_id, quantity, unit_price) "
              "VALUES (%s,%s,%s,%s,%s)", items)
    bulk(cur, "INSERT INTO payments (payment_id, order_id, amount, method, status, paid_at, created_at) "
              "VALUES (%s,%s,%s,%s,%s,%s,%s)", payments)
    bulk(cur, "INSERT INTO order_status_log (log_id, order_id, old_status, new_status, changed_at) "
              "VALUES (%s,%s,%s,%s,%s)", logs)


    conn.commit()
    for t in ["customers", "restaurants", "menu_items", "delivery_partners", "orders",
              "order_items", "payments", "order_status_log", "stock_alerts"]:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        print(f"{t:20s} {cur.fetchone()[0]:>8,}")
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
