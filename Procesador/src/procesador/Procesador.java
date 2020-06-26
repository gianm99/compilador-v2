package procesador;

import antlr.*;
import org.antlr.v4.runtime.*;
import java.io.*;
import org.apache.commons.io.*;

/**
 * Procesador. Programa que procesa un archivo de texto escrito en el lenguaje inventado "vaja" y
 * genera código intermedio, código ensamblador sin optimizar y código ensamblador optimizado.
 *
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class Procesador {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception {
        String buildPath = "pruebas/build/" + FilenameUtils.getBaseName(args[0]);
        File buildDir = new File(buildPath);
        if (!buildDir.mkdirs()) {
            // Si ya existe la carpeta, se vacía
            FileUtils.cleanDirectory(buildDir);
        }
        // Stream del archivo pasado como argumento
        CharStream stream = CharStreams.fromFileName(args[0]);
        // Se crea el lexer y el CommonTokenStream
        vajaLexer lexer = new vajaLexer(stream);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        tokens.fill();
        File tokensFile = new File(buildPath + "/tokens.txt");
        try (Writer buffer = new BufferedWriter(new FileWriter(tokensFile))) {
            for (Token tok : tokens.getTokens()) {
                buffer.write(tok.getText() + '\n');
            }
            buffer.close();
        }
        // Análisis del código fuente
        vajaParser parser = new vajaParser(tokens, buildPath);
        try {
            tokens.seek(0);
            parser.programa();
            System.out.println(ConsoleColors.GREEN_BOLD_BRIGHT
                    + "Proceso de análisis completado con éxito" + ConsoleColors.RESET);
        } catch (RuntimeException e) {
            System.out.println("Se encontraron errores en el código:");
            System.out.println(ConsoleColors.RED_BOLD + e.getMessage() + ConsoleColors.RESET);
            File erroresFile = new File(buildPath + "/errores.txt");
            Writer buffer = new BufferedWriter(new FileWriter(erroresFile));
            if (e != null) {
                buffer.write(e.getMessage());
            }
            buffer.close();
            return;
        }
        // Generación de código intermedio
        vajaC3D parserC3D;
        parserC3D = new vajaC3D(tokens, buildPath, parser.ts);
        try {
            tokens.seek(0);
            parserC3D.programa();
            System.out.println(ConsoleColors.BLUE_BOLD_BRIGHT
                    + "Proceso de generación de código completado con éxito" + ConsoleColors.RESET);
        } catch (RuntimeException e) {
            System.out.println(ConsoleColors.RED_BOLD + "Error al generar código: " + e.getMessage()
                    + ConsoleColors.RESET);
        }
    }
}
