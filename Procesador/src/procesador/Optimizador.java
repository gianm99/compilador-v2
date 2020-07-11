package procesador;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import org.antlr.v4.codegen.SourceGenTriggers;
import procesador.Instruccion.OP;
import procesador.Simbolo.TSub;

public class Optimizador {

    private String directorio;
    private ArrayList<Instruccion> C3D;
    private TablaVariables tv;
    private TablaProcedimientos tp;
    private TablaEtiquetas te;

    public Optimizador(String directorio, final ArrayList<Instruccion> C3D, TablaVariables tv,
            TablaProcedimientos tp, TablaEtiquetas te) {
        this.directorio = directorio;
        this.C3D = C3D;
        this.tv = tv;
        this.tp = tp;
        this.te = te;
    }

    private void C3DquitarInstruccion(int posicion){
        if(C3D.get(posicion).isInstFinal()){
            C3D.get(posicion - 1).setInstFinal(true);
        } 
        C3D.remove(posicion);  
    }

    private void C3DquitarInstruccion(Instruccion ins){
        int posicion = C3D.indexOf(ins);
        if (C3D.get(posicion).isInstFinal()){
            C3D.get(posicion - 1).setInstFinal(true);
        } else {
            C3D.remove(posicion);
        }   
    }

    public void optimizar() {
        eliminaCodigoInaccesibleIf();
        eliminaEtiquetasInnecesarias();
        eliminaCodigoInaccesibleEntreEtiquetas();
        eliminaAsignacionesInnecesarias();
        reasignarLineaEtiqueta();
        // TODO revisar optimizaciones para que se asigne la instrucción final de un subprograma si
        // se cambia el código de esta
        tv.calculoDespOcupVL(tp);
        imprimirC3D();
        //int a = 0;
    }

    /**
     * Imprime el código C3D una vez aplicadas las optimizaciones
     */
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

