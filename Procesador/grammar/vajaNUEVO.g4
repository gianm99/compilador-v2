grammar vajaNUEVO;

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
}

@parser::members {
public TablaSimbolos ts;
String errores="";
String directorio;
Deque<Simbolo> pproc=new ArrayDeque<Simbolo>(); // Pila de procedimientos

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
	VARIABLE tipo ID {
	try{
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.VAR,$tipo.tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": variable "+$ID.getText()+
		"redeclarada\n";
	}
} (
		'=' expr {
	if($expr.tsub!=$tipo.tsub) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tipo.tsub+")\n";
	}
}
	)? ';'
	| CONSTANT tipo ID {
	try {
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.CONST,$tipo.tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": constante "+$ID.getText()+
		"redeclarada\n";
	}
} '=' expr ';' {
	if($expr.tsub!=$tipo.tsub) {
		errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tipo.tsub+")\n";
	}
}
	| FUNCTION tipo encabezado[$tipo.tsub] BEGIN {
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+= e.getMessage();
			}
			param=param.getNext();
		}
	} decls sents END {
		ts=ts.saleBloque();
		pproc.pop();
		if(!$encabezado.met.returnEncontrado) {
			errores+="ERROR SEMÁNTICO - Línea "+$FUNCTION.getLine()+
			": 'return' no encontrado para la función "+$encabezado.met.getId()+"\n";
		}
	}
	| PROCEDURE encabezado[null] BEGIN {
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+= e.getMessage();
			}
			param=param.getNext();
		}
	} decls sents END {
		ts=ts.saleBloque();
		pproc.pop();
		if($encabezado.met.returnEncontrado) {
			errores+="ERROR SEMÁNTICO - Línea "+$PROCEDURE.getLine()+
			": 'return' encontrado para el procedimiento "+$encabezado.met.getId()+"\n";
		}
	};

// Funciones y procedimientos
encabezado[Simbolo.TSub tsub]
	returns[Simbolo met]:
	ID {
		if($tsub!=null) {
			// Función
			$met = new Simbolo($ID.getText(),null,Simbolo.Tipo.FUNC,$tsub);
		} else {
			// Procedimiento
			$met = new Simbolo($ID.getText(),null,Simbolo.Tipo.PROC,Simbolo.TSub.NULL);
		}
	} '(' parametros[$met]? ')';

parametros[Simbolo anterior]:
	parametro ',' {
		$anterior.setNext($parametro.s);
	} parametros[$anterior.getNext()]
	| parametro {
		$anterior.setNext($parametro.s);
	};

parametro
	returns[Simbolo s]:
	tipo ID {
	$s = new Simbolo($ID.getText(),null,Simbolo.Tipo.ARG,$tipo.tsub);
};

sents: sents sent | sent;

sent:
	IF expr BEGIN sents END
	| IF expr BEGIN sents END ELSE BEGIN sents END
	| WHILE expr BEGIN sents END
	| RETURN expr ';'
	| referencia ASSIGN expr ';'
	| referencia ';';

referencia
	returns[Simbolo.TSub tsub]:
	ID
	| ID '(' ')' {
		Simbolo met=new Simbolo();
		try {
			met=ts.consulta($ID.getText());
			$tsub=met.getTsub();
			if(met.getNext()!=null) {
				errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": falta(n) argumento(s) para "+
				$ID.getText()+"\n";
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": "+e.getMessage()+"\n";
		}
	}
	| contIdx ')' {
		$tsub=$contIdx.tsub;
	};

contIdx
	returns[Simbolo.TSub tsub]:
	ID '(' expr {
		Simbolo met=new Simbolo();
		Deque<Simbolo.TSub> pparams=new ArrayDeque<Simbolo.TSub>();
		try {
			met=ts.consulta($ID.getText());
			$tsub=met.getTsub();
			pparams.add($expr.tsub);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": "+e.getMessage()+"\n";
		}
	} contIdx_[pparams] {
		Simbolo.TSub aux;
		Simbolo param=met;
		while(pparams.size()!=0) {
			param=param.getNext();
			aux=pparams.remove();
			if(param==null) {
				errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": demasiados argumentos para "+
				$ID.getText()+"\n";
				break;
			} else if(aux!=param.getTsub()) {
				errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+
				": tipos incompatibles (esperado "+param.getTsub()+")\n";
				break;
			}
		}
		if(param!=null) {
			errores+="ERROR SEMÁNTICO - Línea "+$ID.getLine()+": falta(n) argumento(s) para "+
			$ID.getText()+"\n";
		}
	};

contIdx_[Deque<Simbolo.TSub> pparams]:
	',' expr {
	$pparams.add($expr.tsub);
} contIdx_[$pparams]
	|; // lambda

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
	| SUB expr
	| referencia;

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