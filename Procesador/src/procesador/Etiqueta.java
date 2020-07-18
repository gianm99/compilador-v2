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
    private boolean deproc;

    public Etiqueta() {
        ce++; // Aumenta la cantidad de etiquetas generadas
        ne = ce; // Asigna el número de etiqueta
    }

    public static int get(String etiqueta) {
        return Integer.parseInt(etiqueta.substring(1));
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

    @Override
    public String toString() {
        return "e" + ne;
    }

    public boolean isDeproc() {
        return deproc;
    }

    public void setDeproc(boolean deproc) {
        this.deproc = deproc;
    }
}
