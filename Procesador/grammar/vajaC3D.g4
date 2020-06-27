parser grammar vajaC3D;
options
{
	tokenVocab = vajaLexer;
}

@parser::header {
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
ArrayList<StringBuilder> c3d = new ArrayList<>(); // TODO Crear clase propia
// TODO Asegurarse de que no tenga que ser -1 en vez de 0
int pc = 0; // program counter
int profundidad=0;

public vajaC3D(TokenStream input, String directorio, TablaSimbolos ts){
	this(input);
	this.directorio=directorio;
	this.ts=ts;
	this.tv= new TablaVariables(directorio);
	this.tp= new TablaProcedimientos();
}

public void genera(String codigo){
	pc++;
	StringBuilder aux=new StringBuilder();
	aux.append(codigo);
	c3d.add(aux);
}

public void imprimirC3D(){
	Writer buffer;
	File interFile = new File(directorio + "/intermedio.txt");
	try {
		buffer = new BufferedWriter(new FileWriter(interFile));
		for(int i=0;i<c3d.size();i++) {
			buffer.write(c3d.get(i).toString()+"\n");
		}
		buffer.close();
	} catch(IOException e) {}
}

public void backpatch(Deque<Integer> lista, Etiqueta e){
	if(lista!=null) {
		while(lista.size()>0) {
			int instruccion=lista.remove();
			c3d.get(instruccion).append(e.toString());
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
	genera(e+": skip");
	e.setNl(pc);
	backpatch($sents.sents_seg,e);
	// TODO Según los apuntes aquí faltan cosas
	imprimirC3D();
};

decl:
	VARIABLE tipo ID {
		// Asignación de valor por defecto
		Simbolo s=new Simbolo();
		try {
			s=ts.consulta($ID.getText());
			s.setNv(tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR));
			switch(s.getTsub()) {
				case BOOLEAN:
					genera(s.getNv()+" = false");
					break;
				case INT:
					genera(s.getNv()+" = 0");
					break;
				case STRING:
					genera(s.getNv()+" = \"\"");
					break;
			} 
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} (
		'=' expr {
		genera(s.getNv()+" = "+$expr.r);
	}
	)? ';'
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
	| FUNCTION tipo encabezado BEGIN {
		profundidad++;
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		pproc.push($encabezado.met);
		Etiqueta e=new Etiqueta(); // TODO Hacer una tabla de etiquetas y cambiar esto
		$encabezado.met.setInicio(e);
		genera(e+": skip");
		genera("pmb "+$encabezado.met.getNp()); // TODO Comprobar si esto se hace aquí
	} decl* sents {
		genera("rtn "+$encabezado.met.getNp());
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
		pproc.push($encabezado.met);
		Etiqueta e=new Etiqueta();
		$encabezado.met.setInicio(e);
		genera(e+": skip");
		e.setNl(pc);
		genera("pmb "+$encabezado.met.getNp());
	} decl* sents {
		genera("rtn "+$encabezado.met.getNp());
		profundidad--;
		ts=ts.subeBloque();
	} END;

encabezado
	returns[Procedimiento met]:
	ID '(' parametros? ')' {
		Simbolo s=new Simbolo();
		Procedimiento met;
		try {
			s=ts.consulta($ID.getText());
			met=tp.nuevoProc(profundidad,s.getT());
			s.setNp(met);
			$met = met;
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
		try{
			ts=ts.bajaBloque();
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
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
		genera(ec + ": skip");
		ec.setNl(pc);
	} decl* sents {
		Deque<Integer> sents_seg1 = $sents.sents_seg;
	} END ELSE BEGIN {
		Etiqueta ef = new Etiqueta();
		genera(ef + ": skip");
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
		genera(ei + ": skip");
		ei.setNl(pc);
	} expr BEGIN {
		Etiqueta ec = new Etiqueta();
		genera(ec + ": skip");
		ec.setNl(pc);
	} decl* sents {
		ts=ts.subeBloque();
		backpatch($expr.cierto,ec);
		backpatch($sent_seg,ei);
		$sents_seg=$expr.falso;
		genera("goto "+ei);
	} END
	| RETURN expr ';'
	| referencia '=' expr ';' {
		// $sent_seg=null;
		if($referencia.tsub==Simbolo.TSub.BOOLEAN) {
			Etiqueta ec=new Etiqueta();
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
			backpatch($expr.cierto,ec);
			backpatch($expr.falso,ef);
		} else {
			genera($referencia.r+" = "+$expr.r);		
		}
	}
	| referencia ';';

referencia
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso, Simbolo.TSub tsub]:
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
						genera(t+" = " + s.isvCB());
						break;
					case INT:
						genera(t+" = " + s.getvCI());
						break;
					case STRING:
						genera(t+" = " + s.getvCS());
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
			genera("call " + s.getNp());
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	}
	| contIdx ')' {
		while($contIdx.pparams.size()>0) genera("param_s " + $contIdx.pparams.pop());
		genera("call "+$contIdx.met.getNp());
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
		} catch(TablaSimbolos.TablaSimbolosException e) {
			System.out.println("Error con la tabla de símbolos: "+e.getMessage());
		}
	} contIdx_[$pparams];

contIdx_[Deque<Variable> pparams]:
	',' expr {
		$pparams.push($expr.r);
	} contIdx_[$pparams]
	|; // lambda


expr
	returns[Variable r, Deque<Integer> cierto, Deque<Integer> falso]:
	// Lógicas
	NOT expr {
		$cierto = $expr.falso;
		$falso = $expr.cierto;
	}
	| expr {
		Variable r = new Variable($expr.r);
    } OPREL expr {
		genera("if " + r + " " + $OPREL.getText() + " " + $expr.r + " goto ");
		$cierto=new ArrayDeque<Integer>();
 		$cierto.add(pc);
		genera("goto ");
		$falso=new ArrayDeque<Integer>();
 		$falso.add(pc);

		$r = $expr.r;
    }
	| expr {
		Deque<Integer> cierto = $expr.cierto;
		Deque<Integer> falso = $expr.falso;
	} AND {
		Etiqueta e = new Etiqueta();
		genera(e+": skip");
		e.setNl(pc);
	} expr {
		backpatch(cierto, e);
		$falso = concat(falso, $expr.falso);
		$cierto = $expr.cierto;

		$r = $expr.r;
	}
	| expr {
		Deque<Integer> cierto = $expr.cierto;
		Deque<Integer> falso = $expr.falso;
	} OR {
		Etiqueta e = new Etiqueta();
		genera(e+": skip");
		e.setNl(pc);
	} expr {
		backpatch(falso, e); 
		$cierto = concat(cierto, $expr.cierto);
		$falso = $expr.falso;

		$r = $expr.r;
	}
	// Aritméticas
	| SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		genera(t+" = - " + $expr.r);
		$r = t;
	}
	| expr {
		Variable r = new Variable($expr.r);
	} MULT expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		genera(t+" = " + r + " * " + $expr.r);
		$r = t;
	}
	| expr {
		Variable r = new Variable($expr.r);
	} DIV expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		genera(t+" = " + r + " / " + $expr.r);
		$r = t;
	}
	| expr {
		Variable r = new Variable($expr.r);
	} ADD expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		genera(t+" = " + r + " + " + $expr.r);
		$r = t;
	}
	| expr {
		Variable r = new Variable($expr.r);
	} SUB expr {
		Variable t = tv.nuevaVar(pproc.peek(),Simbolo.Tipo.VAR);
		t.setTemporal(true);
		genera(t+" = " + r + " - " + $expr.r);
		$r = t;
	}
	| '(' expr ')' {
		$r = $expr.r;
		$cierto = $expr.cierto;
		$falso = $expr.falso;
	}
	| referencia {
		$r = $referencia.r;
		$cierto = $referencia.cierto;
		$falso = $referencia.falso;
	}
	| literal {
		Variable t = tv.nuevaVar(pproc.peek(), Simbolo.Tipo.VAR);
		genera(t+" = " + $literal.tsub);
		t.setTemporal(true);
		$r = t;
		if($literal.tsub == Simbolo.TSub.BOOLEAN){
			if($literal.text.equals("true")) {
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
