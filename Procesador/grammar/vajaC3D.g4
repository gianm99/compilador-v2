parser grammar vajaC3D;

options
{
tokenVocab = vajaANTIGUOLexer;
}

@parser::header {
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
	} (declaracion | sents)* EOF;

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

//TODO Gian
sents: sents sent | sent;

sent
	returns[ ArrayList<Integer> sig]:
	sentExpr
	| IF '(' expr ')' {
		Etiqueta e=new Etiqueta(pc);
		genera(e+": skip\n");
	} bloque {
		//backpatch(expr.cierto, e);
		$sig=new ArrayList<Integer>();
		// $sig.addAll(expr.falso);
		// $sig.addAll(bloque.sig);
	}
	| IF '(' expr ')' {
		Etiqueta e1=new Etiqueta(pc);
		genera(e1+": skip\n");
	} bloque ELSE {
		$sig=new ArrayList<Integer>();
		// $sig.addAll(bloque.sig); // concatenar bloque 1
		Etiqueta e2=new Etiqueta(pc);
		genera(e2+": skip\n");
	} bloque {
		// backpatch(expr.cierto,e1);
		// backpatch(expr.falso,e2);
		// $sig.addAll(bloque.sig); // concatenar bloque 2
	}
	| WHILE {
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
	}
	| RETURN expr ';';

sentExpr
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprSent ';';

exprSent
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	asignacion
	| sentInvocaMet;

sentInvocaMet
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	Identificador '(' (argumentos)? ')';

argumentos: expr (',' expr)*;

asignacion
	returns[ ArrayList<Integer> sig]:
	Identificador '=' expr {
	Etiqueta ec,ef,efin;
	Simbolo.TSub idTsub = null;
	$sig=new ArrayList<Integer>();
	try{
		idTsub=simbolos.consulta($Identificador.getText()).getTsub();
		if(idTsub==Simbolo.TSub.BOOLEAN){
			ec=new Etiqueta(pc);
			ef=new Etiqueta(pc);
			efin=new Etiqueta(pc);
			genera(ec+": skip");
			// genera(Identificador);
		}
	}catch(TablaSimbolos.TablaSimbolosException ex){}
 };

expr
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprCondOr
	| asignacion;

exprCondOr
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprCondAnd exprCondOr_;

exprCondOr_
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	OR {
		Etiqueta e=new Etiqueta(pc);
		genera(e+": skip\n");
	}exprCondAnd exprCondOr_
	|; //lambda

exprCondAnd
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprComp exprCondAnd_;

exprCondAnd_
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	AND {
		Etiqueta e=new Etiqueta(pc);
		genera(e+": skip\n");
	}exprComp exprCondAnd_
	|; //lambda

exprComp
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprSuma exprComp_;

exprComp_
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	OPREL exprSuma exprComp_
	|; //lambda

exprSuma
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprMult exprSuma_;

exprSuma_
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	OpBinSum exprMult exprSuma_
	|; //lambda

exprMult
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	exprUnaria exprMult_;

exprMult_
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	MULT exprUnaria exprMult_
	| DIV exprUnaria exprMult_
	|; //lambda

exprUnaria
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	OpBinSum exprNeg
	| exprNeg;

exprNeg
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	NOT exprUnaria { 
		$cierto=$exprUnaria.falso;
		$falso=$exprUnaria.cierto;
	}
	| exprPostfija;

exprPostfija
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	primario {
		$cierto=$primario.cierto;
		$falso=$primario.falso;
	}
	| Identificador
	| sentInvocaMet;

primario
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	'(' expr ')' {
		$cierto=$expr.cierto;
		$falso=$expr.falso;
	}
	| literal {
		$cierto=$literal.cierto;
		$falso=$literal.falso;
	};

literal
	returns[ ArrayList<Integer> cierto, ArrayList<Integer> falso]:
	LiteralInteger
	| LiteralBoolean {
		genera("goto $$$\n");
		$cierto=new ArrayList<Integer>();
		$falso=new ArrayList<Integer>();
		if($LiteralBoolean.getText().equals("true"))
		{
			$cierto.add(pc); // true
		}else{
			$falso.add(pc); // false
		}
	}
	| LiteralString;
