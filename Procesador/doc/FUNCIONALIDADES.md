# Funcionalidades del compilador

En este documento se muestran cuáles son las funcionalidades de las que dispone nuestro compilador ordenadas por su temática.

## Procesamiento de texto

En lo relativo al procesamiento de texto, análisis léxico, sintáctico y semántico dispone de estas funcionalidades o características:

### Lenguaje

El lenguaje es una versión simplificada de Java con elementos propios de lenguajes como Python y con las siguientes características:
- Tipos de variables
- Entero
- String
- Boolean
- Operaciones
- Operaciones aritméticas
    - Negación
    - Multiplicación
    - División
    - Suma
    - Resta
- Operaciones lógicas
    - Not
    - And
    - Or
- Operaciones relacionales
    - Igual
    - Diferente
    - Mayor
    - Menor
    - Mayor o igual
    - Menor o igual
- Operaciones de entrada y salida (read y print)
- Asignación
- Estructura condicional
    - If
    - If else
- Estructura iterativa
    - While
- Llamada a método
    - Llamada a función
    - Llamada a procedmiento
- Return de valor

### Detalles del lenguaje

Como detalles a destacar del lenguaje tenemos los siguientes:

- Se pueden definir variables y constantes dentro de funciones, procedimientos, estructuras condicionales e iterativas.
- Se pueden definir funciones y procedimientos dentro de funciones y procedimientos.
- La estructura de los programas, subprogramas y sentencias complejas (condicionales e iterativas) tiene que ser esta:
  1. *Declaraciones*. Puede no haber ninguna declaración.
  2. *Sentencias*. Tiene que haber como mínimo una.
- Se pueden hacer returns a mitad de función o a mitad de procedimiento. En el caso del procedimiento tiene que ser un return vacío que no devuelva ninguna expresión.

## Compilador

### Detalles del análisis

- El compilador detecta los errores léxicos, sintácticos y semánticos. 
  - Si detecta un error sintáctico deja de ejecutarse.
  - Si detecta un error semántico sigue evaluando el restro del programa para encontrar el resto.
- Al imprimir los mensajes se muestran con colores distintos dependiendo de si el proceso de compilación ha sido exitoso. Se muestra en verde si se ha compilado correctamente y en rojo si ha habido algún error.

### Detalles de la generación de código

- El proceso de compilación de hace en dos pasadas. Primero se realiza la comprobación de que el programa está bien escrito con el análisis léxico, sintáctico y semántico, y después se genera el código intermedio utilizando la información obtenida en la primera pasada y también volviendo a analizar el código.
