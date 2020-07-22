package procesador;

import java.util.ArrayList;

/**
 * TablaEtiquetas. Clase que sirve para almacenar las etiquetas que se generan
 * al analizar el código.
 * 
 * @author Jordi Antoni Sastre Moll
 */
public class TablaEtiquetas {
    private int ne; // Número de etiquetas
    private ArrayList<Etiqueta> te; // Tabla de etiquetas

    public TablaEtiquetas() {
        this.ne = 0; // Al principio hay 0
        this.te = new ArrayList<Etiqueta>();
    }

    public int nuevaEtiqueta(boolean deproc) {
        ne++; // Aumenta el número de etiquetas
        te.add(new Etiqueta(ne, deproc));
        return ne;
    }

    public Etiqueta get(int etiqueta) {
        return te.get(etiqueta - 1);
    }

    public Etiqueta get(String etiqueta) {
        if (etiqueta == null) {
            return null;
        }
        if (etiqueta.equals("")) {
            return null;
        }
        return te.get(Integer.parseInt(etiqueta.substring(1)) - 1);
    }

}