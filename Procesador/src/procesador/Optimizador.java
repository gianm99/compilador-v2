package procesador;
import java.util.ArrayList;

public class Optimizador {
    
    private ArrayList<StringBuilder> codigo = new ArrayList<>();

    public Optimizador(final ArrayList<StringBuilder> codigo){
        this.codigo = codigo;
    }

    public ArrayList<StringBuilder> peephole(){
        final ArrayList<StringBuilder> aux = new ArrayList<>(codigo);

        return aux;
    }
    //Finestreta 1º
    private String[] optimizarIf(final ArrayList<String> codigo){
        String[] res = new String[codigo.size()-2];

        //Dividir el string con el if en tokens separados por un espacio para manipular el contenido
        String sIf = codigo.get(0);
        String[] splitIf = sIf.split("\\s+");
        splitIf[1] = "!"+ splitIf[1];
        //Cambiar el goto e1 por goto e2
        splitIf[splitIf.length - 2] = codigo.get(1);
        splitIf[splitIf.length - 1] = "";
        //Añadir al string resultado los cambios hechos
        res[0] = splitIf.toString();
        for(int i = 3; i<codigo.size()-1; i++){
            res[i-2] = codigo.get(i);
        }
        return res;
    }
    //Finestreta 2º
    private String[] optimizarSaltoIf(final ArrayList<String> codigo){
        String[] res = new String[codigo.size()-1];

        //Dividir el string con el if en tokens separados por un espacio para manipular el contenido
        String sIf = codigo.get(0);
        String[] splitIf = sIf.split("\\s+");
        //Cambiar el goto e1 por goto e2
        splitIf[splitIf.length - 2] = codigo.get(codigo.size()-1);
        splitIf[splitIf.length - 1] = "";
        //Añadir al string resultado los cambios hechos
        res[0] = splitIf.toString();
        for(int i = 1; i<res.length - 1; i++){
            res[i] = codigo.get(i);
        }
        res[res.length-1] = codigo.get(codigo.size()-1);
        return res;
    }
    //Finestreta 3º
    private String optimizarAssigBool(final ArrayList<String> codigo){
        String res = "";

        //Sacar las variables booleanas del código
        String sIf = codigo.get(0);
        String[] splitIf = sIf.split("\\s+");
        String sA = codigo.get(3);
        String[] splitA = sA.split("\\s+");
        //Hacer la asignación
        res = splitA[0] + " = " + splitIf[1];
        return res;
    }
    //Finestreta 4º (op)
    private String optimizarOpConstante(String s){
        String res = "";
        //s --> var = const OpArit const;
        String[] splits = s.split("\\s+");
        int c1 = Integer.parseInt(splits[2]);
        int c2 = Integer.parseInt(splits[4]);
        int v = 0;
        switch (splits[3]){
            case "+":
                v = c1 + c2;
                break; 
            case "-":
                v = c1 - c2;
                break;
            case "*":
                v = c1 * c2;
                break;
            case "/":
                v = c1 / c2;
                break;
        }
        res = splits[0] + " " + splits[1] + " " + String.valueOf(v);
        return res;
    }
    //Finestreta 4º (If)
    private String optimizarIfConstante(final ArrayList<String> codigo, boolean condicion){
        String res = "";
        //Devuelve el goto resultante del if
        if (condicion){
            String sIf = codigo.get(0);
            String[] splitIf = sIf.split("\\s+");
            res = splitIf[splitIf.length - 2].concat(splitIf[splitIf.length - 1]);
        } else {
            res = codigo.get(1);
        }
        return res;
    }
    //Finestreta 5º
    private String[] optimizarCodigoInaccesible(final ArrayList<String> codigo){
        String[] res = new String[2];
        /*
            goto e1
            .
            .   --> No hay ninguna instrucción de salto en el bloque --> Se elimina
            .
            e1: skip        
        */ 
        res[0] = codigo.get(0);
        res[1] = codigo.get(codigo.size()-1);
        return res;
    }
    //Finestreta 7º (Variable - Constante)
    private String optimizarVarConst(final String s){
        String res = "";
        //s --> v = v {+, *} c --> v = c {+, *} v
        String[] splits = s.split("\\s+");
        if(splits[3].equals("+") || splits[3].equals("*")){
            res = splits[0] + " " + splits[1] + " " + splits[4] + " " + splits[3] + " " + splits[2];
        }
        return res;
    }
    //Finestreta 8º
    private String optimizarVarTemp(final String s1, final String s2){
        String res = "";
        //s1 --> t = ...
        //s2 --> x = t
        String[] splits1 = s1.split("=");
        String[] splits2 = s2.split("=");
        res = splits2[0].concat("=" + splits1[1]);
        return res;
    }
}