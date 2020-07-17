parser grammar vajaC3D;
options
{
	tokenVocab = vajaLexer;
}

@parser::header {
package antlr;
import procesador.*;
import procesador.Instruccion.OP;
import procesador.Simbolo.Tipo;
import procesador.Simbolo.TSub;
import java.io.*;
import java.util.Deque;
import java.util.ArrayDeque;
import procesador.*;
}

@parser::members {
private Deque<Integer> pproc=new ArrayDeque<Integer>(); // Pila de procedimientos
private TablaSimbolos ts;
private TablaVariables tv;
private TablaProcedimientos tp;
private TablaEtiquetas te;
private String directorio;
private ArrayList<Instruccion> C3D;
private int pc = 0; // program counter
private int profundidad=0;

public vajaC3D(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
	this.C3D = new ArrayList<Instruccion>();
	this.tv= new TablaVariables(directorio);
	this.tp= new TablaProcedimientos();
	this.te = new TablaEtiquetas();
}

public void genera(OP codigo, String op1, String op2, String destino){
	pc++;
	if(codigo==OP.skip) {
		te.get(destino).setLinea(pc);
	}
	C3D.add(new Instruccion(codigo, op1, op2, destino));
}

public void imprimirC3D(){
	Writer buffer;
	File interFile = new File(directorio+"_C3D.txt");
	try {
		buffer = new BufferedWriter(new FileWriter(interFile));
		for(int i=0;i<C3D.size();i++) {
			buffer.write(C3D.get(i).toString() + "\n");
		}
		buffer.close();
	} catch(IOException e) {}
}

public void backpatch(Deque<Integer> lista, Etiqueta e){
	if(lista!=null) {
		while(lista.size()>0) {
			int instruccion=lista.remove()-1;
			C3D.get(instruccion).setEtiqueta(e.toString());
		}
	}
}

public Deque<Integer> concat(Deque<Integer> dq1, Deque<Integer> dq2){
	if(dq1==null) {
		return dq2;
	} else if(dq2!=null) {
		while(dq2.size()>0) {
			dq1.add(dq2.removeFirst());
		}
	}
	return dq1;
}

public OP valorSaltoCond(String s){
	OP op = null;
	switch(s){
		case "==":
			op = OP.ifEQ;
			break;
		case "!=":
			op = OP.ifNE;
			break;
		case "<":
			op = OP.ifLT;
			break;
		case ">":
			op = OP.ifGT;
			break;
		case ">=":
			op = OP.ifGE;
			break;
		case "<=":
			op = OP.ifLE;
			break;
	}
	return op;
}

public ArrayList<Instruccion> getC3D() {
	return C3D;
}

public TablaVariables getTv() {
	return tv;
}

public TablaProcedimientos getTp() {
	return tp;
}

public TablaEtiquetas getTe(){
	return te;
 }

}

