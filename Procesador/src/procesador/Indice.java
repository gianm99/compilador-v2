package procesador;

/**
 * La clase Indice representa un índice de una tabla y contiene la información
 * relacionada.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Indice {
    private int li; // Límite inferior
    private int lf; // Límite superior
    private int d; // Dimensión del índice
    private Indice siguiente; // Puntero al siguiente índice

    Indice(int li, int lf) {
        this.li = li;
        this.lf = lf;
        this.d = lf - li + 1;
        this.siguiente = null;
    }

    /**
     * Devuelve el siguiente índice.
     * 
     * @return El siguiente índice.
     */
    public Indice siguiente() {
        return siguiente;
    }

    /**
     * Asigna el siguiente índice.
     * 
     * @param indice
     *                   El índice siguiente al actual.
     */
    public void setSiguiente(Indice indice) {
        this.siguiente = indice;
    }

    /**
     * Devuelve el límite inferior.
     * 
     * @return El límite inferior
     */
    public int li() {
        return li;
    }

    /**
     * Devuelve el límite superior.
     * 
     * @return El límite superior.
     */
    public int lf() {
        return lf;
    }

    /**
     * Devuelve la dimensión del índice.
     * 
     * @return La dimensión del índice.
     */
    public int d() {
        return d;
    }
}
