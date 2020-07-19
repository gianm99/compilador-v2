grammar vaja;

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.Deque;
import java.util.ArrayDeque;
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
}

@lexer::members {
@Override
public void recover(RecognitionException ex)
{
	throw new RuntimeException("Error léxico -  "+ex.getMessage());
}
}

programa:
	{
	ts = new TablaSimbolos(directorio);
	// Insertar operaciones de input/output
	try {
		ts.inserta("read",new Simbolo("read",null,Simbolo.Tipo.FUNC,Simbolo.TSub.STRING));
		Simbolo arg = new Simbolo("argBool",null,Simbolo.Tipo.ARG,Simbolo.TSub.BOOLEAN);
		ts.inserta("printb", new Simbolo("printb",arg,Simbolo.Tipo.PROC, Simbolo.TSub.NULL));
		arg = new Simbolo("argInt",null,Simbolo.Tipo.ARG,Simbolo.TSub.INT);
		ts.inserta("printi", new Simbolo("printi",arg,Simbolo.Tipo.PROC, Simbolo.TSub.NULL));
		arg = new Simbolo("argString",null,Simbolo.Tipo.ARG,Simbolo.TSub.STRING);
		ts.inserta("prints", new Simbolo("prints",arg,Simbolo.Tipo.PROC, Simbolo.TSub.NULL));
	} catch (TablaSimbolos.TablaSimbolosException e) {}
} decl* sents EOF {
	ts.saleBloque();
	if(!errores.isEmpty()) {
		throw new RuntimeException(errores);
	}
};

