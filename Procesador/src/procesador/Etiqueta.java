package procesador;

/**
 * Etiqueta. Clase que sirve para gestionar las etiquetas que se generan.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Etiqueta {
    private int ne; // Número de etiqueta
    private int linea; // Número de línea

    public Etiqueta(int ne) {
        this.ne = ne; // Asigna el número de etiqueta
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
}
