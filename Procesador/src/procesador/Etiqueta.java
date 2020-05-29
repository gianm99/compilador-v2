package procesador;

/**
 * Etiqueta. Clase que sirve para gestionar las etiquetas que se generan.
 */
public class Etiqueta {
    private int nl; // Número de línea
    private int ne; // Número de etiqueta
    private static int ce = 0; // Cantidad de etiquetas

    public int getNl() {
        return nl;
    }

    public void setNl(int nl) {
        this.nl = nl;
    }

    public Etiqueta(int nl) {
        this.nl = nl;
    }
}
