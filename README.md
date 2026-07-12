# Antigravity Voice Reader (Text-to-Speech)

Este es un reproductor flotante y herramienta de fondo diseñada para leer en voz alta las respuestas del agente de Antigravity IDE de forma natural, usando el motor nativo de síntesis de voz de Windows.

## Características Principales

*   **Voz Nativa en Español:** Detecta automáticamente tu voz instalada con prefijo `es-*` para garantizar la mejor pronunciación posible y evitar voces extranjeras.
*   **Limpieza Inteligente:** Elimina marcas de código, enlaces, y purga caracteres especiales y tildes utilizando un filtrado estricto ASCII/Unicode para evitar errores robóticos en la dicción.
*   **0-Block UI (Alto Rendimiento):** Utiliza un sistema avanzado de lectura basada en bytes (StreamReader) para monitorizar el chat (`transcript.jsonl`) sin consumir memoria y sin congelar los controles gráficos.
*   **Mini-Reproductor Gráfico:** Una pequeña interfaz flotante (`TopMost`) que siempre permanece encima de tu editor para ofrecerte botones de control.

## Requisitos
- Windows 10 o Windows 11.
- PowerShell.
- Antigravity IDE instalado.

## ¿Cómo funciona?
El script lee en tiempo real el archivo de registro interno de tu chat actual. Cuando detecta que el agente ("MODEL") acaba de enviar una respuesta, extrae el texto, filtra los metadatos y emojis, y lo envía al sintetizador de voz en un proceso paralelo (`SpeakAsync`).

## Instrucciones de Instalación y Uso

La forma más sencilla de utilizar la herramienta es mediante el archivo `.bat` incluido:

1. **Uso Diario (Recomendado):**
   Haz doble clic en el archivo **`Lector.bat`**.
   Esto iniciará el reproductor en modo oculto, mostrará directamente el mini-reproductor y se acoplará a tu conversación actual o a la más reciente de forma automática.

2. **Modo Gráfico por Comando (Avanzado):**
   Puedes invocar manualmente el script con un ID específico:
   ```powershell
   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File .\reader_gui.ps1 -ConversationId auto
   ```

3. **Modo Consola Original (Obsoleto):**
   Si prefieres no usar botones y ejecutar el programa en una terminal pura:
   ```powershell
   .\reader.ps1 -ConversationId auto
   ```

## Controles del Mini-Reproductor
- ⏯️ **(Play / Pausa):** Pausa la síntesis actual y la reanuda desde el mismo punto exacto.
- ⏹️ **(Stop):** Detiene completamente la lectura del mensaje actual.
- 🔄 **(Repetir):** Vuelve a leer el último mensaje desde el inicio.

### Notas adicionales
- El reproductor omite por completo los bloques de código encerrados entre triples comillas y URLs largas para que no pases minutos escuchando a la IA deletrear símbolos de programación.
- Para cerrarlo definitivamente, haz clic en la "X" del mini-reproductor flotante.

<br>

## Clonación

Para clonar este repositorio y empezar a trabajar en local, ejecuta el siguiente comando en tu terminal:

```bash
git clone https://github.com/dwn10/AntigravityVoiceReader.git
cd AntigravityVoiceReader
```

## Contribución

¡Las contribuciones son siempre bienvenidas! Si deseas mejorar el proyecto, sigue estos pasos:
1. Haz un **Fork** del proyecto.
2. Crea tu rama de características (`git checkout -b feature/MejoraIncreible`).
3. Realiza tus cambios y haz commit de ellos (`git commit -m 'Añadir alguna MejoraIncreible'`).
4. Haz push a la rama (`git push origin feature/MejoraIncreible`).
5. Abre un **Pull Request**.

## Licencia

Este proyecto está distribuido bajo la licencia **MIT**. Para más información, consulta el archivo [LICENSE](./LICENSE) incluido en este repositorio. La licencia permite uso comercial, modificación, distribución y uso privado.

<br>
<p align="center">
  <a href="./Project.md"><img src="https://img.shields.io/badge/Visitar-Arquitectura-blue?style=for-the-badge" alt="Visitar Arquitectura"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/Licencia-MIT-green?style=for-the-badge" alt="Licencia MIT"></a>
</p>

---
<br>
<p align="center">
  <small>All rights reserved © 2026 | <a href="https://github.com/dwn10">Darwin Paz</a></small>
</p>
