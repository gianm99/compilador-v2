grammar vaja;

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
}

@parser::members {
public TablaSimbolos ts;
int profCondRep; // Profundidad dentro de estructura condicional o repetitiva
String errores="";
String directorio;
Deque<Simbolo> pproc=new ArrayDeque<Simbolo>(); // Pila de procedimientos

public vajaParser(TokenStream input,String directorio){
	this(input);
	this.directorio=directorio;
}

@Override
public void notifyErrorListeners(Token offendingToken, String msg, RecognitionException ex)
{
	String notificacion = "Error sintáctico - Línea " + offendingToken.getLine()
	+ ", Columna " + offendingToken.getCharPositionInLine() + ": \n\t ";
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

decls: decls decl | decl |;

decl:
	VARIABLE tipo ID {
	try{
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.VAR,$tipo.tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="Error semántico - Línea "+$ID.getLine()+": variable "+$ID.getText()+
		"redeclarada\n";
	}
} (
		'=' expr {
	if($expr.tsub!=$tipo.tsub) {
		errores+="Error semántico - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tipo.tsub+")\n";
	}
}
	)? ';'
	| CONSTANT tipo ID {
	try {
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.CONST,$tipo.tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="Error semántico - Línea "+$ID.getLine()+": constante "+$ID.getText()+
		"redeclarada\n";
	}
} '=' expr ';' {
	if($expr.tsub!=$tipo.tsub) {
		errores+="Error semántico - Línea "+$ID.getLine()+": tipos incompatibles (esperado "+
		$tipo.tsub+")\n";
	}
}
	| FUNCTION tipo encabezado[$tipo.tsub] BEGIN {
		try {
			ts.inserta($encabezado.met.getId(),$encabezado.met);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$FUNCTION.getLine()+": "+e.getMessage();
		}
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+="Error semántico - Línea "+$FUNCTION.getLine()+": "+e.getMessage();
			}
			param=param.getNext();
		}
	} decls sents END {
		ts=ts.saleBloque();
		pproc.pop();
		if(!$encabezado.met.isReturnEncontrado()) {
			errores+="Error semántico - Línea "+$FUNCTION.getLine()+
			": 'return' no encontrado para la función "+$encabezado.met.getId()+"\n";
		}
		if(profCondRep!=0) {
			errores+="Error semántico - Línea "+$FUNCTION.getLine()+
			": no se puede definir una función en una estructura condicional o repetitiva\n";
		}
	}
	| PROCEDURE encabezado[null] BEGIN {
		try {
			ts.inserta($encabezado.met.getId(),$encabezado.met);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$PROCEDURE.getLine()+": "+e.getMessage();
		}
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+="Error semántico - Línea "+$PROCEDURE.getLine()+": "+e.getMessage();
			}
			param=param.getNext();
		}
	} decls sents END {
		ts=ts.saleBloque();
		pproc.pop();
		if($encabezado.met.isReturnEncontrado()) {
			errores+="Error semántico - Línea "+$PROCEDURE.getLine()+
			": 'return' encontrado para el procedimiento "+$encabezado.met.getId()+"\n";
		}
		if(profCondRep!=0) {
			errores+="Error semántico - Línea "+$PROCEDURE.getLine()+
			": no se puede definir un procedimiento en una estructura condicional o repetitiva\n";
		}
	};

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
	IF expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$IF.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decls sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| IF expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$IF.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decls sents {
		ts=ts.saleBloque();
	} END ELSE BEGIN {
		ts=ts.entraBloque();
	} decls sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| WHILE expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="ERROR SEMÁNTICO - Línea "+$WHILE.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decls sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| RETURN expr ';' {
		if(pproc.size()==0) {
			// Return fuera de una función
			errores+="Error semántico - Línea "+$RETURN.getLine()+": return fuera de función\n";
		} else {
			if(pproc.peek().getTsub()!=$expr.tsub) {
				// Return de tipo incorrecto
				errores+="Error semántico - Línea "+$RETURN.getLine()+
				": return de tipo incorrecto (esperado "+pproc.peek().getTsub()+")\n";
			} else if(profCondRep==0) {
				// Return correcto
				pproc.peek().setReturnEncontrado(true);
			}
		}
	}
	| referencia ASSIGN expr ';' {
		if($referencia.s!=null) {
			if($referencia.s.getT()==Simbolo.Tipo.CONST) {
				// Asignación a una constante
				errores+="Error semántico - Línea "+$ASSIGN.getLine()+": "+$referencia.s.getId()+
				"es una constante\n";
			} else if($referencia.s.getTsub()!=$expr.tsub) {
				// Tipos incompatibles
				errores+="Error semántico - Línea "+$ASSIGN.getLine()+
				": asignación de tipo incorrecto (esperado "+$referencia.s.getTsub()+")\n";
			}
		}
	}
	| referencia SEMI {
		if($referencia.s!=null) {
			if($referencia.s.getT()!=Simbolo.Tipo.FUNC && $referencia.s.getT()!=Simbolo.Tipo.PROC) {
				// Tiene que ser función o procedimiento
				errores+="Error semántico - Línea "+$SEMI.getLine()+
				": se esperaba una función o un procedimiento\n";
			}
		}
	};

