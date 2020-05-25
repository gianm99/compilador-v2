package procesador;

import java.util.Hashtable;
import java.io.*;

/**
 * TablaSimbolos. Clase que sirve para gestionar los símbolos que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class TablaSimbolos {

    private Hashtable<String, Simbolo> tabla;
    private int niveltabla;
    private TablaSimbolos pre;
    private static Writer buffer;

    public class exceptionTablaSimbolos extends Exception {

        private static final long serialVersionUID = 7706912154843705180L;

        public exceptionTablaSimbolos(String msg) {
            super(msg);
        }
    }

    public TablaSimbolos(String directorio) {
        niveltabla = 0;
        tabla = new Hashtable<>();
        pre = null;
        try {
            // TS output
            File tsFile = new File(directorio + "\\tablasimbolos.html");
            buffer = new BufferedWriter(new FileWriter(tsFile));
            buffer.write("<!DOCTYPE html>" + "<html>" + "<head>" + "<style>"
                    + "table, th, td {border: 1px solid black;background-color: aqua;}" + "</style>"
                    + "</head>" + "<body>" + "<table style='width:100%'>" + "<tr>" + "<th>Nivel "
                    + niveltabla + "</th>" + "<td>" + "<table style='width:100%'>" + "<tr>"
                    + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>" + "<th>Next</th>"
                    + "</tr>" + "<tr>");
        } catch (IOException e) {
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
    }

    private TablaSimbolos(TablaSimbolos p, int n) {
        niveltabla = n;
        tabla = new Hashtable<>();
        pre = p;
    }

    public TablaSimbolos entraBloque() {
        try {
            // TS entre bloque output
            buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "<tr>" + "<th>Nivel "
                    + (niveltabla + 1) + "</th>" + "<td>" + "<table>" + "<tr>" + "<th>Id</th>"
                    + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>" + "<th>Next</th>" + "</tr>"
                    + "<tr>");
        } catch (IOException e) {
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        return new TablaSimbolos(this, niveltabla + 1);
    }

    public TablaSimbolos saleBloque() {
        niveltabla--;
        try {
            if (niveltabla == -1) {
                // TS acaba de escribir
                buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "</table>" + "</body>"
                        + "</html>");
                buffer.close();
            } else {
                // TS reduce un nivel en el bloque
                buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "<tr>" + "<th>Nivel "
                        + niveltabla + "</th>" + "<td>" + "<table style='width:100%'>" + "<tr>"
                        + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>"
                        + "<th>Next</th>" + "</tr>" + "<tr>");
            }
        } catch (IOException e) {
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        return pre;
    }

    public void inserta(String id, Simbolo s) throws exceptionTablaSimbolos {
        if (this.existe(id)) {
            throw new exceptionTablaSimbolos("Identificador repetido: " + id);
        }
        tabla.put(id, s);
        try {
            // TS poner elemento
            buffer.write("<td>" + s.getId() + "</td>" + "<td>" + s.getT() + "</td>" + "<td>"
                    + s.getTs() + "</td>");
            if (s.getNext() != null) {
                Simbolo sn = s.getNext();
                buffer.write("<td>" + "<table style='width:100%'>" + "<tr>" + "<th>Id</th>"
                        + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>" + "</tr>" + "<tr>");
                while (sn != null) {
                    buffer.write("<td>" + sn.getId() + "</td>" + "<td>" + sn.getT() + "</td>"
                            + "<td>" + sn.getTs() + "</td></tr>");
                    sn = sn.getNext();
                }
                buffer.write("</table>" + "</td>");
            } else {
                buffer.write("<td>" + "null" + "</td>");
            }
            buffer.write("</tr>" + "<tr>");
        } catch (IOException e) {
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }

    }

    private boolean existe(String id) {
        return this.tabla.get(id) != null;
    }

    public Simbolo consulta(String id) throws exceptionTablaSimbolos {
        for (TablaSimbolos ts = this; ts != null; ts = ts.pre) {
            if (ts.tabla.get(id) != null) {
                return ts.tabla.get(id);
            }
        }
        throw new exceptionTablaSimbolos(
                "No se ha encontrado el símbolo " + id + " en la tabla de símbolos");
    }
}
