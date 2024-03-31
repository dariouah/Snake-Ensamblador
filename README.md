# Snake-Ensamblador
Este repositorio aloja el código fuente completo del clásico juego Snake, implementado íntegramente en lenguaje ensamblador.
El objetivo del proyecto es ofrecer una versión eficiente y educativa del juego, permitiendo a los interesados en la programación a bajo nivel explorar las técnicas y desafíos de trabajar directamente con la arquitectura del hardware.

## Entorno de Desarrollo

Para codificar y compilar el juego Snake, es necesario preparar tu entorno de desarrollo siguiendo estos pasos:

### Paso 1: Instalación de DOSBox

DOSBox es un emulador que simula una computadora IBM PC compatible, necesario para ejecutar y compilar código en un entorno DOS. Para instalar DOSBox:

1. Visita el sitio web de DOSBox en [https://www.dosbox.com/](https://www.dosbox.com/).
2. Descarga la versión adecuada para tu sistema operativo.
3. Sigue las instrucciones de instalación proporcionadas en el sitio web o en el archivo descargado.

### Paso 2: Descargar Carpeta del Repositorio

Hemos preparado una carpeta específica en este repositorio que contiene todo lo necesario para trabajar cómodamente en la codificación y compilación del juego. No se tiene prevista la modificación de esta carpeta, su objetivo es ofrecer un entorno sencillo con el que trabajar:

1. Navega a la sección de [entorno](/entorno.rar) de este repositorio.
2. Descarga la última versión de la carpeta preparada para el desarrollo del juego Snake.
3. Descomprime la carpeta en un directorio de tu elección.

### Paso 3: Descargar y Preparar el Archivo `.asm`

Antes de comenzar a compilar el código, es necesario descargar el archivo `.asm` y colocarlo en la carpeta correcta:

1. Descarga el archivo [`snake.asm`](/snake.asm) desde la sección de archivos del repositorio.
2. Mueve el archivo `snake.asm` a la carpeta `bin` dentro de la carpeta del repositorio que has descomprimido previamente.


### Paso 4: Compilación del Código

Para compilar el código fuente del juego Snake, es necesario realizar dos pasos principales: ensamblar el código fuente `.asm` a un archivo objeto `.obj` usando `MASM`, y luego enlazar el archivo objeto para crear el ejecutable `.exe` con `LINK`. Sigue estos pasos detalladamente:

1. Abre DOSBox.
2. Monta el directorio donde descomprimiste la carpeta del repositorio como una unidad en DOSBox usando el comando:
   ```
   MOUNT C [ruta-del-directorio]
   ```
   Reemplaza `[ruta-del-directorio]` con la ruta completa donde se encuentra la carpeta descomprimida.
3. Cambia al directorio montado usando:
   ```
   C:
   ```
4. Navega al directorio específico del juego Snake, si es necesario (si a seguido las intrucciones solo debera ejecutar ```cd bin```).
5. **Ensamblar el Código Fuente:**
   Abre DOSBox y navega al directorio donde se encuentra tu archivo `.asm`. Para ensamblar el código fuente y generar un archivo objeto, utiliza el comando `MASM` seguido del nombre de tu archivo, por ejemplo:
   ```
   MASM nombrearchivo.asm;
   ```
   Tras ejecutar este comando, `MASM` te pedirá confirmación para varias opciones durante el proceso. Puedes pulsar `Enter` para aceptar las opciones por defecto, lo que resultará en la creación de un archivo objeto `nombrearchivo.obj`.
6. **Enlazar el Archivo Objeto:**
Una vez que tengas el archivo objeto, el siguiente paso es crear el archivo ejecutable. Para ello, usa el comando `LINK` seguido del nombre del archivo objeto:
   ```
   LINK nombrearchivo.obj;
   ```
Similarmente, `LINK` puede solicitar confirmaciones durante el proceso. Puedes pulsar `Enter` para seleccionar las opciones por defecto. Esto generará un archivo ejecutable `nombrearchivo.exe` en el mismo directorio.

Estos pasos completan el proceso de compilación del juego Snake desde el código fuente `.asm` hasta obtener el ejecutable `.exe`. Recuerda reemplazar `nombrearchivo` con el nombre real de tu archivo de código fuente y el archivo objeto correspondiente.

Siguiendo estos pasos, deberías ser capaz de compilar el juego Snake y ejecutarlo en tu entorno DOSBox.

Siguiendo estos pasos, deberías ser capaz de preparar tu entorno de desarrollo, descargar el código necesario del repositorio, y compilar el juego Snake para probarlo y jugarlo.

## Cómo Jugar

Una vez que hayas compilado el juego Snake correctamente y tengas el archivo ejecutable (`nombrearchivo.exe`), seguir estos pasos para comenzar a jugar:

1. **Iniciar el Juego:**
   - Ejecuta el archivo ejecutable desde DOSBox tecleando:
     ```
     nombrearchivo.exe
     ```
   - Una vez iniciado el juego, presiona la tecla `E` para empezar a jugar. Podrás ver esta y otras opciones en la pantalla del juego.

2. **Controles del Juego:**
   - Mueve la serpiente utilizando las teclas clásicas `W` (arriba), `A` (izquierda), `S` (abajo) y `D` (derecha). Estos controles te permitirán dirigir la serpiente por todo el mapa.

3. **Objetivo y Finalización del Juego:**
   - **Victoria:** El juego termina con una victoria si consigues que la serpiente ocupe todo el espacio disponible en el mapa sin chocarse consigo misma.
   - **Derrota:** La partida termina en derrota si la serpiente choca contra los límites del mapa o consigo misma.

Sigue estos pasos y controles para disfrutar del clásico juego Snake en tu sistema. ¡Buena suerte y diviértete tratando de completar el mapa!

## Video Tutorial de Uso

Para facilitar aún más el proceso de comprensión sobre cómo compilar y jugar el juego Snake, hemos preparado un video tutorial que cubre los siguientes aspectos:

- **Proceso de Compilación Detallado:** El video muestra paso a paso cómo realizar la compilación del juego Snake, desde la descarga de los archivos necesarios hasta la ejecución de los comandos `MASM` y `LINK` para generar el archivo ejecutable. Se siguen las instrucciones detalladas proporcionadas en la sección de compilación de este documento, asegurando que puedas seguir el proceso sin problemas.

- **Cómo Jugar:** Además, el video tutorial incluye una sección dedicada a cómo iniciar y jugar el juego. Se explican los controles del juego (`W`, `A`, `S`, `D` para mover la serpiente) y se muestra cómo iniciar una partida presionando la tecla `E`. También se abordan las condiciones para ganar o perder el juego, ofreciendo consejos para mejorar tu habilidad.

Este recurso visual está pensado para complementar las instrucciones escritas, ofreciendo una alternativa práctica para aquellos que encuentren más fácil aprender visualmente.

[Ver Video Tutorial](/ejemplo-como-usar.mp4)

Recuerda que el video está diseñado como un complemento a este documento README, por lo que te recomendamos leer detenidamente las secciones anteriores para tener toda la información necesaria antes de comenzar.

## Notas Adicionales

- Asegúrate de seguir las instrucciones de compilación detalladas en este documento para generar correctamente el archivo ejecutable del juego Snake.
- Puedes experimentar modificando el código fuente (`nombrearchivo.asm`) para introducir nuevas características al juego o ajustar su dificultad. Recuerda recompilar el juego después de hacer cambios para ver los efectos de tus ajustes.
## Contribuciones

Si deseas contribuir a mejorar este juego de snake en ensamblador, por favor, sientete libre de hacer un fork del repositorio, realizar cambios y enviar un pull request con tus mejoras.

## Licencia

Este proyecto se comparte de manera libre y abierta. Se permite el uso, distribución y modificación sin restricciones. Sin embargo, se agradece el crédito al autor original en caso de uso público.
