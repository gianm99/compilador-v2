grammar vajaC3D;

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
}

programaPrincipal:
	declaracion[programaPrincipal]* EOF;

declaracion[String padre]:
	'var' tipo declaracionVar[$tipo.tsub]
	| 'const' tipo declaracionConst[$tipo.tsub]
	| 'func' declFunc
	| 'proc' declProc
	| ';';

tipo
	returns[ Simbolo.TipoSubyacente tsub]:
	INT
	| BOOLEAN
	| STRING;
// Variables y constantes
declaracionVar[Simbolo.TipoSubyacente tsub]:
	Identificador ('=' initVar)? ';';

declaracionConst[Simbolo.TipoSubyacente tsub]:
	Identificador '=' initConst ';';

initVar
	returns[Simbolo.TipoSubyacente tsub]: expr;

initConst
	returns[Simbolo.TipoSubyacente tsub]: expr;

// Funciones y procedimientos
declFunc:
	encabezadoFunc cuerpoFunc[$encabezadoFunc.metodo];

encabezadoFunc
	returns[Simbolo metodo]: identificadorMetFunc tipo;

cuerpoFunc[Simbolo metodo]: bloque[$metodo] | ';';

declProc:
	encabezadoProc cuerpoProc[$encabezadoProc.metodo];

encabezadoProc
	returns[Simbolo metodo]: identificadorMetProc;

cuerpoProc[Simbolo metodo]: bloque[$metodo] | ';';

identificadorMetFunc
	returns[Simbolo metodo, int linea]:
	Identificador '(' parametros[$metodo]? ')';

identificadorMetProc
	returns[Simbolo metodo, int linea]:
	Identificador '(' parametros[$metodo]? ')';

parametros[Simbolo ant]:
	parametro ',' parametros[$ant.getNext()]
	| parametro;

parametro
	returns[Simbolo s]: tipo identificadorVar;

identificadorVar
	returns[String id]: Identificador;

bloque[Simbolo met]: '{' exprsBloque? '}';

exprsBloque: exprDeBloque+;

exprDeBloque: sentDeclVarLocal | sent;

sentDeclVarLocal:
	declaracionVarLocal[Simbolo.Tipo.VAR];

declaracionVarLocal[Simbolo.Tipo t]:
	tipo declaracionVar[$tipo.tsub];

sent:
	bloque[null]
	| sentVacia
	| sentExpr
	| sentIf
	| sentIfElse
	| sentWhile
	| sentReturn;

sentVacia: ';';

sentExpr: exprSent ';';

exprSent: asignacion | sentInvocaMet;

sentIf: IF '(' expr ')' bloque[null];

sentIfElse:
	IF '(' expr ')' bloque[null] ELSE bloque[null];

sentWhile: WHILE '(' expr ')' bloque[null];

sentReturn: RETURN expr ';';

sentInvocaMet
	returns[Simbolo.TipoSubyacente tsub]:
	Identificador '(' (
		argumentos[$Identificador.getText(), $Identificador.getLine()]
	)? ')';

argumentos[String nombre, int linea]: expr (',' expr)*;

asignacion
	returns[ Simbolo.TipoSubyacente tsub ]:
	Identificador '=' expr;

expr
	returns[ Simbolo.TipoSubyacente tsub]:
	exprCondOr
	| asignacion;

exprCondOr
	returns[ Simbolo.TipoSubyacente tsub]:
	exprCondAnd exprCondOr_;

exprCondOr_
	returns[ Simbolo.TipoSubyacente tsub]:
	OR exprCondAnd exprCondOr_
	|; //lambda

exprCondAnd
	returns[ Simbolo.TipoSubyacente tsub]: exprComp exprCondAnd_;

exprCondAnd_
	returns[ Simbolo.TipoSubyacente tsub]:
	AND exprComp exprCondAnd_
	|; //lambda

exprComp
	returns[ Simbolo.TipoSubyacente tsub]: exprSuma exprComp_;

exprComp_
	returns[ Simbolo.TipoSubyacente tsub]:
	Comparador exprSuma exprComp_
	|; //lambda

exprSuma
	returns[ Simbolo.TipoSubyacente tsub]: exprMult exprSuma_;

exprSuma_
	returns[ Simbolo.TipoSubyacente tsub]:
	OpBinSum exprMult exprSuma_
	|; //lambda

exprMult
	returns[ Simbolo.TipoSubyacente tsub ]: exprUnaria exprMult_;

exprMult_
	returns[ Simbolo.TipoSubyacente tsub ]:
	MULT exprUnaria exprMult_
	| DIV exprUnaria exprMult_
	|; //lambda

exprUnaria
	returns[ Simbolo.TipoSubyacente tsub ]:
	OpBinSum exprNeg
	| exprNeg;

exprNeg
	returns[ Simbolo.TipoSubyacente tsub ]:
	NOT exprUnaria
	| exprPostfija;

exprPostfija
	returns[ Simbolo.TipoSubyacente tsub ]:
	primario
	| Identificador
	| sentInvocaMet;

primario
	returns[ Simbolo.TipoSubyacente tsub ]:
	'(' expr ')'
	| literal;

literal
	returns[ Simbolo.TipoSubyacente tsub ]:
	LiteralInteger
	| LiteralBoolean
	| LiteralString;
