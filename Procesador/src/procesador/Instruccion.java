package procesador;

public class Instruccion {

    private OP codigo;
    private String[] instruccion = new String[4];

    public enum OP {
        copy, add, sub, mult, div, mod, neg, and, or, not, et, condLT, condLE, condEQ, condNEQ, condGE, condGT, incond, LT, LE, EQ, NEQ, GE, GT, init, call, ret, params
    }

    public Instruccion(OP codigo, String op1, String op2, String op3) {
        this.codigo = codigo;
        this.instruccion[1] = op1;
        this.instruccion[2] = op2;
        this.instruccion[3] = op3;
        switch (codigo) {
            case add:
                instruccion[0] = "+";
                break;
            case sub:
            case neg:
                instruccion[0] = "-";
                break;
            case mult:
                instruccion[0] = "*";
                break;
            case div:
                instruccion[0] = "/";
                break;
            case and:
                instruccion[0] = "&&";
                break;
            case or:
                instruccion[0] = "||";
                break;
            case copy:
                instruccion[0] = "=";
                break;
            case LT:
                instruccion[0] = "<";
                break;
            case LE:
                instruccion[0] = "<=";
                break;
            case EQ:
                instruccion[0] = "==";
                break;
            case NEQ:
                instruccion[0] = "!=";
                break;
            case GE:
                instruccion[0] = ">=";
                break;
            case GT:
                instruccion[0] = ">";
                break;
            case not:
                instruccion[0] = "!";
                break;
            case et:
                instruccion[0] = "skip";
                break;
            case condLT:
                instruccion[0] = "<";
                break;
            case condLE:
                instruccion[0] = "<=";
                break;
            case condEQ:
                instruccion[0] = "==";
                break;
            case condNEQ:
                instruccion[0] = "!=";
                break;
            case condGE:
                instruccion[0] = ">=";
                break;
            case condGT:
                instruccion[0] = ">";
                break;
            case incond:
                instruccion[0] = "goto";
                break;
            case init:
                instruccion[0] = "pmb";
                break;
            case call:
                instruccion[0] = "call";
                break;
            case ret:
                instruccion[0] = "rtn";
                break;
            case params:
                instruccion[0] = "param_s";
                break;
        }
    };

    @Override
    public String toString() {
        String s = "";
        switch (codigo) {
            case add:
            case sub:
            case mult:
            case div:
            case and:
            case or:
                s = instruccion[3] + " = " + instruccion[1] + " " + instruccion[0] + " "
                        + instruccion[2];
                break;
            case copy:
                s = instruccion[3] + " " + instruccion[0] + " " + instruccion[1];
                break;
            case LT:
            case LE:
            case EQ:
            case NEQ:
            case GE:
            case GT:
                s = instruccion[1] + " " + instruccion[0] + " " + instruccion[2];
                break;
            case neg:
                s = instruccion[3] + " = " + instruccion[0] + instruccion[1];
                break;
            case not:
                s = instruccion[3] + " = " + instruccion[0] + " " + instruccion[1];
                break;
            case et:
                s = instruccion[3] + ": " + instruccion[0];
                break;
            case condLT:
            case condLE:
            case condEQ:
            case condNEQ:
            case condGE:
            case condGT:
                s = "if " + instruccion[1] + " " + instruccion[0] + " "
                        + instruccion[2] + " goto " + instruccion[3];
                break;
            case incond:
            case init:
            case call:
            case ret:
            case params:
                s = instruccion[0] + " " + instruccion[3];
                break;
            default:
                s = "Error instrucción";
                break;
        }
        return s;
    }

    public OP getCodigo() {
        return codigo;
    }

    public void setCodigo(OP codigo) {
        this.codigo = codigo;
    }

    public String[] getOperando() {
        return instruccion;
    }

    public void setOperando(String[] instruccion) {
        this.instruccion = instruccion;
    }

    public void setInstruccion3(String instruccion) {
        this.instruccion[3] = instruccion;
    }
}
