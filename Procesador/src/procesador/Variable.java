package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Variable {

    private int nv; // Número de variable
    private int np; // Número de subprograma que la ha declarado
    private Tipo tipo; // Tipo: variable, constante o argumento
    private static int numVar = 0; // Número de variables creadas

    public enum Tipo {
        VAR, CONST, ARG
    }

    public int getNv() {
        return nv;
    }

    public static int getNumVar() {
        return numVar;
    }

    public void setNv(int nv) {
        this.nv = nv;
    }

    public int getNp() {
        return np;
    }

    public void setNp(int np) {
        this.np = np;
    }

    public Tipo getTipo() {
        return tipo;
    }

    public void setTipo(Tipo tipo) {
        this.tipo = tipo;
    }

    public Variable(int nv, int np, Tipo tipo) {
        this.nv = nv;
        this.np = np;
        this.tipo = tipo;
        numVar++;
    }

}