    /**
     * Comprueba y optimiza el código C3D de los IF con valores sabidos en tiempo de compilación
     */
    public void eliminaCodigoInaccesibleIf() {
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (esIf(ins)) {
                if (operandosConstantes(ins)) {
                    i += ejecutaIf(ins, i);
                }
            }
        }
    }

    /**
     * Comprueba y elimina todas las etiquetas de salto (skip) las cuales no tengan una instrucción
     * de salto (goto) asignadas
     */
    private void eliminaEtiquetasInnecesarias() {
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
                        C3DquitarInstruccion(i);
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
                C3DquitarInstruccion(i - 1);
            borrado = false;
            if (C3D.get(i).getOpCode() == Instruccion.OP.jump) {
                if (C3D.get(i + 1).getOpCode() == Instruccion.OP.skip
                        && C3D.get(i).destino().equals(C3D.get(i + 1).destino())) {
                    borrado = true;
                    C3DquitarInstruccion(i);
                }
            }
            i++;
        }
    }

    /**
     * Para cada conjunto de instrucciones entre un goto y su skip más cercano, si no se detecta un
     * skip de otra etiqueta, elimina el código entre goto y el skip, sin incluir el skip. Después
     * llama a la función "eliminaEtiquetasInnecesarias()" para borrar todos los skips que no tengan
     * un gotos asocioados después de aplicar esta optimización
     */
    private void eliminaCodigoInaccesibleEntreEtiquetas() {
        ArrayList<Instruccion> aux = new ArrayList<Instruccion>();
        int j;
        for (int i = 0; i < C3D.size(); i++) {
            if (C3D.get(i).getOpCode() == Instruccion.OP.jump) {
                aux.add(C3D.get(i));
                j = i;
                while (j < C3D.size()) {
                    if (C3D.get(j).getOpCode() == Instruccion.OP.skip) {
                        if (C3D.get(j).destino().equals(aux.get(0).destino()))
                            reemplazaCodigo(null, i, i + aux.size() - 1);
                        break;
                    }
                    j++;
                    aux.add(C3D.get(j));
                }
                aux.clear();
            }
        }
        eliminaEtiquetasInnecesarias();
    }

    /**
     * Reduce el número de variables temporales para las asignaciones, siempre y cuando no sean de
     * tipo String o necesitados para pasar por parámetro para una función.
     */
    private void eliminaAsignacionesInnecesarias() {
        ArrayList<Instruccion> InstrucVars = new ArrayList<Instruccion>();
        ArrayList<Instruccion> InstrucParams = new ArrayList<Instruccion>();
        ArrayList<Instruccion> InstrucArit = new ArrayList<Instruccion>();
        int i = 0;
        while (i < C3D.size()) {
            if (C3D.get(i).destino().charAt(0) == 't' && C3D.get(i).destino().charAt(1) == '$') {
                if ((C3D.get(i).getOpCode() == Instruccion.OP.copy)) {
                    if (!InstrucVars.contains(C3D.get(i))
                            && !(tv.get(C3D.get(i).destino()).getTsub() == Simbolo.TSub.STRING)) {
                        InstrucVars.add(C3D.get(i));
                    }
                } else if (C3D.get(i).getOpCode() == Instruccion.OP.params) {
                    InstrucParams.add(C3D.get(i));
                } else if (esArit(C3D.get(i))) {
                    InstrucArit.add(C3D.get(i));
                }
            }
            i++;
        }
        int j = 0;
        for (i = 0; i < InstrucParams.size(); i++) {
            j = 0;
            while (j < InstrucVars.size()) {
                if (InstrucParams.get(i).destino().equals(InstrucVars.get(j).destino())) {
                    InstrucVars.remove(j);
                    j = InstrucVars.size();
                }
                j++;
            }
        }
        boolean primerEncuentro;
        for (i = 0; i < InstrucVars.size(); i++) {
            primerEncuentro = false;
            while (j < C3D.size()) {
                if (C3D.get(j).getOpCode() == Instruccion.OP.copy) {
                    if (!primerEncuentro) {
                        if (InstrucVars.get(i).equals(C3D.get(j))) {
                            primerEncuentro = true;
                        }
                    } else {
                        if (InstrucVars.get(i).equals(C3D.get(j))) {
                            InstrucVars.remove(i);
                            break;
                        }
                    }
                }
                j++;
            }
        }
        i = 0;
        int k;
        while (i < InstrucVars.size()) {
            k = devolverLineaVariableUsada(InstrucVars.get(i).destino());
            if (k > 0) {
                if (C3D.get(k).getOperando(1).equals(InstrucVars.get(i).destino())) {
                    C3D.get(k).setOperando(1, InstrucVars.get(i).getOperando(1));
                }
                if (C3D.get(k).getOperando(2) != null) {
                    if (C3D.get(k).getOperando(2).equals(InstrucVars.get(i).destino())) {
                        C3D.get(k).setOperando(2, InstrucVars.get(i).getOperando(1));
                    }
                }
            }
            tv.quitarVar(InstrucVars.get(i).destino());
            C3DquitarInstruccion(InstrucVars.get(i));
            i++;
        }
        i = 0;
        while (i < InstrucArit.size()) {
            k = devolverLineaVariableUsada(InstrucArit.get(i).destino());
            if (k > 0) {
                if (C3D.get(k).getOperando(1) != null)
                    if (C3D.get(k).getOperando(1).equals(InstrucArit.get(i).destino())) {
                        C3D.get(k).setOpCode(InstrucArit.get(i).getOpCode());
                        C3D.get(k).setOperando(0, InstrucArit.get(i).getOperando(0));
                        C3D.get(k).setOperando(1, InstrucArit.get(i).getOperando(1));
                        C3D.get(k).setOperando(2, InstrucArit.get(i).getOperando(2));
                    }
            }
            tv.quitarVar(InstrucArit.get(i).destino());
            C3DquitarInstruccion(InstrucArit.get(i));
            i++;
        }
        i = 0;
        while (i < C3D.size() - 1) {
            if (C3D.get(i).equals(C3D.get(i + 1))) {
                C3DquitarInstruccion(i + 1);
            } else {
                i++;
            }
        }
    }

    private void reasignarLineaEtiqueta() { // TODO mirar que funciona el reasignado
        ArrayList<Etiqueta> teaux = new ArrayList<Etiqueta>();
        Etiqueta e;
        for (int i = 0; i < C3D.size(); i++) {
            if (C3D.get(i).getOpCode() == Instruccion.OP.skip) {
                e = te.get(C3D.get(i).destino().substring(1));
                e.setNl(i + 1);
                teaux.add(e);
            }
        }
        te.getTe().clear();
        te.getTe().addAll(teaux);
;    }

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

    /**
     * Devuelve la línea en la lista C3D donde la variable ha sido usada para una asignación (sin
     * ser esta el destino de la propia asignación)
     * 
     * @param var String que contiene el nombre de la variable
     * @return Línea en la lista C3D
     */
    private int devolverLineaVariableUsada(String var) {
        String[] str = new String[4];
        for (int i = 0; i < C3D.size(); i++) {
            str = C3D.get(i).getInstruccion();
            if (str[1] != null) {
                if (str[1].equals(var))
                    return i;
            }
            if (str[2] != null) {
                if (str[2].equals(var))
                    return i;
            }
        }
        return -1;
    }

    /**
     * Devuelve las líneas de código C3D que comprenden desde la posición inicial "pos" hasta la
     * posición final "posEtiqueta"
     *
     * @param pos         Posición inicial
     * @param posEtiqueta Posición final marcado por una etiqueta
     * @return Devuelve el código entre las dos posiciones
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

    /**
     * Reemplaza el código de C3D entre la posición incial "empieza" y la posición final "acaba" por
     * la lista de instrucciones de codigoR.
     * 
     * @param codigoR Lista de instrucciones a sustituir en el código de C3D
     * @param empieza Posición inicial del C3D
     * @param acaba   Posición final del C3D
     */
    private void reemplazaCodigo(ArrayList<Instruccion> codigoR, int empieza, int acaba) {
        List<Instruccion> sublistacodigo = this.C3D.subList(empieza, acaba);
        for(int i = 0; i< sublistacodigo.size();i++){
            if(sublistacodigo.get(i).isInstFinal()){
                codigoR.get(codigoR.size() - 1).setInstFinal(true);
                break;
            }       
        }
        sublistacodigo.clear();
        if (codigoR != null)
            this.C3D.addAll(empieza, codigoR);
    }

    /**
     * Comprueba si la instrucción "ins" es una instrucción de tipo IF
     * 
     * @param ins Instrucción a comprobar
     * @return Valor de la comprobación
     */
    private boolean esIf(Instruccion ins) {
        return (ins.getOpCode() == Instruccion.OP.ifLT || ins.getOpCode() == Instruccion.OP.ifLE
                || ins.getOpCode() == Instruccion.OP.ifEQ || ins.getOpCode() == Instruccion.OP.ifNE
                || ins.getOpCode() == Instruccion.OP.ifGE
                || ins.getOpCode() == Instruccion.OP.ifGT);
    }

    /**
     * Comprueba si la instrucción "ins" es una instrucción de tipo aritmético
     * 
     * @param ins Instrucción a comprobar
     * @return Valor de la comprobación
     */
    private boolean esArit(Instruccion ins) {
        return (ins.getOpCode() == Instruccion.OP.add || ins.getOpCode() == Instruccion.OP.sub
                || ins.getOpCode() == Instruccion.OP.mult || ins.getOpCode() == Instruccion.OP.div);
    }

    /**
     * Comprueba si los 2 opereandos de la instrucción "ins" son valores constantes
     * 
     * @param ins Instrucción a comprobar
     * @return Valor de la comprobación
     */
    private Boolean operandosConstantes(Instruccion ins) {
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

    /**
     * Para cada caso de IF en relación al operador relacional usado en él, comprueba si es cierto o
     * falso y llama a la función que realizará la optimización del IF
     * 
     * @param ins     Instrucción de tipo IF a comprobar
     * @param empieza Número de la instrucción en la lista C3D
     * @return Número de líneas reemplazadas por la función de optimización del IF
     */
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

    /**
     * Optimiza un IF cierto
     * 
     * @param empieza Número de la instrucción en la lista C3D
     * @return Número de líneas reemplazadas por la función
     */
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

    /**
     * Optimiza un IF falso
     * 
     * @param empieza Número de la instrucción en la lista C3D
     * @return Número de líneas reemplazadas por la función
     */
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

    public ArrayList<Instruccion> getC3D() {
        return C3D;
    }
}
