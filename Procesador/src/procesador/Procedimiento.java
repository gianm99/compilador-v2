package procesador;

/**
 * Procedmiento. Clase que sirve para gestionar los procedimientos que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Procedimiento {

    private int np; // Número de procedimiento
    private int nivelDecl; // Nivel de la declaración
    private Etiqueta inicio; // Etiqueta de inicio
    private int numDecl; // Número de declaraciones o variables
    private static int numProc = 0; // Número de procedimientos creados

    public int getNp() {
        return np;
    }

    public static int getNumProc() {
        return numProc;
    }

    public void setNp(int np) {
        this.np = np;
    }

    public int getNivelDecl() {
        return nivelDecl;
    }

    public void setNivelDecl(int nivelDecl) {
        this.nivelDecl = nivelDecl;
    }

    public Etiqueta getInicio() {
        return inicio;
    }

    public void setInicio(Etiqueta inicio) {
        this.inicio = inicio;
    }

    public int getNumDecl() {
        return numDecl;
    }

    public void setNumDecl(int numDecl) {
        this.numDecl = numDecl;
    }

    public Procedimiento(int np, int nivelDecl, Etiqueta inicio, int numDecl) {
        this.np = np;
        this.nivelDecl = nivelDecl;
        this.inicio = inicio;
        this.numDecl = numDecl;
        numProc++;
    }
}
