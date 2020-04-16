package antlrprocesador;

import org.antlr.v4.runtime.*;
import java.io.*;


/**
 *
 * @author gianm
 */

public class Procesador {
    static int var1,var2,var3;
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception{
		CharStream stream = new ANTLRFileStream(args[0]);
		vajaLexer lexer = new vajaLexer(stream);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		vajaParser parser = new vajaParser(tokens);
		vajaDOT parserDOT = new vajaDOT(tokens);

        tokens.fill();
        try (Writer writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("TOKENS.txt"), "utf-8"))) {
            for ( Token tok : tokens.getTokens() ) {
               writer.write(tok.getText() + '\n');
            }
            writer.close();
        }

		try {
			tokens.seek(0);
			parser.programaPrincipal();
			tokens.seek(0);
			parserDOT.programaPrincipal();
			System.out.println("Compilación terminada");
		} catch (RuntimeException e) {
			System.out.println(e.getMessage());
			Writer writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("ERRORES.txt"), "utf-8"));
			writer.write(e.getMessage());
			writer.close();
		}
	}
}
