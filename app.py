from flask import Flask, jsonify, request, Response
from db.queries import *
from flask_cors import CORS


app = Flask(__name__)
CORS(app)


@app.route('/')
def hello():
    return 'Hello, World!'

@app.route('/view/<view_name>', defaults={'columns': None})
@app.route('/view/<view_name>/<columns>')
def get_view(view_name: str, columns: str):
    return jsonify(get_view_from_db(view_name, columns))

@app.route('/table/<table_name>', defaults={'columns': None})
@app.route('/table/<table_name>/<columns>')
def get_table(table_name: str, columns: str):
    return jsonify(get_table_from_db(table_name, columns))

@app.route('/delivery_service/<delivery_service_id>/<table>', defaults={'columns': None})
@app.route('/delivery_service/<delivery_service_id>/<table>/<columns>')
def get_table_for_ds(delivery_service_id: str, table: str, columns: str):
    return jsonify(get_ds_info_from_table(delivery_service_id, table, columns))

@app.route('/user/<username>/<table>', defaults={'columns': None})
@app.route('/user/<username>/<table>/<columns>')
def get_table_for_user(username: str, table: str, columns: str):
    return jsonify(get_user_info_from_table(username, table, columns))

@app.route('/procedure/<procedure_name>', methods=['POST', 'PUT', 'DELETE'])
def run_procedure(procedure_name: str):
    params = request.get_json(force=True)
    results = execute_stored_procedure(procedure_name, params["params"])
    if results["result"] == "Success":
        return jsonify(results), 200
    else:
        return jsonify(results), 400

if __name__ == "__main__":
    app.run(debug=True)