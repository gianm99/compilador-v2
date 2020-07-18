package procesador;

import java.util.ArrayList;

public class TablaEtiquetas {
    
    private ArrayList<Etiqueta> te;

    public TablaEtiquetas() {
        this.te = new ArrayList<Etiqueta>();
    }

    public void nuevaEtiqueta(Etiqueta e, int nl, boolean deproc){
        e.setNl(nl);
        e.setDeproc(deproc);
        te.add(e);
    }

    public ArrayList<Etiqueta> getTe() {
        return te;
    }

    public void setTe(ArrayList<Etiqueta> te) {
        this.te = te;
    }

    public Etiqueta get(String etiqueta) {
        if (etiqueta == null) {
            return null;
        } 
        if(etiqueta.equals("")){
            return null;
        }
        return te.get(Integer.parseInt(etiqueta.substring(1)) - 1);
    }

}