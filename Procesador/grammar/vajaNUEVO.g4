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
Simbolo.TipoSubyacente tiporeturn = null;
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

programaPrincipal: declaracion* sent* EOF;

declaracion:
	'var' tipo declaracionVar
	| 'const' tipo declaracionConst
	| 'func' declFunc
	| 'proc' declProc;

tipo: INT | BOOLEAN | STRING;
// Variables y constantes
declaracionVar: Identificador ('=' initVar)? ';';

declaracionConst: Identificador '=' initConst ';';

initVar: expr;

initConst: expr;

// Funciones y procedimientos
declFunc: encabezadoFunc cuerpoFunc;

encabezadoFunc: identificadorMetFunc tipo;

cuerpoFunc: bloque | ';';

declProc: encabezadoProc cuerpoProc;

encabezadoProc: identificadorMetProc;

cuerpoProc: bloque | ';';

identificadorMetFunc: Identificador '(' parametros? ')';

identificadorMetProc: Identificador '(' parametros? ')';

parametros: parametro ',' parametros | parametro;

parametro: tipo identificadorVar;

identificadorVar: Identificador;

bloque: '{' exprsBloque? '}';

exprsBloque: exprDeBloque+;

exprDeBloque: sentDeclVarLocal | sent;

sentDeclVarLocal: declaracionVarLocal;

declaracionVarLocal: tipo declaracionVar;

sents: sents sent | sent;

// sent: bloque | sentExpr | sentIf | sentIfElse | sentWhile | sentReturn | ';';
sent:
	IF expr BEGIN sents END
	| IF expr BEGIN sents END ELSE BEGIN sents END
	| WHILE expr BEGIN sents END
	| referencia ASSIGN expr
	| RETURN expr ';';

referencia: Identificador;

sentExpr: exprSent ';';

exprSent: asignacion | sentInvocaMet;

// sentIf: IF '(' expr ')' bloque;

// sentIfElse: IF '(' expr ')' bloque ELSE bloque;

// sentWhile: WHILE '(' expr ')' bloque;

// sentReturn: RETURN expr ';';

sentInvocaMet: Identificador '(' ( argumentos)? ')';

argumentos: expr (',' expr)*;

asignacion: Identificador '=' expr;

// expr: exprCondOr | asignacion;
expr:
	expr OPREL expr
	| NOT expr
	| expr AND expr
	| expr OR expr
	| expr ADD expr
	| expr SUB expr
	| expr MULT expr
	| expr DIV expr
	| expr expr
	| LPAREN expr RPAREN
	| literal;

exprCondOr: exprCondAnd exprCondOr_;

exprCondOr_: OR exprCondAnd exprCondOr_ |; //lambda

exprCondAnd: exprComp exprCondAnd_;

exprCondAnd_: AND exprComp exprCondAnd_ |; //lambda

exprComp: exprSuma exprComp_;

exprComp_: OPREL exprSuma exprComp_ |; //lambda

exprSuma: exprMult exprSuma_;

exprSuma_: OpBinSum exprMult exprSuma_ |; //lambda

exprMult: exprUnaria exprMult_;

exprMult_:
	MULT exprUnaria exprMult_
	| DIV exprUnaria exprMult_
	|; //lambda

exprUnaria: OpBinSum exprNeg | exprNeg;

exprNeg: NOT exprUnaria | exprPostfija;

exprPostfija: primario | Identificador | sentInvocaMet;

primario: '(' expr ')' | literal;

literal: LiteralInteger | LiteralBoolean | LiteralString;

// Palabras reservadas
VAR: 'var';
CONST: 'const';
FUNCTION: 'func';
PROCEDURE: 'proc';
RETURN: 'return';

// Tipos
INT: 'int';
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
Identificador: LETRA LETRADIGITO*;

fragment LETRA: [a-zA-Z$_];

fragment LETRADIGITO: [a-zA-Z$_0-9];

// Comentarios y espacios en blanco
WS: [ \r\n\t]+ -> skip;

BLOCK_COMMENT: '/*' .*? '*/' -> skip;

LINE_COMMENT: '#' ~[\r\n]* -> skip;