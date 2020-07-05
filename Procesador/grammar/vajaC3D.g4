parser grammar vajaC3D;
options
{
	tokenVocab = vajaLexer;
}

@parser::header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.Deque;
import java.util.ArrayDeque;
import procesador.*;
}

@parser::members {
private Deque<Procedimiento> pproc=new ArrayDeque<Procedimiento>(); // Pila de procedimientos
private TablaSimbolos ts;
private TablaVariables tv;
private TablaProcedimientos tp;
private String directorio;
private ArrayList<Instruccion> c3d;
private int pc = 0; // program counter
private int profundidad=0;

public vajaC3D(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
	this.c3d = new ArrayList<Instruccion>();
	this.tv= new TablaVariables(directorio);
	this.tp= new TablaProcedimientos();
}

public void genera(Instruccion.OP codigo, String op1, String op2, String op3){
	pc++;
	c3d.add(new Instruccion(codigo, op1, op2, op3));
}

public ArrayList<Instruccion> getC3D() {
	return c3d;
}

public void imprimirC3D(){
	Writer buffer;
	File interFile = new File(directorio+"C3D.txt");
	try {
		buffer = new BufferedWriter(new FileWriter(interFile));
		for(int i=0;i<c3d.size();i++) {
			buffer.write(c3d.get(i).toString() + "\n");
		}
		buffer.close();
	} catch(IOException e) {}
}

public void backpatch(Deque<Integer> lista, Etiqueta e){
	if(lista!=null) {
		while(lista.size()>0) {
			int instruccion=lista.remove()-1;
			c3d.get(instruccion).setInstruccion3(e.toString());
		}
	}
}

public Deque<Integer> concat(Deque<Integer> dq1, Deque<Integer> dq2){
	if(dq2!=null) {
		while(dq2.size()>0){
		dq1.add(dq2.removeFirst());
		}
	}
	return dq1;
}

public Instruccion.OP valorSaltoCond(String s){
	Instruccion.OP op = null;
	switch(s){
		case "==":
			op = Instruccion.OP.ifEQ;
			break;
		case "!=":
			op = Instruccion.OP.ifNE;
			break;
		case "<":
			op = Instruccion.OP.ifLT;
			break;
		case ">":
			op = Instruccion.OP.ifGT;
			break;
		case ">=":
			op = Instruccion.OP.ifGE;
			break;
		case "<=":
			op = Instruccion.OP.ifLE;
			break;
	}
	return op;
}
}

