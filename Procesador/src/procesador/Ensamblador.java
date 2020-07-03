package procesador;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;

public class Ensamblador {

    public void ensamblar(String directorio, ArrayList<Instruccion> c3d) {
        generarASM(directorio, c3d);
        generarEXE(directorio);
    }

    public void generarEXE(String directorio) {
        try {
            Process compilado = Runtime.getRuntime().exec("ml /c /Zd /coff " + directorio + ".asm");
            compilado.waitFor();
            Process enlazado =
                    Runtime.getRuntime().exec("link /subsystem:console " + directorio + ".obj");
            enlazado.waitFor();
            System.out.println(ConsoleColors.YELLOW_BOLD_BRIGHT
                    + "Proceso de ensamblado completado con éxito\n"
                    + "Se han generado los archivos: " + directorio + ".asm, " + directorio
                    + ".obj y " + directorio + ".exe" + ConsoleColors.RESET);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void generarASM(String directorio, ArrayList<Instruccion> c3d) {
        Writer buffer;
        File asmFile = new File(directorio + ".asm");
        ArrayList<String> asm = traducir(c3d);
        try {
            buffer = new BufferedWriter(new FileWriter(asmFile));
            for (int i = 0; i < asm.size(); i++) {
                buffer.write(asm.get(i) + "\n");
            }
            buffer.close();
        } catch (IOException e) {
        }
    }

    public ArrayList<String> traducir(ArrayList<Instruccion> c3d) {
        ArrayList<String> asm = new ArrayList<>();
        // TODO Hacer la traducción a x86
        return asm;
    }
}
