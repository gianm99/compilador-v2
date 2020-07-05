package procesador;

import java.util.ArrayList;

/**
 * TablaProcedimientos. Clase que sirve para almacenar los procedimientos que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaProcedimientos {
    private ArrayList<Procedimiento> tp;

    public TablaProcedimientos() {
        tp = new ArrayList<Procedimiento>();
    }

    public Procedimiento nuevoProc(int prof, Simbolo.Tipo tipo){
        Procedimiento met=new Procedimiento(prof,tipo);
        tp.add(met);
        return met;
    }

    // Getters y setters
    public ArrayList<Procedimiento> getTP() {
        return tp;
    }

    public void setTP(ArrayList<Procedimiento> tP) {
        this.tp = tP;
    }
}