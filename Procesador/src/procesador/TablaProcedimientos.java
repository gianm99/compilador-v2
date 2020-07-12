package procesador;

import java.util.ArrayList;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;

/**
 * TablaProcedimientos. Clase que sirve para almacenar los procedimientos que aparecen en el código.
 * 
 * @author Gian Lucas Martín Chamorro
 */
public class TablaProcedimientos {
    private ArrayList<Procedimiento> tp;
    private int np;
    private static Writer buffer;

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

    public void tablaHTML(String directorio) {
        try {
            File tsFile = new File(directorio);
            buffer = new BufferedWriter(new FileWriter(tsFile));
            String tabla =
                    "<!DOCTYPE html><html><head><head><style>table, th, td {  border: 1px solid black;  border-collapse: collapse;}th, td {  padding: 5px;  text-align: center;}</style></head><body><table style=\"width:100%; background-color:#727272; font-family:'Courier New'\"><tr style=\"color:white\"><th>tipo</th><th>nombre</th><th>prof</th><th>inicio</th><th>numParams</th><th>ocupVL</th></tr>";
            Procedimiento proc;
            String inicio, numParams;
            for (int i = 0; i < tp.size(); i++) {
                proc = tp.get(i);
                tabla += "<tr style=\"background-color:";
                switch (proc.getTipo()) {
                    case FUNC:
                        tabla += "#D1BCFF\">";
                        break;
                    case PROC:
                        tabla += "#FFD1BC\">";
                        break;
                }
                if(proc.getInicio() != null){
                    inicio = proc.getInicio().toString();
                } else {
                    inicio = "-";
                }
                if(proc.getNumParams() != 0){
                    numParams = String.valueOf(proc.getNumParams());
                } else {
                    numParams = "-";
                }
                tabla += "<td>" + proc.getTipo() + "</td><td>" + proc.toString() + "</td><td>"
                        + proc.getProf() + "</td><td>" + inicio + "</td><td>"
                        + numParams + "</td><td>" + proc.getOcupVL() + "</td></tr>";
            }
            tabla += "</table></body></html>";
            buffer.write(tabla);
            buffer.close();
        } catch (

        IOException e) {
            System.out.println("Error escribiendo la tabla de procedimientos: " + e.getMessage());
        }
    }
}
