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
    private Simbolo.Tipo tipo; // Tipo: variable o constante
    private Simbolo.TSub tsub; // Tipo subyacente
    private String id; // Identificador de la variable (t si es temporal)
    private String valor; // Valor para constantes
    private int ocup; // Ocupación de la variable
    private int desp; // Desplazamiento en el ámbito local
    private int nparam; // Número de parámetro
    private boolean borrada; // Si la variable ha sido borrada
    private int elementos; // Es 1 a menos que sea una tabla. Para tablas puede ser mayor.

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
        this.desp = 0;
        this.elementos = 1; // Por defecto es 1
    }

    public int getElementos() {
        return elementos;
    }

    public void setElementos(int elementos) {
        this.elementos = elementos;
    }

    public boolean isBorrada() {
        return borrada;
    }

    public void setBorrada(boolean borrada) {
        this.borrada = borrada;
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

    public Simbolo.TSub tsub() {
        return tsub;
    }

    public boolean temporal() {
        return temporal;
    }

    public int nv() {
        return nv;
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
