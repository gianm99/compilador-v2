package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Variable {
    private int r;
    private int nv; // Número de variable
    private Procedimiento sub; // Subprograma que la ha declarado
    private Simbolo.Tipo tipo; // Tipo: variable, constante o argumento
    private boolean temporal;
    private static int cv = 0; // Cantidad de variables creadas

    public Variable(Procedimiento sub, Simbolo.Tipo tipo) {
        cv++; // Aumenta la cantidad de variables
        this.nv = cv;
        this.tipo = tipo;
        this.sub = sub;
    }

    public Variable(Variable v) {
        this.r=v.r;
        this.nv=v.nv;
        this.sub=v.sub;
        this.tipo=v.tipo;
        this.temporal=v.temporal;
    }

    public boolean isTemporal() {
        return temporal;
    }

    public void setTemporal(boolean temporal) {
        this.temporal = temporal;
    }

    public int getR() {
        return r;
    }

    public void setR(int r) {
        this.r = r;
    }

    public int getNv() {
        return nv;
    }

    public void setNv(int nv) {
        this.nv = nv;
    }

    public Procedimiento getSub() {
        return sub;
    }

    public void setSub(Procedimiento sub) {
        this.sub = sub;
    }

    public Simbolo.Tipo getTipo() {
        return tipo;
    }

    public void setTipo(Simbolo.Tipo tipo) {
        this.tipo = tipo;
    }

    public static int getCv() {
        return cv;
    }

    public static void setCv(int cv) {
        Variable.cv = cv;
    }

    @Override
    public String toString() {
        if (temporal) {
            return "t"+nv;
        } else {
            return "v"+nv;
        }
    }
}
