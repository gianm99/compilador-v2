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
    private ArrayList<Instruccion> c3d;
    private ArrayList<String> asm;
    private TablaVariables tv;
    private TablaProcedimientos tp;
    private int npActual; // El número de procedimiento actual

    public Ensamblador(String directorio, ArrayList<Instruccion> c3d, TablaVariables tv,
            TablaProcedimientos tp) {
        this.directorio = directorio;
        this.c3d = c3d;
        this.asm = new ArrayList<>();
        this.tv = tv;
        this.tp = tp;
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
            // System.out.println("Output:\n");
            // String s = null;
            // while ((s = stdInput.readLine()) != null) {
            // System.out.println(s);
            // }
            compilado.waitFor();

            Process enlazado = Runtime.getRuntime().exec(
                    "link /out:" + directorio + ".exe /subsystem:console " + directorio + ".obj");

            stdInput = new BufferedReader(new InputStreamReader(enlazado.getInputStream()));
            // Leer el output del comando
            // System.out.println("Output:\n");
            // s = null;
            // while ((s = stdInput.readLine()) != null) {
            // System.out.println(s);
            // }
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
        asm = traducir();
        try {
            buffer = new BufferedWriter(new FileWriter(asmFile));
            for (int i = 0; i < asm.size(); i++) {
                buffer.write(asm.get(i) + "\n");
            }
            buffer.close();
        } catch (IOException e) {
        }
    }

    public ArrayList<String> traducir() {
        ArrayList<String> asm = new ArrayList<>();
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
        // Strings constantes
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() == Simbolo.TSub.STRING) {
                asm.add(vx + "  DB  " + vx.getValor() + ",0");
            }
        }
        asm.add(".data?");
        // DISP
        asm.add("DISP  DW  1000 DUP (?)");
        // Variables globales
        for (int x = 1; x < tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.VAR && !vx.isBorrada() && vx.proc() == 0) {
                asm.add(vx + "  DD  ?");
            }
        }
        asm.add(".code");
        // TODO Añadir las subrutinas propias del lenguaje (Input y Output)
        // Subrutinas definidas por el usuario
        for (int p = 5; p < tp.getNp(); p++) {
            npActual = p; // La subrutina actual
            Procedimiento pp = tp.get(p);
            int i = pp.getInicio().getNl();
            asm.add(pp + "  PROC");
            // pmb
            int prof4x = tp.get(p).getProf() * 4;
            asm.add("lea  esi, DISP  ; ESI = @DISP");
            asm.add("push [esi+" + prof4x + "]");
            asm.add("push ebp");
            asm.add("mov ebp, esp  ; BP = SP");
            asm.add("mov [esi+" + prof4x + "], ebp  ; DISP(prof) = BP");
            asm.add("sub esp, " + pp.getOcupVL()
                    + "  ; reserva memoria para las variables locales");
            i++;
            while (true) {
                Instruccion ins = c3d.get(i);
                if (ins.getOpCode() == OP.pmb) {
                    // Saltar las declaraciones de subrutinas locales
                    i = saltarSubprograma(i);
                } else {
                    if (ins.getOpCode() == OP.ret) {
                        // Caso del return
                        asm.add("mov esp, ebp  ; SP = BP");
                        asm.add("pop ebp  ; BP = antiguo BP");
                        asm.add("lea edi, DISP  ; EDI = @DISP");
                        asm.add("pop [edi+" + prof4x + "]  ; DISP[prof] = antiguo valor");
                        if (ins.getOperando(1) != null) {
                            // Guardar el valor de retorno en %eax
                            Variable var = tv.get(ins.getOperando(1));
                            if (var != null) {
                                // Si no es un literal
                                loadMemReg("eax", var);
                            } else {
                                // Solo puede ser un int o un boolean
                                asm.add("mov eax, " + ins.getOperando(1));
                            }
                        }
                        asm.add("ret");
                    } else {
                        // El resto de instrucciones
                        conversion(i);
                    }
                    if (ins.isInstFinal()) {
                        // Si es la última instrucción, sale del bucle
                        break;
                    } else {
                        // Si no, continua
                        i++;
                    }
                }
            }
            asm.add(pp + "  ENDP");
        }
        asm.add("start:");
        // Programa principal
        npActual = 0; // Ya no se está en una subrutina
        int i = 0;
        while (i < c3d.size()) {
            if (c3d.get(i).getOpCode() == OP.pmb) {
                // Saltar los subprogramas
                i = saltarSubprograma(i);
            } else {
                conversion(i);
            }
        }
        asm.add("end start");
        return asm;
    }

    private void conversion(int i) {
        Variable a, b, c;
        Instruccion ins = c3d.get(i);
        switch (ins.getOpCode()) {
        case and:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("and eax, ebx");
            storeRegMem(a, "eax");
            break;
        case or:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("or eax, ebx");
            storeRegMem(a, "eax");
            break;
        case not:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            asm.add("xor eax, eax  ; EAX = 0");
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(1));
            }
            asm.add("not eax, ebx");
            storeRegMem(a, "eax");
            break;
        case add:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("add eax, ebx");
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
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("sub eax, ebx");
            storeRegMem(a, "eax");
            break;
        case neg:
            // a = -b
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            asm.add("xor eax, eax  ; EAX = 0");
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(1));
            }
            asm.add("sub eax, ebx");
            break;
        case div:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            asm.add("mov edx, eax");
            asm.add("sar edx, 31");
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("idiv ebx");
            storeRegMem(a, "eax");
            break;
        case mult:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            c = tv.get(ins.getOperando(2));
            if (b != null) {
                loadMemReg("eax", b);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (c != null) {
                loadMemReg("ebx", c);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("imul eax, ebx");
            storeRegMem(a, "eax");
            break;
        case copy:
            a = tv.get(ins.destino());
            b = tv.get(ins.getOperando(1));
            if (b == null) {
                asm.add("mov eax, " + ins.getOperando(1));
            } else if (b.tipo() == Tipo.CONST && b.getTsub() == TSub.STRING) {
                loadAddrReg("eax", b);
            } else {
                loadMemReg("eax", b);
            }
            storeRegMem(a, "eax");
            break;
        case skip:
            asm.add(ins.destino() + " :");
            break;
        case jump:
            asm.add("jmp " + ins.destino());
            break;
        case ifEQ:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("je " + ins.destino());
            break;
        case ifNE:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("jne " + ins.destino());
            break;
        case ifGE:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("jge " + ins.destino());
            break;
        case ifGT:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("jgt " + ins.destino());
            break;
        case ifLT:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("jl " + ins.destino());
            break;
        case ifLE:
            a = tv.get(ins.getOperando(1));
            b = tv.get(ins.getOperando(2));
            if (a != null) {
                loadMemReg("eax", a);
            } else {
                asm.add("mov eax, " + ins.getOperando(1));
            }
            if (b != null) {
                loadMemReg("ebx", b);
            } else {
                asm.add("mov ebx, " + ins.getOperando(2));
            }
            asm.add("cmp ebx, eax");
            asm.add("jle " + ins.destino());
            break;
        case call:
            break;
        case params:
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
            asm.add("mov " + R + ", " + x);
        } else if (profx == 0) {
            // x es una variable global
            asm.add("mov " + R + ", " + x + "  ; " + R + " = " + x);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("mov " + R + ", [ebp" + dx + "]");
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("mov esi, [ebp+" + dx + "]");
            asm.add("mov " + R + ", [esi]");
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("mov " + R + ", [esi" + dx + "]");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("mov esi, [esi+" + dx + "]  ; ESI = @ param");
            asm.add("mov " + R + ", [esi]");
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
    private void storeRegMem(Variable x, String R) { // TODO Comprobar si hay instrucciones ambiguas
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
        if (profx == 0) {
            // x es una variable global
            asm.add("mov " + x + ", " + R);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("mov [ebp" + dx + "], " + R);
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("mov edi, [ebp+" + dx + "]");
            asm.add("mov [edi], " + R);
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov edi, [esi+" + prof4x + "]  ; EDI = DISP[profx] = BPx");
            asm.add("mov [edi" + dx + "], R");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov esi, [esi+" + prof4x + "]  ; ESI = BPx");
            asm.add("mov edi, [esi+" + dx + "]  ; EDI = @ param");
            asm.add("mov [edi], " + R);
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
            asm.add("mov " + R + ", OFFSET " + x + "  ; " + R + " = @ " + x);
        } else if (profx == 0) {
            // x es una variable global
            asm.add("mov " + R + ", OFFSET " + x + "  ; " + R + " = @ " + x);
        } else if (profp == profx && x.getDesp() < 0) {
            // x es una variable local
            int dx = x.getDesp();
            asm.add("lea " + R + ", [ebp" + dx + "]");
        } else if (profp == profx) {
            // x es un parámetro local
            int dx = 8 + 4 * x.getNparam();
            asm.add("mov " + R + ", [ebp+" + dx + "]");
        } else if (profp < profx && x.getDesp() < 0) {
            // x es una variable definida en otro ámbito
            int dx = x.getDesp();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("lea " + R + ", [esi" + dx + "]");
        } else if (profx < profp) {
            // x es un parámetro definido en otro ámbito
            int dx = 8 + 4 * x.getNparam();
            int prof4x = profx * 4;
            asm.add("mov esi, OFFSET DISP  ; ESI = @ DISP");
            asm.add("mov esi, [esi+" + prof4x + "]  ; ESI = DISP[profx] = BPx");
            asm.add("mov " + R + ", [esi+" + dx + "]");
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
            if (c3d.get(i).isInstFinal()) {
                prof--;
            } else if (c3d.get(i).getOpCode() == OP.pmb) {
                prof++;
            }
            i++;
        }
        return i;
    }
}