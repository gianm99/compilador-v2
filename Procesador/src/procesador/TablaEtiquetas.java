package procesador;

import java.util.ArrayList;

public class TablaEtiquetas {
    private int ne; // Número de etiquetas
    private ArrayList<Etiqueta> te; // Tabla de etiquetas

    public TablaEtiquetas() {
        this.ne = 0; // Al principio hay 0
        this.te = new ArrayList<Etiqueta>();
    }

    public int nuevaEtiqueta() {
        ne++; // Aumenta el número de etiquetas
        te.add(new Etiqueta(ne));
        return ne;
    }

    public Etiqueta get(int etiqueta) {
        return te.get(etiqueta-1);
    }

    public Etiqueta get(String etiqueta) {
        if (etiqueta != null) {
            return get(Integer.parseInt(etiqueta.substring(1)));
        } else {
            return null;
        }
    }

}