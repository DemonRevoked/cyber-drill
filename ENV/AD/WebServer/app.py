#!/usr/bin/env python3
import os
import sqlite3
from flask import Flask, request, render_template, redirect, url_for, flash, jsonify
import hashlib
import base64

app = Flask(__name__)
app.secret_key = 'dev_key_12345'  # Hardcoded secret key

# Hardcoded credentials (vulnerability)
ADMIN_USER = 'admin'
ADMIN_PASS = 'admin123'
DB_PATH = '/app/database.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE,
            password TEXT,
            email TEXT,
            role TEXT DEFAULT 'user'
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS flags (
            id INTEGER PRIMARY KEY,
            flag TEXT UNIQUE,
            description TEXT,
            points INTEGER DEFAULT 10
        )
    ''')
    
    # Insert default admin user
    cursor.execute('INSERT OR IGNORE INTO users (username, password, email, role) VALUES (?, ?, ?, ?)',
                   (ADMIN_USER, hashlib.md5(ADMIN_PASS.encode()).hexdigest(), 'admin@cyberrange.local', 'admin'))
    
    # Insert some flags
    flags = [
        ('FLAG{SQL_INJECTION_1}', 'SQL Injection vulnerability found', 50),
        ('FLAG{HARDCODED_CREDS}', 'Hardcoded credentials discovered', 30),
        ('FLAG{INSECURE_DIRECT_OBJECT}', 'Insecure direct object reference', 40),
        ('FLAG{COMMAND_INJECTION}', 'Command injection vulnerability', 60),
        ('FLAG{XSS_REFLECTED}', 'Reflected XSS vulnerability', 35)
    ]
    
    for flag, desc, points in flags:
        cursor.execute('INSERT OR IGNORE INTO flags (flag, description, points) VALUES (?, ?, ?)',
                       (flag, desc, points))
    
    conn.commit()
    conn.close()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        # Vulnerable SQL query (SQL injection)
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{hashlib.md5(password.encode()).hexdigest()}'"
        cursor.execute(query)
        user = cursor.fetchone()
        conn.close()
        
        if user:
            flash('Login successful!', 'success')
            return redirect(url_for('dashboard', user_id=user[0]))
        else:
            flash('Invalid credentials', 'error')
    
    return render_template('login.html')

@app.route('/dashboard/<int:user_id>')
def dashboard(user_id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        flash('User not found', 'error')
        return redirect(url_for('index'))
    
    return render_template('dashboard.html', user=user)

@app.route('/flags')
def flags():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM flags')
    flags = cursor.fetchall()
    conn.close()
    return render_template('flags.html', flags=flags)

@app.route('/admin')
def admin():
    # No authentication check (vulnerability)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users')
    users = cursor.fetchall()
    cursor.execute('SELECT * FROM flags')
    flags = cursor.fetchall()
    conn.close()
    return render_template('admin.html', users=users, flags=flags)

@app.route('/search')
def search():
    query = request.args.get('q', '')
    if query:
        # Command injection vulnerability
        import subprocess
        result = subprocess.run(['grep', '-r', query, '/app/flags/'], 
                              capture_output=True, text=True, shell=True)
        return f"Search results: {result.stdout}"
    return "No search query provided"

@app.route('/api/user/<int:user_id>')
def api_user(user_id):
    # Insecure direct object reference
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return jsonify({
            'id': user[0],
            'username': user[1],
            'email': user[3],
            'role': user[4]
        })
    return jsonify({'error': 'User not found'}), 404

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
