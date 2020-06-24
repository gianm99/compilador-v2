package procesador;

import java.util.ArrayList;

/**
 * TablaVariable. Clase que sirve para almacenar las variables que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaVariables {

    private ArrayList<Variable> tv;

    public ArrayList<Variable> getTV() {
        return tv;
    }

    public void setTV(ArrayList<Variable> tv) {
        this.tv = tv;
    }

    public TablaVariables(String directorio){
        
    }

    public Variable nuevaVar(Procedimiento sub, Simbolo.Tipo tipo){
        Variable var = new Variable(sub, tipo);
        tv.add(var);
        return var;
    }
}
