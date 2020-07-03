package procesador;

import java.util.ArrayList;
import java.util.List;

public class Optimizador {

    private ArrayList<Instruccion> codigo;
    private TablaVariables tv;

    public Optimizador(final ArrayList<Instruccion> codigo, TablaVariables tv) {
        this.codigo = codigo;
        this.tv = tv;
    }

    public ArrayList<Instruccion> getCodigo() {
        return codigo;
    }

    public void optimizarCodigo(){
        eliminaCodigoInaccesible();
    }


    public void eliminaCodigoInaccesible() {
        for (int i = 0; i < codigo.size(); i++) {
            Instruccion ins = codigo.get(i);
            if (esIf(ins)) {
                if (esValorConstante(ins, i)) {
                    i += detectaTipoOpRelIf(ins, i);
                }
            }
        }
    }

    /*
     * 
     * 
     * 
     * 
     * Código para optimizaciones
     * 
     * 
     * 
     * 
     */

    private ArrayList<Instruccion> recogerCodigo(int empieza, int lineaEtiqueta) {
        boolean codigoRecogido = false;
        int lineas = empieza;
        ArrayList<Instruccion> lista = new ArrayList<Instruccion>();
        Instruccion insAux = codigo.get(lineas);
        //Recoger valor etiqueta
        int intAux = Integer.parseInt(codigo.get(lineaEtiqueta).getInstruccion()[3].substring(1));
        lista.add(insAux);
        while (!codigoRecogido) {
            lineas++;
            insAux = codigo.get(lineas);
            lista.add(insAux);
            //Comprobar si se ha encontrado el skip con la etiqueta
            if (insAux.getCodigo() == Instruccion.OP.et && intAux == Integer.parseInt(insAux.getInstruccion()[3].substring(1)))
                codigoRecogido = true;
        }

        return lista;
    }

    private void reemplazaCodigo(ArrayList<Instruccion> codigoR, int empieza, int acaba) {
        List<Instruccion> sublistacodigo = this.codigo.subList(empieza, acaba);
        sublistacodigo.clear();
        this.codigo.addAll(empieza, codigoR);
    }

    private boolean esIf(Instruccion ins){
        return (ins.getCodigo() == Instruccion.OP.ifLT || ins.getCodigo() == Instruccion.OP.ifLE || ins.getCodigo() == Instruccion.OP.ifEQ || ins.getCodigo() == Instruccion.OP.ifNE || ins.getCodigo() == Instruccion.OP.ifGE || ins.getCodigo() == Instruccion.OP.ifGT);
     }

    private Boolean esValorConstante(Instruccion ins, int linea) {
        boolean esConst1 = false, esConst2 = false;
        boolean b = false;

        if (ins.getInstruccion()[1].charAt(0) == 'v') {
            if (tv.getTV().get(Integer.parseInt(ins.getInstruccion()[1].substring(1)))
                    .getTipo() == Simbolo.Tipo.CONST) {
                esConst1 = true;
            }
        } else {
            esConst1 = true;
        }

        if (ins.getInstruccion()[2].charAt(0) == 'v') {
            if (tv.getTV().get(Integer.parseInt(ins.getInstruccion()[2].substring(1)))
                    .getTipo() == Simbolo.Tipo.CONST) {
                esConst2 = true;
            }
        } else {
            esConst2 = true;
        }

        if (esConst1 && esConst2)
            b = true;

        return b;
    }

    private int detectaTipoOpRelIf(Instruccion ins, int empieza) {  //Mirar para valores literales
        int lineasReemplazo = 0;
        int parseInt1 = Integer.parseInt(ins.getInstruccion()[1].substring(1)) - 1;
        int parseInt2 = Integer.parseInt(ins.getInstruccion()[2].substring(1)) - 1;
        int c1 = tv.getTV().get(parseInt1).getR();
        int c2 = tv.getTV().get(parseInt2).getR();
        switch (ins.getCodigo()) {
            case ifLT:
                if (c1 < c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            case ifLE:
                if (c1 <= c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            case ifEQ:
                if (c1 == c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            case ifNE:
                if (c1 != c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);;
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            case ifGE:
                if (c1 >= c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            case ifGT:
                if (c1 > c2) {
                    lineasReemplazo = optimizarIfCierto(empieza);
                } else {
                    lineasReemplazo = optimizarIfFalso(empieza);
                }
                break;
            default:
                break;
        }
        return lineasReemplazo;
    }


    private int optimizarIfCierto(int empieza) {
        int lineasReemplazo = 0;
        ArrayList<Instruccion> lista = recogerCodigo(empieza, empieza + 1);
        lista.add(0, new Instruccion(Instruccion.OP.jump, "", "", lista.get(0).getInstruccion()[3]));
        lista.remove(1);
        lista.remove(1);
        reemplazaCodigo(lista, empieza, empieza + lista.size() + 1);
        lineasReemplazo = lista.size();
        return lineasReemplazo;
    }

    private int optimizarIfFalso(int empieza) {
        int lineasReemplazo = 0;
        ArrayList<Instruccion> lista = recogerCodigo(empieza, empieza + 1);
        ArrayList<Instruccion> aux = new ArrayList<Instruccion>();
        aux.add(lista.get(1));
        aux.add(lista.get(lista.size()-1));
        reemplazaCodigo(aux, empieza, empieza + lista.size());
        lineasReemplazo = aux.size();
        return lineasReemplazo;
    }
}
