grammar vaja;

// SINTAXIS

@header {
	package procesador.antlr;
	import procesador.*;
}

@parser::members {
	TablaSimbolos ts;
	boolean returnreq = false;
	boolean returnenc = false;
	Simbolo.TipoSubyacente tiporeturn = null;
	String errores="";
        String directorio;
        
        public vajaParser(TokenStream input,String directorio){
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

}

@lexer::members {
	@Override
	public void recover(RecognitionException ex) 
	{
		throw new RuntimeException("ERROR LEXICO -  "+ex.getMessage()); 
	}

 }

programaPrincipal:
	{
		try{
			ts=new TablaSimbolos(directorio);
			Simbolo operacionArg;
			//Operación de entrada
			ts.inserta("read",new Simbolo("read",null,Simbolo.Tipo.FUNC,
				Simbolo.TipoSubyacente.STRING));
			// Operaciones de salida
			for(Simbolo.TipoSubyacente tsub : Simbolo.TipoSubyacente.values()){
				if(tsub!=Simbolo.TipoSubyacente.NULL){
					operacionArg=new Simbolo("print"+tsub+"Arg",null,Simbolo.Tipo.ARG,tsub);
					ts.inserta("print"+tsub,new Simbolo("print"+tsub,operacionArg, 
						Simbolo.Tipo.PROC,Simbolo.TipoSubyacente.NULL));
				}
			}

		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - error al crear la tabla de símbolos: "
				+ ex.getMessage()+"\n");
		}
	} declaracion* EOF {
		try{
			ts.saleBloque();
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - error con la tabla de símbolos: "+ex.getMessage()+"\n");
		}
		if(!errores.isEmpty()){
			throw new RuntimeException(errores);
		}
	};

declaracion:
	'var' tipo declaracionVar[$tipo.tsub]
	| 'const' tipo declaracionConst[$tipo.tsub]
	| 'func' declFunc
	| 'proc' declProc
	| ';';

tipo
	returns[ Simbolo.TipoSubyacente tsub]:
	INT { $tsub=Simbolo.TipoSubyacente.INT;}
	| BOOLEAN { $tsub=Simbolo.TipoSubyacente.BOOLEAN;}
	| STRING { $tsub=Simbolo.TipoSubyacente.STRING;};

// Variables y constantes	
declaracionVar[Simbolo.TipoSubyacente tsub]:
	Identificador {
		try{
			ts.inserta($Identificador.getText(), 
				new Simbolo($Identificador.getText(),
				null,Simbolo.Tipo.VAR,$tsub));
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", la variable "
				+ $Identificador.getText()+" ya ha sido declarada\n");
		}
	 } (
		'=' initVar {
		 if($initVar.tsub != $tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", tipos incompatibles \n"+
			"encontrado: "+$initVar.tsub+" esperado: "+$tsub+"\n");
		 }
	 }
	)? ';';

declaracionConst[Simbolo.TipoSubyacente tsub]:
	Identificador {
		try{
			ts.inserta($Identificador.getText(), new Simbolo($Identificador.getText(),null,Simbolo.Tipo.CONST,$tsub));
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", la variable "+$Identificador.getText()+
			" ya ha sido declarada\n");
		}
	 } '=' initConst ';' {
		 if($initConst.tsub != $tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", tipos incompatibles \n"+
			"encontrado: "+$initConst.tsub+" esperado: "+$tsub+"\n");
		 }
	 };

initVar
	returns[Simbolo.TipoSubyacente tsub]:
	expr { $tsub = $expr.tsub;};

initConst
	returns[Simbolo.TipoSubyacente tsub]:
	expr { $tsub = $expr.tsub; };

// Funciones y procedimientos
declFunc:
	encabezadoFunc cuerpoFunc[$encabezadoFunc.metodo];

encabezadoFunc
	returns[Simbolo metodo]:
	identificadorMetFunc tipo {
		try{
			$identificadorMetFunc.metodo.setTs($tipo.tsub);
			$metodo = $identificadorMetFunc.metodo;
			ts.inserta($identificadorMetFunc.metodo.getId(), $identificadorMetFunc.metodo);
		}catch (TablaSimbolos.exceptionTablaSimbolos e){
			errores += ("ERROR SEMANTICO - Línea: " + $identificadorMetFunc.linea + ": " + e.getMessage()+"\n");
		}
	};

