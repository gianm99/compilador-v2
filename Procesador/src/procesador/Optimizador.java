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
    private TablaProcedimientos tp;

    public Optimizador(String directorio, final ArrayList<Instruccion> C3D, TablaVariables tv,
            TablaProcedimientos tp) {
        this.directorio = directorio;
        this.C3D = C3D;
        this.tv = tv;
        this.tp = tp;
    }

    public ArrayList<Instruccion> getC3D() {
        return C3D;
    }

    public void optimizar() {
        eliminaCodigoInaccesible();
        eliminaEtiquetasInecesarias();
        tv.calculoDespOcupVL(tp);
        imprimirC3D();
    }

    private void imprimirC3D() {
        Writer buffer;
        File interFile = new File(directorio + "_C3D.txt");
        try {
            buffer = new BufferedWriter(new FileWriter(interFile));
            for (int i = 0; i < C3D.size(); i++) {
                buffer.write(C3D.get(i).toString() + "\n");
            }
            buffer.close();
            System.out.println(ConsoleColors.PURPLE_BOLD_BRIGHT
                    + "Proceso de optimización completado con éxito" + ConsoleColors.RESET);
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
        i = 0;
        int k;
        while (i < vars.size()) {
            k = devolverLineaVariableUsada(vars.get(i).destino());
            if (C3D.get(k).getOperando(1).equals(vars.get(i).destino())) {
                C3D.get(k).setOperando(1, vars.get(i).destino());
            } else {
                C3D.get(k).setOperando(2, vars.get(i).destino());
            }
            C3D.remove(vars.get(i));
            i++;
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

    private int devolverLineaVariableUsada(String var) {
        String[] str = new String[4];
        for (int i = 0; i < C3D.size(); i++) {
            str = C3D.get(i).getInstruccion();
            if (str[1].equals(var) || str[2].equals(var)) {
                return i;
            }
        }
        return 0;
    }

    /**
     * Devuelve las líneas de código intermedio que comprenden desde la posición
     * inicial pos hasta la etiqueta skip igual a la misma etiqueta para un goto
     * indicado por posGoto
     *
     * @param pos
     * @param posEtiqueta
     * @return
     */
    private ArrayList<Instruccion> recogerCodigo(int pos, int posEtiqueta) {
        boolean terminado = false;
        ArrayList<Instruccion> lista = new ArrayList<Instruccion>();
        Instruccion ins = C3D.get(pos);
        // Recoger valor etiqueta
        int nEtiqueta = Etiqueta.get(C3D.get(posEtiqueta).destino());
        lista.add(ins);
        while (!terminado) {
            pos++;
            ins = C3D.get(pos);
            lista.add(ins);
            // Comprobar si se ha encontrado el skip con la etiqueta
            if (ins.getOpCode() == Instruccion.OP.skip && nEtiqueta == Etiqueta.get(ins.destino()))
                terminado = true;
        }
        return lista;
    }

    private void reemplazaCodigo(ArrayList<Instruccion> codigoR, int empieza, int acaba) {
        List<Instruccion> sublistacodigo = this.C3D.subList(empieza, acaba);
        sublistacodigo.clear();
        this.C3D.addAll(empieza, codigoR);
    }

    private boolean esIf(Instruccion ins) {
        return (ins.getOpCode() == Instruccion.OP.ifLT || ins.getOpCode() == Instruccion.OP.ifLE
                || ins.getOpCode() == Instruccion.OP.ifEQ || ins.getOpCode() == Instruccion.OP.ifNE
                || ins.getOpCode() == Instruccion.OP.ifGE
                || ins.getOpCode() == Instruccion.OP.ifGT);
    }

    private Boolean operandosConstantes(Instruccion ins, int linea) {
        boolean esConst1 = false, esConst2 = false;
        Variable operando1 = tv.get(ins.getOperando(1));
        if (operando1 == null || operando1.tipo() == Simbolo.Tipo.CONST) {
            esConst1 = true;
        }

        Variable operando2 = tv.get(ins.getOperando(2));
        if (operando2 == null || operando2.tipo() == Simbolo.Tipo.CONST) {
            esConst2 = true;
        }

        return esConst1 && esConst2;
    }

    private int ejecutaIf(Instruccion ins, int empieza) {
        int lineasReemplazo = 0;
        int c1, c2;
        Variable v1, v2;
        v1 = tv.get(ins.getOperando(1));
        if (v1 != null) {
            c1 = Integer.parseInt(v1.getValor()); // Constante
        } else {
            c1 = Integer.parseInt(ins.getOperando(1)); // Literal
        }
        v2 = tv.get(ins.getOperando(2));
        if (v2 != null) {
            c2 = Integer.parseInt(v2.getValor()); // Constante
        } else {
            c2 = Integer.parseInt(ins.getOperando(2)); // Literal
        }
        switch (ins.getOpCode()) {
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
                lineasReemplazo = optimizarIfCierto(empieza);
                ;
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
        // Se cambia la instrucción if (valor) goto e por goto e
        lista.add(0, new Instruccion(Instruccion.OP.jump, "", "", lista.get(0).destino()));
        // Se borran las dos instrucciones que vienen a continuación del goto e
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
        // Se sustituye todo el código por la segunda y última instruccion
        aux.add(lista.get(1));
        aux.add(lista.get(lista.size() - 1));
        reemplazaCodigo(aux, empieza, empieza + lista.size());
        lineasReemplazo = aux.size();
        return lineasReemplazo;
    }

    public TablaVariables getTv() {
        return tv;
    }

    public void setTv(TablaVariables tv) {
        this.tv = tv;
    }

    public TablaProcedimientos getTp() {
        return tp;
    }

    public void setTp(TablaProcedimientos tp) {
        this.tp = tp;
    }
}
