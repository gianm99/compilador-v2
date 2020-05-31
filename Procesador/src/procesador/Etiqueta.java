package procesador;

/**
 * Etiqueta. Clase que sirve para gestionar las etiquetas que se generan.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Etiqueta {
    private int nl; // Número de línea
    private int ne; // Número de etiqueta
    private static int ce = 0; // Cantidad de etiquetas

    public Etiqueta(int nl) {
        ce++; // Aumenta la cantidad de etiquetas generadas
        this.nl = nl;
        ne = ce; // Asigna el número de etiqueta
    }

    public int getNe() {
        return ne;
    }

    public int getNl() {
        return nl;
    }

    public void setNl(int nl) {
        this.nl = nl;
    }
}
