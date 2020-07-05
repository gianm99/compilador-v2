package procesador;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

public class Optimizador {

    private String directorio;
    private ArrayList<Instruccion> C3D;
    private TablaVariables tv;

    public Optimizador(String directorio, final ArrayList<Instruccion> C3D, TablaVariables tv) {
        this.directorio = directorio;
        this.C3D = C3D;
        this.tv = tv;
    }

    public ArrayList<Instruccion> getC3D() {
        return C3D;
    }


    public void imprimirC3D_Opt(String directorio) {
        Writer buffer;
        File interFile = new File(directorio + "/intermedioOptimo.txt");
        try {
            buffer = new BufferedWriter(new FileWriter(interFile));
            for (int i = 0; i < C3D.size(); i++) {
                buffer.write(C3D.get(i).toString() + "\n");
            }
            buffer.close();
        } catch (IOException e) {
        }
    }

    public void eliminaCodigoInaccesible() {
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (esIf(ins)) {
                if (operandosConstantes(ins, i)) {
                    i += ejecutaIf(ins, i);
                }
            }
        }
    }

    public void eliminaEtiquetasInecesarias() {
        ArrayList<String> skips = new ArrayList<String>();
        ArrayList<String> gotos = new ArrayList<String>();
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (ins.getOpCode() == Instruccion.OP.skip) {
                skips.add(ins.destino());
            } else if (ins.getOpCode() == Instruccion.OP.jump || esIf(ins)) {
                gotos.add(ins.destino());
            }
        }
        skips.removeAll(gotos);
        Instruccion aux;
        int i = 0;
        boolean borrado;
        while (i < C3D.size()) {
            aux = C3D.get(i);
            borrado = false;
            if (aux.getOpCode() == Instruccion.OP.skip) {
                for (int j = 0; j < skips.size(); j++) {
                    if (skips.get(j).equals(aux.destino())) {
                        C3D.remove(i);
                        j = skips.size();
                        borrado = true;
                    }
                }
            }
            if (!borrado)
                i++;
        }
        i = 0;
        borrado = false;
        while (i < C3D.size() - 1) { // TODO Puede haber más gotos en este caso
            if (borrado)
                C3D.remove(i - 1);
            borrado = false;
            if (C3D.get(i).getOpCode() == Instruccion.OP.jump) {
                if (C3D.get(i + 1).getOpCode() == Instruccion.OP.skip
                        && C3D.get(i).destino().equals(C3D.get(i + 1).destino())) {
                    borrado = true;
                    C3D.remove(i);
                }
            }
            i++;
        }
    }

    public void eliminaAsignacionesInecesarias() {
        ArrayList<Instruccion> vars = new ArrayList<Instruccion>();
        int i = 0;
        while (i < C3D.size()) {
            if (C3D.get(i).getOpCode() == Instruccion.OP.copy
                    && C3D.get(i).destino().charAt(0) == 't') {
                if (!vars.contains(C3D.get(i))) {
                    vars.add(C3D.get(i));
                }
            }
            i++;
        }
        int j = 0;
        boolean primerEncuentro;
        for (i = 0; i < vars.size(); i++) {
            primerEncuentro = false;
            while (j < C3D.size()) {
                if (C3D.get(j).getOpCode() == Instruccion.OP.copy) {
                    if (!primerEncuentro) {
                        if (vars.get(i).equals(C3D.get(j))) {
                            primerEncuentro = true;
                        }
                    } else {
                        if (vars.get(i).equals(C3D.get(j))) {
                            vars.remove(i);
                            j = C3D.size();
                        }
                    }
                }
                j++;
            }
        }
        //Seguir aquí
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
        // Recoger valor etiqueta
        int intAux = Integer.parseInt(codigo.get(lineaEtiqueta).getInstruccion()[3].substring(1));
        lista.add(insAux);
        while (!codigoRecogido) {
            lineas++;
            insAux = codigo.get(lineas);
            lista.add(insAux);
            // Comprobar si se ha encontrado el skip con la etiqueta
            if (insAux.getCodigo() == Instruccion.OP.et
                    && intAux == Integer.parseInt(insAux.getInstruccion()[3].substring(1)))
                codigoRecogido = true;
        }

        return lista;
    }

    private void reemplazaCodigo(ArrayList<Instruccion> codigoR, int empieza, int acaba) {
        List<Instruccion> sublistacodigo = this.codigo.subList(empieza, acaba);
        sublistacodigo.clear();
        this.codigo.addAll(empieza, codigoR);
    }

    private boolean esIf(Instruccion ins) {
        return (ins.getCodigo() == Instruccion.OP.ifLT || ins.getCodigo() == Instruccion.OP.ifLE
                || ins.getCodigo() == Instruccion.OP.ifEQ || ins.getCodigo() == Instruccion.OP.ifNE
                || ins.getCodigo() == Instruccion.OP.ifGE
                || ins.getCodigo() == Instruccion.OP.ifGT);
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

    private int ejecutaIf(Instruccion ins, int empieza) {
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
        lista.add(0,
                new Instruccion(Instruccion.OP.jump, "", "", lista.get(0).getInstruccion()[3]));
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
        aux.add(lista.get(lista.size() - 1));
        reemplazaCodigo(aux, empieza, empieza + lista.size());
        lineasReemplazo = aux.size();
        return lineasReemplazo;
    }
}