decl:
	tipo ID {
	try{
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.VAR,$tipo.tsub));
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="Error semántico - Línea "+$ID.getLine()+": variable '"+$ID.getText()+
		"' redeclarada\n";
	}
} (
		'=' expr {
	try{
		ts.consulta($ID.getText()).setInicializada(true);
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="Error semántico - Línea "+$ID.getLine()+": variable '"+$ID.getText()+
		"' no existe\n";
	}
	if($expr.tsub!=$tipo.tsub) {
		errores+="Error semántico - Línea "+$ID.getLine()+": tipos incompatibles (esperado '"+
		$tipo.tsub+"', encontrado '"+$expr.tsub+"')\n";
	}
}
	)? ';'
	| CONSTANT tipo ID {
	Simbolo s = null;
	try {
		ts.inserta($ID.getText(),new Simbolo($ID.getText(),null,Simbolo.Tipo.CONST,$tipo.tsub));
		s = ts.consulta($ID.getText());
		s.setInicializada(true);
	} catch(TablaSimbolos.TablaSimbolosException e) {
		errores+="Error semántico - Línea "+$ID.getLine()+": constante '"+$ID.getText()+
		"' redeclarada\n";
	}
} '=' literal ';' {
	if($literal.tsub!=$tipo.tsub) {
		errores+="Error semántico - Línea "+$ID.getLine()+": tipos incompatibles (esperado '"+
		$tipo.tsub+"')\n";
	}
	if(s!=null) {
		switch($literal.tsub) {
			case INT:
				s.setValor($literal.text);
				break;
			case BOOLEAN:
				if($literal.text.equals("true")) {
					s.setValor("-1");
				} else {
					s.setValor("0");
				}
				break;
			case STRING:
				s.setValor($literal.text);
				break;
			default:
				break;
		}
	}
}
	| declArray ']' ';'
	| FUNCTION tipo encabezado[$tipo.tsub] BEGIN {
		try {
			ts.inserta($encabezado.met.getId(),$encabezado.met);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$FUNCTION.getLine()+": "+e.getMessage()+"\n";
		}
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setInicializada(true);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+="Error semántico - Línea "+$FUNCTION.getLine()+": "+e.getMessage()+"\n";
			}
			param=param.getNext();
		}
	} decl* sents END {
		ts=ts.saleBloque();
		pproc.pop();
		if(!$encabezado.met.isReturnEncontrado()) {
			errores+="Error semántico - Línea "+$FUNCTION.getLine()+
			": 'return' no encontrado para la función '"+$encabezado.met.getId()+"'\n";
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
			errores+="Error semántico - Línea "+$PROCEDURE.getLine()+": "+e.getMessage()+"\n";
		}
		ts=ts.entraBloque();
		pproc.push($encabezado.met);
		Simbolo param=$encabezado.met.getNext();
		while(param!=null) {
			Simbolo aux=new Simbolo(param);
			aux.setInicializada(true);
			aux.setNext(null);
			try {
				ts.inserta(aux.getId(),aux);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				errores+="Error semántico - Línea "+$PROCEDURE.getLine()+": "+e.getMessage()+"\n";
			}
			param=param.getNext();
		}
	} decl* sents END {
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

declArray: 	tipo ID '[' literal declArray_;

declArray_: ']' '[' literal declArray_;

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

sents: sent sents_;

sents_: sent sents_ |;

sent:
	IF expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$IF.getLine()+
			": tipos incompatibles (esperado 'BOOLEAN', encontrado '"+$expr.tsub+"')\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decl* sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| IF expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$IF.getLine()+
			": tipos incompatibles (esperado 'BOOLEAN', encontrado '"+$expr.tsub+
			"', encontrado '"+$expr.tsub+"')\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decl* sents {
		ts=ts.saleBloque();
	} END ELSE BEGIN {
		ts=ts.entraBloque();
	} decl* sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| contcase endcase {
		profCondRep--;
	} END
	| WHILE expr {
		if($expr.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$WHILE.getLine()+
			": tipos incompatibles (esperado 'BOOLEAN', encontrado '"+$expr.tsub+"')\n";
		}
	} BEGIN {
		profCondRep++;
		ts=ts.entraBloque();
	} decl* sents {
		profCondRep--;
		ts=ts.saleBloque();
	} END
	| RETURN expr ';' {
		Simbolo funcion;
		if(pproc.size()==0) {
			// Return fuera de una función
			errores+="Error semántico - Línea "+$RETURN.getLine()+": return fuera de función\n";
		} else {
			funcion=pproc.peek();
			if (funcion.getT()==Simbolo.Tipo.PROC) {
				// Return no vacío en un procedimiento
				errores+="Error semántico - Línea "+$RETURN.getLine()+
				": return de expresión en un procedimiento\n";
			} else if(funcion.tsub()!=$expr.tsub) {
				// Return de tipo incorrecto
				errores+="Error semántico - Línea "+$RETURN.getLine()+
				": return de tipo incorrecto (esperado '"+pproc.peek().tsub()+
				"', encontrado '"+$expr.tsub+"')\n";
			} else if(profCondRep==0) {
				// Return correcto
				pproc.peek().setReturnEncontrado(true);
			}
		}
	}
	| RETURN ';' {
		Simbolo procedure;
		if(pproc.size()==0) {
			// Return fuera de una función
			errores+="Error semántico - Línea "+$RETURN.getLine()+": return fuera de función\n";
		} else {
			procedure=pproc.peek();
			if (procedure.getT()==Simbolo.Tipo.FUNC) {
				// Return vacío en una función
				errores+="Error semántico - Línea "+$RETURN.getLine()+
				": return vacío en una función)\n";
			}
		}
	}
	| referencia[true] ASSIGN expr ';' {
		if($referencia.s!=null) {
			if($referencia.s.getT()==Simbolo.Tipo.CONST) {
				errores+="Error semántico - Línea "+$ASSIGN.getLine()+": "+$referencia.s.getId()+
				"es una constante\n";
			} else if($referencia.s.getT()==Simbolo.Tipo.FUNC || $referencia.s.tsub()==Simbolo.TSub.NULL) {
				errores+="Error semántico - Línea "+$ASSIGN.getLine()+
				": no se pueden asignar valores a esta referencia\n";
			} else if($referencia.s.tsub()!=$expr.tsub) {
				errores+="Error semántico - Línea "+$ASSIGN.getLine()+
				": asignación de tipo incorrecto (esperado '"+$referencia.s.tsub()+
				"', encontrado '"+$expr.tsub+"')\n";
			}
		}
	}
	| referencia[false] SEMI {
		if($referencia.s!=null) {
			if($referencia.s.getT()!=Simbolo.Tipo.FUNC && $referencia.s.getT()!=Simbolo.Tipo.PROC) {
				// Tiene que ser función o procedimiento
				errores+="Error semántico - Línea "+$SEMI.getLine()+
				": se esperaba una función o un procedimiento\n";
			}
		}
	};

contcase:
	SWITCH expr {
		if($expr.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$SWITCH.getLine()+
			": tipos incompatibles (esperado 'INT', encontrado '"+$expr.tsub+"')\n";
		}
	} BEGIN {
		profCondRep++;
	} contcase_;

contcase_: caso contcase_ |; // lambda

caso:
	CASE expr {
	if($expr.tsub!=Simbolo.TSub.INT) {
		errores+="Error semántico - Línea "+$CASE.getLine()+
		": tipos incompatibles (esperado 'INT', encontrado '"+$expr.tsub+"')\n";
	}
} ':' sents (BREAK ';')?;

