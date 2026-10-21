import os
from fastapi import FastAPI, status
from pydantic import BaseModel

app = FastAPI(
    title="Cloud Health & Echo Service",
    version="1.0.0"
)

class RespuestaSalud(BaseModel):
    status: str
    environment: str

class RespuestaInfo(BaseModel):
    service: str
    message: str
    status: str
    environment: str

class RespuestaRaiz(BaseModel):
    nombre: str
    version: str
    endpoints: dict

@app.get("/", response_model=RespuestaRaiz, status_code=status.HTTP_200_OK)
def leer_raiz():
    return {
        "nombre": "Cloud Health & Echo Service",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "info": "/info",
            "docs": "/docs"
        }
    }

@app.get("/health", response_model=RespuestaSalud, status_code=status.HTTP_200_OK)
def obtener_salud():
    entorno = os.getenv("ENVIRONMENT", "production")
    return {
        "status": "ok",
        "environment": entorno
    }

@app.get("/info", response_model=RespuestaInfo, status_code=status.HTTP_200_OK)
def obtener_informacion():
    saludo = os.getenv("APP_GREETING", "Hola desde Azure Key Vault")
    entorno = os.getenv("ENVIRONMENT", "production")
    return {
        "service": "Cloud Health & Echo Service",
        "message": saludo,
        "status": "active",
        "environment": entorno
    }

if __name__ == "__main__":
    import uvicorn
    puerto = int(os.getenv("PORT", 8000))
    uvicorn.run("app:app", host="0.0.0.0", port=puerto, reload=True)
