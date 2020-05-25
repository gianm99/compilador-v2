package procesador;

import java.util.ArrayList;

/**
 * TablaVariable. Clase que sirve para almacenar las variables que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaVariables {

    private ArrayList<Variable> TV;

    public ArrayList<Variable> getTV() {
        return TV;
    }

    public void setTV(ArrayList<Variable> tV) {
        this.TV = tV;
    }

    public TablaVariables(){
        
    }
}
