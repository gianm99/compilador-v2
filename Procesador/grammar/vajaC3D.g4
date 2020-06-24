grammar vajaC3D;
// options { tokenVocab = vajaNUEVOLexer; }

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
import procesador.*;
}

@parser::members {
Deque<Integer> pproc=new ArrayDeque<Integer>(); // Pila de procedimientos
TablaSimbolos ts;
TablaVariables tv;
TablaProcedimientos tp;
String directorio;
int pc = 0; // program counter
ArrayList<String> codigoIntermedio = new ArrayList<String>();

public vajaC3DParser(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
}

public void genera(String codigo){
	try{
		pc++;
		codigoIntermedio.add(codigo);
	}catch(IOException e){}
}

public void imprimirGenera(){
	try{
		BufferedWriter writer = new BufferedWriter(new FileWriter(intermedio));
		codigoIntermedio.forEach((s) -> writer.write(s));
		writer.close();
	}
	catch(FileNotFoundException e){
		System.out.println("Error al escribir el código intermedio en fichero");
	}
}

public void backpatch(Deque<Integer> lista, Etiqueta e){

}

public Deque<Integer> concat(Deque<Integer> dq1, Deque<Integer> dq2){
	while(dq2.size()>0){
		dq1.add(dq2.removeFirst());
	}
	return dq1;
}
}

programa: decls sents EOF;

decls: decls decl | decl;

decl:
	VARIABLE tipo ID ('=' expr)? ';'
	| CONSTANT tipo ID '=' expr ';'
	| FUNCTION tipo encabezado[$tipo.tsub] BEGIN decls sents END
	| PROCEDURE encabezado[null] BEGIN decls sents END;

encabezado[Simbolo.TSub tsub]
	returns[Simbolo met]: ID '(' parametros[$met]? ')';

parametros[Simbolo anterior]:
	parametro ',' parametros[$anterior.getNext()]
	| parametro;

parametro
	returns[Simbolo s]: tipo ID;

sents: sents sent | sent;

sent:
	IF expr BEGIN sents END
	| IF expr BEGIN sents END ELSE BEGIN sents END
	| WHILE expr BEGIN sents END
	| RETURN expr ';'
	| referencia ASSIGN expr ';'
	| referencia ';';

referencia
	returns[Variable r]: ID | ID '(' ')' | contIdx ')';

contIdx
	returns[Simbolo.TSub tsub]: ID '(' expr contIdx_[null];

contIdx_[Deque<Simbolo.TSub> pparams]:
	',' expr contIdx_[$pparams]
	|; // lambda

expr
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	// Lógicas
	NOT expr {
		$cierto = $expr.falso;
		$falso = $expr.cierto;
	}
	| expr {
		Variable r = $r;
    } OPREL expr {
		genera("if " + r + " " + OPREL.getText() + " " + $expr.r + " goto ");
		$cierto = pc;
		genera("goto ");
		$falso = pc;
    }
	| expr {
		Deque<Integer> cierto = $expr.cierto;
		Deque<Integer> falso = $expr.falso;
	} AND {
		Etiqueta e = new Etiqueta(pc);
		genera("e : skip");
	} expr {
		backpatch(cierto, e);
		$falso = concat(falso, $expr.falso);
		$cierto = $expr.cierto;
	}
	| expr {
		Deque<Integer> cierto = $expr.cierto;
		Deque<Integer> falso = $expr.falso;
	} OR {
		Etiqueta e = new Etiqueta(pc);
		genera("e : skip");
	} expr {
		backpatch(cierto, e);
		$falso = concat(falso, $expr.falso);
		$cierto = $expr.cierto;
	}
	// Aritméticas
	| SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = - " + $expr.r);
		$r = t;
	} expr {
		Variable r = $expr.r;
	} MULT expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = " + r + " * " + $expr.r);
		$r = t;
	} expr {
		Variable r = $expr.r;
	} DIV expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = " + r + " / " + $expr.r);
		$r = t;
	}
	| expr {
		Variable r = $expr.r;
	} ADD expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = " + r + " + " + $expr.r);
		$r = t;
	} expr {
		Variable r = $expr.r;
	} SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = " + r + " - " + $expr.r);
		$r = t;
	}
	| '(' expr ')' {
		$r = $expr.r;
	}
	| referencia {
		$r = $referencia.r;
	}
	| literal {
		Variable t = tv.nuevaVar(pproc.peek(), $literal.tsub);
		genera("t = " + $literal.tsub);
		$r = t;
		if($literal.tsub == BOOLEAN){
			if($literal.getText().equals('true')) {
				genera("goto ");
				$cierto = pc;
				$falso = null;
			} else {
				genera("goto ");
				$falso = pc;
				$cierto = null;
			}
		}
	};

tipo
	returns[Simbolo.TSub tsub]: INTEGER | BOOLEAN | STRING;

literal
	returns[Simbolo.TSub tsub]:
	LiteralInteger
	| LiteralBoolean
	| LiteralString;

// Palabras reservadas
VARIABLE: 'var';
CONSTANT: 'const';
FUNCTION: 'func';
PROCEDURE: 'proc';
RETURN: 'return';
// Tipos
INTEGER: 'int';
BOOLEAN: 'boolean';
STRING: 'string';
// Operaciones
WHILE: 'while';
IF: 'if';
ELSE: 'else';
// Enteros
LiteralInteger: DecimalLiteral;
fragment DecimalLiteral: DecimalPositivo | '0';
fragment DecimalPositivo: [1-9][0-9]*;
// Booleans
LiteralBoolean: 'true' | 'false';
// Cadenas
LiteralString: '"' LetrasString? '"';
fragment LetrasString: LetraString+;
fragment LetraString: ~["\\\r\n];
// Separadores
LPAREN: '(';
RPAREN: ')';
BEGIN: '{';
END: '}';
COMMA: ',';
SEMI: ';';
// Operadores
OPREL: EQUAL | NOTEQUAL | GT | LT | GE | LE;
OpBinSum: ADD | SUB;
ASSIGN: '=';
EQUAL: '==';
NOTEQUAL: '!=';
GT: '<';
LT: '>';
GE: '>=';
LE: '<=';
ADD: '+';
SUB: '-';
MULT: '*';
DIV: '/';
AND: '&&';
OR: '||';
NOT: '!';
// Identificador
ID: LETRA LETRADIGITO*;
fragment LETRA: [a-zA-Z$_];
fragment LETRADIGITO: [a-zA-Z$_0-9];
// Comentarios y espacios en blanco
WS: [ \r\n\t]+ -> skip;
BLOCK_COMMENT: '/*' .*? '*/' -> skip;
LINE_COMMENT: '#' ~[\r\n]* -> skip;