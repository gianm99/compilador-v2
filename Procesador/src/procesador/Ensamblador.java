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
                                loadMemReg(var, "eax");
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
        npActual = 0; // Ya no se está en una subrutina
        // TODO Añadir el programa principal
        asm.add("end start");
        return asm;
    }

    private void conversion(int i) {
        switch (c3d.get(i).getOpCode()) {
        case EQ:
            break;
        case GE:
            break;
        case GT:
            break;
        case LE:
            break;
        case LT:
            break;
        case NEQ:
            break;
        case add:
            break;
        case and:
            break;
        case call:
            break;
        case copy:
            break;
        case div:
            break;
        case ifEQ:
            break;
        case ifGE:
            break;
        case ifGT:
            break;
        case ifLE:
            break;
        case ifLT:
            break;
        case ifNE:
            break;
        case jump:
            break;
        case mult:
            break;
        case neg:
            break;
        case not:
            break;
        case or:
            break;
        case params:
            break;
        case skip:
            break;
        case sub:
            break;
        default:
            break;

        }
    }

    // private void lecturaMemReg(Variable x, String R) {
    // if (x.tipo() == Simbolo.Tipo.CONST) {

    // }
    // }

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