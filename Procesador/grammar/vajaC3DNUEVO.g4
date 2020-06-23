
grammar vajaC3DNUEVO;
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
Writer writer;
int pc = 0; // program counter

public vajaC3DNUEVOParser(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
}

public void genera(String codigo){
	try{
		pc++;
		writer.write(codigo);
	}catch(IOException e){}
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
	returns[Simbolo.TSub tsub]:
	ID '(' expr contIdx_[null];

contIdx_[Deque<Simbolo.TSub> pparams]:
	',' expr contIdx_[$pparams]
	|; // lambda

expr
	returns[Variable r]:
	// Lógicas
	NOT expr {
		
	}
	| expr{

    } OPREL expr {

    }
	| expr AND expr
	| expr OR expr
	// Aritméticas
	| SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.VAR);
		genera("t = - " + $expr.r);
		$r = t;
	}
	| expr MULT expr
	| expr DIV expr
	| expr ADD expr
	| expr SUB expr
	| '(' expr ')'
	| referencia {
		$r = $referencia.r;
	}
	| literal {
		Variable t = tv.nuevaVar(pproc.peek(), $literal.tsub);
		genera("t = " + $literal.tsub);
		$r = t;
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