cuerpoFunc[Simbolo metodo]: bloque[$metodo] | ';';

declProc:
	encabezadoProc cuerpoProc[$encabezadoProc.metodo];

encabezadoProc
	returns[Simbolo metodo]:
	identificadorMetProc {
		try{
			$metodo = $identificadorMetProc.metodo;
			ts.inserta($identificadorMetProc.metodo.getId(), $identificadorMetProc.metodo);
		}catch (TablaSimbolos.exceptionTablaSimbolos e){
			errores += ("ERROR SEMANTICO - Línea: " + $identificadorMetProc.linea + ": " + e.getMessage()+"\n");
		}
	};

cuerpoProc[Simbolo metodo]: bloque[$metodo] | ';';

identificadorMetFunc
	returns[Simbolo metodo, int linea]:
	Identificador {
		$metodo = new Simbolo($Identificador.getText(), null, Simbolo.Tipo.FUNC, Simbolo.TipoSubyacente.NULL);
	} '(' parametros[$metodo]? ')';

identificadorMetProc
	returns[Simbolo metodo, int linea]:
	Identificador {
		$metodo = new Simbolo($Identificador.getText(), null, Simbolo.Tipo.PROC, Simbolo.TipoSubyacente.NULL);
	} '(' parametros[$metodo]? ')';

parametros[Simbolo ant]:
	parametro ',' {
		$ant.setNext($parametro.s);
	} parametros[$ant.getNext()]
	| parametro {
		$ant.setNext($parametro.s);
		$parametro.s.setNext(null);
	};

parametro
	returns[Simbolo s]:
	tipo identificadorVar {
		$s = new Simbolo($identificadorVar.id, null, Simbolo.Tipo.ARG, $tipo.tsub);
	};

identificadorVar
	returns[String id]:
	Identificador {
		$id = $Identificador.getText();
	};

bloque[Simbolo met]:
	{
		ts=ts.entraBloque();
		if($met != null){
			if($met.getT() == Simbolo.Tipo.FUNC){
				returnreq = true;
				tiporeturn = $met.getTs();
			} 
			Simbolo ps = $met.getNext();
			while(ps != null){
				Simbolo saux = new Simbolo(ps);
				saux.setNext(null);
				try{
					ts.inserta(saux.getId(), saux);
				} catch(TablaSimbolos.exceptionTablaSimbolos e){
					errores += (e.getMessage()+"\n");
				}
				ps = ps.getNext();
			}
		}
	} '{' exprsBloque? '}' {
		ts = ts.saleBloque();
		if($met != null){
			if($met.getT() == Simbolo.Tipo.FUNC){
				if(!returnenc){
					errores += ("ERROR SEMANTICO: falta return para la función " + $met.getId() + "\n");
				}
			} else if ($met.getT() == Simbolo.Tipo.PROC){
				if(returnenc){
					errores += ("ERROR SEMANTICO: encontrado return para el procedimiento " + $met.getId() + "\n");
				}
			}
			returnreq = false;
			returnenc = false;
			tiporeturn = null;
		}
	};

exprsBloque: exprDeBloque+;

exprDeBloque: sentDeclVarLocal | sent;

sentDeclVarLocal:
	declaracionVarLocal[Simbolo.Tipo.VAR];

declaracionVarLocal[Simbolo.Tipo t]:
	tipo declaracionVar[$tipo.tsub];

sent:
	bloque[null]
	| sentVacia
	| sentExpr
	| sentIf
	| sentIfElse
	| sentWhile
	| sentReturn;

sentVacia: ';';

sentExpr: exprSent ';';

exprSent: asignacion | sentInvocaMet;

sentIf:
	{
			boolean reqaux = returnreq;
			boolean encaux = returnenc;
			returnreq = false;
		} IF '(' expr ')' bloque[null] {
			if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
				errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
				"La expresión debe ser de tipo BOOLEAN\n");
			}
			returnreq = reqaux;
			returnenc = encaux;
		};

