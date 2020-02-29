import flask
import os

ENTORNO = os.environ.get("ENTORNO","desarrollo")

app = flask.Flask(__name__)


@app.route("/")
def index():
    return f"Desde {ENTORNO}: hola nanos que pasa!"


if __name__ == '__main__':
    
    if ENTORNO == "produccion":
        from waitress import serve
        serve(app, host="0.0.0.0", port=5000)
    elif ENTORNO == 'desarrollo':
        app.run(host='0.0.0.0', port=5000, debug=True)        
    else:
        print(f"Variable entorno {ENTORNO} no definida")
    
        
