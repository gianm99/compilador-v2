package procesador;

import java.util.ArrayList;

/**
 * TablaVariable. Clase que sirve para almacenar las variables que aparecen en
 * el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaVariables {

    private ArrayList<Variable> tv;
    private int nv;

    public TablaVariables(String directorio) {
        tv = new ArrayList<Variable>();
        nv = 0;
    }

    public int nuevaVar(boolean temporal, Integer proc, Simbolo.Tipo tipo, Simbolo.TSub tsub) {
        Variable var;
        nv++;
        if (proc==null) {
            var = new Variable(nv, temporal, 0, tipo, tsub);            
        } else {
            var = new Variable(nv, temporal, proc, tipo, tsub);            
        }
        tv.add(var);
        return nv;
    }

    public void quitarVar(String var) {
        String segmentos[] = var.split("\\$");
        tv.remove(Integer.parseInt(segmentos[1]));
    }

    public Variable get(int nv) {
        return tv.get(nv-1);
    }

    public Variable get(String var) {
        String segmentos[] = var.split("\\$");
        if (segmentos.length > 1) {
            return tv.get(Integer.parseInt(segmentos[1]));
        } else {
            return null;
        }
    }
}