package procesador;

/**
 * La clase Indice representa un índice de una tabla y contiene la información
 * relacionada.
 * 
 * @author @gianm99
 */
public class Indice {
    private int li; // Límite inferior
    private int lf; // Límite superior
    private int d; // Dimensión del índice
    private Indice siguiente;

    Indice(int li, int lf) {
        this.li = li;
        this.lf = lf;
        this.d = lf - li + 1;
        this.siguiente = null;
    }

    public Indice siguiente() {
        return siguiente;
    }

    public void setSiguiente(Indice indice) {
        this.siguiente = indice;
    }

    public int li() {
        return li;
    }

    public int lf() {
        return lf;
    }

    public int d() {
        return d;
    }
}
