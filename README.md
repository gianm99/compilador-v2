# Compilador: *front-end* y *back-end*

Asignatura `21743 - Compiladores II`

Curso 2019-2020

## Descripción

Programa que procesa un archivo de texto escrito en el lenguaje inventado *Vaja* y genera código intermedio, código ensamblador sin optimizar y código ensamblador optimizado.

## Enunciado de la práctica

La práctica puede ser realizada en grupos de como mucho tres personas. La conformación de cada grupo se tendrá que hacer mediante el apartado correspondiente dentro de la página de la asignatura y en la herramienta Aula Digital.

La práctica consiste en el desarrollo de la parte *back-end* de un procesador para un lenguaje de programación. Las tareas que tendrá que realizar el procesador son las de generación de código intermedio, optimización y generación de código ensamblador. Se tendrá que partir del *front-end* que se ha desarrollado como práctica de la asignatura `21742 - Compiladores I`.

### Funcionalidades del Procesador

El procesador que se tiene que desarrollar debe contemplar las siguientes funcionalidades:

- Tendrá que ser capaz de procesar el código fuente suministrado en un archivo de texto. El procesamiento se realizará a partir del módulo *front-end* desarrollado en la asignatura `21742 - Compiladores I`. A partir de este desarrollo se procederá a generar el código intermedio, a optimizarlo y a generar el código ensamblador resultante.
- Tendrá que generar una serie de ficheros como resultado de su ejecución:
  - Las tablas de variables y procedimientos, con tal de poder comprobar la corrección del código de tres direcciones.
  - Fichero de código intermedio: El código intermedio correspondiente al programa.
  - Fichero de código ensamblador, sin optimizar. Para cada instrucción de tres direcciones se mostrará un comentario con la instrucción y a continuación la traducción.
  - Fichero de código ensamblador, optimizado. La idea es que el ejecutable obtenido con el código optimizado y el código sin optimizar hagan lo mismo pero que se pueda ver la diferencia en el rendimiento.
  - Errores: si se detectan errores se generará un documento con los errores detectados. Indicando por cada error, la línea en la que se ha detectado, el tipo y un mensaje explicativo.

### Características del lenguaje y del procesador

Si es necesario, se tendrá que revisar y completar el lenguaje para asegurar que:

- Se puedan hacer llamadas desde subprogramas a otros subprogramas
- Se pueden hacer declaraciones de subprogramas con parámetros

Opcionalmente se pueden añadir las siguientes funcionalidades:

- Asignación dinámica de memoria

Las operaciones de entrada y salida necesitan una interacción con el sistema operativo. Se tendrán que suministrar las rutinas necesarias para hacerlo.

El proceso de optimización del *back-end* puede constar de diferentes elementos, se tendrá que indicar qué optimizaciones se han realizado. Se entiende por optimización cualquier mejora que se pueda hacer con tal de reducir el tiempo de ejecución o el espacio ocupado por el programa.

## Presentación de la práctica

Se tendrá que entregar una documentación describiendo el trabajo realizado y el código generado, que tiene que funcionar perfectamente y sin errores, el código fuente también se tiene que poder compilar sin errores ni avisos de ningún tipo.

Una vez entregada la práctica se tendrá que realizar una entrevista para discutir los diferentes aspectos.

## Elementos de evaluación

- Documentación correctamente escrita en la que se describan las técnicas utilizadas, el diseño y cualquier aspecto que se desee destacar. No constará de los listados de código fuente. Si por algún motivo especial se considera de especial interés alguna parte del código, sí que se podrá adjuntar.
- Código fuente completo. Instrucciones para la correcta ejecución. La compilación del código fuente o la interpretación no deben generar errores ni excepciones no controladas. El código ensamblador se tendrá que poder compilar sin que se genere ningún error o mensaje de aviso. La ejecución del programa optimizado tendrá que dar el mismo resultado que el del programa no optimizado.
- Como mínimo, **3 casos de prueba correctos** y **3 casos de prueba incorrectos**. Todos los casos se deben poder reproducir. El resultado de la ejecución será:
  - Para los casos correctos el fichero de código de tres direcciones, el de ensamblador no optimizado y el de ensamblador optimizado. Además de la tabla de símbolos y el archivo con los tokens.
  - Para los casos erróneos el código y los mensajes de error obtenidos.
