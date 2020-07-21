package procesador;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
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
    private static Writer buffer;

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
        tv.get(Integer.parseInt(segmentos[1]) - 1).setBorrada(true);
    }

    public void quitarVar(ArrayList<Instruccion> var) {
        int i = 0;
        while (i < var.size()) {
            if (get(var.get(i).destino()).tsub() != Simbolo.TSub.STRING) {
                quitarVar(var.get(i).destino());
                var.remove(i);
            } else {
                i++;
            }
        }
    }

    public Variable get(int nv) {
        return tv.get(nv - 1);
    }

    public Variable get(String var) {
        String segmentos[] = var.split("\\$");
        if (segmentos.length > 1) {
            return tv.get(Integer.parseInt(segmentos[1]) - 1);
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
                if (vx.getNparam() == 0) {
                    int ocupx = vx.getOcup() * vx.getElementos(); // Por las tablas
                    Procedimiento pp = tp.get(p);
                    pp.setOcupVL(pp.getOcupVL() + ocupx);
                    vx.setDesp(-pp.getOcupVL());
                } else {
                    vx.setDesp(8 + 4 * vx.getNparam());
                }
            }
        }
    }

    public int getNv() {
        return nv;
    }

    public void setNv(int nv) {
        this.nv = nv;
    }

    public void tablaHTML(String directorio) {
        try {
            File tsFile = new File(directorio);
            buffer = new BufferedWriter(new FileWriter(tsFile));
            String tabla = "<!DOCTYPE html><html><head><head><style>table, th, td {  border: 1px solid\n"
                    + " black;  border-collapse: collapse;}th, td {  padding: 5px;  text-align:\n"
                    + " center;}</style></head><body><table style=\"width:100%; \n"
                    + "background-color:#727272; font-family:'Courier New'\"><tr \n"
                    + "style=\"color:white\"><th>tsub</th><th>nombre</th><th>temporal</th>\n"
                    + " <th>proc</th><th>tipo</th><th>valor</th><th>elementos</th><th>ocup</th>\n"
                    + "<th>desp</th><th>nparam</th></tr>";
            Variable var;
            String valor, proc, nparam, desp, elementos;
            for (int i = 0; i < tv.size(); i++) {
                var = tv.get(i);
                tabla += "<tr style=\"background-color:";
                switch (var.tsub()) {
                // TODO Hacer algo para cuando son arrays
                case STRING:
                    tabla += "#D1BCFF\">";
                    break;
                case INT:
                    tabla += "#FFD1BC\">";
                    break;
                case BOOLEAN:
                    tabla += "#BCFFD1\">";
                    break;
                case NULL:
                    tabla += "#D6A384\">";
                    break;
                }
                if (var.getValor() != null) {
                    valor = var.getValor();
                } else {
                    valor = "-";
                }
                if (var.proc() != 0) {
                    proc = String.valueOf(var.proc());
                } else {
                    proc = "-";
                }
                if (var.getNparam() != 0) {
                    nparam = String.valueOf(var.getNparam());
                } else {
                    nparam = "-";
                }
                if (var.getDesp() != 0) {
                    desp = String.valueOf(var.getDesp());
                } else {
                    desp = "-";
                }
                if (var.getElementos() != 1) {
                    elementos = String.valueOf(var.getElementos());
                } else {
                    elementos = "-";
                }
                if (!var.isBorrada())
                    tabla += "<td>" + var.tsub() + "</td><td>" + var.toString() + "</td><td>"
                            + var.temporal() + "</td><td>" + proc + "</td><td>" + var.tipo()
                            + "</td><td>" + valor + "</td><td>" + elementos + "</td><td>"
                            + var.getOcup() + "</td><td>" + desp + "</td><td>" + nparam
                            + "</td></tr>";
            }
            tabla += "</table></body></html>";
            buffer.write(tabla);
            buffer.close();
        } catch (IOException e) {
            System.out.println("Error escribiendo la tabla de variables: " + e.getMessage());
        }
    }
}
