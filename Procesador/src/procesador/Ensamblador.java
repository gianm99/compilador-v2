package procesador;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Writer;
import java.util.ArrayList;

public class Ensamblador {
    private String directorio;
    private ArrayList<Instruccion> c3d;
    private TablaVariables tv;
    private TablaProcedimientos tp;

    public Ensamblador(String directorio, ArrayList<Instruccion> c3d, TablaVariables tv,
            TablaProcedimientos tp) {
        this.directorio = directorio;
        this.c3d = c3d;
        this.tv = tv;
        this.tp = tp;
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
        ArrayList<String> asm = traducir();
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
        for (int p = 5; p < tp.getNp(); p++) {
            Procedimiento pp = tp.get(p);
            int i = pp.getInicio().getNl();
            asm.add(pp + "  PROC");
            int prof4x = tp.get(p).getProf() * 4;
            asm.add("lea  esi, DISP  ; esi = @DISP");
            asm.add("push [esi+" + prof4x + "]");
            asm.add("push ebp");
            asm.add("mov ebp, esp  ; BP = SP");
            asm.add("mov [esi+" + prof4x + "], ebp  ; DISP(prof) = BP");
            asm.add("sub esp, " + pp.getOcupVL()
                    + "  ; reserva memoria para las variables locales");
            i++;
            do {
                switch (c3d.get(i).getOpCode()) {
                case pmb:
                    i = saltarSubprograma(i);
                    break;
                default:
                    conversion(i);
                    i++;
                    break;
                }
            } while (!c3d.get(i).isInstFinal());
            asm.add(pp + "  ENDP");
        }
        asm.add("start:");
        // TODO Añadir el programa principal
        asm.add("end start");
        return asm;
    }

    private void lecturaMemReg(Variable x, String R) {
        if (x.tipo() == Simbolo.Tipo.CONST) {

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