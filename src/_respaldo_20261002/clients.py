"""
Capa de clientes de modelos — interfaz común sobre los SDKs oficiales.
Tesis: LLMs como Asistentes de Programación PLC en la Academia (FIE-UTP).

Diseño: cada proveedor implementa ModelClient.generate(). El runner no sabe
qué proveedor usa: solo pide (texto, metadatos). Esto garantiza que todos
los modelos reciban EXACTAMENTE el mismo prompt y parámetros (variable de
control del diseño experimental).

Claves de API (nunca en el código; variables de entorno):
    OPENAI_API_KEY, ANTHROPIC_API_KEY, GOOGLE_API_KEY
Ollama no requiere clave (servidor local, http://localhost:11434).
"""

from __future__ import annotations
import os
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class Generacion:
    """Resultado de una llamada: el texto y los metadatos que exige la propuesta."""
    texto: str
    modelo_reportado: str      # identificador exacto que reporta la API
    tokens_entrada: int
    tokens_salida: int
    latencia_s: float


class ModelClient(ABC):
    """Interfaz común. El runner solo conoce esta clase."""

    def __init__(self, model_id: str, temperature: float, max_tokens: int):
        self.model_id = model_id
        self.temperature = temperature
        self.max_tokens = max_tokens

    @abstractmethod
    def generate(self, prompt: str) -> Generacion:
        ...


class OpenAIClient(ModelClient):
    """GPT-4o vía SDK oficial `openai`. También sirve para cualquier endpoint
    compatible con la API de OpenAI (ver OllamaClient)."""

    def __init__(self, model_id, temperature, max_tokens, base_url=None, api_key=None):
        super().__init__(model_id, temperature, max_tokens)
        from openai import OpenAI  # import diferido: solo si se usa
        self._cli = OpenAI(
            base_url=base_url,
            api_key=api_key or os.environ.get("OPENAI_API_KEY"),
        )

    def generate(self, prompt: str) -> Generacion:
        t0 = time.monotonic()
        r = self._cli.chat.completions.create(
            model=self.model_id,
            messages=[{"role": "user", "content": prompt}],
            temperature=self.temperature,
            max_tokens=self.max_tokens,
        )
        return Generacion(
            texto=r.choices[0].message.content,
            modelo_reportado=r.model,
            tokens_entrada=r.usage.prompt_tokens,
            tokens_salida=r.usage.completion_tokens,
            latencia_s=round(time.monotonic() - t0, 2),
        )


class OllamaClient(OpenAIClient):
    """Modelos open-source locales (Qwen 2.5 Coder, etc.).
    Ollama expone un endpoint compatible con OpenAI: mismo cliente, otra URL."""

    def __init__(self, model_id, temperature, max_tokens):
        super().__init__(
            model_id, temperature, max_tokens,
            base_url="http://localhost:11434/v1",
            api_key="ollama",  # valor dummy requerido por el SDK
        )


class AnthropicClient(ModelClient):
    """Claude vía SDK oficial `anthropic`."""

    def __init__(self, model_id, temperature, max_tokens):
        super().__init__(model_id, temperature, max_tokens)
        import anthropic
        self._cli = anthropic.Anthropic()  # lee ANTHROPIC_API_KEY del entorno

    def generate(self, prompt: str) -> Generacion:
        t0 = time.monotonic()
        r = self._cli.messages.create(
            model=self.model_id,
            max_tokens=self.max_tokens,
            temperature=self.temperature,
            messages=[{"role": "user", "content": prompt}],
        )
        return Generacion(
            texto="".join(b.text for b in r.content if b.type == "text"),
            modelo_reportado=r.model,
            tokens_entrada=r.usage.input_tokens,
            tokens_salida=r.usage.output_tokens,
            latencia_s=round(time.monotonic() - t0, 2),
        )


class GeminiClient(ModelClient):
    """Gemini vía SDK oficial `google-genai`."""

    def __init__(self, model_id, temperature, max_tokens):
        super().__init__(model_id, temperature, max_tokens)
        from google import genai
        self._cli = genai.Client()  # lee GOOGLE_API_KEY del entorno
        self._types = __import__("google.genai.types", fromlist=["types"])

    def generate(self, prompt: str) -> Generacion:
        t0 = time.monotonic()
        r = self._cli.models.generate_content(
            model=self.model_id,
            contents=prompt,
            config={
                "temperature": self.temperature,
                "max_output_tokens": self.max_tokens,
            },
        )
        um = r.usage_metadata
        return Generacion(
            texto=r.text,
            modelo_reportado=self.model_id,
            tokens_entrada=getattr(um, "prompt_token_count", 0) or 0,
            tokens_salida=getattr(um, "candidates_token_count", 0) or 0,
            latencia_s=round(time.monotonic() - t0, 2),
        )


def crear_cliente(proveedor: str, model_id: str,
                  temperature: float, max_tokens: int) -> ModelClient:
    """Fábrica: traduce la entrada del config.yaml a un cliente concreto."""
    fabrica = {
        "openai": OpenAIClient,
        "anthropic": AnthropicClient,
        "google": GeminiClient,
        "ollama": OllamaClient,
    }
    if proveedor not in fabrica:
        raise ValueError(f"Proveedor no soportado: {proveedor}")
    return fabrica[proveedor](model_id, temperature, max_tokens)
