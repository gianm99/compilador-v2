package procesador;

import antlr.*;
import org.antlr.v4.runtime.*;
import java.io.*;
import org.apache.commons.io.*;

/**
 * Procesador. Programa que procesa un archivo de texto escrito en el lenguaje
 * inventado "vaja" y genera código intermedio, código ensamblador sin optimizar
 * y código ensamblador optimizado.
 *
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class Procesador {

    public static void main(String[] args) throws Exception {
        String filename = FilenameUtils.getBaseName(args[0]);
        String buildPath = "pruebas\\build\\" + filename + "\\";
        File buildDir = new File(buildPath);
        if (!buildDir.mkdirs()) {
            // Si ya existe la carpeta, se vacía
            FileUtils.cleanDirectory(buildDir);
        }
        // Stream del archivo paso como argumento
        CharStream stream = CharStreams.fromFileName(args[0]);
        // Se crea el lexer y el CommonTokenStream
        vajaLexer lexer = new vajaLexer(stream);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        tokens.fill();
        File tokensFile = new File(buildPath + "tokens.txt");
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
            File erroresFile = new File(buildPath + "errores.txt");
            Writer buffer = new BufferedWriter(new FileWriter(erroresFile));
            if (e != null) {
                buffer.write(e.getMessage());
            }
            buffer.close();
            return;
        }
        // Generación de código intermedio
        vajaC3D parserC3D;
        parserC3D = new vajaC3D(tokens, buildPath + filename, parser.ts);
        try {
            tokens.seek(0);
            parserC3D.programa();
            System.out.println(ConsoleColors.BLUE_BOLD_BRIGHT
                    + "Proceso de generación de código completado con éxito" + ConsoleColors.RESET);
        } catch (RuntimeException e) {
            System.out.println(
                    ConsoleColors.RED_BOLD + "Error al generar código:" + ConsoleColors.RESET);
            throw e;
        }
        // Ensamblado de código sin optimizar
        Ensamblador normal = new Ensamblador(buildPath + filename, parserC3D.getC3D(),
                parserC3D.getTv(), parserC3D.getTp(), parserC3D.getTe());
        normal.ensamblar();
        // Optimización de código
        parserC3D.getTv().tablaHTML(buildPath + "/tablavariables.html");
        parserC3D.getTp().tablaHTML(buildPath + "/tablaprocedimientos.html");
        Optimizador optimizador = new Optimizador(buildPath + filename + "_OPT", parserC3D.getC3D(),
                parserC3D.getTv(), parserC3D.getTp(), parserC3D.getTe());
        optimizador.optimizar();
        optimizador.getTv().tablaHTML(buildPath + "/tablavariables_OPT.html");
        // Ensamblado de código optimizado
        Ensamblador optimizado = new Ensamblador(buildPath + filename + "_OPT",
                optimizador.getC3D(), optimizador.getTv(), optimizador.getTp(),
                optimizador.getTe());
        optimizado.ensamblar();
    }
}
