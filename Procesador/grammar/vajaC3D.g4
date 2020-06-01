parser grammar vajaC3D;

options
{
	tokenVocab = vajaLexer;
}

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
import procesador.*;
}

@parser::members {
TablaSimbolos simbolos;
TablaVariables variables;
TablaProcedimientos procedimientos;
String directorio;
Writer writer;
int pc = 0; // program counter

public vajaC3D(TokenStream input, String directorio, TablaSimbolos simbolos){
	this(input);
	this.directorio=directorio;
	this.simbolos=simbolos;
}

public void genera(String codigo){
	try{
		pc++;
		writer.write(codigo);
	}catch(IOException e){}
}
}

// TODO Jordi
programaPrincipal:
	{
		try{
			File c3dFile=new File(this.directorio+"/c3d.txt");
			writer=new BufferedWriter(new FileWriter(c3dFile));
		}catch(Exception e){}
	} declaracion* EOF;

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

sentIf
	returns[ ArrayList<Integer> sig]:
	IF '(' expr ')' {
		Etiqueta e=new Etiqueta(pc);
		genera(e+": skip\n");
	} bloque {
		//backpatch(expr.cierto, e);
		$sig=new ArrayList<Integer>();
		// $sig.addAll(expr.falso);
		// $sig.addAll(bloque.sig);
	};

sentIfElse
	returns[ ArrayList<Integer> sig]:
	IF '(' expr ')' {
		Etiqueta e1=new Etiqueta(pc);
		genera(e1+": skip\n");
	} bloque ELSE {
		// $sig=new ArrayList<Integer>();
		// $sig.addAll(bloque.sig); // concatenar bloque 1
		Etiqueta e2=new Etiqueta(pc);
		genera(e2+": skip\n");
	} bloque {
		// backpatch(expr.cierto,e1);
		// backpatch(expr.falso,e2);
		// $sig.addAll(bloque.sig); // concatenar bloque 2
};

sentWhile
	returns[ ArrayList<Integer> sig ]:
	WHILE {
	Etiqueta e1=new Etiqueta(pc);
	genera(e1+": skip\n");
} '(' expr ')' {
	Etiqueta e2=new Etiqueta(pc);
	genera(e2+": skip\n");
} bloque {
	// backpatch(expr.cierto,e2);
	// backpatch(bloque.sig, e1);
	// $sig=expr.falso;
	genera("goto "+e1+"\n");
};

sentReturn: RETURN expr ';';

sentInvocaMet: Identificador '(' ( argumentos)? ')';

argumentos: expr (',' expr)*;

asignacion returns [ ArrayList<Integer> sig]:
	Identificador '=' expr {
	Etiqueta ec,ef,efin;
	Simbolo.TipoSubyacente idTsub = null;
	$sig=new ArrayList<Integer>();
	try{
		idTsub=simbolos.consulta($Identificador.getText()).getTs();
		if(idTsub==Simbolo.TipoSubyacente.BOOLEAN){
			ec=new Etiqueta(pc);
			ef=new Etiqueta(pc);
			efin=new Etiqueta(pc);
			genera(ec+": skip");
			// genera(Identificador);
		}		
	}catch(TablaSimbolos.exceptionTablaSimbolos ex){}
 };

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
