grammar vajaC3D;
// options { tokenVocab = vajaNUEVOLexer; }

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
import procesador.*;
}

@parser::members {
Deque<Procedimiento> pproc=new ArrayDeque<Procedimiento>(); // Pila de procedimientos
TablaSimbolos ts;
TablaVariables tv;
TablaProcedimientos tp;
String directorio;
ArrayList<String> codigoIntermedio = new ArrayList<String>();
// TODO Asegurarse de que no tenga que ser -1 en vez de 0
int pc = 0; // program counter
int profundidad=0;

public vajaC3DParser(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
}

public void genera(String codigo){
	try{
		pc++;
		codigoIntermedio.add(codigo);
	}catch(IOException e){}
}

public void imprimirGenera(){
	try{
		BufferedWriter writer = new BufferedWriter(new FileWriter(intermedio));
		codigoIntermedio.forEach((s) -> writer.write(s));
		writer.close();
	}
	catch(FileNotFoundException e){
		System.out.println("Error al escribir el código intermedio en fichero");
	}
}

public void backpatch(Deque<Integer> lista, Etiqueta e){

}

public Deque<Integer> concat(Deque<Integer> dq1, Deque<Integer> dq2){
	while(dq2.size()>0){
		dq1.add(dq2.removeFirst());
	}
	return dq1;
}
}

programa:
	decl* sents {
	Etiqueta e=new Etiqueta();
	genera(e+": skip");
	e.setNl(pc);
	backpatch($sents.sents_seg,e);
	// TODO Según los apuntes aquí faltan cosas
} EOF;

decl:
	VARIABLE tipo ID ('=' expr)? ';' // TODO Preguntar cómo va esto
	| CONSTANT tipo ID '=' expr ';'
	| FUNCTION tipo encabezado BEGIN {
		profundidad++;
		pproc.push($encabezado.met);
		Etiqueta e=new Etiqueta(); // TODO Hacer una tabla de etiquetas y cambiar esto
		$encabezado.met.setInicio(e);
		genera(e+": skip");
		genera("pmb "+$encabezado.met.getNp()); // TODO Comprobar si esto se hace aquí
	} decl* sents {
		genera("rtn "+$encabezado.met.getNp());
		profundidad--;
	} END
	| PROCEDURE encabezado BEGIN {
		profundidad++;
		pproc.push($encabezado.met);
		Etiqueta e=new Etiqueta();
		$encabezado.met.setInicio(e);
		genera(e+": skip");
		e.setNl(pc);
		genera("pmb "+$encabezado.met.getNp());
	} decl* sents {
		genera("rtn "+$encabezado.met.getNp());
		profundidad--;
	} END;

encabezado
	returns[Procedimiento met]:
	ID '(' parametros? ')' {
		Simbolo s=new Simbolo();
		try {
			s=ts.consulta($ID.getText());
			$met=tp.nuevoProc(profundidad,s.getT());
			s.setNp($met);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos "+e.getMessage());
		}
	};

parametros: parametro ',' parametros | parametro;

parametro: tipo ID;

sents
	returns[Deque<Integer> sents_seg]:
	sent[$sents_seg] {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} sents_[$sents_seg] {
		backpatch($sent.sent_seg, ec);
		if($sents_.sents_seg_!=null) {
			$sents_seg = $sents_.sents_seg_;
		} else{
			$sents_seg= $sent.sent_seg;
		}
	};

sents_[Deque<Integer> sents_seg]
	returns[Deque<Integer> sents_seg_]:
	sent[$sents_seg] {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} sents_[$sents_seg] {
		backpatch($sent.sent_seg, ec);
		if($sents_.sents_seg_!=null) {
			$sents_seg_ = $sents_.sents_seg_;
		} else{
			$sents_seg_= $sent.sent_seg;
		}
	}
	|;

sent[Deque<Integer> sents_seg]
	returns[Deque<Integer> sent_seg]:
	IF expr BEGIN {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} decl* sents {
		backpatch($expr.cierto, ec);
		$sent_seg = concat($expr.falso, $sents_seg);
	} END
	| IF expr BEGIN {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} decl* sents {
		Deque<Integer> sents_seg1 = $sents.sents_seg;
	} END ELSE BEGIN {
		Etiqueta ef = new Etiqueta();
		genera(ef + ": skip");
		ef.setNl(pc);
	} decl* sents END {
		backpatch($expr.cierto, ec);
		backpatch($expr.falso, ef);
		$sent_seg = concat(sents_seg1, $sents.sents_seg);
	}
	| WHILE {
		Etiqueta ei = new Etiqueta();
		genera(ei + ": skip");
		ei.setNl(pc);
	} expr BEGIN {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} decl* sents {
		backpatch($expr.cierto,ec); // TODO Comprobar si esto es correcto
		backpatch($sent_seg,ei);
		$sents_seg=$expr.falso;
		genera("goto "+ei);
	} END
	| RETURN expr ';'
	| referencia ASSIGN expr ';' { // TODO Comprobar si esto es suficiente
		$sent_seg=null;
		if($referencia.tsub==Simbolo.TSub.BOOLEAN) {
			Etiqueta ec=new Etiqueta(); // TODO Revisar todos los new Etiqueta()
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			genera(ec+": skip");
			ec.setNl(pc);
			genera($referencia.r+"= -1");
			genera("goto "+efin);
			genera(ef+": skip");
			ef.setNl(pc);
			genera($referencia.r+"= 0");
			genera(efin+": skip");
			efin.setNl(pc);
		}
	}
	| referencia ';';

