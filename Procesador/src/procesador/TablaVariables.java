package procesador;

import java.util.Hashtable;
import java.io.*;

public class TablaVariables {

    private int profundidad;
    private Hashtable<String, Variable> tabla;

    
    public void inserta(Variable var){
        tabla.put(var.getNv(), var);
    }

}