package procesador;
// Utilidades específicas de antlr
import antlr.*;
import org.antlr.v4.runtime.*;
// Utilidades generales
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
        // Parser para el análisis sintáctico y semántico
        vajaParser parser = new vajaParser(tokens, buildPath);
        tokens.fill();
        File tokensFile = new File(buildPath + "/tokens.txt");
        try (Writer buffer = new BufferedWriter(new FileWriter(tokensFile))) {
            for (Token tok : tokens.getTokens()) {
                buffer.write(tok.getText() + '\n');
            }
            buffer.close();
        }
        try {
            tokens.seek(0);
            parser.programaPrincipal();
            System.out.println("PROCESO COMPLETADO CON ÉXITO");
        } catch (RuntimeException e) {
            System.out.println(e.getMessage());
            File erroresFile = new File(buildPath + "/errores.txt");
            Writer buffer = new BufferedWriter(new FileWriter(erroresFile));
            buffer.write(e.getMessage());
            buffer.close();
        }
    }
}
