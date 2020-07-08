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
        asm.add(".data");
        // Strings constantes
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() == Simbolo.TSub.STRING) {
                asm.add(vx + "  DB  " + vx.getValor() + ",0");
            }
        }
        // TODO Añadir las variables globales
        asm.add(".const");
        // Integers y booleans constantes
        for (int x = 1; x <= tv.getNv(); x++) {
            Variable vx = tv.get(x);
            if (vx.tipo() == Simbolo.Tipo.CONST && vx.getTsub() != Simbolo.TSub.STRING) {
                asm.add(vx + "  EQU  " + vx.getValor());
            }
        }
        asm.add(".code");
        // TODO Añadir las subrutinas de manera independiente
        asm.add("start:");
        // TODO Añadir el programa principal
        asm.add("end start");
        return asm;
    }

    private void lecturaMemReg(Variable x, String R) {
        if (x.tipo() == Simbolo.Tipo.CONST) {

        }
    }
}