endcase: DEFAULT ':' sents |;

referencia[boolean asignacion]
	returns[Simbolo s]:
	ID {
		try {
			$s=ts.consulta($ID.getText());
			if($asignacion) {
				$s.setInicializada(true);
			} else {
				if(!$s.isInicializada()) {
					errores+="Error semántico - Línea "+$ID.getLine()+": '"+$ID.getText()+
					"' no ha sido inicializada\n";
				}
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			errores+="Error semántico - Línea "+$ID.getLine()+": "+e.getMessage()+"\n";
			$s=null;
		}
	}
	| idx ']'
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

idx: ID '[' expr idx_;

idx_: ']' '[' expr idx_ |;

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
				} else if(aux!=param.tsub()) {
					errores+="Error semántico - Línea "+$ID.getLine()+
					": tipos incompatibles (esperado '"+param.tsub()+
					"', encontrado '"+aux+"')\n";
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

// Expresiones
expr
	returns[Simbolo.TSub tsub]:
	exprOr {
		$tsub=$exprOr.tsub;
	};

// Expresión de OR
exprOr
	returns[Simbolo.TSub tsub]:
	exprAnd exprOr_ {
		if($exprOr_.tsub!=null) {
			if($exprAnd.tsub!=$exprOr_.tsub) {
				errores+="Error semántico - Línea "+$exprOr_.start.getLine()+
				": tipos incompatibles (esperado "+$exprAnd.tsub+","+
				" encontrado "+$exprOr_.tsub+")\n";
			} 
			$tsub=$exprOr_.tsub;
		} else {
			$tsub=$exprAnd.tsub;
		}
	};

exprOr_
	returns[Simbolo.TSub tsub]:
	OR exprAnd exprOr_ {
		if($exprAnd.tsub!=Simbolo.TSub.BOOLEAN){
			errores+="Error semántico - Línea "+$exprAnd.start.getLine()+
				": tipos incompatibles (esperado BOOLEAN, encontrado "+$exprAnd.tsub+")\n";
		}
		$tsub=Simbolo.TSub.BOOLEAN;
	}
	|; //lambda

// Expresión de AND
exprAnd
	returns[Simbolo.TSub tsub]:
	exprNot exprAnd_ {
		if($exprAnd_.tsub!=null) {
			if($exprNot.tsub!=$exprAnd_.tsub) {
				errores+="Error semántico - Línea "+$exprAnd_.start.getLine()+
				": tipos incompatibles (esperado "+$exprNot.tsub+","+
				" encontrado "+$exprAnd_.tsub+")\n";
			}
			$tsub=$exprAnd_.tsub;
		} else {
			$tsub=$exprNot.tsub;
		}
	};

exprAnd_
	returns[Simbolo.TSub tsub]:
	AND exprNot exprAnd_ {
		if($exprNot.tsub!=Simbolo.TSub.BOOLEAN){
			errores+="Error semántico - Línea "+$exprNot.start.getLine()+
				": tipos incompatibles (esperado BOOLEAN, encontrado "+$exprNot.tsub+")\n";
		}
		$tsub=Simbolo.TSub.BOOLEAN;
	}
	|; //lambda

// Expresión de NOT
exprNot
	returns[Simbolo.TSub tsub]:
	NOT exprComp {
		if($exprComp.tsub!=Simbolo.TSub.BOOLEAN) {
			errores+="Error semántico - Línea "+$exprComp.start.getLine()+
			": tipos incompatibles (esperado BOOLEAN, encontrado "+$exprComp.tsub+")\n";
		} 		
		$tsub=Simbolo.TSub.BOOLEAN;

	}
	| exprComp {
		$tsub=$exprComp.tsub;
	};

// Expresión comparativa
exprComp
	returns[Simbolo.TSub tsub]:
	exprAdit exprComp_ {
		if($exprComp_.tsub!=null) {
			if($exprAdit.tsub!=Simbolo.TSub.INT) {
				errores+="Error semántico - Línea "+$exprComp_.start.getLine()+
				": tipos incompatibles (esperado INT,"+
				" encontrado "+$exprComp_.tsub+")\n";
				$tsub=Simbolo.TSub.BOOLEAN;
			}
			$tsub=$exprComp_.tsub;
		} else {
			$tsub=$exprAdit.tsub;
		}
	};

exprComp_
	returns[Simbolo.TSub tsub]:
	// OPREL exprAdit exprComp_{
	OPREL exprAdit {
		if($exprAdit.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$exprAdit.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$exprAdit.tsub+")\n";
		}
		$tsub=Simbolo.TSub.BOOLEAN;
	}
	|; //lambda

// Expresión aditiva
exprAdit
	returns[Simbolo.TSub tsub]:
	exprMult exprAdit_ {
		if($exprAdit_.tsub!=null) {
			if($exprMult.tsub!=$exprAdit_.tsub) {
				errores+="Error semántico - Línea "+$exprAdit_.start.getLine()+
				": tipos incompatibles (esperado "+$exprMult.tsub+","+
				" encontrado "+$exprAdit_.tsub+")\n";
			} 
			$tsub=$exprAdit_.tsub;
		} else {
			$tsub=$exprMult.tsub;
		}
	};

exprAdit_
	returns[Simbolo.TSub tsub]:
	ADD exprMult exprAdit_ {
		if($exprMult.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$exprMult.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$exprMult.tsub+")\n";
		}
		$tsub=Simbolo.TSub.INT;
	}
	| SUB exprMult exprAdit_ {
		if($exprMult.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$exprMult.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$exprMult.tsub+")\n";
		}
		$tsub=Simbolo.TSub.INT;
	}
	|; //lambda

// Expresión multiplicativa
exprMult
	returns[Simbolo.TSub tsub]:
	exprNeg exprMult_ {
		if($exprMult_.tsub!=null) {
			if($exprNeg.tsub!=$exprMult_.tsub) {
				errores+="Error semántico - Línea "+$exprMult_.start.getLine()+
				": tipos incompatibles (esperado "+$exprMult_.tsub+","+
				" encontrado "+$exprNeg.tsub+")\n";
			} 
			$tsub=$exprMult_.tsub;
		} else {
			$tsub=$exprNeg.tsub;
		}
	};

exprMult_
	returns[Simbolo.TSub tsub]:
	MULT exprNeg exprMult_ {
		if($exprNeg.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$exprNeg.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$exprNeg.tsub+")\n";
		}
		$tsub=Simbolo.TSub.INT;
	}
	| DIV exprNeg exprMult_ {
		if($exprNeg.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$exprNeg.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$exprNeg.tsub+")\n";
		} else if($exprNeg.cero) {
			errores+="Error semántico - Línea "+$exprNeg.start.getLine()+
			": división por cero\n";
		}
		$tsub=Simbolo.TSub.INT;
	}
	|; //lambda

// Expresión de negación
exprNeg
	returns[Simbolo.TSub tsub, boolean cero]:
	SUB primario {
		if($primario.tsub!=Simbolo.TSub.INT) {
			errores+="Error semántico - Línea "+$primario.start.getLine()+
			": tipos incompatibles (esperado INT, encontrado "+$primario.tsub+")\n";
		}
		$tsub=Simbolo.TSub.INT;
		$cero=$primario.cero;
	}
	| primario {
		$tsub=$primario.tsub;
		$cero=$primario.cero;
	};

primario
	returns[Simbolo.TSub tsub, boolean cero]:
	'(' expr ')' {
		$tsub=$expr.tsub;
		$cero=false;
	}
	| referencia[false] {
		if($referencia.s==null) {
			errores+="Error semántico - Línea "+$referencia.start.getLine()+
			": tipos incompatibles (encontrado NULL)\n";
			$tsub=Simbolo.TSub.NULL;
		} else {
			$tsub=$referencia.s.tsub();
			if($referencia.s.getT()==Simbolo.Tipo.CONST && $referencia.s.tsub()==Simbolo.TSub.INT) {
				$cero=$referencia.s.getValor().equals("0");
			}
		}
	}
	| literal {
		$tsub=$literal.tsub;
		$cero=$literal.cero;
	};

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
	returns[Simbolo.TSub tsub, boolean cero]:
	LiteralInteger {
		$tsub=Simbolo.TSub.INT;
		$cero=$LiteralInteger.getText().equals("0");
	}
	| LiteralBoolean {
		$tsub=Simbolo.TSub.BOOLEAN;
		$cero=false;
	}
	| LiteralString {
		$tsub=Simbolo.TSub.STRING;
		$cero=false;
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
SWITCH: 'switch';
CASE: 'case';
DEFAULT: 'default';
BREAK: 'break';
// Enteros
LiteralInteger: DecimalLiteral;
fragment DecimalLiteral: DecimalPositivo | '0';
fragment DecimalPositivo: [1-9][0-9]*;
// Booleans
LiteralBoolean: 'true' | 'false';
// Cadenas
LiteralString: '"' LetrasString? '"';
fragment LetrasString: LetraString+;
fragment LetraString: ~[$"\\\r\n];
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