sentIfElse:
	IF '(' expr ')' bloque[null]{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
				errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
				"La expresión debe ser de tipo BOOLEAN\n");
		}
		boolean primerreturn = returnenc;
		returnenc = false;

	} ELSE bloque[null] {
		if(!(primerreturn && returnenc)){
			returnenc = false;
		}
	};

sentWhile:
	{
			boolean reqaux = returnreq;
			boolean encaux = returnenc;
			returnreq = false;
		} WHILE '(' expr ')' bloque[null]{
			if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
				errores += ("ERROR SEMANTICO - Línea: " +$WHILE.getLine()+"\n"+
				"La expresión debe ser de tipo BOOLEAN\n");
			}
			returnreq = reqaux;
			returnenc = encaux;
		};

sentReturn:
	RETURN expr ';' {
			try {
				if($expr.tsub != tiporeturn){
					errores += ("ERROR SEMANTICO - Línea: " +$RETURN.getLine()+"\n"+
					"Tipo en el return encontrado: "+$expr.tsub+"\n"+
					"Tipo en el return esperado: "+tiporeturn+"\n");
				} else {
					returnenc = true;
				}
			} catch (NullPointerException e){
				returnenc = true;
			}
	};

sentInvocaMet
	returns[Simbolo.TipoSubyacente tsub]:
	Identificador '(' {
		boolean argEnc=false;
		try{
			Simbolo s;
			if((s=ts.consulta($Identificador.getText()))!=null && !$Identificador.getText().equals("print")){
				if(s.getT()==Simbolo.Tipo.PROC){
					$tsub=Simbolo.TipoSubyacente.NULL;
				} else if(s.getT()==Simbolo.Tipo.FUNC){
					$tsub=s.getTs();
				}
			} else if($Identificador.getText().equals("print")) {
				$tsub = Simbolo.TipoSubyacente.NULL;
			}
			
		}catch(TablaSimbolos.exceptionTablaSimbolos e){
			errores+=("ERROR SEMANTICO - Línea: " + $Identificador.getLine() +", "+ e.getMessage()+"\n");
		}
	} (
		argumentos[$Identificador.getText(), $Identificador.getLine()] {
		argEnc=true;
	}
	)? ')' {
		try{
			if(!argEnc && ($Identificador.getText().equals("print") || ts.consulta($Identificador.getText()).getNext()!= null)){
				errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", faltan parámetros para "+$Identificador.getText()+"\n");
			}	
		} catch(TablaSimbolos.exceptionTablaSimbolos e) {
			errores += (e.getMessage()+"\n");
		}
	};

argumentos[String nombre, int linea]:
	{
		Simbolo metodo=null;
		boolean demasiadosArg=false;
		try{
			metodo=ts.consulta($nombre).getNext();
		}catch(TablaSimbolos.exceptionTablaSimbolos ex){
			errores+=("ERROR SEMANTICO - Línea: "+$linea+", error con la tabla de símbolos: "+ex.getMessage()+"\n");
		}		
	} expr {
		if($nombre.equals("print")){
			String print = "print" + $expr.tsub;
			try{
				Simbolo.TipoSubyacente tprint = ts.consulta(print).getNext().getTs();
			} catch (TablaSimbolos.exceptionTablaSimbolos e){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", al invocar "+ $nombre +" no se esperaba un " + $expr.tsub + "\n");
			}
		}else {
			if(metodo==null){
				demasiadosArg=true;
				errores+=("ERROR SEMANTICO - Línea "+$linea+"\n");
			}

			if(metodo==null){
				demasiadosArg=true;
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", "+ $nombre +"tiene demasiados argumentos" + "\n");
			}else{
				if(metodo.getTs()!=$expr.tsub){
					errores+=("ERROR SEMANTICO - Línea: "+$linea+", tipos incompatibles\n"+
					"encontrado: "+$expr.tsub+" esperado "+metodo.getTs()+"\n");
				}
				metodo=metodo.getNext();
			}
		}
 	} (
		',' expr {
		if(metodo == null || $nombre.equals("print")){
			if(!demasiadosArg){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", "+ $nombre +"tiene demasiados argumentos" + "\n");
				demasiadosArg = true;
			}
		}
		if(metodo != null){
			if(metodo.getTs() != $expr.tsub){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", al invocar"+ $nombre +"se esperaba un " + metodo.getTs() + " y se ha encontrado un " + $expr.tsub + "\n");
			}
			metodo = metodo.getNext();
		}
	}
	)* {
		if(metodo != null){
		errores+=("ERROR SEMANTICO - Línea: "+$linea+", a "+ $nombre +"le faltan argumentos" + "\n");
		}
	};

