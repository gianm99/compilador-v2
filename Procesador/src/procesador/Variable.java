package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Variable {
    private int r;
    private int nv; // Número de variable
    private int np; // Subprograma que la ha declarado. 0 -> ninguno
    private Tipo tipo; // Tipo: variable, constante o argumento
    private static int cv = 0; // Cantidad de variables creadas

    public Variable(int np, Tipo tipo) {
        cv++; // Aumenta la cantidad de variables
        this.nv = cv;
        this.np = np;
        this.tipo = tipo;
    }

    public enum Tipo {
        VAR, CONST, ARG
    }

    public int getNv() {
        return nv;
    }

    public int getNp() {
        return np;
    }

    public Tipo getTipo() {
        return tipo;
    }

    public static int getNumVar() {
        return cv;
    }

    public int getR() {
        return r;
    }

    public void setR(int r) {
        this.r = r;
    }
}
