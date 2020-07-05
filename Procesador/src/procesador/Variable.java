package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en el
 * código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Variable {
    private int r;
    private int nv; // Número de variable
    private Procedimiento proc; // Procedimiento que la ha declarado
    private Simbolo.Tipo tipo; // Tipo: variable, constante o argumento
    private Simbolo.TSub tsub; // Tipo subyacente
    private boolean temporal;
    private static boolean inicializada;
    private static int cv = 0; // Cantidad de variables creadas

    public Variable(Variable v) {
        this.r = v.r;
        this.nv = v.nv;
        this.proc = v.proc;
        this.tipo = v.tipo;
        this.temporal = v.temporal;
    }

    public Variable(Procedimiento proc, Simbolo.Tipo tipo, Simbolo.TSub tsub) {
        cv++; // Aumenta la cantidad de variables
        this.nv = cv;
        this.tipo = tipo;
        this.setTsub(tsub);
        this.proc = proc;
    }

    public Simbolo.TSub getTsub() {
        return tsub;
    }

    public void setTsub(Simbolo.TSub tsub) {
        this.tsub = tsub;
    }

    public static boolean isInicializada() {
        return inicializada;
    }

    public static void setInicializada(boolean inicializada) {
        Variable.inicializada = inicializada;
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
            return "t" + nv;
        } else {
            return "v" + nv;
        }
    }

    public Procedimiento getProc() {
        return proc;
    }

    public void setProc(Procedimiento proc) {
        this.proc = proc;
    }
}
