parser grammar vajaC3D;
options
{
	tokenVocab = vajaLexer;
}

@parser::header {
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
ArrayList<Instruccion> c3d;
int pc = 0; // program counter
int profundidad=0;

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

public void imprimirC3D(){
	Writer buffer;
	File interFile = new File(directorio + "/intermedio.txt");
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
	//genera(e+": skip");
	genera(Instruccion.OP.et, "", "", e.toString());
	e.setNl(pc);
	backpatch($sents.sents_seg,e);
	imprimirC3D();
};

decl:
	VARIABLE tipo ID {
		Simbolo s=new Simbolo();
		boolean inicializada=false;
		try {
			s=ts.consulta($ID.getText());
			s.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR));
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} (
		'=' expr {
			inicializada=true;
			if(s.getTsub()==Simbolo.TSub.BOOLEAN) {
				Etiqueta ec=new Etiqueta();
				Etiqueta ef=new Etiqueta();
				Etiqueta efin=new Etiqueta();
				//genera(ec+": skip");
				genera(Instruccion.OP.et, "", "", ec.toString());
				ec.setNl(pc);
				//genera(s.getNv()+" = -1");
				genera(Instruccion.OP.copy, "-1", "", s.getNv().toString());
				//genera("goto "+efin);
				genera(Instruccion.OP.jump, "", "", efin.toString());
				//genera(ef+": skip");
				genera(Instruccion.OP.et, "", "", ef.toString());
				ef.setNl(pc);
				//genera(s.getNv()+" = 0");
				genera(Instruccion.OP.copy, "0", "", s.getNv().toString());
				//genera(efin+": skip");
				genera(Instruccion.OP.et, "", "", efin.toString());
				efin.setNl(pc);
				backpatch($expr.cierto,ec);
				backpatch($expr.falso,ef);
			} else {
				//genera(s.getNv()+" = "+$expr.r);
				genera(Instruccion.OP.copy, $expr.r.toString(), "", s.getNv().toString());
			}
	}
	)? {
		// Asignación de valor por defecto
		if(!inicializada) {
			switch(s.getTsub()) {
				case BOOLEAN:
				case INT:
					//genera(s.getNv()+" = 0");
					genera(Instruccion.OP.copy, "0", "", s.getNv().toString());
					break;
				case STRING:
					//genera(s.getNv()+" = \"\"");
					genera(Instruccion.OP.copy, "\"\"", "", s.getNv().toString());
					break;
			}
		}
	} ';'
	| CONSTANT tipo ID '=' literal ';' {
		Simbolo s;
		try {
			s = ts.consulta($ID.getText());
			switch(s.getTsub()) {
				case BOOLEAN:
					s.setvCB(Boolean.parseBoolean($literal.text));
					break;
				case INT:
					s.setvCI(Integer.parseInt($literal.text));
					break;
				case STRING:
					s.setvCS($literal.text);
					break;
			}
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
		Simbolo aux=$encabezado.s.getNext();
		try {
			while(aux!=null) {
				ts.consulta(aux.getId()).setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR));
				aux=aux.getNext();
			}
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta e=new Etiqueta(); // TODO Hacer una tabla de etiquetas y cambiar esto
		$encabezado.met.setInicio(e);
		//genera(e+": skip");
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
		//genera("pmb "+$encabezado.met.getNp());
		genera(Instruccion.OP.init, "", "", String.valueOf($encabezado.met.getNp()));
	} decl* sents {
		// genera("rtn "+$encabezado.met.getNp());
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
		Simbolo aux=$encabezado.s.getNext();
		while(aux!=null) {
			aux.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR));
			aux=aux.getNext();
		}
		Etiqueta e=new Etiqueta();
		$encabezado.met.setInicio(e);
		//genera(e+": skip");
		genera(Instruccion.OP.et, "", "", e.toString());
		e.setNl(pc);
		//genera("pmb "+$encabezado.met.getNp());
		genera(Instruccion.OP.init, "", "", String.valueOf($encabezado.met.getNp()));;
	} decl* sents {
		// genera("rtn "+$encabezado.met.getNp());
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
		//genera(ec + ": skip");
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} sents_[$sents_seg] {
		// TODO Comprobar si esto es correcto
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
		//genera(ec + ": skip");
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
		//genera(ec + ": skip");
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
		//genera(ec + ": skip");
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} decl* sents {
		Deque<Integer> sents_seg1 = $sents.sents_seg;
	} END ELSE BEGIN {
		Etiqueta ef = new Etiqueta();
		//genera(ef + ": skip");
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
		//genera(ei + ": skip");
		genera(Instruccion.OP.et, "", "", ei.toString());
		ei.setNl(pc);
	} expr BEGIN {
		Etiqueta ec = new Etiqueta();
		//genera(ec + ": skip");
		genera(Instruccion.OP.et, "", "", ec.toString());
		ec.setNl(pc);
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto,ec);
		backpatch($sent_seg,ei);
		$sent_seg=$expr.falso;
		//genera("goto "+ei);
		genera(Instruccion.OP.jump, "", "", ei.toString());
	} END
	| RETURN expr ';' {
		if($expr.cierto!=null || $expr.falso!=null) {//cambiar
			Etiqueta ec=new Etiqueta();
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			//genera(ec+": skip");
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			//genera($expr.r+" = -1");
			genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
			//genera("goto "+efin);
			genera(Instruccion.OP.jump, "", "", efin.toString());
			//genera(ef+": skip");
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			//genera($expr.r+" = 0");
			genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
			//genera(efin+": skip");
			genera(Instruccion.OP.et, "", "", efin.toString());
			efin.setNl(pc);
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		}
		//genera("rtn "+pproc.peek().getNp()+", "+$expr.r);
		genera(Instruccion.OP.ret, $expr.r.toString(), "", String.valueOf(pproc.peek().getNp()));
	}
	| RETURN ';' {
		//genera("rtn "+pproc.peek().getNp());
		genera(Instruccion.OP.ret, "", "", String.valueOf(pproc.peek().getNp()));
	}
	| referencia '=' expr ';' {
		if($referencia.tsub==Simbolo.TSub.BOOLEAN) {
			Etiqueta ec=new Etiqueta();
			Etiqueta ef=new Etiqueta();
			Etiqueta efin=new Etiqueta();
			//genera(ec+": skip");
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			//genera($referencia.r+" = -1");
			genera(Instruccion.OP.copy, "-1", "", $referencia.r.toString());
			//genera("goto "+efin);
			genera(Instruccion.OP.jump, "", "", ef.toString());
			//genera(ef+": skip");
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			//genera($referencia.r+" = 0");
			genera(Instruccion.OP.copy, "0", "", $referencia.r.toString());
			//genera(efin+": skip");
			genera(Instruccion.OP.et, "", "", efin.toString());
			efin.setNl(pc);
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		} else {
			//genera($referencia.r+" = "+$expr.r);
			genera(Instruccion.OP.copy, $expr.r.toString(), "", $referencia.r.toString());
		}
	}
	| referencia ';';

