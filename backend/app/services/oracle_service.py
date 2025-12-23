def call_procedure(name: str, params: list):
    conn = get_connection()
    cur = conn.cursor()
    cur.callproc(name, params)
    return params
