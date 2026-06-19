import sqlite3

conn = sqlite3.connect('db.sqlite3')
cursor = conn.cursor()
cursor.execute("SELECT id, email, first_name, last_name, role FROM users_user;")
users = cursor.fetchall()

cursor.execute("SELECT assigned_agent_id, COUNT(*) FROM dossiers_dossier GROUP BY assigned_agent_id;")
agent_dossiers = cursor.fetchall()
conn.close()

print("Agent dossier counts:")
for row in agent_dossiers:
    agent_id = row[0]
    count = row[1]
    user = next((u for u in users if u[0] == agent_id), None)
    if user:
        print(f"Agent: {user[1]} ({user[2]} {user[3]}) - Dossiers: {count}")
    else:
        print(f"Agent ID: {agent_id} - Dossiers: {count}")
