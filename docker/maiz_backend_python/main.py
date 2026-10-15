from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Form
from fastapi.middleware.cors import CORSMiddleware
from ia_maiz import CornDiagnosisModel
import os
import jwt

# Leer configuración sensible desde variables de entorno
JWT_SECRET = os.getenv('JWT_SECRET')
API_KEY = os.getenv('PYTHON_API_KEY')


app = FastAPI()

# ================================
#            CORS
# ================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv('FRONTEND_URL', "https://maizapp-ec.com")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializar modelo una sola vez al arrancar
model = CornDiagnosisModel()

# ================================
#    MODO SIMULADOR
# ================================
def simulator_mode():
    try:
        if os.path.exists("simulator_mode.txt"):
            with open("simulator_mode.txt", "r") as f:
                return f.read().strip().lower() == "on"
        return False
    except:
        return False

# ================================
#   PREDICCIÓN IA (Único Endpoint)
# ================================
@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    tipo: str = Form('enfermedad'),
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None)
):
    """
    Recibe la imagen desde Node.js, la procesa y devuelve el JSON.
    No guarda nada en BD.
    """
    # autenticación simple: aceptar JWT válido o API_KEY
    if JWT_SECRET:
        if not authorization:
            raise HTTPException(status_code=401, detail="Token requerido")
        parts = authorization.split(' ')
        if len(parts) != 2 or parts[0] != 'Bearer':
            raise HTTPException(status_code=401, detail="Formato de token inválido")
        try:
            jwt.decode(parts[1], JWT_SECRET, algorithms=['HS256'])
        except Exception as e:
            raise HTTPException(status_code=401, detail="Token inválido")
    elif API_KEY:
        if x_api_key != API_KEY:
            raise HTTPException(status_code=401, detail="API key inválida")

    try:
        img_bytes = await file.read()

        if simulator_mode():
            import random
            # Intentar leer etiquetas reales si existen
            labels = ["maiz_sano", "roya", "tizon", "mancha_gris", "no_maiz"]
            if os.path.exists("labels.txt"):
                labels = open("labels.txt").read().splitlines()
            
            fake = random.choice(labels)

            return {
                "disease": fake,
                "confidence": 0.99,
                "advice": "Diagnóstico simulado por IA Python",
                "is_corn_leaf": fake != "no_maiz"
            }

        # Predicción Real
        return model.predict(img_bytes, tipo)

    except Exception as e:
        print(f"Error en predicción Python: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ================================
#   HEALTH CHECK
# ================================
@app.get("/health")
def health():
    return {"status": "ok", "service": "Python AI Worker"}

if __name__ == "__main__":
    import uvicorn
    # Corre en puerto 8000 INTERNO del contenedor
    uvicorn.run(app, host="0.0.0.0", port=8000)