referencia
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso, Simbolo.TSub tsub]:
	ID {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Simbolo.Tipo.CONST){
				Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.CONST);
				switch(s.getTsub()) {
					case BOOLEAN:
						genera("t"+Variable.getCv()+" = " + s.isvCB());
						break;
					case INT:
						genera("t"+Variable.getCv()+" = " + s.getvCI());
						break;
					case STRING:
						genera("t"+Variable.getCv()+" = " + s.getvCS());
						break;
				}
				$r = t;
			} else {
				$tsub=s.getTsub();
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos "+e.getMessage());
		}
	}
	| ID '(' ')' {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			genera("call " + s.getNp());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos "+e.getMessage());
		}
	}
	| contIdx ')' {
		while($contIdx.pparams.size()>0) genera("param_s" + $contIdx.pparams.pop());
		genera("call "+$contIdx.met.getNp());
	};

contIdx
	returns[Deque<Variable> pparams, Procedimiento met]:
	ID '(' expr {
		Simbolo met;
		$pparams = new ArrayDeque<Variable>();
		try {
			met = ts.consulta($ID.getText());
			$pparams.push($expr.r);
			$met = met.getNp();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos "+e.getMessage());
		}
	} contIdx_[$pparams];

contIdx_[Deque<Variable> pparams]:
	',' expr {
		$pparams.push($expr.r);
	} contIdx_[$pparams]
	|; // lambda

expr
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	NOT expr {
		$cierto = $expr.falso;
		$falso = $expr.cierto;
	} expr_[null,$cierto, $falso]
	| SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = - " + $expr.r);
		$r = t;
	} expr_[$r,null,null]
	| '(' expr ')' {
		$r = $expr.r;
		$cierto = $expr.cierto;
		$falso = $expr.falso;
	} expr_[$r,$cierto,$falso]
	| referencia { // TODO Comprobar si esto es suficiente
		$r = $referencia.r;
		$cierto = $referencia.cierto;
		$falso = $referencia.falso;
	} expr_[$r, $cierto, $falso]
	| literal {
		// TODO Comprobar si hay que hacer esto para las 3 variables de valores de Simbolo
		Variable t = tv.nuevaVar(pproc.peek(), Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = " + $literal.start.getText());
		$r = t;
		if($literal.tsub == Simbolo.TSub.BOOLEAN){
			if($literal.start.getText().equals("true")) {
				genera("goto ");
				$cierto=new ArrayDeque<Integer>();
				$cierto.add(pc);
				$falso = null;
			} else {
				genera("goto ");
				$falso=new ArrayDeque<Integer>();
				$falso.add(pc);
				$cierto = null;
			}
		}
	} expr_[$r,$cierto,$falso];

expr_[Variable r, Deque<Integer> cierto, Deque<Integer> falso]
	returns[Variable t]:
	OPREL expr {
		genera("if " + $r + " " + $OPREL.getText() + " " + $expr.r + " goto ");
		$cierto=new ArrayDeque<Integer>();
		$cierto.add(pc);
		genera("goto ");
		$falso=new ArrayDeque<Integer>();
		$falso.add(pc);
    } expr_[$r,$cierto,$falso]
	| AND {
		Etiqueta e = new Etiqueta();
		genera("e : skip");
		e.setNl(pc);
	} expr {
		backpatch($cierto, e);
		$falso = concat($falso, $expr.falso);
		$cierto = $expr.cierto;
	} expr_[$r, $cierto, $falso]
	| OR {
		Etiqueta e = new Etiqueta();
		genera("e : skip");
		e.setNl(pc);
	} expr {
		backpatch($cierto, e); // TODO Preguntar si esto es correcto
		$cierto = concat($cierto, $expr.cierto);
		$falso = $expr.falso;
	} expr_[$r, $cierto, $falso]
	| MULT expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = " + $r + " * " + $expr.r);
		$t = t;
	} expr_[$r, null, null]
	| DIV expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = " + $r + " / " + $expr.r);
		$t = t;
	} expr_[$r, null, null]
	| ADD expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = " + $r + " + " + $expr.r);
		$t = t;
	} expr_[$r,null,null]
	| SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		genera("t"+Variable.getCv()+" = " + $r + " - " + $expr.r);
		$t = t;
	} expr_[$r, null, null]
	|;

tipo: INTEGER | BOOLEAN | STRING;

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
