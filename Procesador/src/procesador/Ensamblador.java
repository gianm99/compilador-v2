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
            //     System.out.println(s);
            // }
            compilado.waitFor();

            Process enlazado = Runtime.getRuntime().exec(
                    "link /out:" + directorio + ".exe /subsystem:console " + directorio + ".obj");

            stdInput = new BufferedReader(new InputStreamReader(enlazado.getInputStream()));
            // Leer el output del comando
            // System.out.println("Output:\n");
            // s = null;
            // while ((s = stdInput.readLine()) != null) {
            //     System.out.println(s);
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
        asm.add(".data"); // Variables globales
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() == Simbolo.TSub.STRING) {
                asm.add(vx + "  DB  " + vx.getValor() + ",0");
            }
        }
        asm.add(".const"); // Constantes de integer y boolean
        for (int x = 0; x < tv.getNv(); x++) {
            
        }
        asm.add(".code"); // Todas las subrutinas y el programa principal
        asm.add("start:");
        for (Instruccion instruccion : c3d) {
            switch (instruccion.getOpCode()) {
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
            case skip:
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
            case pmb:
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
            case ret:
                break;
            case sub:
                break;
            }
        }
        asm.add("end start");
        return asm;
    }

    /**
     * Lectura de memoria a registro. Implementa la lectura de una posición de
     * memoria a un registro.
     */
    private void lecturaMemReg(Variable x, String R) {
        if (x.tipo() == Simbolo.Tipo.CONST) {

        }
    }
}