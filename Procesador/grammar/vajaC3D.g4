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

public void backpatch(int linea, Etiqueta e){
	C3D.get(linea-1).setEtiqueta(e.toString());
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
	Etiqueta e=te.get(te.nuevaEtiqueta(false));
	genera(OP.skip, null, null, e.toString());
	backpatch($sents.sents_seg,e);
	tv.calculoDespOcupVL(tp);
	imprimirC3D();
};

decl:
	tipo ID {
		Simbolo s=new Simbolo();
		int nv=0;
		try {
			s=ts.consulta($ID.getText());
			nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, s.tsub());
			tv.get(nv).setId(s.getId());
			s.setNv(nv);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} (
		'=' expr {
			if(s.tsub()==TSub.BOOLEAN) {
				Etiqueta ec=te.get(te.nuevaEtiqueta(false));
				Etiqueta ef=te.get(te.nuevaEtiqueta(false));
				Etiqueta efin=te.get(te.nuevaEtiqueta(false));
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
			int nv=tv.nuevaVar(false,pproc.peek(),Simbolo.Tipo.CONST, s.tsub());
			tv.get(nv).setId(s.getId());
			tv.get(nv).setValor(s.getValor());
			s.setNv(nv);
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| declArray ']' ';'
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
				int nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, aux.tsub());
				tv.get(nv).setNparam(nparam);
				tv.get(nv).setId(aux.getId());
				ts.consulta(aux.getId()).setNv(nv);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				System.out.println("Error con la tabla de símbolos: "+e.getMessage());
			}
			aux=aux.getNext();
			nparam++;
		}
		Etiqueta e=te.get(te.nuevaEtiqueta(true));
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
				int nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, aux.tsub());
				tv.get(nv).setNparam(nparam);
				tv.get(nv).setId(aux.getId());
				ts.consulta(aux.getId()).setNv(nv);
			} catch(TablaSimbolos.TablaSimbolosException e) {
				System.out.println("Error con la tabla de símbolos: "+e.getMessage());
			}
			aux=aux.getNext();
			nparam++;
		}
		Etiqueta e=te.get(te.nuevaEtiqueta(true));
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

declArray:
	tipo ID '[' (numero '..')? numero declArray_ {
	Simbolo s=null;
	int nv=0;
	try {
		s=ts.consulta($ID.getText());
		Tabla dt = s.getDt();
		nv=tv.nuevaVar(false,pproc.peek(),Tipo.VAR, dt.tsubt());
		tv.get(nv).setId(s.getId());
		s.setNv(nv);
		tv.get(nv).setElementos(dt.entradas());
	} catch(TablaSimbolos.TablaSimbolosException e) {
		System.out.println("Error con la tabla de símbolos: "+e.getMessage());
	}
};

declArray_:
	']' '[' (numero '..')? numero declArray_
	|; // lambda