programa:
	{
		// Poner los métodos de IO en la tabla de procedimientos
		Simbolo s;
		try{
			// Operación de entrada
			s=ts.consulta("read");
			s.setNp(tp.nuevoProc(profundidad,s.getT(),"read"));
			// Operaciones de salida
			s=ts.consulta("printb");
			s.setNp(tp.nuevoProc(profundidad,s.getT(),"printb"));
			s=ts.consulta("printi");
			s.setNp(tp.nuevoProc(profundidad,s.getT(),"printi"));
			s=ts.consulta("prints");
			s.setNp(tp.nuevoProc(profundidad,s.getT(),"prints"));
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} decl* sents EOF {
	Etiqueta e=te.get(te.nuevaEtiqueta());
	genera(OP.skip, null, null, e.toString());
	backpatch($sents.sents_seg,e);
	tv.calculoDespOcupVL(tp);
	imprimirC3D();
};

decl:
	VARIABLE tipo ID {
		Simbolo s=new Simbolo();
		int nv=0;
		try {
			s=ts.consulta($ID.getText());
			nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, s.getTsub());
			tv.get(nv).setId(s.getId());
			s.setNv(nv);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} (
		'=' expr {
			if(s.getTsub()==TSub.BOOLEAN) {
				Etiqueta ec=te.get(te.nuevaEtiqueta());
				Etiqueta ef=te.get(te.nuevaEtiqueta());
				Etiqueta efin=te.get(te.nuevaEtiqueta());
				genera(OP.skip, null, null, ec.toString());
				genera(OP.copy, "-1", null, tv.get(nv).toString());
				genera(OP.jump, null, null, efin.toString());
				genera(OP.skip, null, null, ef.toString());
				genera(OP.copy, "0", null, tv.get(nv).toString());
				genera(OP.skip, null, null, efin.toString());
				backpatch($expr.cierto,ec);
				backpatch($expr.falso,ef);
			} else {
				genera(OP.copy, $expr.r.toString(), null, tv.get(nv).toString());
			}
	}
	)? ';'
	| CONSTANT tipo ID '=' literal ';' {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
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
			int nv=tv.nuevaVar(false,pproc.peek(),Simbolo.Tipo.CONST, s.getTsub());
			tv.get(nv).setId(s.getId());
			tv.get(nv).setValor(s.getValor());
			s.setNv(nv);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| FUNCTION tipo encabezado BEGIN {
		profundidad++;
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		pproc.push($encabezado.met.getNp());
		// Crear variables para los parámetros
		Simbolo aux=$encabezado.s.getNext();
		int nparam=1;
		while(aux!=null) {
			try {
				int nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, aux.getTsub());
				tv.get(nv).setNparam(nparam);
				tv.get(nv).setId(aux.getId());
				ts.consulta(aux.getId()).setNv(nv);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				System.out.println("Error con la tabla de símbolos: "+e.getMessage());
			}
			aux=aux.getNext();
			nparam++;
		}
		Etiqueta e=te.get(te.nuevaEtiqueta());
		$encabezado.met.setInicio(e.getNe());
		$encabezado.met.setNumParams(nparam-1);
		genera(OP.skip, null, null, e.toString());
		genera(OP.pmb, null, null, $encabezado.met.toString());
	} decl* sents {
		C3D.get(pc-1).setInstFinal(true);
		pproc.pop();
		profundidad--;
		ts=ts.subeBloque();
	} END
	| PROCEDURE encabezado BEGIN {
		profundidad++;
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		pproc.push($encabezado.met.getNp());
		// Crear variables para los parámetros
		Simbolo aux=$encabezado.s.getNext();
		int nparam=1;
		while(aux!=null) {
			try {
				int nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, aux.getTsub());
				tv.get(nv).setNparam(nparam);
				tv.get(nv).setId(aux.getId());
				ts.consulta(aux.getId()).setNv(nv);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				System.out.println("Error con la tabla de símbolos: "+e.getMessage());
			}
			aux=aux.getNext();
			nparam++;
		}
		Etiqueta e=te.get(te.nuevaEtiqueta());
		$encabezado.met.setInicio(e.getNe());
		$encabezado.met.setNumParams(nparam-1);
		genera(OP.skip, null, null, e.toString());
		genera(OP.pmb, null, null, $encabezado.met.toString());;
	} decl* sents {
		genera(OP.ret, null, null, String.valueOf($encabezado.met.getNp()));
		C3D.get(pc-1).setInstFinal(true);
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
			met=tp.nuevoProc(profundidad,s.getT(),$ID.getText());
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
		Etiqueta ec = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ec.toString());
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
		Etiqueta ec = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ec.toString());
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
		Etiqueta ec = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ec.toString());
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto, ec);
		$sent_seg = concat($expr.falso, $sents.sents_seg);
	} END
	| IF expr BEGIN {
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ec = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ec.toString());
	} decl* sents {
	} END {
		Deque<Integer> sents_seg1 = new ArrayDeque<Integer>();
		genera(OP.jump, null, null, null);
		sents_seg1.add(pc);
		Etiqueta ef = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ef.toString());
	} ELSE BEGIN {
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
		Etiqueta ei = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ei.toString());
	} expr BEGIN {
		Etiqueta ec = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, ec.toString());
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto,ec);
		backpatch($sent_seg,ei);
		$sent_seg=$expr.falso;
		genera(OP.jump, null, null, ei.toString());
	} END
	| RETURN expr ';' {
		if($expr.cierto!=null || $expr.falso!=null) {//cambiar
			Etiqueta ec=te.get(te.nuevaEtiqueta());
			Etiqueta ef=te.get(te.nuevaEtiqueta());
			Etiqueta efin=te.get(te.nuevaEtiqueta());
			genera(OP.skip, null, null, ec.toString());
			genera(OP.copy, "-1", null, $expr.r.toString());
			$expr.r.setValor("-1");
			genera(OP.jump, null, null, efin.toString());
			genera(OP.skip, null, null, ef.toString());
			genera(OP.copy, "0", null, $expr.r.toString());
			$expr.r.setValor("0");
			genera(OP.skip, null, null, efin.toString());
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		}
		genera(OP.ret, $expr.r.toString(), null, pproc.peek().toString());
	}
	| RETURN ';' {
		genera(OP.ret, null, null, pproc.peek().toString());
	}
	| referencia '=' expr ';' {
		if($referencia.tsub==TSub.BOOLEAN) {
			Etiqueta ec=te.get(te.nuevaEtiqueta());
			Etiqueta ef=te.get(te.nuevaEtiqueta());
			Etiqueta efin=te.get(te.nuevaEtiqueta());
			genera(OP.skip, null, null, ec.toString());
			genera(OP.copy, "-1", null, $referencia.r.toString());
			genera(OP.jump, null, null, efin.toString());
			genera(OP.skip, null, null, ef.toString());
			genera(OP.copy, "0", null, $referencia.r.toString());
			genera(OP.skip, null, null, efin.toString());
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		} else {
			genera(OP.copy, $expr.r.toString(), null, $referencia.r.toString());
		}
	}
	| referencia ';';

