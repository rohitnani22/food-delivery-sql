"""
app_demo.py - calls the food_delivery database from Python using parameterized queries.
"""
import json
import os

import mysql.connector
from dotenv import load_dotenv

load_dotenv()
   import warnings
   warnings.filterwarnings("ignore", category=DeprecationWarning)


def connect():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME", "food_delivery"),
    )


def count_orders_unsafe(cur, status):
    # DANGEROUS: the input is glued into the SQL text
    cur.execute(f"SELECT COUNT(*) FROM orders WHERE status = '{status}'")
    return cur.fetchone()[0]


def count_orders_safe(cur, status):
    # SAFE: %s is a placeholder, the driver sends the value separately as data
    cur.execute("SELECT COUNT(*) FROM orders WHERE status = %s", (status,))
    return cur.fetchone()[0]


def main():
    conn = connect()
    cur = conn.cursor()

    print("1. SQL injection demo")
    evil = "delivered' OR '1'='1"
    print("   unsafe query returns:", count_orders_unsafe(cur, evil), "orders")
    print("   safe query returns:  ", count_orders_safe(cur, evil), "orders")

    print("\n2. Search orders with the stored procedure")
    cur.callproc("search_orders", (1, "delivered", None, None, "amount", 3))
    for result in cur.stored_results():
        for row in result.fetchall():
            print("  ", row)

    print("\n3. Place an order (stored procedure with a transaction)")
    cart = json.dumps([{"item_id": 27, "qty": 1}])
    out = cur.callproc("place_order", (1, 3, cart, "upi", 0, 0))
    order_id, total = out[4], out[5]
    print(f"   created order {order_id}, total {total}")

    print("\n4. A failing order is rejected and rolled back")
    bad_cart = json.dumps([{"item_id": 27, "qty": 9999}])
    try:
        cur.callproc("place_order", (1, 3, bad_cart, "upi", 0, 0))
    except mysql.connector.Error as err:
        print("   rejected:", err.msg)

    print("\n5. Cancel the order from step 3")
    cur.callproc("cancel_order", (order_id,))
    for result in cur.stored_results():
        print("  ", result.fetchall())

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
