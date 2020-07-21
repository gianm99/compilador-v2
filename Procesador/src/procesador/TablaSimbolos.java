package procesador;

import java.util.ArrayList;
import java.util.Hashtable;
import java.io.*;

/**
 * TablaSimbolos. Clase que sirve para gestionar los símbolos que aparecen en el
 * código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class TablaSimbolos {

    private Hashtable<String, Simbolo> tabla;
    private int niveltabla;
    private int ultimoBloque;
    private TablaSimbolos pre;
    private static Writer buffer;
    private ArrayList<TablaSimbolos> tablasBloques;

    public class TablaSimbolosException extends Exception {

        private static final long serialVersionUID = 7706912154843705180L;

        public TablaSimbolosException(String msg) {
            super(msg);
        }
    }

    public TablaSimbolos(String directorio) {
        niveltabla = 0;
        tabla = new Hashtable<>();
        tablasBloques = new ArrayList<TablaSimbolos>();
        pre = null;
        try {
            // TS output
            File tsFile = new File(directorio + "/tablasimbolos.html");
            buffer = new BufferedWriter(new FileWriter(tsFile));
            buffer.write(
                    "<!DOCTYPE html><html><head><head><style>table, th, td {  border: 1px solid\n"
                            + " black;  border-collapse: collapse;}th, td {padding: 5px;text-align:\n"
                            + " center;}</style>" + "</head>" + "<body style >"
                            + "<table style=\"width:100%; \n"
                            + "background-color:#DDDDDD; font-family:'Courier New'\">" + "<tr>"
                            + "<th>Nivel " + niveltabla + "</th>" + "<td>"
                            + "<table style=\"width:100%; \n"
                            + "background-color:#DDDDDD; font-family:'Courier New'\">" + "<tr>"
                            + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>"
                            + "<th>Next</th>" + "</tr>" + "<tr>\n");
        } catch (IOException e) {
            System.out.println("error escribiendo la tabla de símbolos: " + e.getMessage());
        }
    }

    private TablaSimbolos(TablaSimbolos p, int n) {
        niveltabla = n;
        tabla = new Hashtable<>();
        tablasBloques = new ArrayList<>();
        pre = p;
    }

    public TablaSimbolos entraBloque() {
        try {
            // TS entre bloque output
            buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "<tr>" + "<th>Nivel "
                    + (niveltabla + 1) + "</th>" + "<td>" + "<table style=\"width:100%; \n"
                    + "background-color:#DDDDDD; font-family:'Courier New'\">" + "<tr>"
                    + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>" + "<th>Next</th>"
                    + "</tr>" + "<tr>\n");
        } catch (IOException e) {
            System.out.println("error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        TablaSimbolos tabla = new TablaSimbolos(this, niveltabla + 1);
        this.tablasBloques.add(tabla);
        return tabla;
    }

    public TablaSimbolos bajaBloque() throws TablaSimbolosException {
        if (ultimoBloque > this.tablasBloques.size()) {
            throw new TablaSimbolosException(
                    "posicion incorrecta de la lista de las tablas de bloques inferiores");
        }
        return tablasBloques.get(ultimoBloque);
    }

    public TablaSimbolos saleBloque() {
        niveltabla--;
        try {
            if (niveltabla == -1) {
                // TS acaba de escribir
                buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "</table>" + "</body>"
                        + "</html>\n");
                buffer.close();
            } else {
                // TS reduce un nivel en el bloque
                buffer.write("</tr>" + "</table>" + "</td>" + "</tr>" + "<tr>" + "<th>Nivel "
                        + niveltabla + "</th>" + "<td>" + "<table style=\"width:100%; \n"
                        + "background-color:#DDDDDD; font-family:'Courier New'\">" + "<tr>"
                        + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>"
                        + "<th>Next</th>" + "</tr>" + "<tr>\n");
            }
        } catch (IOException e) {
            System.out.println("error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        return pre;
    }

    public TablaSimbolos subeBloque() {
        return pre;
    }

    public void inserta(String id, Simbolo s) throws TablaSimbolosException {
        if (this.existe(id)) {
            throw new TablaSimbolosException("identificador repetido: " + id);
        }
        tabla.put(id, s);
        try {
            // TS poner elemento
            buffer.write("<td>" + s.getId() + "</td>" + "<td>" + s.getT() + "</td>" + "<td>"
                    + s.tsub() + "</td>\n");
            if (s.getNext() != null) {
                Simbolo sn = s.getNext();
                buffer.write("<td>" + "<table style=\"width:100%; \n"
                        + "background-color:#DDDDDD; font-family:'Courier New'\">" + "<tr>"
                        + "<th>Id</th>" + "<th>Tipo</th>" + "<th>Tipo Subyacente</th>" + "</tr>"
                        + "<tr>\n");
                while (sn != null) {
                    buffer.write("<td>" + sn.getId() + "</td>" + "<td>" + sn.getT() + "</td>"
                            + "<td>" + sn.tsub() + "</td></tr>\n");
                    sn = sn.getNext();
                }
                buffer.write("</table>" + "</td>\n");
            } else {
                buffer.write("<td>" + "null" + "</td>\n");
            }
            buffer.write("</tr>" + "<tr>\n");
        } catch (IOException e) {
            System.out.println("error escribiendo la tabla de símbolos: " + e.getMessage());
        }

    }

    private boolean existe(String id) {
        return this.tabla.get(id) != null;
    }

    public Simbolo consulta(String id) throws TablaSimbolosException {
        for (TablaSimbolos ts = this; ts != null; ts = ts.pre) {
            if (ts.tabla.get(id) != null) {
                return ts.tabla.get(id);
            }
        }
        throw new TablaSimbolosException(
                "no se ha encontrado el símbolo " + id + " en la tabla de símbolos");
    }
}
