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
    private static int cp = 0; // Cantidad de procedimientos creados
    private Simbolo.Tipo tipo;

    public Procedimiento(int nivelDecl, Simbolo.Tipo tipo) {
        cp++; // Aumenta la cantidad de procedimientos
        this.np = cp;
        this.tipo = tipo;
    }

    public int getNp() {
        return np;
    }

    public static int getNumProc() {
        return cp;
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

    public static int getCp() {
        return cp;
    }

    public static void setCp(int cp) {
        Procedimiento.cp = cp;
    }

    public Simbolo.Tipo getTipo() {
        return tipo;
    }

    public void setTipo(Simbolo.Tipo tipo) {
        this.tipo = tipo;
    }

    @Override
    public String toString() {
        return String.valueOf(np);
    }
}