referencia
// returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso, Simbolo.TSub tsub]:
	returns[Variable r, Simbolo.TSub tsub]:
	ID {
		Simbolo s;
		Variable t;
		try {
			s = ts.consulta($ID.getText());
			if (s.getT() == Simbolo.Tipo.CONST){
				t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.CONST);
				t.setTemporal(true);
				switch(s.getTsub()) {
					case BOOLEAN:
						//genera(t+" = " + s.isvCB());
						genera(Instruccion.OP.copy, String.valueOf(s.isvCB()), "", t.toString());
						break;
					case INT:
						//genera(t+" = " + s.getvCI());
						genera(Instruccion.OP.copy, String.valueOf(s.getvCI()), "", t.toString());
						break;
					case STRING:
						//genera(t+" = " + s.getvCS());
						genera(Instruccion.OP.copy, s.getvCS(), "", t.toString());
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
			//genera("call " + s.getNp());
			genera(Instruccion.OP.call, "", "", s.getNp().toString());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| contIdx ')' {
		while($contIdx.pparams.size()>0) 
			//genera("param_s " + $contIdx.pparams.pop());
			genera(Instruccion.OP.params, "", "", $contIdx.pparams.pop().toString());
		//genera("call "+$contIdx.met.getNp());
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
			$pparams.push($expr.r);
			// Boolean parámetro
			if($expr.cierto!=null || $expr.falso!=null) {
				Etiqueta ec=new Etiqueta();
				Etiqueta ef=new Etiqueta();
				Etiqueta efin=new Etiqueta();
				//genera(ec+": skip");
				genera(Instruccion.OP.et, "", "", ec.toString());
				ec.setNl(pc);
				//genera($expr.r+" = -1");
				genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
				//genera("goto "+efin);
				genera(Instruccion.OP.jump, "", "", efin.toString());
				//genera(ef+": skip");
				genera(Instruccion.OP.et, "", "", ef.toString());
				ef.setNl(pc);
				//genera($expr.r+" = 0");
				genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
				//genera(efin+": skip");
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
			//genera(ec+": skip");
			genera(Instruccion.OP.et, "", "", ec.toString());
			ec.setNl(pc);
			//genera($expr.r+" = -1");
			genera(Instruccion.OP.copy, "-1", "", $expr.r.toString());
			//genera("goto "+efin);
			genera(Instruccion.OP.jump, "", "", efin.toString());
			//genera(ef+": skip");
			genera(Instruccion.OP.et, "", "", ef.toString());
			ef.setNl(pc);
			//genera($expr.r+" = 0");
			genera(Instruccion.OP.copy, "0", "", $expr.r.toString());
			//genera(efin+": skip");
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
		//genera("e : skip");
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
		//genera("e : skip");
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
		//genera("if " + $t1 + " " + $OPREL.getText() + " " + $exprAdit.r + " goto ");
		genera(valorSaltoCond($OPREL.getText()), $t1.toString(), $exprAdit.r.toString(), "");
		$cierto=new ArrayDeque<Integer>();
 		$cierto.add(pc);
		//genera("goto ");
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
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		//genera(t+" = " + $t1 + " + " + $exprMult.r);
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
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		//genera(t+" = " + $t1 + " - " + $exprMult.r);
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
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		//genera(t+" = " + $t1 + " * " + $exprNeg.r);
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
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		//genera(t+" = " + $t1 + " / " + $exprNeg.r);
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
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		//genera(t+" = - " + $primario.r);
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
			//genera("if "+$r+" = -1 goto ");
			genera(Instruccion.OP.ifEQ, $r.toString(), "-1", "");
			$cierto=new ArrayDeque<Integer>();
			$cierto.add(pc);
			//genera("goto ");
			genera(Instruccion.OP.jump, "", "", "");
			$falso=new ArrayDeque<Integer>();
			$falso.add(pc);
		}
	}
	| literal {
		Variable t = tv.nuevaVar(pproc.peek(), Simbolo.Tipo.VAR);
		t.setTemporal(true);
		$r = t;
		if($literal.tsub == Simbolo.TSub.BOOLEAN){
			Etiqueta e = new Etiqueta();
			if($literal.text.equals("true")) {
				//genera(t+" = -1");
				genera(Instruccion.OP.copy, "-1", "", t.toString());
				//genera("goto ");
				genera(Instruccion.OP.jump, "", "", "");
				$cierto=new ArrayDeque<Integer>();
				$cierto.add(pc);
				$falso = null;
			} else {
				//genera(t+" = 0");
				genera(Instruccion.OP.copy, "0", "", t.toString());
				//genera("goto ");
				genera(Instruccion.OP.jump, "", "", "");
				$falso=new ArrayDeque<Integer>();
				$falso.add(pc);
				$cierto = null;
			}
		} else {
			//genera(t+" = " + $literal.text);
			genera(Instruccion.OP.copy, $literal.text, "", t.toString());
		}
	};

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