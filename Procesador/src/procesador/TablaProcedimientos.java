package procesador;

import java.util.ArrayList;

/**
 * TablaProcedimientos. Clase que sirve para almacenar los procedimientos que
 * aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaProcedimientos {
    private ArrayList<Procedimiento> tp;
    private int np;

    public TablaProcedimientos() {
        tp = new ArrayList<Procedimiento>();
        np = 0;
    }

    public Procedimiento nuevoProc(int prof, Simbolo.Tipo tipo, String id) {
        np++;
        tp.add(new Procedimiento(np, prof, tipo, id));
        return tp.get(tp.size() - 1);
    }

    public Procedimiento get(int np) {
        return tp.get(np - 1);
    }

    public Procedimiento get(String proc) {
        String segmentos[] = proc.split("\\$");
        return tp.get(Integer.parseInt(segmentos[1]) - 1);
    }

    // Getters y setters
    public ArrayList<Procedimiento> getTP() {
        return tp;
    }

    public void setTP(ArrayList<Procedimiento> tP) {
        this.tp = tP;
    }

    public int getNp() {
        return np;
    }

    public void setNp(int np) {
        this.np = np;
    }
}