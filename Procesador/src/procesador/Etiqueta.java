package procesador;

/**
 * Etiqueta. Clase que sirve para gestionar las etiquetas que se generan.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Etiqueta {
    private int ne; // Número de etiqueta
    private int linea; // Número de línea
    private boolean deproc;

    public Etiqueta(int ne, boolean deproc) {
        this.ne = ne; // Asigna el número de etiqueta
        this.deproc = deproc;
        this.linea= 0; // Al principio la línea no está asignada
    }

    public static int get(String etiqueta) {
        return Integer.parseInt(etiqueta.substring(1));
    }

    public int getNe() {
        return ne;
    }

    public int getLinea() {
        return linea;
    }

    public void setLinea(int linea) {
        this.linea = linea;
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