numero
	returns[int valor, boolean constante]:
	LiteralInteger
	| ID;

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
		Etiqueta ec = te.get(te.nuevaEtiqueta(false));
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
		Etiqueta ec = te.get(te.nuevaEtiqueta(false));
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
		Etiqueta ec = te.get(te.nuevaEtiqueta(false));
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
		Etiqueta ec = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, ec.toString());
	} decl* sents {
	} END {
		Deque<Integer> sents_seg1 = new ArrayDeque<Integer>();
		genera(OP.jump, null, null, null);
		sents_seg1.add(pc);
		Etiqueta ef = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, ef.toString());
	} ELSE BEGIN {
	} decl* sents END {
		ts=ts.subeBloque();
		backpatch($expr.cierto, ec);
		backpatch($expr.falso, ef);
		$sent_seg = concat(sents_seg1, $sents.sents_seg);
	}
	| contcase endcase END {
		genera(OP.skip, null, null, $contcase.etest.toString());
		while($contcase.pilacond.size()!=0) {
			Etiqueta econd = $contcase.pilacond.remove();
			Etiqueta etest = $contcase.pilatest.remove();
			Variable v = tv.get($contcase.pilavar.remove());
			Etiqueta esent = $contcase.pilasent.remove();
			genera(OP.jump, null, null, econd.toString());
			genera(OP.skip, null, null, etest.toString());
			genera(OP.ifEQ, $contcase.r.toString(), v.toString(), esent.toString());
		}
		if($endcase.e!=null) {
			if(!$contcase.acababreak && $contcase.pilaefi.size()>0) {
				int seg = $contcase.pilaefi.removeLast();
				backpatch(seg, $endcase.e);
			}
			genera(OP.jump, null, null, $endcase.e.toString());
			genera(OP.skip, null, null, $endcase.efi.toString());
		}
		Etiqueta efi = te.get(te.nuevaEtiqueta(false));
		backpatch($contcase.pilaefi, efi);
		genera(OP.skip, null, null, efi.toString());
	}
	| WHILE {
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ei = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, ei.toString());
	} expr BEGIN {
		Etiqueta ec = te.get(te.nuevaEtiqueta(false));
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
			Etiqueta ec=te.get(te.nuevaEtiqueta(false));
			Etiqueta ef=te.get(te.nuevaEtiqueta(false));
			Etiqueta efin=te.get(te.nuevaEtiqueta(false));
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
		if($referencia.d!=null) {
			if($referencia.tsub==TSub.BOOLEAN) {
				Etiqueta ec=te.get(te.nuevaEtiqueta(false));
				Etiqueta ef=te.get(te.nuevaEtiqueta(false));
				Etiqueta efin=te.get(te.nuevaEtiqueta(false));
				genera(OP.skip, null, null, ec.toString());
				genera(OP.ind_ass, $referencia.d.toString(),"-1", $referencia.r.toString());
				genera(OP.jump, null, null, efin.toString());
				genera(OP.skip, null, null, ef.toString());
				genera(OP.ind_ass, $referencia.d.toString(), "0", $referencia.r.toString());
				genera(OP.skip, null, null, efin.toString());
				backpatch($expr.cierto,ec);
				backpatch($expr.falso,ef);
			} else {
				genera(OP.ind_ass, $referencia.d.toString(), $expr.r.toString(), $referencia.r.toString());
			}
		} else {
			if($referencia.tsub==TSub.BOOLEAN) {
				Etiqueta ec=te.get(te.nuevaEtiqueta(false));
				Etiqueta ef=te.get(te.nuevaEtiqueta(false));
				Etiqueta efin=te.get(te.nuevaEtiqueta(false));
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
	}
	| referencia ';';

contcase
	returns[Variable r, boolean acababreak, Etiqueta etest, Deque<Integer> pilaefi, Deque<Etiqueta> pilasent, Deque<Integer> pilavar, Deque<Etiqueta> pilacond, Deque<Etiqueta> pilatest]
		:
	SWITCH expr BEGIN {
		$etest = te.get(te.nuevaEtiqueta(false));
		genera(OP.jump, null, null, $etest.toString());
		$r = $expr.r;
		$pilaefi = new ArrayDeque<>();
		$pilasent = new ArrayDeque<Etiqueta>();
		$pilavar = new ArrayDeque<Integer>();
		$pilacond = new ArrayDeque<Etiqueta>();
		$pilatest = new ArrayDeque<Etiqueta>();
	} contcase_[$r, true, $etest, $pilaefi, $pilasent, $pilavar, $pilacond, $pilatest] {
		$acababreak = $contcase_.acababreak;
	};

contcase_[Variable r, boolean acababreak1, Etiqueta etest, Deque<Integer> pilaefi, Deque<Etiqueta> pilasent, Deque<Integer> pilavar, Deque<Etiqueta> pilacond, Deque<Etiqueta> pilatest]
	returns[boolean acababreak]:
	caso {
		if(!$acababreak1 && $pilaefi.size()>0) {
			int seg = $pilaefi.removeLast();
			backpatch(seg, $caso.esent);
		}
		$pilaefi.add($caso.seg);
		$pilacond.add($caso.econd);
		$pilavar.add($caso.r.nv());
		$pilatest.add($caso.etest);
		$pilasent.add($caso.esent);
	} contcase_[$r, $caso.acababreak, $etest, $pilaefi, $pilasent, $pilavar, $pilacond, $pilatest] {
		$acababreak=$contcase_.acababreak;
	}
	| {
		$acababreak=$acababreak1;
	}; // lambda

caso
	returns[Variable r, Etiqueta econd, Etiqueta etest, Etiqueta esent, int seg, boolean acababreak]
		:
	CASE {
		$econd = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, $econd.toString());
	} expr ':' {
		$etest = te.get(te.nuevaEtiqueta(false));
		genera(OP.jump, null, null, $etest.toString());
		$esent = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, $esent.toString());
	} sents {
		$acababreak=false;
	} (
		BREAK ';' {
		$acababreak=true;
	}
	)? {
		$r = $expr.r;
		genera(OP.jump, null, null, null);
		$seg = pc;
	};