asignacion
	returns[ Simbolo.TipoSubyacente tsub ]:
	Identificador '=' expr { 
		Simbolo.TipoSubyacente idTsub = null;
		Simbolo.Tipo idT = null;
		try{
			idTsub = ts.consulta($Identificador.getText()).getTs();
			idT = ts.consulta($Identificador.getText()).getT();
		}catch(TablaSimbolos.exceptionTablaSimbolos ex){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", "+ex.getMessage()+"\n");
		}
		if(idT==Simbolo.Tipo.CONST){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", "+$Identificador.getText()+" es una constante\n");
		}else if(idTsub!=$expr.tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", asignación no permitida a "+$Identificador.getText()+
			" \nencontrado: "+$expr.tsub+" esperado: "+idTsub+"\n");
		}
		$tsub=idTsub;
	};

expr
	returns[ Simbolo.TipoSubyacente tsub]:
	exprCondOr { $tsub=$exprCondOr.tsub;}
	| asignacion { $tsub=$asignacion.tsub;};

exprCondOr
	returns[ Simbolo.TipoSubyacente tsub]:
	exprCondAnd exprCondOr_ { 
		if($exprCondOr_.tsub!=null){
			if($exprCondAnd.tsub!=$exprCondOr_.tsub){
				errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
				"encontrado: "+$exprCondOr_.tsub+" esperado: "+$exprCondAnd.tsub+"\n");
			}else{
				$tsub=Simbolo.TipoSubyacente.BOOLEAN;
			}
		}else{
			$tsub=$exprCondAnd.tsub;
		}
	};

exprCondOr_
	returns[ Simbolo.TipoSubyacente tsub]:
	OR exprCondAnd exprCondOr_ { 
		if($exprCondAnd.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
			"encontrado: "+$exprCondAnd.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=Simbolo.TipoSubyacente.BOOLEAN;
	}
	|; //lambda

exprCondAnd
	returns[ Simbolo.TipoSubyacente tsub]:
	exprComp exprCondAnd_ { 
		if($exprCondAnd_.tsub!=null){
			if($exprComp.tsub!=$exprCondAnd_.tsub){
				errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
				"encontrado: "+$exprCondAnd_.tsub+" esperado: "+$exprComp.tsub+"\n");
			}else{
				$tsub=Simbolo.TipoSubyacente.BOOLEAN;
			}
		}else{
			$tsub=$exprComp.tsub;
		}
	};

exprCondAnd_
	returns[ Simbolo.TipoSubyacente tsub]:
	AND exprComp exprCondAnd_ {
		if($exprComp.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
			"encontrado: "+$exprComp.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=Simbolo.TipoSubyacente.BOOLEAN;
	}
	|; //lambda

exprComp
	returns[ Simbolo.TipoSubyacente tsub]:
	exprSuma exprComp_ { 
		if($exprComp_.tsub!=null){
			if($exprSuma.tsub!=$exprComp_.tsub){
				errores+=("ERROR SEMANTICO - comparación de tipos incompatibles\n"+
				"encontrado: "+$exprComp_.tsub+" esperado: "+$exprSuma.tsub+"\n");
			}
			$tsub=Simbolo.TipoSubyacente.BOOLEAN;
		}else{
			$tsub=$exprSuma.tsub;
		}
	};

exprComp_
	returns[ Simbolo.TipoSubyacente tsub]:
	Comparador exprSuma exprComp_ {
		if($exprSuma.tsub==Simbolo.TipoSubyacente.BOOLEAN && !($Comparador.getText().equals("==") || $Comparador.getText().equals("!="))){
			errores+=("ERROR SEMANTICO - Línea: "+$Comparador.getLine()+", comparación incompatible con tipo BOOLEAN\n");
		}
		if($exprComp_.tsub!=null && $exprSuma.tsub!=$exprComp_.tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Comparador.getLine()+", comparación de tipos incompatibles\n"+
			"encontrado: "+$exprComp_.tsub+" esperado: "+$exprSuma.tsub+"\n");
		}
		$tsub=$exprSuma.tsub;
	}
	|; //lambda

