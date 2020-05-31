parser grammar vajaC3D;

options { tokenVocab=vajaLexer; }

@header {
	package antlr;
	import procesador.*;
	import java.io.*;
    import java.util.*;
	import procesador.*;
}

@parser::members {
	TablaVariables variables;
	TablaProcedimientos procedimientos;
	String directorio;
}

// TODO Jordi
programaPrincipal: declaracion* EOF;

declaracion:
	'var' tipo declaracionVar
	| 'const' tipo declaracionConst
	| 'func' declFunc
	| 'proc' declProc
	| ';';

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

sent:
	bloque
	| sentVacia
	| sentExpr
	| sentIf
	| sentIfElse
	| sentWhile
	| sentReturn;

//TODO Gian
sentVacia: ';';

sentExpr: exprSent ';';

exprSent: asignacion | sentInvocaMet;

sentIf: IF '(' expr ')' bloque;

sentIfElse: IF '(' expr ')' bloque ELSE bloque;

sentWhile: WHILE '(' expr ')' bloque;

sentReturn: RETURN expr ';';

sentInvocaMet: Identificador '(' ( argumentos)? ')';

argumentos: expr (',' expr)*;

asignacion: Identificador '=' expr;

expr: exprCondOr | asignacion;

exprCondOr: exprCondAnd exprCondOr_;

exprCondOr_: OR exprCondAnd exprCondOr_ |; //lambda

exprCondAnd: exprComp exprCondAnd_;

exprCondAnd_: AND exprComp exprCondAnd_ |; //lambda

exprComp: exprSuma exprComp_;

exprComp_: Comparador exprSuma exprComp_ |; //lambda

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