programa:
	{
		// Poner los métodos de IO en la tabla de procedimientos
		Simbolo s;
		try{
			// Operación de entrada
			s=ts.consulta("read");
			s.setNp(tp.nuevoProc(profundidad,s.getT()));
			// Operaciones de salida
			for(Simbolo.TSub tsub : Simbolo.TSub.values()) {
				if(tsub!=Simbolo.TSub.NULL) {
					s=ts.consulta("print"+tsub);
					s.setNp(tp.nuevoProc(profundidad,s.getT()));
				}
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} decl* sents EOF {
	Etiqueta e=new Etiqueta();
	genera(Instruccion.OP.et, "", "", e.toString());
	e.setNl(pc);
	backpatch($sents.sents_seg,e);
	imprimirC3D();
};

decl:
	VARIABLE tipo ID {
		Simbolo s=new Simbolo();
		try {
			s=ts.consulta($ID.getText());
			s.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR, s.getTsub()));
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} (
		'=' expr {
			// TODO Quitar esto y no generar código para inicializaciones de variables globales
			if(s.getTsub()==Simbolo.TSub.BOOLEAN) {
				Etiqueta ec=new Etiqueta();
				Etiqueta ef=new Etiqueta();
				Etiqueta efin=new Etiqueta();
				genera(Instruccion.OP.et, "", "", ec.toString());
				ec.setNl(pc);
				genera(Instruccion.OP.copy, "-1", "", s.getNv().toString());
				s.getNv().setR(-1);
				genera(Instruccion.OP.jump, "", "", efin.toString());
				genera(Instruccion.OP.et, "", "", ef.toString());
				ef.setNl(pc);
				genera(Instruccion.OP.copy, "0", "", s.getNv().toString());
				s.getNv().setR(0);
				genera(Instruccion.OP.et, "", "", efin.toString());
				efin.setNl(pc);
				backpatch($expr.cierto,ec);
				backpatch($expr.falso,ef);
			} else {
				genera(Instruccion.OP.copy, $expr.r.toString(), "", s.getNv().toString());
				if(s.getTsub()==Simbolo.TSub.INT)
					s.getNv().setR($expr.r.getR());
			}
	}
	)? ';'
	| CONSTANT tipo ID '=' literal ';' {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			s.setValor($literal.text);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| FUNCTION tipo encabezado BEGIN { // TODO Ocupación de variables locales y número de parámetros
		profundidad++;
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		pproc.push($encabezado.met);
		// Crear variables para los parámetros
		Simbolo aux=new Simbolo();
		try {
			aux=ts.consulta($encabezado.s.getId()).getNext();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		while(aux!=null) {
			aux.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR, aux.getTsub()));
			aux=aux.getNext();
		}
		Etiqueta e=new Etiqueta();
		$encabezado.met.setInicio(e);
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
		genera(Instruccion.OP.init, "", "", String.valueOf($encabezado.met.getNp()));
	} decl* sents {
		genera(Instruccion.OP.ret, "", "", String.valueOf($encabezado.met.getNp()));
		pproc.pop();
		profundidad--;
		ts=ts.subeBloque();
	} END
	| PROCEDURE encabezado BEGIN { // TODO Ocupación de variables locales y número de parámetros
		profundidad++;
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		pproc.push($encabezado.met);
		// Crear variables para los parámetros
		Simbolo aux = new Simbolo();
		try {
			aux=ts.consulta($encabezado.s.getId()).getNext();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		while(aux!=null) {
			aux.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR, aux.getTsub()));
			aux=aux.getNext();
		}
		Etiqueta e=new Etiqueta();
		$encabezado.met.setInicio(e);
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
		genera(Instruccion.OP.init, "", "", String.valueOf($encabezado.met.getNp()));;
	} decl* sents {
		genera(Instruccion.OP.ret, "", "", String.valueOf($encabezado.met.getNp()));
		pproc.pop();
		profundidad--;
		ts=ts.subeBloque();
	} END;

encabezado
	returns[Procedimiento met, Simbolo s]:
	ID '(' parametros? ')' {
		Simbolo s=new Simbolo();
		Procedimiento met;
		try {
			s=ts.consulta($ID.getText());
			met=tp.nuevoProc(profundidad,s.getT());
			s.setNp(met);
			$met = met;
			$s=s;
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	};

parametros: parametro ',' parametros | parametro;

parametro: tipo ID;

sents
	returns[Deque<Integer> sents_seg]:
	sent[$sents_seg] {
		Etiqueta ec = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ec.toString());
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
		genera(Instruccion.OP.et, "", "", ec.toString());
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
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ec = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto, ec);
		$sent_seg = concat($expr.falso, $sents_seg);
	} END
	| IF expr BEGIN {
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ec = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} decl* sents {
		Deque<Integer> sents_seg1 = $sents.sents_seg;
	} END ELSE BEGIN {
		Etiqueta ef = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ef.toString());
		ef.setNl(pc);
	} decl* sents END {
		ts=ts.subeBloque();
		backpatch($expr.cierto, ec);
		backpatch($expr.falso, ef);
		$sent_seg = concat(sents_seg1, $sents.sents_seg);
	}
	| WHILE {
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ei = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ei.toString());
		ei.setNl(pc);
	} expr BEGIN {
		Etiqueta ec = new Etiqueta();
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto,ec);
		backpatch($sent_seg,ei);
		$sent_seg=$expr.falso;
		genera(Instruccion.OP.jump, "", "", ei.toString());
	} END
	| RETURN expr ';' {
		if($expr.cierto!=null || $expr.falso!=null) {//cambiar
			Etiqueta ec=new Etiqueta();
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
			$expr.r.setR(-1);
			genera(Instruccion.OP.jump, "", "", efin.toString());
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
			$expr.r.setR(0);
			genera(Instruccion.OP.et, "", "", efin.toString());
			efin.setNl(pc);
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		}
		genera(Instruccion.OP.ret, $expr.r.toString(), "", String.valueOf(pproc.peek().getNp()));
	}
	| RETURN ';' {
		genera(Instruccion.OP.ret, "", "", String.valueOf(pproc.peek().getNp()));
	}
	| referencia '=' expr ';' {
		if($referencia.tsub==Simbolo.TSub.BOOLEAN) {
			Etiqueta ec=new Etiqueta();
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			genera(Instruccion.OP.copy, "-1", "", $referencia.r.toString());
			$referencia.r.setR(-1);
			genera(Instruccion.OP.jump, "", "", efin.toString());
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			genera(Instruccion.OP.copy, "0", "", $referencia.r.toString());
			$referencia.r.setR(0);
			genera(Instruccion.OP.et, "", "", efin.toString());
			efin.setNl(pc);
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		} else {
			genera(Instruccion.OP.copy, $expr.r.toString(), "", $referencia.r.toString());
			$referencia.r.setR($expr.r.getR());
		}
	}
	| referencia ';';