exprSuma
	returns[ Simbolo.TipoSubyacente tsub]:
	exprMult exprSuma_ {
		if($exprSuma_.tsub!=null && $exprMult.tsub!=$exprSuma_.tsub){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprSuma_.tsub+" esperado: "+$exprMult.tsub+"\n");
		}
		$tsub=$exprMult.tsub;
	};

exprSuma_
	returns[ Simbolo.TipoSubyacente tsub]:
	OpBinSum exprMult exprSuma_ { 
		if($exprMult.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprMult.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprMult.tsub;
	}
	|; //lambda

exprMult
	returns[ Simbolo.TipoSubyacente tsub ]:
	exprUnaria exprMult_ {
		if($exprMult_.tsub!=null && $exprUnaria.tsub!=$exprMult_.tsub){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprMult_.tsub+" esperado: "+$exprUnaria.tsub+"\n");
		}
		$tsub=$exprUnaria.tsub;
	};

exprMult_
	returns[ Simbolo.TipoSubyacente tsub ]:
	MULT exprUnaria exprMult_ {
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - Línea: "+$MULT.getLine()+", tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	| DIV exprUnaria exprMult_ {
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - Línea: "+$DIV.getLine()+", tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	|; //lambda

exprUnaria
	returns[ Simbolo.TipoSubyacente tsub ]:
	OpBinSum exprNeg {
		if($exprNeg.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprNeg.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprNeg.tsub;
	}
	| exprNeg { $tsub=$exprNeg.tsub; };

exprNeg
	returns[ Simbolo.TipoSubyacente tsub ]:
	NOT exprUnaria {
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	| exprPostfija { $tsub=$exprPostfija.tsub; };

exprPostfija
	returns[ Simbolo.TipoSubyacente tsub ]:
	primario { $tsub=$primario.tsub; }
	| Identificador {
		try{
			Simbolo s=ts.consulta($Identificador.getText());
                        if(s!=null){
                            $tsub=s.getTs();
                        }
		}catch(TablaSimbolos.exceptionTablaSimbolos ex){
			errores+=("ERROR SEMANTICO - "+ex.getMessage()+"\n");
		}
	}
	| sentInvocaMet { $tsub=$sentInvocaMet.tsub; };

primario
	returns[ Simbolo.TipoSubyacente tsub ]:
	'(' expr ')' { $tsub=$expr.tsub; }
	| literal { $tsub=$literal.tsub; };

literal
	returns[ Simbolo.TipoSubyacente tsub ]:
	LiteralInteger { $tsub=Simbolo.TipoSubyacente.INT; }
	| LiteralBoolean { $tsub=Simbolo.TipoSubyacente.BOOLEAN; }
	| LiteralString { $tsub=Simbolo.TipoSubyacente.STRING; };

// LÉXICO

// Palabras reservadas
VAR: 'var';
CONST: 'const';
FUNCTION: 'func';
PROCEDURE: 'proc';
RETURN: 'return';

// Tipos
INT: 'int';
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
Comparador: EQUAL | NOTEQUAL | GT | LT | GE | LE;

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
Identificador: LETRA LETRADIGITO*;

fragment LETRA: [a-zA-Z$_];

fragment LETRADIGITO: [a-zA-Z$_0-9];

// Comentarios y espacios en blanco
WS: [ \r\n\t]+ -> skip;

BLOCK_COMMENT: '/*' .*? '*/' -> skip;

LINE_COMMENT: '#' ~[\r\n]* -> skip;