endcase
	returns[Etiqueta e, Etiqueta efi]:
	DEFAULT ':' {
		$e = te.get(te.nuevaEtiqueta(false));
		genera(OP.skip, null, null, $e.toString());
	} sents {
		$efi = te.get(te.nuevaEtiqueta(false));
		genera(OP.jump, null, null, $efi.toString());
	}
	|; // lambda

referencia
	returns[Variable r, Variable d, TSub tsub]:
	ID {
		Simbolo s;
		int t;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Tipo.CONST){
				t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,s.tsub());
				switch(s.tsub()) {
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
			$tsub=s.tsub();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| idx ']' {
		Variable t2;
		String nbytes = String.valueOf($idx.dt.ocupacion());
		if($idx.dt.b()==0) {
			t2 = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
			genera(OP.mult, $idx.d.toString(), nbytes, t2.toString());
		} else {
			String b = String.valueOf($idx.dt.b());
			Variable t1 = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
			genera(OP.sub, $idx.d.toString(), b, t1.toString());
			t2 = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
			genera(OP.mult, t1.toString(), nbytes, t2.toString());
		}
		$r = $idx.r;
		$d = t2;
	}
	| ID '(' ')' {
		Simbolo s;
		int t;
		try {
			s = ts.consulta($ID.getText());
			genera(OP.call, null, null, s.getNp().toString());
			if(s.getT()==Tipo.FUNC) {
				t = tv.nuevaVar(true, pproc.peek(),Tipo.VAR,s.tsub());
				$r = tv.get(t);
				$tsub=s.tsub();
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
			t = tv.nuevaVar(true, pproc.peek(),Tipo.VAR,$contIdx.s.tsub());
			$r = tv.get(t);
			$tsub = $contIdx.s.tsub();
			genera(OP.st, null, null, tv.get(t).toString());
		}
	};

idx
	returns[Tabla dt, Variable r, Variable d]:
	ID '[' expr {
		Simbolo dv = null;
		try {
			dv = ts.consulta($ID.getText());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		$dt = dv.getDt();
		Indice idx = $dt.primerIndice();
		$r = tv.get(dv.getNv());
		Variable d = $expr.r;
	} idx_[idx, d] {
		$d = $idx_.d;
	};

idx_[Indice idx1, Variable d1]
	returns[Variable d]:
	']' '[' expr {
		Indice idx = idx1.siguiente();
		Variable t1 = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
		genera(OP.mult, $d1.toString(), String.valueOf(idx.d()), t1.toString());
		Variable t2 = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
		genera(OP.add, t1.toString(), $expr.r.toString(), t2.toString());
	} idx_[idx, t2] {
		$d=$idx_.d;
	}
	| {
		$d=$d1; // Devuelve la misma variable que recibe
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
			$pparams.push($expr.r);
			// Boolean parámetro
			if($expr.cierto!=null || $expr.falso!=null) {
				Etiqueta ec=te.get(te.nuevaEtiqueta(false));
				Etiqueta ef=te.get(te.nuevaEtiqueta(false));
				Etiqueta efin=te.get(te.nuevaEtiqueta(false));
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
			Etiqueta ec=te.get(te.nuevaEtiqueta(false));
			Etiqueta ef=te.get(te.nuevaEtiqueta(false));
			Etiqueta efin=te.get(te.nuevaEtiqueta(false));
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
		Etiqueta e = te.get(te.nuevaEtiqueta(false));
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
		Etiqueta e = te.get(te.nuevaEtiqueta(false));
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
	| MOD exprNeg{
		int t = tv.nuevaVar(true,pproc.peek(),Tipo.VAR,TSub.INT);
		genera(OP.mod, $t1.toString(), $exprNeg.r.toString(), tv.get(t).toString());
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
		if($referencia.d!=null) {
			// Caso para cuando hay desplazamiento
			Variable t = tv.get(tv.nuevaVar(true, pproc.peek(), Tipo.VAR, TSub.INT));
			genera(OP.ind_val, $referencia.r.toString(), $referencia.d.toString(), t.toString());
			$r = t;
		} else {
			$r = $referencia.r;
		}
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