referencia
	returns[Variable r, Simbolo.TSub tsub]:
	ID {
		Simbolo s;
		Variable t;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Simbolo.Tipo.CONST){
				t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.CONST,s.getTsub());
				t.setTemporal(true);
				switch(s.getTsub()) {
					case BOOLEAN:
						genera(Instruccion.OP.copy, s.getValor(), "", t.toString());
						if(Boolean.parseBoolean(s.getValor())){
							t.setR(-1);
						} else {
							t.setR(0);
						}
						break;
					case INT:
						genera(Instruccion.OP.copy, s.getValor(), "", t.toString());
						t.setR(Integer.parseInt(s.getValor()));
						break;
					case STRING:
						genera(Instruccion.OP.copy, s.getValor(), "", t.toString());
						break;
				}
				$r = t;
			} else {
				$r = s.getNv();
			}
			$tsub=s.getTsub();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| ID '(' ')' {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			genera(Instruccion.OP.call, "", "", s.getNp().toString());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| contIdx ')' {
		while($contIdx.pparams.size()>0) 
		genera(Instruccion.OP.params, "", "", $contIdx.pparams.pop().toString());
		genera(Instruccion.OP.call, "", "", String.valueOf($contIdx.met.getNp()));
	};

contIdx
	returns[Deque<Variable> pparams, Procedimiento met]:
	ID '(' expr {
		Simbolo s=new Simbolo();
		$pparams = new ArrayDeque<Variable>();
		try {
			s = ts.consulta($ID.getText());
			$met = s.getNp();
			// TODO Comprobar si esto funciona con booleans
			$pparams.push($expr.r);
			// Boolean parámetro
			if($expr.cierto!=null || $expr.falso!=null) {
				Etiqueta ec=new Etiqueta();
				Etiqueta ef=new Etiqueta();
				Etiqueta efin=new Etiqueta();
				genera(Instruccion.OP.et, "", "", ec.toString());
				ec.setNl(pc);
				genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
				$expr.r.setR(-1);
				genera(Instruccion.OP.jump, "", "", efin.toString());
				genera(Instruccion.OP.et, "", "", ef.toString());
				ef.setNl(pc);
				genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
				$expr.r.setR(0);
				genera(Instruccion.OP.et, "", "", efin.toString());
				efin.setNl(pc);
				backpatch($expr.cierto,ec);
				backpatch($expr.falso,ef);
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} contIdx_[$pparams];

contIdx_[Deque<Variable> pparams]:
	',' expr {
		$pparams.push($expr.r);
		// Boolean parámetro
		if($expr.cierto!=null || $expr.falso!=null) {
			Etiqueta ec=new Etiqueta();
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
			$expr.r.setR(-1);
			genera(Instruccion.OP.jump, "", "", efin.toString());
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
			$expr.r.setR(0);
			genera(Instruccion.OP.et, "", "", efin.toString());
			efin.setNl(pc);
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		}
	} contIdx_[$pparams]
	|; // lambda

expr
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprOr {
		$r=$exprOr.r;
		$cierto=$exprOr.cierto;
		$falso=$exprOr.falso;
	};

// Expresión de OR
exprOr
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprAnd {
		$r=$exprAnd.r;
		$cierto=$exprAnd.cierto;
		$falso=$exprAnd.falso;
	} exprOr_[$r,$cierto,$falso] {
		if($exprOr_.cierto!=null || $exprOr_.falso!=null) {
			$r = $exprOr_.r;
			$cierto=$exprOr_.cierto;
			$falso=$exprOr_.falso;
		}
	};

exprOr_[Variable t1, Deque<Integer> cierto1, Deque<Integer> falso1]
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	OR {
		Etiqueta e = new Etiqueta();
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
	} exprAnd {
		backpatch($falso1, e);
		$cierto = concat($cierto1, $exprAnd.cierto);
		$falso = $exprAnd.falso;
	} exprOr_[$r,$cierto,$falso]{
		if($exprOr_.cierto!=null || $exprOr_.falso!=null) {
			$r = $exprOr_.r;
			$cierto=$exprOr_.cierto;
			$falso=$exprOr_.falso;
		}
	}
	|; //lambda

// Expresión de AND
exprAnd
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprNot {
		$r=$exprNot.r;
		$cierto=$exprNot.cierto;
		$falso=$exprNot.falso;
	} exprAnd_[$r,$cierto,$falso] {
		if($exprAnd_.cierto!=null || $exprAnd_.falso!=null) {
			$r = $exprAnd_.r;
			$cierto=$exprAnd_.cierto;
			$falso=$exprAnd_.falso;
		}
	};

exprAnd_[Variable t1, Deque<Integer> cierto1, Deque<Integer> falso1]
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	AND {
		Etiqueta e = new Etiqueta();
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
	} exprNot {
		backpatch($cierto1, e);
		$falso = concat($falso1, $exprNot.falso);
		$cierto = $exprNot.cierto;
	} exprAnd_[$r, $cierto, $falso]{
		if($exprAnd_.cierto!=null || $exprAnd_.falso!=null) {
			$r = $exprAnd_.r;
			$cierto=$exprAnd_.cierto;
			$falso=$exprAnd_.falso;
		}
	}
	|; //lambda

// Expresión de NOT
exprNot
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	NOT exprComp {
		$cierto=$exprComp.falso;
		$falso=$exprComp.cierto;
		$r=$exprComp.r;
	}
	| exprComp {
		$cierto=$exprComp.cierto;
		$falso=$exprComp.falso;
		$r=$exprComp.r;
	};

// Expresión comparativa
exprComp
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprAdit {
		$r=$exprAdit.r;
		$cierto=$exprAdit.cierto;
		$falso=$exprAdit.falso;
	} exprComp_[$r]{
		if($exprComp_.cierto!=null || $exprComp_.falso!=null) {
			$cierto=$exprComp_.cierto;
			$falso=$exprComp_.falso;
		}
	};

exprComp_[Variable t1]
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	OPREL exprAdit {
		genera(valorSaltoCond($OPREL.getText()), $t1.toString(), $exprAdit.r.toString(), "");
		$cierto=new ArrayDeque<Integer>();
 		$cierto.add(pc);
		genera(Instruccion.OP.jump, "", "", "");
		$falso=new ArrayDeque<Integer>();
 		$falso.add(pc);
		$r = $exprAdit.r;
    }
	//exprComp_
	|; //lambda

// Expresión aditiva
exprAdit
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprMult {
		$r = $exprMult.r;
		$cierto=$exprMult.cierto;
		$falso=$exprMult.falso;
	} exprAdit_[$r] {
		if($exprAdit_.cierto!=null || $exprAdit_.falso!=null || $exprAdit_.r!=null) {
			$r=$exprAdit_.r;
			$cierto=$exprAdit_.cierto;
			$falso=$exprAdit_.falso;
		}
	};

exprAdit_[Variable t1]
	returns[Variable r, Deque<Integer> cierto, Deque<Integer falso>]:
	ADD exprMult {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR,Simbolo.TSub.INT);
		t.setTemporal(true);
		genera(Instruccion.OP.add, $t1.toString(), $exprMult.r.toString(), t.toString());
		$r=t;
		$cierto=$exprMult.cierto;
		$falso=$exprMult.falso;
	} exprAdit_[$r] {
		if($exprAdit_.r!=null || $exprAdit_.cierto!=null || $exprAdit_.falso!=null) {
			$r=$exprAdit_.r;
			$cierto=$exprAdit_.cierto;
			$falso=$exprAdit_.falso;
		}
	}
	| SUB exprMult {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR,Simbolo.TSub.INT);
		t.setTemporal(true);
		genera(Instruccion.OP.sub, $t1.toString(), $exprMult.r.toString(), t.toString());
		$r=t;
		$cierto=$exprMult.cierto;
		$falso=$exprMult.falso;
	} exprAdit_[$r] {
		if($exprAdit_.r!=null || $exprAdit_.cierto!=null || $exprAdit_.falso!=null) {
			$r=$exprAdit_.r;
			$cierto=$exprAdit_.cierto;
			$falso=$exprAdit_.falso;
		}
	}
	|; //lambda

// Expresión multiplicativa
exprMult
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	exprNeg {
		$r = $exprNeg.r;
		$cierto=$exprNeg.cierto;
		$falso=$exprNeg.falso;
	} exprMult_[$r] {
		if($exprMult_.r!=null || $exprMult_.cierto!=null || $exprMult_.falso!=null) {
			$r=$exprMult_.r;
			$cierto=$exprMult_.cierto;
			$falso=$exprMult_.falso;
		}
	};

exprMult_[Variable t1]
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	MULT exprNeg {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR,Simbolo.TSub.INT);
		t.setTemporal(true);
		genera(Instruccion.OP.mult, $t1.toString(), $exprNeg.r.toString(), t.toString());
		$r=t;
		$cierto=$exprNeg.cierto;
		$falso=$exprNeg.falso;
	} exprMult_[$r] {
		if($exprMult_.r!=null || $exprMult_.cierto!=null || $exprMult_.falso!=null) {
			$r=$exprMult_.r;
			$cierto=$exprMult_.cierto;
			$falso=$exprMult_.falso;
		}
	}
	| DIV exprNeg {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR,Simbolo.TSub.INT);
		t.setTemporal(true);
		genera(Instruccion.OP.div, $t1.toString(), $exprNeg.r.toString(), t.toString());
		$r=t;
		$cierto=$exprNeg.cierto;
		$falso=$exprNeg.falso;
	} exprMult_[$r] {
		if($exprMult_.r!=null || $exprMult_.cierto!=null || $exprMult_.falso!=null) {
			$r=$exprMult_.r;
			$cierto=$exprMult_.cierto;
			$falso=$exprMult_.falso;
		}
	}
	|; //lambda

