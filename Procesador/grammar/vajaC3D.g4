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
Deque<Integer> pproc=new ArrayDeque<Integer>(); // Pila de procedimientos
TablaSimbolos ts;
TablaVariables tv;
TablaProcedimientos tp;
String directorio;
Writer writer;
// TODO 
int pc = 0; // program counter

public vajaC3DParser(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
}

public void genera(String codigo){
	try{
		pc++;
		writer.write(codigo);
	}catch(IOException e){}
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

programa: decl* sents EOF;

decl:
	VARIABLE tipo ID ('=' expr)? ';'
	| CONSTANT tipo ID '=' expr ';'
	| FUNCTION tipo encabezado[$tipo.tsub] BEGIN decl* sents END
	| PROCEDURE encabezado[null] BEGIN decl* sents END;

encabezado[Simbolo.TSub tsub]
	returns[Simbolo met]: ID '(' parametros[$met]? ')';

parametros[Simbolo anterior]:
	parametro ',' parametros[$anterior.getNext()]
	| parametro;

parametro
	returns[Simbolo s]: tipo ID;

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

sents_[Deque<Integer> sents_seg] returns[Deque<Integer> sents_seg_]:
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

	| RETURN expr ';'
	| referencia {
		Variable r = $referencia.r;
	} ASSIGN expr ';' {
		genera("referencia.r = " + $expr.r);
	}
	| referencia ';';

referencia
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	ID {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Simbolo.Tipo.CONST){
				Variable t = tv.nuevaVar(pproc.peek(),Variable.Tipo.CONST);
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
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("ERROR TABLA SÍMBOLOS"+e.getMessage());
		}
	}
	| ID '(' ')'
	| contIdx ')';

contIdx
	returns[Simbolo met]: ID '(' expr contIdx_[pparams];

contIdx_[Deque<Simbolo.TSub> pparams]:
	',' expr contIdx_[$pparams]
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
	| referencia {
		$r = $referencia.r;
		$cierto = $referencia.cierto;
		$falso = $referencia.falso;
	} expr_[$r, $cierto, $falso]
	| literal {		// Añadir para las 3 variables de valores de Simbolo
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
		backpatch($falso, e);
		$falso = $expr.falso;
		$cierto = concat(cierto, $expr.cierto);
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

tipo
	returns[Simbolo.TSub tsub]: INTEGER | BOOLEAN | STRING;

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
