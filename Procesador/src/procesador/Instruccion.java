package procesador;

public class Instruccion {

    private OP opCode;
    private String[] instruccion = new String[4];
    private boolean instFinal;

    public enum OP {
        copy, add, sub, mult, div, neg, and, or, not, skip, ifLT, ifLE, ifEQ, ifNE, ifGE, ifGT, jump, LT, LE, EQ, NEQ, GE, GT, pmb, call, ret, params
    }

    public Instruccion(OP opCode, String op1, String op2, String op3) {
        this.opCode = opCode;
        this.instruccion[1] = op1;
        this.instruccion[2] = op2;
        this.instruccion[3] = op3;
        switch (opCode) {
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
        case skip:
            instruccion[0] = "skip";
            break;
        case ifLT:
            instruccion[0] = "<";
            break;
        case ifLE:
            instruccion[0] = "<=";
            break;
        case ifEQ:
            instruccion[0] = "==";
            break;
        case ifNE:
            instruccion[0] = "!=";
            break;
        case ifGE:
            instruccion[0] = ">=";
            break;
        case ifGT:
            instruccion[0] = ">";
            break;
        case jump:
            instruccion[0] = "goto";
            break;
        case pmb:
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
    }

    public boolean isInstFinal() {
        return instFinal;
    }

    public void setInstFinal(boolean instFinal) {
        this.instFinal = instFinal;
    }

    @Override
    public String toString() {
        String s = "";
        switch (opCode) {
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
        case skip:
            s = instruccion[3] + ": " + instruccion[0];
            break;
        case ifLT:
        case ifLE:
        case ifEQ:
        case ifNE:
        case ifGE:
        case ifGT:
            s = "if " + instruccion[1] + " " + instruccion[0] + " " + instruccion[2] + " goto "
                    + instruccion[3];
            break;
        case jump:
        case pmb:
        case call:
        case ret:
            s = instruccion[0] + " " + instruccion[3];
            if (instruccion[1] != null) {
                s = s + ", " + instruccion[1];
            }
            break;
        case params:
            s = instruccion[0] + " " + instruccion[3];
            break;
        }
        return s;
    }

    public String[] getInstruccion() {
        return instruccion;
    }

    public void setInstruccion(String[] instruccion) {
        this.instruccion = instruccion;
    }

    public String getOperando(int n) {
        return instruccion[n];
    }

    public void setOperando(int n, String operando) {
        this.instruccion[n] = operando;
    }

    public String destino() {
        return instruccion[3];
    }

    public void setEtiqueta(String etiqueta) {
        this.instruccion[3] = etiqueta;
    }

    public OP getOpCode() {
        return opCode;
    }
}
