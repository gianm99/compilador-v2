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
        if (proc == null) {
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
        return tv.get(nv - 1);
    }

    public Variable get(String var) {
        String segmentos[] = var.split("\\$");
        if (segmentos.length > 1) {
            return tv.get(Integer.parseInt(segmentos[1])-1);
        } else {
            return null;
        }
    }

    /**
     * Calcula el desp de todas las variables y el ocupVL de todos los
     * procedimientos.
     * 
     * @param tp
     *               La tabla de procedimientos que actualiza.
     */
    public void calculoDespOcupVL(TablaProcedimientos tp) {
        for (int p = 1; p <= tp.getNp(); p++) {
            tp.get(p).setOcupVL(0);
        }
        for (int x = 0; x < tv.size(); x++) {
            Variable vx = tv.get(x);
            int p = vx.proc();
            if (vx.tipo() == Simbolo.Tipo.VAR && p != 0) {
                int ocupx = vx.getOcup();
                Procedimiento pp = tp.get(p);
                pp.setOcupVL(pp.getOcupVL() + ocupx);
                vx.setDesp(-pp.getOcupVL()); // TODO Preguntar a Pere Palmer esto
            }
        }
    }

    public int getNv() {
        return nv;
    }

    public void setNv(int nv) {
        this.nv = nv;
    }
}