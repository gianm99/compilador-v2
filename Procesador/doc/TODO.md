# Componentes de la práctica

- **Generar una tabla de variables y procedimientos**. En el proceso de compilación se tiene que usar una tabla de variables y una tabla de procedimientos en las que se guardará información.
  - `Variable` y `TablaVariables`.
  - `Procedimiento` y `TablaProcedimientos`.
- **Generación de código intermedio**. Hay que modificar todas las rutinas semánticas que sean necesarias y añadir instrucciones para que, además de hacer un análisis sintáctico y semántico, se genere el código intermedio que corresponda.
- **Programa que optimiza el código intermedio**. Hay que hacer una clase que se encargue de la optimización del código intermedio generado por el Procesador.
- **Programa que traduce de código intermedio a ensamblador (MOTOROLA 68000)**. Hay que desarrollar una clase que se encargue de traducir de instrucciones en código intermedio a un lenguaje ensamblador que puede ser, por ejemplo, Motorola 68000.
