import pytest
from fastapi.testclient import TestClient
from app import app

cliente = TestClient(app)

def test_endpoint_raiz():
    respuesta = cliente.get("/")
    assert respuesta.status_code == 200
    datos = respuesta.json()
    assert datos["nombre"] == "Cloud Health & Echo Service"
    assert "health" in datos["endpoints"]
    assert "info" in datos["endpoints"]

def test_endpoint_salud_por_defecto():
    respuesta = cliente.get("/health")
    assert respuesta.status_code == 200
    datos = respuesta.json()
    assert datos["status"] == "ok"
    assert datos["environment"] == "production"

def test_endpoint_salud_entorno_personalizado(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "staging")
    respuesta = cliente.get("/health")
    assert respuesta.status_code == 200
    datos = respuesta.json()
    assert datos["status"] == "ok"
    assert datos["environment"] == "staging"

def test_endpoint_info_por_defecto():
    respuesta = cliente.get("/info")
    assert respuesta.status_code == 200
    datos = respuesta.json()
    assert datos["service"] == "Cloud Health & Echo Service"
    assert "message" in datos
    assert len(datos["message"]) > 0

def test_endpoint_info_con_secreto_inyectado(monkeypatch):
    valor_secreto = "Hola desde Azure Key Vault"
    monkeypatch.setenv("APP_GREETING", valor_secreto)
    
    respuesta = cliente.get("/info")
    assert respuesta.status_code == 200
    datos = respuesta.json()
    assert datos["service"] == "Cloud Health & Echo Service"
    assert datos["message"] == valor_secreto
    assert datos["status"] == "active"
