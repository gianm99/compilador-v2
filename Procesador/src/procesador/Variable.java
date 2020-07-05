package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en el
 * código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Variable {
    private int nv; // Número de variable
    private boolean temporal; // Si la variable es temporal
    private int proc; // Número del procedimiento que la ha declarado
    private Simbolo.Tipo tipo; // Tipo: variable, constante o argumento
    private Simbolo.TSub tsub; // Tipo subyacente
    // TODO #48 Comprobar que las variables estén inicializadas
    private boolean inicializada; // Si ha sido inicializada
    private String id; // Identificador de la variable (t si es temporal)
    private String valor;

    public Variable(Variable v) {
        this.valor = v.valor;
        this.nv = v.nv;
        this.proc = v.proc;
        this.tipo = v.tipo;
        this.temporal = v.temporal;
    }

    public Variable(int nv, boolean temporal, int proc, Simbolo.Tipo tipo, Simbolo.TSub tsub) {
        this.nv = nv;
        this.temporal = temporal;
        this.proc = proc;
        this.tipo = tipo;
        this.tsub = tsub;
        if (temporal) {
            id="t";
        }
    }

    public String getValor() {
        return valor;
    }

    public void setValor(String valor) {
        this.valor = valor;
    }

    public Simbolo.TSub getTsub() {
        return tsub;
    }

    public boolean isInicializada() {
        return inicializada;
    }

    public void setInicializada(boolean inicializada) {
        this.inicializada = inicializada;
    }

    public boolean isTemporal() {
        return temporal;
    }

    public void setTemporal(boolean temporal) {
        this.temporal = temporal;
    }

    public int getNv() {
        return nv;
    }

    public void setNv(int nv) {
        this.nv = nv;
    }

    public Simbolo.Tipo tipo() {
        return tipo;
    }

    public int proc() {
        return proc;
    }

    @Override
    public String toString() {
        return id+"$"+nv;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }
}
