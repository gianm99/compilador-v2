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
    private String id; // Identificador de la variable (t si es temporal)
    private String valor; // Valor para constantes
    private int ocup; // Ocupación de la variable
    private int desp; // Desplazamiento en el ámbito local
    private int nparam; // Número de parámetro
    private boolean resultado; // Si la variable es resultado de una función
    private boolean borrada; // Si la variable ha sido borrada

    public Variable(int nv, boolean temporal, int proc, Simbolo.Tipo tipo, Simbolo.TSub tsub) {
        this.nv = nv;
        this.temporal = temporal;
        this.proc = proc;
        this.tipo = tipo;
        this.tsub = tsub;
        if (temporal) {
            id = "t";
        }
        this.ocup = 4; // 32 bits
        this.borrada = false;
    }

    public boolean isBorrada() {
        return borrada;
    }

    public void setBorrada(boolean borrada) {
        this.borrada = borrada;
    }

    public boolean isResultado() {
        return resultado;
    }

    public void setResultado(boolean resultado) {
        this.resultado = resultado;
    }

    public int getNparam() {
        return nparam;
    }

    public void setNparam(int nparam) {
        this.nparam = nparam;
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
        return id + "$" + nv;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public int getOcup() {
        return ocup;
    }

    public void setOcup(int ocup) {
        this.ocup = ocup;
    }

    public int getDesp() {
        return desp;
    }

    public void setDesp(int desp) {
        this.desp = desp;
    }
}
