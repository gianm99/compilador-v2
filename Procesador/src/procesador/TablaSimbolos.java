package procesador;

import java.util.Hashtable;
import java.io.*;

public class TablaSimbolos {

    private Hashtable<String, Simbolo> tabla;
    private int niveltabla;
    private TablaSimbolos ant;
    private static Writer writer;

    public class exceptionTablaSimbolos extends Exception{
        public exceptionTablaSimbolos (String msg){
            super(msg);
        }
    }

    public TablaSimbolos(String directorio) {
        niveltabla = 0;
        tabla = new Hashtable<String, Simbolo>();
        ant = null;
        try{
            //TS output
            File tsFile = new File(directorio+"\\tablasimbolos.html");
            writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(tsFile), "utf-8"));
			writer.write("<!DOCTYPE html>\n<html>\n<head><style>\ntable, th, td {\nborder: 1px solid black;\nbackground-color: aqua;\n}</style>"+
			"</head>\n<body>\n<table style=\"width:100%\">");
			writer.write("\n<tr>\n<th>Nivel "+niveltabla+"</th>\n<td><table style=\"width:100%\">"+
			"\n<tr>\n<th>Id</th>\n<th>Tipo</th>\n<th>Tipo Subyacente</th>\n<th>Next</th>\n</tr>\n<tr>");
		} catch(Exception e){
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
    }

    private TablaSimbolos(TablaSimbolos p, int n){
        niveltabla = n;
        tabla  = new Hashtable<String, Simbolo>();
        ant = p;
    }

    public TablaSimbolos entraBloque(){
        try{
            //TS entre bloque output
			writer.write("\n</tr>\n</table>\n</td>\n</tr>\n<tr>\n<th>Nivel "+(niveltabla+1)+"</th>\n<td><table>"+
			"\n<tr>\n<th>Id</th>\n<th>Tipo</th>\n<th>Tipo Subyacente</th>\n<th>Next</th>\n</tr>\n<tr>");
        }catch (Exception e){
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        return new TablaSimbolos(this, niveltabla+1);
    }

    public TablaSimbolos saleBloque(){
        niveltabla--;
        try{
            if(niveltabla==-1){
				//TS acaba de escribir
				writer.write("\n</tr>\n</table>\n</td>\n</tr>\n</table>\n</body>\n</html>");
                writer.close();
            }else{
				//TS reduce un nivel en el bloque
				writer.write("\n</tr>\n</table>\n</td>\n</tr>\n<tr>\n<th>Nivel "+niveltabla+"</th>\n<td><table style=\"width:100%\">"+
				"\n<tr>\n<th>Id</th>\n<th>Tipo</th>\n<th>Tipo Subyacente</th>\n<th>Next</th>\n</tr>\n<tr>");
            }
        }catch (Exception e){
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }
        return ant;
    }

    public void inserta(String id,  Simbolo s) throws exceptionTablaSimbolos{
        if (this.existe(id)){
            throw new exceptionTablaSimbolos("Identificador repetido: " + id);
        }
        tabla.put(id, s);
        try{
			//TS poner elemento
            writer.write("\n<td>"+s.getId()+"</td>"
                +"\n<td>"+s.getT()+"</td>"
                +"\n<td>"+s.getTs()+"</td>");
            if(s.getNext()!=null){
                Simbolo sn = s.getNext();
                writer.write("\n<td><table style=\"width:100%\">"
                    +"\n<tr>\n<th>Id</th>\n<th>Tipo</th>\n<th>Tipo Subyacente</th>\n</tr>\n<tr>");
                while(sn!=null){
                    writer.write("\n<td>"+sn.getId()+"</td>"
                        +"\n<td>"+sn.getT()+"</td>"
                        +"\n<td>"+sn.getTs()+"</td>\n</tr>");
                    sn = sn.getNext();
                }
                writer.write("\n</table>\n</td>");
            }else{
                writer.write("\n<td>"+"null"+"</td>");
            } 
            writer.write("</tr>\n<tr>");  
        }catch (Exception e){
            System.out.println("Error escribiendo la tabla de símbolos: " + e.getMessage());
        }

    }

    private boolean existe(String id){
        return this.tabla.get(id) != null;
    }

    public Simbolo consulta(String id) throws exceptionTablaSimbolos{
        for (TablaSimbolos ts = this; ts != null; ts = ts.ant) {
            if(ts.tabla.get(id) != null){
                return ts.tabla.get(id);
            }
        }
        throw new exceptionTablaSimbolos("No se ha encontrado el símbolo "+ id + " en la tabla de símbolos");
    }
}