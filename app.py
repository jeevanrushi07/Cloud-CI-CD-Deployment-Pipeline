from flask import Flask, render_template, request
import psycopg2
import os

app = Flask(__name__)

# Environment Variables
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

# 🔼 NEW FUNCTION TO CREATE TABLE IF NOT EXISTS
def create_table_if_not_exists():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS greetings (
                id SERIAL PRIMARY KEY,
                username TEXT NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Table creation failed: {e}")

@app.route('/', methods=['GET', 'POST'])
def index():
    create_table_if_not_exists()  # 🔼 ADDED THIS LINE

    if request.method == 'POST':
        username = request.form['username']
        greeting = f"Hello {username}!"
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO greetings (username, message) VALUES (%s, %s);",
                (username, greeting)
            )
            conn.commit()
            cur.close()
            conn.close()
        except Exception as e:
            return f"Database insert failed: {str(e)}"

        return render_template('hello.html', username=username)

    return render_template('form.html')

@app.route('/greetings')
def show_greetings():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT message FROM greetings ORDER BY created_at DESC;")
        greetings = cur.fetchall()
        cur.close()
        conn.close()
        return "<br>".join([g[0] for g in greetings])
    except Exception as e:
        return f"Error fetching greetings: {str(e)}"

@app.route('/users')
def show_usernames():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT username FROM greetings ORDER BY created_at DESC;")
        usernames = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('usernames.html', usernames=[u[0] for u in usernames])
    except Exception as e:
        return f"❌ Error: {str(e)}"

@app.route('/healthz')
def healthz():
    return {'status': 'broken'}, 500
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1;')
        cur.fetchone()
        cur.close()
        conn.close()
        return {'status': 'healthy', 'database': 'reachable'}, 200
    except Exception as e:
        return {'status': 'unhealthy', 'database': 'unreachable', 'error': str(e)}, 503

@app.route('/check')
def check_count():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM greetings;")
        count = cur.fetchone()[0]
        cur.close()
        conn.close()
        return f"✅ Total greetings in database: {count}"
    except Exception as e:
        return f"❌ Error: {str(e)}"

@app.route('/debug')
def check_rows():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, username, message, created_at FROM greetings ORDER BY created_at DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return "<br>".join([f"{row[0]} | {row[1]} | {row[2]} | {row[3]}" for row in rows])
    except Exception as e:
        return f"❌ Error: {str(e)}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
