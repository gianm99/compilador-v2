package procesador;

import java.util.ArrayList;

/**
 * TablaProcedimientos. Clase que sirve para almacenar los procedimientos que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaProcedimientos {
    private ArrayList<Procedimiento> tp;

    public ArrayList<Procedimiento> getTP() {
        return tp;
    }

    public void setTP(ArrayList<Procedimiento> tP) {
        this.tp = tP;
    }

    public TablaProcedimientos() {
    }
    
    public Procedimiento nuevoProc(int nivelDecl, Simbolo.Tipo tipo){
        Procedimiento met=new Procedimiento(nivelDecl,tipo);
        tp.add(met);
        return met;
    }
}