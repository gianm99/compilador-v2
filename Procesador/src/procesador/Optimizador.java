package procesador;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import procesador.Instruccion.OP;

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

    private void C3DquitarInstruccion(int posicion) {
        if (C3D.get(posicion).isInstFinal()) {
            C3D.get(posicion - 1).setInstFinal(true);
        }
        C3D.remove(posicion);
    }

    private void C3DquitarInstruccion(Instruccion ins) {
        int posicion = C3D.indexOf(ins);
        if (C3D.get(posicion).isInstFinal()) {
            C3D.get(posicion - 1).setInstFinal(true);
        } else {
            C3D.remove(posicion);
        }
    }

    public void optimizar() {
        optimizarAssigBoolean();
        eliminaCodigoInaccesibleIf();
        optimizarIfNegandoCond();
        eliminaEtiquetasInnecesarias();
        eliminaCodigoInaccesibleEntreEtiquetas();
        eliminaAsignacionesInnecesarias();
        reasignarLineaEtiqueta();
        tv.calculoDespOcupVL(tp);
        imprimirC3D();
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
    private void eliminaCodigoInaccesibleIf() {
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
     * Detecta y optimiza la assignación de un boolean.
     */

    private void optimizarAssigBoolean() {
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (esIf(ins)) {
                Variable operando1 = tv.get(ins.getOperando(1));
                if (operando1.tsub() == Simbolo.TSub.BOOLEAN && operando1 != null
                        && C3D.get(i).destino().equals(C3D.get(i + 2).destino())) {
                    ArrayList<Instruccion> arrayaux = new ArrayList<Instruccion>();
                    arrayaux.add(new Instruccion(OP.copy, C3D.get(i).getOperando(1), "",
                            C3D.get(i + 3).destino()));
                    reemplazaCodigo(arrayaux, i, i + 7);
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
            if (ins.getOpCode() == Instruccion.OP.skip && !te.get(ins.destino()).isDeproc()) {
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
        while (i < C3D.size() - 1) {
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
                    if (aux.size() > 1)
                        aux.add(C3D.get(j));
                    j++;
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
        // Lista de asignaciones de variables temporales
        ArrayList<Instruccion> InstrucVars = new ArrayList<Instruccion>();
        // Lista de parámetros
        ArrayList<Instruccion> InstrucParams = new ArrayList<Instruccion>();
        // Lista de operaciones aritméticas
        ArrayList<Instruccion> InstrucArit = new ArrayList<Instruccion>();
        // Se añade a cada lista lo que le corresponde
        int i = 0;
        while (i < C3D.size()) {
            if (C3D.get(i).destino().charAt(0) == 't' && C3D.get(i).destino().charAt(1) == '$') {
                if ((C3D.get(i).getOpCode() == Instruccion.OP.copy)) {
                    if (!InstrucVars.contains(C3D.get(i))
                            && !(tv.get(C3D.get(i).destino()).tsub() == Simbolo.TSub.STRING)) {
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
        // Evita que las variables temporales generadas para parámetros sean borradas
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
        // Quita de la lista de variables temporales todas las que tengan más de asignación,
        // evitando que se borren más tarde
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
        // Se borran las variables de la lista de InstrucVars y se asigna directamente su contenido
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
        // Se borran las variables de la lista de InstrucArit y se asigna directamente su contenido
        i = 0;
        while (i < InstrucArit.size()) {
            k = devolverLineaVariableUsada(InstrucArit.get(i).destino());
            if (k > 0) {
                for (int a = 0; a < InstrucVars.size(); a++) {
                    if (InstrucVars.get(a).destino().equals(C3D.get(k).getOperando(1))) {
                        C3D.get(k).setOperando(1, InstrucVars.get(a).getOperando(1));
                        C3D.get(k).setOpCode(InstrucArit.get(i).getOpCode());
                        C3D.get(k).setOperando(0, InstrucArit.get(i).getOperando(0));
                        tv.quitarVar(InstrucArit.get(i).destino());
                        C3DquitarInstruccion(InstrucArit.get(i));
                        break;
                    } else if (InstrucVars.get(a).destino().equals(C3D.get(k).getOperando(2))) {
                        C3D.get(k).setOperando(2, InstrucVars.get(a).getOperando(1));
                        C3D.get(k).setOpCode(InstrucArit.get(i).getOpCode());
                        C3D.get(k).setOperando(0, InstrucArit.get(i).getOperando(0));
                        tv.quitarVar(InstrucArit.get(i).destino());
                        C3DquitarInstruccion(InstrucArit.get(i));
                        break;
                    }
                }
                if (C3D.get(k).getOpCode() == OP.copy) {
                    for (int a = 0; a < InstrucArit.size(); a++) {
                        if (C3D.contains(InstrucArit.get(a))) {
                            if (InstrucArit.get(a).destino().equals(C3D.get(k).getOperando(1))) {
                                C3D.get(k - 1).setOperando(3, C3D.get(k).destino());
                                tv.quitarVar(C3D.get(k).getOperando(1));
                                C3DquitarInstruccion(C3D.get(k));
                            }
                        }
                    }
                }
            }
            i++;
        }
        // Si hay asignaciones repetidas contiguas (por como funciona las optimizaciones), se borra
        // una de ellas
        i = 0;
        while (i < C3D.size() - 1) {
            if (C3D.get(i).equals(C3D.get(i + 1))) {
                C3DquitarInstruccion(i + 1);
            } else {
                i++;
            }
        }
    }

    /**
     * Reasigna la linea de cada etiqueta al final de las optimizaciones
     */
    private void reasignarLineaEtiqueta() {
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (ins.getOpCode() == OP.skip) {
                te.get(ins.destino()).setLinea(i + 1);
            }
        }
    }

    /**
     * Optimiza un IF negando la condición, reduciendo el número de etiquetas necesarias.
     */
    private void optimizarIfNegandoCond() {
        for (int i = 0; i < C3D.size(); i++) {
            Instruccion ins = C3D.get(i);
            if (esIf(ins)) {
                if (!operandosConstantes(ins) && noEsIfSwitch(i)) {
                    switch (ins.getOpCode()) {
                        case ifLT:
                            C3D.get(i).setOpCode(OP.ifGE);
                            break;
                        case ifLE:
                            C3D.get(i).setOpCode(OP.ifGT);
                            break;
                        case ifEQ:
                            C3D.get(i).setOpCode(OP.ifNE);
                            break;
                        case ifNE:
                            C3D.get(i).setOpCode(OP.ifEQ);
                            break;
                        case ifGE:
                            C3D.get(i).setOpCode(OP.ifLT);
                            break;
                        case ifGT:
                            C3D.get(i).setOpCode(OP.ifLE);
                            break;
                        default:
                            break;
                    }
                    C3D.get(i).setOperando(3, C3D.get(i + 1).destino());
                    C3DquitarInstruccion(i + 1);
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

    /**
     * Comprueba que el IF generado no pertenece al codigo de un SWITCH
     * 
     * @param i Línea de la instrucción C3D
     * @return
     */
    private boolean noEsIfSwitch(int i) {
        return C3D.get(i).destino().equals(C3D.get(i + 2).destino());
    }

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
        for (int i = 0; i < sublistacodigo.size(); i++) {
            if (sublistacodigo.get(i).isInstFinal()) {
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
                || ins.getOpCode() == Instruccion.OP.mult || ins.getOpCode() == Instruccion.OP.div
                || ins.getOpCode() == Instruccion.OP.mod);
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
        if (operando1 == null || operando1.tipo() == Simbolo.Tipo.CONST
                || (operando1.isTemporal() && operando1.getValor() != null)) {
            esConst1 = true;
        }

        Variable operando2 = tv.get(ins.getOperando(2));
        if (operando2 == null || operando2.tipo() == Simbolo.Tipo.CONST
                || (operando2.isTemporal() && operando2.getValor() != null)) {
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

    public TablaProcedimientos getTp() {
        return tp;
    }

    public TablaEtiquetas getTe() {
        return te;
    }

    public void setTp(TablaProcedimientos tp) {
        this.tp = tp;
    }

    public ArrayList<Instruccion> getC3D() {
        return C3D;
    }
}