referencia
	returns[Variable r, TSub tsub]:
	ID {
		Simbolo s;
		int t;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Tipo.CONST){
				t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,s.getTsub());
				tv.get(t).setTemporal(true);
				switch(s.getTsub()) {
					case BOOLEAN:
						genera(OP.copy, s.getValor(), null, tv.get(t).toString());
						if(s.getValor().equals("true")){
							tv.get(t).setValor("-1");
						} else {
							tv.get(t).setValor("0");
						}
						break;
					case INT:
						genera(OP.copy, s.getValor(), null, tv.get(t).toString());
						tv.get(t).setValor(s.getValor());
						break;
					case STRING:
						genera(OP.copy, tv.get(s.getNv()).toString(), null, tv.get(t).toString());
						tv.get(t).setValor(s.getValor());
						break;
				}
				$r = tv.get(t);
			} else {
				$r = tv.get(s.getNv());
			}
			$tsub=s.getTsub();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| ID '(' ')' {
		Simbolo s;
		int t;
		try {
			s = ts.consulta($ID.getText());
			genera(OP.call, null, null, s.getNp().toString());
			if(s.getT()==Tipo.FUNC) {
				t = tv.nuevaVar(true, pproc.peek(),Tipo.VAR,s.getTsub());
				$r = tv.get(t);
				$tsub=s.getTsub();
				genera(OP.st, null, null, tv.get(t).toString());
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| contIdx ')' {
		int t;
		while($contIdx.pparams.size()>0)
		genera(OP.params, null, null, $contIdx.pparams.pop().toString());
		genera(OP.call, null, null, $contIdx.met.toString());
		if($contIdx.s.getT()==Tipo.FUNC) {
			t = tv.nuevaVar(true, pproc.peek(),Tipo.VAR,$contIdx.s.getTsub());
			$r = tv.get(t);
			$tsub = $contIdx.s.getTsub();
			genera(OP.st, null, null, tv.get(t).toString());
		}
	};

contIdx
	returns[Deque<Variable> pparams, Procedimiento met, Simbolo s]:
	ID '(' expr {
		Simbolo s=new Simbolo();
		$pparams = new ArrayDeque<Variable>();
		try {
			s = ts.consulta($ID.getText());
			$s = s;
			$met = s.getNp();
			// TODO Comprobar si esto funciona con booleans
			$pparams.push($expr.r);
			// Boolean parámetro
			if($expr.cierto!=null || $expr.falso!=null) {
				Etiqueta ec=te.get(te.nuevaEtiqueta());
				Etiqueta ef=te.get(te.nuevaEtiqueta());
				Etiqueta efin=te.get(te.nuevaEtiqueta());
				genera(OP.skip, null, null, ec.toString());
				genera(OP.copy, "-1", null, $expr.r.toString());
				genera(OP.jump, null, null, efin.toString());
				genera(OP.skip, null, null, ef.toString());
				genera(OP.copy, "0", null, $expr.r.toString());
				genera(OP.skip, null, null, efin.toString());
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
			Etiqueta ec=te.get(te.nuevaEtiqueta());
			Etiqueta ef=te.get(te.nuevaEtiqueta());
			Etiqueta efin=te.get(te.nuevaEtiqueta());
			genera(OP.skip, null, null, ec.toString());
			genera(OP.copy, "-1", null, $expr.r.toString());
			genera(OP.jump, null, null, efin.toString());
			genera(OP.skip, null, null, ef.toString());
			genera(OP.copy, "0", null, $expr.r.toString());
			genera(OP.skip, null, null, efin.toString());
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
		Etiqueta e = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, e.toString());
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
		Etiqueta e = te.get(te.nuevaEtiqueta());
		genera(OP.skip, null, null, e.toString());
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
		genera(valorSaltoCond($OPREL.getText()), $t1.toString(), $exprAdit.r.toString(), null);
		$cierto=new ArrayDeque<Integer>();
 		$cierto.add(pc);
		genera(OP.jump, null, null, null);
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
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		tv.get(t).setTemporal(true);
		genera(OP.add, $t1.toString(), $exprMult.r.toString(), tv.get(t).toString());
		$r=tv.get(t);
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
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		tv.get(t).setTemporal(true);
		genera(OP.sub, $t1.toString(), $exprMult.r.toString(), tv.get(t).toString());
		$r=tv.get(t);
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
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		tv.get(t).setTemporal(true);
		genera(OP.mult, $t1.toString(), $exprNeg.r.toString(), tv.get(t).toString());
		$r=tv.get(t);
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
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		tv.get(t).setTemporal(true);
		genera(OP.div, $t1.toString(), $exprNeg.r.toString(), tv.get(t).toString());
		$r=tv.get(t);
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
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		tv.get(t).setTemporal(true);
		genera(OP.neg, $primario.r.toString(), null, tv.get(t).toString());
		$r = tv.get(t);
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
		if($referencia.tsub==TSub.BOOLEAN) {
			genera(OP.ifEQ, $r.toString(), "-1", null);
			$cierto=new ArrayDeque<Integer>();
			$cierto.add(pc);
			genera(OP.jump, null, null, null);
			$falso=new ArrayDeque<Integer>();
			$falso.add(pc);
		}
	}
	| literal {
		int t=0;
		switch($literal.tsub) {
			case BOOLEAN:
				t = tv.nuevaVar(true,pproc.peek(), Tipo.VAR,TSub.BOOLEAN);
				if($literal.text.equals("true")) {
					genera(OP.copy, "-1", null, tv.get(t).toString());
					tv.get(t).setValor("-1");
					genera(OP.jump, null, null, null);
					$cierto=new ArrayDeque<Integer>();
					$cierto.add(pc);
					$falso = null;
				} else {
					genera(OP.copy, "0", null, tv.get(t).toString());
					tv.get(t).setValor("0");
					genera(OP.jump, null, null, null);
					$falso=new ArrayDeque<Integer>();
					$falso.add(pc);
					$cierto = null;
				}
				break;
			case STRING:
				t = tv.nuevaVar(true,pproc.peek(), Tipo.CONST,TSub.STRING);
				tv.get(t).setValor($literal.text);
				break;
			case INT:
				t = tv.nuevaVar(true,pproc.peek(), Tipo.VAR,TSub.INT);
				genera(OP.copy, $literal.text, null, tv.get(t).toString());
				tv.get(t).setValor($literal.text);
				break;
			default:
				break;
		}
		tv.get(t).setTemporal(true);
		$r = tv.get(t);
	};

tipo
	returns[TSub tsub]:
	INTEGER {
	$tsub=TSub.INT;
	}
	| BOOLEAN {
		$tsub=TSub.BOOLEAN;
	}
	| STRING {
		$tsub=TSub.STRING;
	};

literal
	returns[TSub tsub]:
	LiteralInteger {
		$tsub=TSub.INT;
	}
	| LiteralBoolean {
		$tsub=TSub.BOOLEAN;
	}
	| LiteralString {
		$tsub=TSub.STRING;
	};
