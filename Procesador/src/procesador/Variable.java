package procesador;

/**
 * Variable. Clase que sirve para gestionar las variables que aparecen en 
 * el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class Variable {

    private String nv;
    private String idsubprograma;
    private Tipo tipo;

    public enum Tipo{
        VAR, CONST, ARG
    }

}