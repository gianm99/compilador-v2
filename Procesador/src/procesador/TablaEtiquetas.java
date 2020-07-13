package procesador;

import java.util.ArrayList;

public class TablaEtiquetas {
    
    private ArrayList<Etiqueta> te;

    public TablaEtiquetas() {
        this.te = new ArrayList<Etiqueta>();
    }

    public void nuevaEtiqueta(Etiqueta e, int nl){
        e.setNl(nl);
        te.add(e);
    }

    public ArrayList<Etiqueta> getTe() {
        return te;
    }

    public void setTe(ArrayList<Etiqueta> te) {
        this.te = te;
    }

    public Etiqueta get(String etiqueta) {
        if (etiqueta != null) {
            return te.get(Integer.parseInt(etiqueta) - 1);
        } else {
            return null;
        }
    }

}