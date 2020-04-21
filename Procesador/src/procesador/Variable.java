package procesador;

public class Variable {

    private String nv;
    private String idsubprograma;
    private Tipo tipo;

    public enum Tipo{
        VAR, CONST, ARG
    }

    public Variable getNv(){
        return this.nv;
    }
}