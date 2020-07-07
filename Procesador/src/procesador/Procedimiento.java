package procesador;

/**
 * Procedmiento. Clase que sirve para gestionar los procedimientos que aparecen
 * en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class Procedimiento {

    private int np; // Número de procedimiento
    private int prof; // Nivel de la declaración
    private Etiqueta inicio; // Etiqueta de inicio
    private int numParams; // Número de parámetros
    private int ocupVL; // Ocupación de las variables locales
    private Simbolo.Tipo tipo; // Función o Procedimiento

    public Procedimiento(int np, int prof, Simbolo.Tipo tipo) {
        this.np = np;
        this.tipo = tipo;
        this.setProf(prof);
        this.numParams = 0;
    }

    public int getProf() {
        return prof;
    }

    public void setProf(int prof) {
        this.prof = prof;
    }

    public int getNp() {
        return np;
    }

    public void setNp(int np) {
        this.np = np;
    }

    public Etiqueta getInicio() {
        return inicio;
    }

    public void setInicio(Etiqueta inicio) {
        this.inicio = inicio;
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

    public int getNumParams() {
        return numParams;
    }

    public void setNumParams(int numParams) {
        this.numParams = numParams;
    }

    public int getOcupVL() {
        return ocupVL;
    }

    public void setOcupVL(int ocupVL) {
        this.ocupVL = ocupVL;
    }
}
