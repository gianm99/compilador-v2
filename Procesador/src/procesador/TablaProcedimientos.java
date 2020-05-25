package procesador;

import java.util.ArrayList;

/**
 * TablaProcedimientos. Clase que sirve para almacenar los procedimientos que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaProcedimientos {
    private ArrayList<Procedimiento> TP;

    public ArrayList<Procedimiento> getTP() {
        return TP;
    }

    public void setTP(ArrayList<Procedimiento> tP) {
        this.TP = tP;
    }

    public TablaProcedimientos() {
    }
}