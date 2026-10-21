# Antigravity Voice Reader (Text-to-Speech)

<p align="center">
  <strong>Language:</strong>
  <a href="README.md">Español</a> |
  <a href="README.en.md">English</a> |
  <a href="README.de.md">Deutsch</a>
</p>

Este es un reproductor flotante y herramienta de fondo diseñada para leer en voz alta las respuestas del agente de Antigravity IDE de forma natural, usando el motor nativo de síntesis de voz de Windows.

## Características Principales

*   **Multilingüe Inteligente (Auto-Detección):** Analiza en tiempo real el texto de la respuesta y conmuta automáticamente entre las voces instaladas en Windows:
    *   🇩🇪 **Alemán (de-DE):** `Microsoft Hedda Desktop` (pronuncia umlauts ä, ö, ü, ß a la perfección).
    *   🇪🇸 **Español (es-ES):** `Microsoft Helena Desktop`.
    *   🇺🇸 **Inglés (en-US):** `Microsoft Zira Desktop`.
*   **Selector Manual de Idioma:** En el modo expandido dispones de un menú desplegable para bloquear el lector en un idioma específico (`Auto`, `Español`, `Deutsch`, `English`).
*   **Limpieza Inteligente Contextual:** Elimina marcas de código y enlaces adaptando la pronunciación al idioma (ej. *"Code ausgelassen"* en alemán vs *"código omitido"* en español).
*   **0-Block UI (Alto Rendimiento):** Utiliza un sistema avanzado de lectura basada en bytes (StreamReader) para monitorizar el chat (`transcript.jsonl`) sin consumir memoria y sin congelar los controles gráficos.
*   **Mini-Reproductor Gráfico Híbrido:** Interfaz flotante (`TopMost`) con modo compacto y modo expandido con transcripción en vivo.

## Requisitos
- Windows 10 o Windows 11.
- PowerShell.
- Antigravity IDE instalado.

## ¿Cómo funciona?
El script lee en tiempo real el archivo de registro interno de tu chat actual. Cuando detecta que el agente ("MODEL") acaba de enviar una respuesta, determina el idioma, normaliza el texto y lo envía al sintetizador de voz en un proceso paralelo (`SpeakAsync`).

## Instrucciones de Instalación y Uso

La forma más sencilla de utilizar la herramienta es mediante los archivos `.bat` incluidos:

0. **Instalación Rápida (Para acceso global):**
   Haz doble clic en el archivo **`Instalar_Acceso.bat`**. Esto creará de forma automática un acceso directo en tu Escritorio.

1. **Uso Diario (Recomendado - Auto-Detección):**
   Haz doble clic en **`Lector.bat`**. Se acoplará automáticamente a tu conversación y detectará el idioma en cada mensaje.

2. **Lanzar Directamente en Alemán:**
   Haz doble clic en **`Lector_DE.bat`** (en la raíz o en la carpeta `VoiceReader_de/`). Iniciará el lector directamente configurado en alemán con saludo *"Sprachausgabe bereit"*.

3. **Modo Gráfico por Comando (Avanzado):**
   Puedes invocar manualmente el script con idioma específico o automático:
   ```powershell
   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File .\reader_gui.ps1 -ConversationId auto -Language auto
   ```

3. **Modo Consola Original (Obsoleto):**
   Si prefieres no usar botones y ejecutar el programa en una terminal pura:
   ```powershell
   .\reader.ps1 -ConversationId auto
   ```

## Controles del Reproductor (Mini y Expandido)
- ⏯️ **Pause / Resume:** Pausa la síntesis actual y la reanuda desde el mismo punto exacto.
- ⏹️ **Stop:** Detiene completamente la lectura del mensaje actual.
- 🔄 **Repeat:** Vuelve a leer el último mensaje desde el inicio.
- 🗖 **Maximizar / Modo Expandido:** Permite ampliar la ventana para ver en tiempo real el texto transcrito de la respuesta que se está leyendo y el estado actual.
- 🗗 **Volver a Modo Compacto:** Mediante el botón de restaurar de la ventana o el botón `Compact` en la barra superior, la ventana regresa al tamaño flotante compacto.
- 🗕 **Minimizar:** Minimiza la ventana a la barra de tareas de Windows para no interrumpir tu espacio de trabajo.
- ❌ **Cerrar:** Cierra y finaliza la aplicación.

### Notas adicionales
- El reproductor omite por completo los bloques de código encerrados entre triples comillas y URLs largas para que no pases minutos escuchando a la IA deletrear símbolos de programación.
- Puedes alternar entre el modo mini flotante compacto y el modo expandido en cualquier momento sin interrumpir la reproducción.

<br>
<p align="center">
  <a href="./Project.md"><img src="https://img.shields.io/badge/Visitar-Arquitectura-blue?style=for-the-badge"></a>
</p>

---
<br>
<p align="center">
  <small>All rights reserved © 2026 | <a href="https://github.com/dwn10">Darwin Paz</a></small>
</p>
