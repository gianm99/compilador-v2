# Preguntas
- ¿Hay que implementar arrays en nuestro lenguaje si no los tiene ya?
  - No, no es necesario.
- ¿Cómo hacemos para usar la tabla de variables y la tabla de procedimientos si ya usamos una tabla de símbolos al compilar?
  - Como nosotros queramos, es información que se basa en la de la tabla de símbolos. La tabla de símbolos al ser orientada a objetos puede tener entradas que sean variables y otras que sean procedimientos. Si se construyen la tabla de variables y la de procedimientos al mismo tiempo que la tabla de símbolos se confía en que el programa esté bien hecho. Si se hace en dos pasos, es decir, primero se hace la parte front-end y después la parte de construcción de código, es mejor porque puedes decidir hacer esas tablas cuando ya sabes que el programa está bien escrito. Es lo mismo en términos de rendimiento. A parte de esto también habrá que hacer la estructura que necesitemos para escribir el programa en código intermedio.
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