referencia
	returns[Simbolo s]:
	ID {
		try {
			$s=ts.consulta($ID.getText());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea"+$ID.getLine()+": "+e.getMessage();
			$s=null;
		}
	}
	| ID '(' ')' {
		try {
			$s=ts.consulta($ID.getText());
			if($s.getNext()!=null) {
				errores+="Error semántico - Línea "+$ID.getLine()+": falta(n) argumento(s) para "+
				$ID.getText()+"\n";
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$ID.getLine()+": "+e.getMessage()+"\n";
			$s=null;
		}
	}
	| contIdx ')' {
		$s=$contIdx.met;
	};

contIdx
	returns[Simbolo met]:
	ID '(' expr {
		Deque<Simbolo.TSub> pparams=new ArrayDeque<Simbolo.TSub>();
		try {
			$met=ts.consulta($ID.getText());
			pparams.add($expr.tsub);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$ID.getLine()+": "+e.getMessage()+"\n";
			$met=null;
		}
	} contIdx_[pparams] {
		if($met!=null) {
			Simbolo.TSub aux;
			Simbolo param=$met;
			param=param.getNext();
			while(pparams.size()!=0) {
				aux=pparams.remove();
				if(param==null) {
					errores+="Error semántico - Línea "+$ID.getLine()+
					": demasiados argumentos para "+$ID.getText()+"\n";
					break;
				} else if(aux!=param.getTsub()) {
					errores+="Error semántico - Línea "+$ID.getLine()+
					": tipos incompatibles (esperado "+param.getTsub()+")\n";
					break;
				}
				param=param.getNext();
			}
			if(param!=null) {
				errores+="Error semántico - Línea "+$ID.getLine()+": falta(n) argumento(s) para "+
				$ID.getText()+"\n";
			}
		}
	};

contIdx_[Deque<Simbolo.TSub> pparams]:
	',' expr {
	$pparams.add($expr.tsub);
} contIdx_[$pparams]
	|; // lambda

expr
	returns[Simbolo.TSub tsub]:
	NOT expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$expr.start.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
		$tsub=Simbolo.TSub.BOOLEAN;
	} expr_[$tsub]
	| SUB expr {
		if($expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$expr.start.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
		$tsub=Simbolo.TSub.INT;
	} expr_[$tsub]
	| '(' expr ')' {
		$tsub=$expr.tsub;
	} expr_[$tsub]
	| referencia {
		if($referencia.s==null) {
			errores+="Error semántico - Línea "+$referencia.start.getLine()+
			": tipos incompatibles (encontrado NULL)\n";
			$tsub=Simbolo.TSub.NULL;
		} else {
			$tsub=$referencia.s.getTsub();
		}
	} expr_[$tsub]
	| literal {
		$tsub=$literal.tsub;
	} expr_[$tsub];

expr_[Simbolo.TSub tsub]:
	OPREL expr {
		if($tsub!=Simbolo.TSub.INT||$expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$OPREL.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
	} expr_[Simbolo.TSub.BOOLEAN]
	| AND {
		if($tsub!=Simbolo.TSub.BOOLEAN||$expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$AND.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
	} expr expr_[Simbolo.TSub.BOOLEAN]
	| OR {
		if($tsub!=Simbolo.TSub.BOOLEAN||$expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$OR.getLine()+
			": tipos incompatibles (esperado BOOLEAN)\n";
		}
	} expr expr_[Simbolo.TSub.BOOLEAN]
	| MULT expr {
		if($tsub!=Simbolo.TSub.INT||$expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$MULT.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
	} expr_[Simbolo.TSub.INT]
	| DIV expr {
		if($tsub!=Simbolo.TSub.INT||$expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$DIV.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
	} expr_[Simbolo.TSub.INT]
	| ADD expr {
		if($tsub!=Simbolo.TSub.INT||$expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$ADD.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
	} expr_[Simbolo.TSub.INT]
	| SUB expr {
		if($tsub!=Simbolo.TSub.INT||$expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$SUB.getLine()+
			": tipos incompatibles (esperado INT)\n";
		}
	} expr_[Simbolo.TSub.INT]
	|;

tipo
	returns[Simbolo.TSub tsub]:
	INTEGER {
		$tsub=Simbolo.TSub.INT;
	}
	| BOOLEAN {
		$tsub=Simbolo.TSub.BOOLEAN;
	}
	| STRING {
		$tsub=Simbolo.TSub.STRING;
	};

literal
	returns[Simbolo.TSub tsub]:
	LiteralInteger {
		$tsub=Simbolo.TSub.INT;
	}
	| LiteralBoolean {
		$tsub=Simbolo.TSub.BOOLEAN;
	}
	| LiteralString {
		$tsub=Simbolo.TSub.STRING;
	};

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