// Expresión de negación
exprNeg
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	SUB primario {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR,Simbolo.TSub.INT);
		t.setTemporal(true);
		genera(Instruccion.OP.neg, $primario.r.toString(), "", t.toString());
		$r = t;
		$cierto = $primario.cierto;
		$falso = $primario.falso;
	}
	| primario {
		$r = $primario.r;
		$cierto = $primario.cierto;
		$falso = $primario.falso;
	};

primario
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	'(' expr ')' {
		$r = $expr.r;
		$cierto = $expr.cierto;
		$falso = $expr.falso;
	}
	| referencia {
		$r = $referencia.r;
		if($referencia.tsub==Simbolo.TSub.BOOLEAN) {
			genera(Instruccion.OP.ifEQ, $r.toString(), "-1", "");
			$cierto=new ArrayDeque<Integer>();
			$cierto.add(pc);
			genera(Instruccion.OP.jump, "", "", "");
			$falso=new ArrayDeque<Integer>();
			$falso.add(pc);
		}
	}
	| literal {
		Variable t = tv.nuevaVar(pproc.peek(), Simbolo.Tipo.VAR,$literal.tsub);
		t.setTemporal(true);
		$r = t;
		if($literal.tsub == Simbolo.TSub.BOOLEAN){
			if($literal.text.equals("true")) {
				genera(Instruccion.OP.copy, "-1", "", t.toString());
				t.setR(-1);
				genera(Instruccion.OP.jump, "", "", "");
				$cierto=new ArrayDeque<Integer>();
				$cierto.add(pc);
				$falso = null;
			} else {
				genera(Instruccion.OP.copy, "0", "", t.toString());
				t.setR(0);
				genera(Instruccion.OP.jump, "", "", "");
				$falso=new ArrayDeque<Integer>();
				$falso.add(pc);
				$cierto = null;
			}
		} else {
			genera(Instruccion.OP.copy, $literal.text, "", t.toString());
			if($literal.tsub==Simbolo.TSub.BOOLEAN){
				if(Boolean.parseBoolean($literal.text)){
					t.setR(-1);
				} else {
					t.setR(0);
				}
			} else if($literal.tsub==Simbolo.TSub.INT){
				t.setR(Integer.parseInt($literal.text));
			}	
		}
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
