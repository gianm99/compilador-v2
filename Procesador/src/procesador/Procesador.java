package procesador;

import procesador.antlr.*;
import org.antlr.v4.runtime.*;
import java.io.*;
import org.apache.commons.io.*;

/**
 * Procesador. Programa que procesa un archivo de texto escrito en el lenguaje
 * inventado "vaja" y genera código intermedio, código ensamblador sin 
 * optimizar y código ensamblador optimizado.
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
        // Se crea una carpeta con el mismo nombre que el archivo

        // Parser para crear el árbol sintáctico
        vajaDOT parserARBOL = new vajaDOT(tokens, buildPath);

        tokens.fill();
        File tokensFile = new File(buildPath + "\\tokens.txt");
        try (Writer writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(tokensFile), "utf-8"))) {
            for (Token tok : tokens.getTokens()) {
                writer.write(tok.getText() + '\n');
            }
            writer.close();
        }

        try {
            tokens.seek(0);
            parser.programaPrincipal();
            tokens.seek(0);
            parserARBOL.programaPrincipal();
            System.out.println("Se ha completado el proceso de compilación");
        } catch (RuntimeException e) {
            System.out.println(e.getMessage());
            File erroresFile = new File(buildPath + "\\errores.txt");
            Writer writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(erroresFile), "utf-8"));
            writer.write(e.getMessage());
            writer.close();
        }
    }
}
