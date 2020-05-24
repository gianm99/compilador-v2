# Preguntas
- ¿Hay que implementar arrays en nuestro lenguaje si no los tiene ya?
- ¿Cómo hacemos para usar la tabla de variables y la tabla de procedimientos si ya usamos una tabla de símbolos al compilar?
- ¿Qué es exactamente `pproc` y para qué sirve si, por ejemplo, no se pueden declarar procedimientos dentro de otros procedimientos?
- ¿Cuál es la información que se tiene que guardar de una variable?
- ¿Cuál es la información que se tiene que guardar de un procedimiento?
- ¿Qué es realmente el `.r` que usamos cuando hablamos de una variable?
- ¿Qué es realmente el `.d` que usamos cuando hablamos de una variable?
- ¿Qué son las etiquetas, números de líneas?
- ¿Hay que crear una clase etiqueta y guardarlas de alguna manera en concreto?
- ¿Qué hace este código? Es parte del código de la rutina semántica para la gestión de arrays.
    ```
    dv = consulta(ts,id.id)
    dt = consulta(ts,dv.td)
    idx = primer_index(ts,dt)
    ```
- ¿Qué estructura deberíamos usar para las tablas (símbolos, variables y procedimentos)?¿Arrays, listas enlazadas, HashTables?