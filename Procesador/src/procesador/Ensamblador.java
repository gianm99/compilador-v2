package procesador;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Writer;
import java.util.ArrayList;
import procesador.Instruccion.OP;
import procesador.Simbolo.TSub;
import procesador.Simbolo.Tipo;

public class Ensamblador {
    private String directorio;
    private ArrayList<Instruccion> C3D;
    private ArrayList<String> asm;
    private TablaVariables tv;
    private TablaProcedimientos tp;
    private TablaEtiquetas te;
    private int npActual; // El número de procedimiento actual

    public Ensamblador(String directorio, ArrayList<Instruccion> C3D, TablaVariables tv,
            TablaProcedimientos tp, TablaEtiquetas te) {
        this.directorio = directorio;
        this.C3D = C3D;
        this.asm = new ArrayList<>();
        this.tv = tv;
        this.tp = tp;
        this.te = te;
        this.npActual = 0;
    }

    public void ensamblar() {
        generarASM();
        generarEXE();
    }

    public void generarEXE() {
        try {
            Process compilado = Runtime.getRuntime()
                    .exec("ml /Fo" + directorio + ".obj" + " /c /Zd /coff  " + directorio + ".asm");
            BufferedReader stdInput = new BufferedReader(
                    new InputStreamReader(compilado.getInputStream()));
            // Leer el output del comando
            System.out.println("Output:\n");
            String s = null;
            while ((s = stdInput.readLine()) != null) {
                System.out.println(s);
            }
            compilado.waitFor();

            Process enlazado = Runtime.getRuntime().exec(
                    "link /out:" + directorio + ".exe /subsystem:console " + directorio + ".obj");

            stdInput = new BufferedReader(new InputStreamReader(enlazado.getInputStream()));
            // Leer el output del comando
            System.out.println("Output:\n");
            s = null;
            while ((s = stdInput.readLine()) != null) {
                System.out.println(s);
            }
            enlazado.waitFor();
            System.out.println(ConsoleColors.YELLOW_BOLD_BRIGHT + "Proceso de ensamblado ("
                    + directorio + ") completado con éxito" + ConsoleColors.RESET);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void generarASM() {
        Writer buffer;
        File asmFile = new File(directorio + ".asm");
        traducir();
        try {
            buffer = new BufferedWriter(new FileWriter(asmFile));
            for (int i = 0; i < asm.size(); i++) {
                buffer.write(asm.get(i) + "\n");
            }
            buffer.close();
        } catch (IOException e) {
        }
    }

    public void traducir() {
        asm.add(".386");
        asm.add(".model flat, stdcall");
        asm.add("option casemap:none");
        asm.add("include \\masm32\\include\\windows.inc");
        asm.add("include \\masm32\\include\\kernel32.inc");
        asm.add("include \\masm32\\include\\masm32.inc");
        asm.add("includelib \\masm32\\lib\\kernel32.lib");
        asm.add("includelib \\masm32\\lib\\masm32.lib");
        asm.add(".const");
        // Integers y booleans constantes
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() != Simbolo.TSub.STRING) {
                switch (vx.getTsub()) {
                case INT:
                    asm.add(vx + "  EQU  " + vx.getValor());
                    break;
                case BOOLEAN:
                    if (vx.getValor().equals("true")) {
                        asm.add(vx + "  EQU  -1");
                    } else {
                        asm.add(vx + "  EQU  0");
                    }
                    break;
                default:
                    break;
                }
            }
        }
        asm.add(".data");
        asm.add("\tinputPtr DD offset inputBuffer"); // Variable para control de input
        // Strings constantes
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() == Simbolo.TSub.STRING) {
                asm.add("\t" + vx + "  DB  " + vx.getValor() + ",0");
            }
        }
        asm.add(".data?");
        asm.add("\tinputBuffer db 65536 dup(?)"); // Buffer del input (256^2 bytes)
        // DISP
        asm.add("\tDISP  DW  1000 DUP (?)");
        // Variables globales
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.VAR && !vx.isBorrada() && vx.proc() == 0) {
                asm.add("\t" + vx + "  DD  ?");
            }
        }
        asm.add(".code");
        asm.add("start PROC");
        // Programa principal
        npActual = 0; // Ya no se está en una subrutina
        int i = 0;
        while (i < C3D.size()) {
            if (C3D.get(i).getOpCode() == OP.pmb) {
                // Saltar los subprogramas
                i = saltarSubprograma(i);
            } else {
                conversion(i);
                i++;
            }
        }
        asm.add("\tinvoke ExitProcess, 0");
        asm.add("start ENDP");
        // Función para leer un string
        asm.add("read$1:");
        asm.add("\tmov esi, OFFSET DISP    ; ESI = @ DISP");
        asm.add("\tpush [esi]");
        asm.add("\tpush ebp");
        asm.add("\tmov ebp, esp            ; BP = SP");
        asm.add("\tmov [esi], ebp          ; DISP(prof4x) = BP");
        asm.add("\tsub esp, 4");
        asm.add("\tpush 254");
        asm.add("\tpush inputPtr");
        asm.add("\tcall StdIn");
        asm.add("\tpush inputPtr");
        asm.add("\tcall strlen");
        asm.add("\tmov [ebp-4], eax        ; guardar resultado de strlen");
        asm.add("\tmov eax, inputPtr       ; guardar el inputPtr");
        asm.add("\tmov ebx, eax            ; preparar comprobacion");
        asm.add("\tadd ebx, [ebp-4]        ; sumar longitud del string");
        asm.add("\tsub ebx, OFFSET inputBuffer");
        asm.add("\tcmp ebx, SIZEOF inputBuffer");
        asm.add("\tjl @F                   ; comprobar direccion");
        asm.add("\tmov ebx, OFFSET inputBuffer");
        asm.add("\tmov inputPtr, ebx       ; reiniciar puntero");
        asm.add("@@:");
        asm.add("\tmov esp, ebp");
        asm.add("\tpop ebp");
        asm.add("\tmov edi, OFFSET DISP");
        asm.add("\tpop [edi]");
        asm.add("\tret");
        // Función para imprimir un boolean
        asm.add("printb$2:");
        asm.add("\tmov esi, OFFSET DISP    ; ESI = @ DISP");
        asm.add("\tpush [esi]");
        asm.add("\tpush ebp");
        asm.add("\tmov ebp, esp            ; BP = SP");
        asm.add("\tmov [esi], ebp          ; DISP(prof4x) = BP");
        asm.add("\tsub esp, 16             ; espacio para 'true' y 'false'");
        asm.add("\tmov esi, [ebp+12]");
        asm.add("\tmov eax, [esi]");
        asm.add("\tmov byte ptr [ebp-8], 't'");
        asm.add("\tmov byte ptr [ebp-7], 'r'");
        asm.add("\tmov byte ptr [ebp-6], 'u'");
        asm.add("\tmov byte ptr [ebp-5], 'e'");
        asm.add("\tmov byte ptr [ebp-4], 0");
        asm.add("\tmov byte ptr [ebp-16], 'f'");
        asm.add("\tmov byte ptr [ebp-15], 'a'");
        asm.add("\tmov byte ptr [ebp-14], 'l'");
        asm.add("\tmov byte ptr [ebp-13], 's'");
        asm.add("\tmov byte ptr [ebp-12], 'e'");
        asm.add("\tmov byte ptr [ebp-11], 0");
        asm.add("\ttest eax, eax           ; comprobar si es 0 (falso) o -1 (verdadero)");
        asm.add("\tjnl falso");
        asm.add("\tlea edi, [ebp-8]");
        asm.add("\tjmp fin");
        asm.add("\tfalso:");
        asm.add("\tlea edi, [ebp-16]");
        asm.add("\tfin:");
        asm.add("\tinvoke StdOut, edi");
        asm.add("\tmov esp, ebp");
        asm.add("\tpop ebp");
        asm.add("\tmov edi, OFFSET DISP");
        asm.add("\tpop [edi]");
        asm.add("\tret");
        // Función para imprimir un integer
        asm.add("printi$3:");
        asm.add("\tmov esi, OFFSET DISP    ; ESI = @ DISP");
        asm.add("\tpush [esi]");
        asm.add("\tpush ebp");
        asm.add("\tmov ebp, esp            ; BP = SP");
        asm.add("\tmov [esi], ebp          ; DISP(prof4x) = BP");
        asm.add("\tsub esp, 12             ; reservar espacio para el string buffer");
        asm.add("\tmov esi, [ebp+12]");
        asm.add("\tmov eax, [esi]          ; mover a eax el int a imprimir");
        asm.add("\tlea edi, [ebp-12]       ; mover a edi la dirección del string buffer");
        asm.add("\tcall EAX_to_DEC");
        asm.add("\tlea edi, [ebp-12]");
        asm.add("\tinvoke StdOut, edi");
        asm.add("\tmov esp, ebp");
        asm.add("\tpop ebp");
        asm.add("\tmov edi, OFFSET DISP");
        asm.add("\tpop [edi]");
        asm.add("\tret");
        // Función para imprimir un string
        asm.add("prints$4:");
        asm.add("\tmov esi, OFFSET DISP    ; ESI = @ DISP");
        asm.add("\tpush [esi]");
        asm.add("\tpush ebp");
        asm.add("\tmov ebp, esp            ; BP = SP");
        asm.add("\tmov [esi], ebp          ; DISP(prof4x) = BP");
        asm.add("\tmov esi, [ebp+12]");
        asm.add("\tmov edi, [esi]          ; mover a edi la dirección del string");
        asm.add("\tinvoke StdOut, edi");
        asm.add("\tmov esp, ebp");
        asm.add("\tpop ebp");
        asm.add("\tmov edi, OFFSET DISP");
        asm.add("\tpop [edi]");
        asm.add("\tret");
        // Funciones necesarias para las funciones de input/output
        // Función para convertir de integer a ascii
        asm.add("EAX_to_DEC PROC         ; ARG: EDI pointer to string buffer");
        asm.add("\ttest eax, eax           ; Test if number is less than zero");
        asm.add("\tjnl non_negative");
        asm.add("\tneg eax");
        asm.add("\tmov byte ptr [edi], '-'");
        asm.add("\tinc edi");
        asm.add("\tnon_negative:");
        asm.add("\tmov ebx, 10             ; Divisor = 10");
        asm.add("\txor ecx, ecx            ; ECX=0 (digit counter)");
        asm.add("\t@@:                     ; First Loop: store the remainders");
        asm.add("\txor edx, edx");
        asm.add("\tdiv ebx                 ; EDX:EAX / EBX = EAX remainder EDX");
        asm.add("\tpush dx                 ; push the digit in DL (LIFO)");
        asm.add("\tadd cl,1                ; = inc cl (digit counter)");
        asm.add("\tor  eax, eax            ; AX == 0?");
        asm.add("\tjnz @B                  ; no: once more (jump to the first @@ above)");
        asm.add("\t@@:                       ; Second loop: load the remainders in reversed order");
        asm.add("\tpop ax                  ; get back pushed digits");
        asm.add("\tor al, 00110000b        ; to ASCII");
        asm.add("\tstosb                   ; Store AL to [EDI] (EDI is a pointer to a buffer)");
        asm.add("\tloop @B                 ; until there are no digits left");
        asm.add("\tmov byte ptr [edi], 0   ; ASCIIZ terminator (0)");
        asm.add("\tret                     ; RET: EDI pointer to ASCIIZ-string");
        asm.add("EAX_to_DEC ENDP");
        // Función que calcula la longitud de un string
        asm.add("strlen:");
        asm.add("\tmov esi, OFFSET DISP    ; ESI = @ DISP");
        asm.add("\tpush [esi]");
        asm.add("\tpush ebp");
        asm.add("\tmov ebp, esp            ; BP = SP");
        asm.add("\tmov [esi], ebp          ; DISP(prof4x) = BP");
        asm.add("\tmov esi, [ebp+12]");
        asm.add("\txor eax, eax");
        asm.add("\tloop_len:");
        asm.add("\tmov ebx, [esi]");
        asm.add("\tcmp ebx, 0");
        asm.add("\tje done");
        asm.add("\tinc esi");
        asm.add("\tinc eax");
        asm.add("\tjmp loop_len");
        asm.add("\tdone:");
        asm.add("\tmov esp, ebp");
        asm.add("\tpop ebp");
        asm.add("\tmov edi, OFFSET DISP");
        asm.add("\tpop [edi]");
        asm.add("\tret");
        // Subrutinas definidas por el usuario
        for (int p = 5; p <= tp.getNp(); p++) {
            npActual = p; // La subrutina actual
            Procedimiento pp = tp.get(p);
            int l = te.get(pp.getInicio()).getLinea();
            asm.add(pp + ":");
            // pmb
            int prof4x = tp.get(p).getProf() * 4;
            asm.add("\tmov  esi, OFFSET DISP  ; ESI = @DISP");
            asm.add("\tpush [esi+" + prof4x + "]");
            asm.add("\tpush ebp");
            asm.add("\tmov ebp, esp  ; BP = SP");
            asm.add("\tmov [esi+" + prof4x + "], ebp  ; DISP(prof) = BP");
            asm.add("\tsub esp, " + pp.getOcupVL()
                    + "  ; reserva memoria para las variables locales");
            l++;
            while (true) {
                Instruccion ins = C3D.get(l);
                if (ins.getOpCode() == OP.pmb) {
                    // Saltar las declaraciones de subrutinas locales
                    l = saltarSubprograma(l);
                } else {
                    if (ins.getOpCode() == OP.ret) {
                        // Caso del return
                        asm.add("\tmov esp, ebp  ; SP = BP");
                        asm.add("\tpop ebp  ; BP = antiguo BP");
                        asm.add("\tlea edi, DISP  ; EDI = @DISP");
                        asm.add("\tpop [edi+" + prof4x + "]  ; DISP[prof] = antiguo valor");
                        if (ins.getOperando(1) != null) {
                            // Guardar el valor de retorno en %eax
                            Variable var = tv.get(ins.getOperando(1));
                            if (var != null) {
                                // Si no es un literal
                                loadMemReg("eax", var);
                            } else {
                                // Solo puede ser un int o un boolean
                                asm.add("\tmov eax, " + ins.getOperando(1));
                            }
                        }
                        asm.add("\tret");
                    } else {
                        // El resto de instrucciones
                        conversion(l);
                    }
                    if (ins.isInstFinal()) {
                        // Si es la última instrucción, sale del bucle
                        break;
                    } else {
                        // Si no, continua
                        l++;
                    }
                }
            }
        }
        asm.add("END start");
    }

    private void conversion(int i) {
        Variable a, b, c;
        Instruccion ins = C3D.get(i);
        switch (ins.getOpCode()) {
        case and:
            // a = b and c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tand eax, ebx");
            storeRegMem(a, "eax");
            break;
        case or:
            // a = b or c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tor eax, ebx");
            storeRegMem(a, "eax");
            break;
        case not:
            // a = not b
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            asm.add("\txor eax, eax  ; EAX = 0");
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(1));
            }
            asm.add("\tnot eax, ebx");
            storeRegMem(a, "eax");
            break;
        case add:
            // a = b + c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tadd eax, ebx");
            storeRegMem(a, "eax");
            break;
        case sub:
            // a = b - c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tsub eax, ebx");
            storeRegMem(a, "eax");
            break;
        case neg:
            // a = -b
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            asm.add("\txor eax, eax  ; EAX = 0");
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(1));
            }
            asm.add("\tsub eax, ebx");
            storeRegMem(a, "eax");
            break;
        case div:
            // a = b / c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            asm.add("\tmov edx, eax");
            asm.add("\tsar edx, 31");
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tidiv ebx");
            storeRegMem(a, "eax");
            break;
        case mult:
            // a = b * c
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\t\timul eax, ebx");
            storeRegMem(a, "eax");
            break;
        case copy:
            // a = b
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            if (b == null) {
                asm.add("\tmov eax, " + ins.getOperando(1));
            } else if (b.tipo() == Tipo.CONST && b.getTsub() == TSub.STRING) {
                loadAddrReg("eax", b);
            } else {
                loadMemReg("eax", b);
            }
            storeRegMem(a, "eax");
            break;
        case skip:
            // e: skip
            asm.add(ins.destino() + ":");
            break;
        case jump:
            // goto e
            asm.add("\tjmp " + ins.destino());
            break;
        case ifEQ:
            // if a == b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tje " + ins.destino());
            break;
        case ifNE:
            // if a != b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tjne " + ins.destino());
            break;
        case ifGE:
            // if a >= b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tjge " + ins.destino());
            break;
        case ifGT:
            // if a > b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tjg " + ins.destino());
            break;
        case ifLT:
            // if a <= b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tjl " + ins.destino());
            break;
        case ifLE:
            // if a < b goto e
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("\tmov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("\tmov ebx, " + ins.getOperando(2));
            }
            asm.add("\tcmp eax, ebx");
            asm.add("\tjle " + ins.destino());
            break;
        case call:
            // call ne
            int numpar4 = tp.get(ins.destino()).getNumParams() * 4;
            asm.add("\tcall " + ins.destino());
            asm.add("\tadd esp, " + numpar4);
            break;
        case params:
            // params a
            a = tv.get(ins.destino());
            loadAddrReg("eax", a); // TODO Solucionar el caso de strings literales
            asm.add("\tpush eax");
            break;
        case st:
            // store a
            a = tv.get(ins.destino());
            storeRegMem(a, "eax");
            break;
        default:
            break;
        }
    }

    /**
     * Carga un valor de memoria a un registro.
     * 
     * @param R
     *              El registro en el que se quiere cargar el valor de memoria.
     * @param x
     *              El valor de memoria que se quiere cargar en el registro.
     */
    private void loadMemReg(String R, Variable x) {
        int profp, profx;
        if (npActual != 0) {
            profp = tp.get(npActual).getProf();
        } else {
            profp = 0;
        }
        if (x.proc() != 0) {
            profx = tp.get(x.proc()).getProf();
        } else {
            profx = 0;
        }
        if (x.tipo() == Simbolo.Tipo.CONST) {
            // x es un valor constante
            asm.add("\tmov " + R + ", " + x);
        } else if (x.getDesp() == 0) {
            // x es una variable global
            asm.add("\tmov " + R + ", " + x + "  ; " + R + " = " + x);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("\tmov " + R + ", [ebp" + dx + "]");
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("\tmov esi, [ebp+" + dx + "]");
            asm.add("\tmov " + R + ", [esi]");
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("\tmov " + R + ", [esi" + dx + "]");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("\tmov esi, [esi+" + dx + "]  ; ESI = @ param");
            asm.add("\tmov " + R + ", [esi]");
        }
    }

    /**
     * Guarda el valor de un registro en una posición de memoria.
     * 
     * @param x
     *              La posición de memoria en la que se quiere guardar el valor.
     * @param R
     *              El registro que contiene el valor a escribir.
     */
    private void storeRegMem(Variable x, String R) {
        int profp, profx;
        if (npActual != 0) {
            profp = tp.get(npActual).getProf();
        } else {
            profp = 0;
        }
        if (x.proc() != 0) {
            profx = tp.get(x.proc()).getProf();
        } else {
            profx = 0;
        }
        if (x.getDesp() == 0) {
            // x es una variable global
            asm.add("\tmov " + x + ", " + R);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("\tmov [ebp" + dx + "], " + R);
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("\tmov edi, [ebp+" + dx + "]");
            asm.add("\tmov [edi], " + R);
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov edi, [esi+" + prof4x + "]  ; EDI = DISP[profx] = BPx");
            asm.add("\tmov [edi" + dx + "], R");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov esi, [esi+" + prof4x + "]  ; ESI = BPx");
            asm.add("\tmov edi, [esi+" + dx + "]  ; EDI = @ param");
            asm.add("\tmov [edi], " + R);
        }
    }

    /**
     * Carga una dirección de memoria a un registro.
     * 
     * @param R
     *              El registro en el que se quiere cargar la posición de memoria.
     * @param x
     *              La posición de memoria que se quiere cargar en el registro.
     */
    private void loadAddrReg(String R, Variable x) {
        int profp, profx;
        if (npActual != 0) {
            profp = tp.get(npActual).getProf();
        } else {
            profp = 0;
        }
        if (x.proc() != 0) {
            profx = tp.get(x.proc()).getProf();
        } else {
            profx = 0;
        }
        if (x.tipo() == Simbolo.Tipo.CONST) {
            // x es un valor constante
            asm.add("\tmov " + R + ", OFFSET " + x + "  ; " + R + " = @ " + x);
        } else if (x.getDesp() == 0) {
            // x es una variable global
            asm.add("\tmov " + R + ", OFFSET " + x + "  ; " + R + " = @ " + x);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("\tlea " + R + ", [ebp" + dx + "]");
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("\tmov " + R + ", [ebp+" + dx + "]");
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("\tlea " + R + ", [esi" + dx + "]");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("\tmov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("\tmov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("\tmov " + R + ", [esi+" + dx + "]");
        }
    }

    /**
     * Salta las declaraciones de subrutinas que se encuentra.
     * 
     * @param i
     *              La instrucción en la que empieza.
     * @return la primera instrucción que no es parte de una declaración de
     *         subrutina.
     */
    private int saltarSubprograma(int i) {
        int prof = 1;
        i++;
        while (prof != 0) {
            if (C3D.get(i).isInstFinal()) {
                prof--;
            } else if (C3D.get(i).getOpCode() == OP.pmb) {
                prof++;
            }
            i++;
        }
        return i;
    }
}