grammar vajaNUEVO;

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
}

@parser::members {
public TablaSimbolos ts;
boolean returnreq = false;
boolean returnenc = false;
Simbolo.TSub tiporeturn = null;
String errores="";
String directorio;

public vajaNUEVOParser(TokenStream input,String directorio){
	this(input);
	this.directorio=directorio;
}

@Override
public void notifyErrorListeners(Token offendingToken, String msg, RecognitionException ex)
{
	String notificacion = "ERROR SINTACTICO - Línea " + offendingToken.getLine()
	+ " Columna " + offendingToken.getCharPositionInLine() + ": \n\t ";
	String expected = msg;
	if(expected.contains("expecting")){
		expected = expected.substring(expected.indexOf("expecting") + 10);
		notificacion += "encontrado: '" + offendingToken.getText() + "' esperado: "+ expected;
	}else if(expected.contains("missing")){
		expected = expected.substring(expected.indexOf("missing") + 8);
		expected = expected.substring(0, expected.indexOf("at") - 1);
		notificacion += "encontrado: '" + offendingToken.getText() + "', falta "+ expected;
	}else if(expected.contains("alternative")){
		expected = expected.substring(expected.indexOf("input") + 6);
		notificacion += "no se reconoce " + expected;
	}
	notificacion = notificacion.replaceAll("Comparador","==, !=, <, >, <=, >=");
	notificacion = notificacion.replaceAll("OpBinSum","+, -");
	throw new RuntimeException(notificacion);
}
// DOT
Writer writer;
int dot = 0;
}

@lexer::members {
@Override
public void recover(RecognitionException ex)
{
	throw new RuntimeException("ERROR LEXICO -  "+ex.getMessage());
}
}

programa:
	{
	ts = new TablaSimbolos(directorio);
	// Insertar operaciones de input/output
	try {
		ts.inserta("read",new Simbolo("read",null,Simbolo.Tipo.FUNC,Simbolo.TSub.STRING));
		for(Simbolo.TSub tsub : Simbolo.TSub.values()) {
			if(tsub!=Simbolo.TSub.NULL) {
				Simbolo arg = new Simbolo("arg"+tsub,null,Simbolo.Tipo.ARG,tsub); 
				ts.inserta("print"+tsub,new Simbolo("print"+tsub,arg,Simbolo.Tipo.PROC,
				Simbolo.TSub.NULL));
			}
		}
	} catch (TablaSimbolos.TablaSimbolosException e) {}
	
} decls sents EOF {
	ts.saleBloque();
	if(!errores.isEmpty()) {
		throw new RuntimeException(errores);
	}
};

decls: decls decl | decl;

decl:
	VARIABLE tipo declVar[$tipo.tsub]
	| CONSTANT tipo declConst[$tipo.tsub]
	| FUNCTION encabezadoFunc BEGIN decls sents END
	| PROCEDURE encabezadoProc BEGIN decls sents END;

// Variables y constantes
declVar[Simbolo.TSub tsub]:
	ID {
	try{
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.VAR,$tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": variable "+$ID.getText()+
		"redeclarada\n";
	}
} (
		'=' expr {
	if($expr.tsub!=$tsub) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tsub+")";
	}
}
	)? ';';

declConst[Simbolo.TSub tsub]: ID {
	try {
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.CONST,$tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": constante "+$ID.getText()+
		"redeclarada\n";
	}
} '=' expr ';' {
	if($expr.tsub!=$tsub) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tsub+")";
	}
};

// Funciones y procedimientos
encabezadoFunc: tipo ID '(' parametros? ')';

encabezadoProc: ID '(' parametros? ')';

parametros: parametro ',' parametros | parametro;

parametro: tipo ID;

sents: sents sent | sent;

sent:
	IF expr BEGIN sents END
	| IF expr BEGIN sents END ELSE BEGIN sents END
	| WHILE expr BEGIN sents END
	| RETURN expr ';'
	| referencia ASSIGN expr
	| referencia;

referencia: ID | cont_idx ')';

cont_idx: cont_idx ',' expr | ID '(' expr;

expr
	returns[Simbolo.TSub tsub]:
	NOT expr
	| '(' expr ')'
	| literal
	| expr OPREL expr
	| expr AND expr
	| expr OR expr
	| expr MULT expr
	| expr DIV expr
	| expr ADD expr
	| expr SUB expr
	| SUB expr;

tipo
	returns[Simbolo.TSub tsub]: INTEGER | BOOLEAN | STRING;

literal: LiteralInteger | LiteralBoolean | LiteralString;

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