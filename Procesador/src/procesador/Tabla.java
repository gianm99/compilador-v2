package procesador;

import procesador.Simbolo.TSub;

/**
 * La clase Tabla representa una tabla o 'array' y contiene la información
 * necesaria para verificar que se usan de forma correcta en los archivos que se
 * analizan.
 *
 * @author @gianm99
 */
public class Tabla {
    private TSub tsubt; // Tipo subyacente de la tabla
    private Indice primero, ultimo; // Inicio y fin de lista de índices
    private int b; // Desplazamiento conocido en tiempo de compilación
    private int ocupacion; // Ocupación (bytes) de cada elemento
    private int dimensiones; // Número de dimensiones de la tabla

    public Tabla(TSub tsubt) {
        // TSub.NULL porque la tabla no tiene tipo subyacente
        this.tsubt = tsubt;
        this.primero = null;
        this.ultimo = null;
        this.ocupacion = 4; // Todos los tipos de datos ocupan 4 bytes
    }

    /**
     * Calcula el número de dimensiones que tiene la tabla.
     */
    public void calcularDimensiones() {
        int dimensiones = 0;
        Indice i = primero;
        while (i != null) {
            dimensiones++;
            i = i.siguiente();
        }
        this.dimensiones = dimensiones;
    }

    /**
     * Calcula el desplazamiento conocido en tiempo de compilación.
     */
    public void calcularB() {
        int b = 0;
        if (primero != null) {
            b = primero.li();
            Indice i = primero.siguiente();
            while (i != null) {
                b = b * i.d() + i.li();
            }
        }
        this.b = b;
    }

    /**
     * Añade un nuevo índice o dimensión a la tabla.
     */
    public void nuevoIndice(int li, int lf) {
        if (primero == null) {
            primero = new Indice(li, lf);
            ultimo = primero;
        } else {
            ultimo.setSiguiente(new Indice(li, lf));
            ultimo = ultimo.siguiente();
        }
    }

    /**
     * Devuelve el primer índice de la tabla.
     * 
     * @return El primer índice de la tabla.
     */
    public Indice primerIndice() {
        return primero;
    }

    /**
     * Devuelve el tipo subyacente de los elementos de la tabla.
     * 
     * @return El tipo subyacente de los elementos de la tabla.
     */
    public TSub tsubt() {
        return tsubt;
    }

    /**
     * Devuelve el desplazamiento conocido en tiempo de compilación.
     * 
     * @return El desplazamiento conocido en tiempo de compilación.
     */
    public int b() {
        return b;
    }

    /**
     * Devuelve la ocupación (en bytes) de cada elemento de la tabla.
     * 
     * @return La ocupación de cada elemento de la tabla.
     */
    public int ocupacion() {
        return ocupacion;
    }

    /**
     * Devuelve el número de dimensiones de la tabla.
     * 
     * @return El número de dimensiones de la tabla.
     */
    public int dimensiones() {
        return dimensiones;
    }
}
