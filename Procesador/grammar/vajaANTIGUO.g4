grammar vajaANTIGUO;

@header {
package antlr;
import procesador.*;
import java.io.*;
import java.util.*;
}

@parser::members {
public TablaSimbolos ts;
boolean returnreq = false;
boolean returnenc = false;
Simbolo.TipoSubyacente tiporeturn = null;
String errores="";
String directorio;

public vajaANTIGUOParser(TokenStream input,String directorio){
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
	notificacion = notificacion.replaceAll("OPREL","==, !=, <, >, <=, >=");
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
		// DOT
		try{
            File arbolFile=new File(this.directorio+"/arbol.dot");
			writer = new BufferedWriter(new FileWriter(arbolFile));
            writer.write("digraph G {");//}
        }catch (Exception e){}
		String programaPrincipal="programaPrincipal"+(dot++);
	} (declaracion[programaPrincipal]|sents)* EOF {
		try{
			ts.saleBloque();
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - error con la tabla de símbolos: "+ex.getMessage()+"\n");
		}
		if(!errores.isEmpty()){
			throw new RuntimeException(errores);
		}
		// DOT
		try{//{
            writer.write("}");
            writer.close();
        }catch (Exception e){}
	};

declaracion[String padre]:
	{
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}
        try{writer.write(declaracion+"->var"+(dot++)+";\n");}catch(Exception e){}
	} 'var' {
		try{writer.write(declaracion+"->tipo"+(dot)+";\n");}catch(Exception e){}
	} tipo {
		try{writer.write(declaracion+"->declaracionVar"+(dot)+";\n");}catch(Exception e){}
	} declaracionVar[$tipo.tsub]
	|
	{
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}
        try{writer.write(declaracion+"->const"+(dot++)+";\n");}catch(Exception e){}}'const'
		{try{writer.write(declaracion+"->tipo"+(dot)+";\n");}catch(Exception e){}}tipo
		{try{writer.write(declaracion+"->declaracionConst"+(dot)+";\n");}catch(Exception e){}}declaracionConst[$tipo.tsub]
	|
	{
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}
        try{writer.write(declaracion+"->func"+(dot++)+";\n");}catch(Exception e){}}'func'
		{try{writer.write(declaracion+"->declFunc"+(dot)+";\n");}catch(Exception e){}}declFunc
	|
	{
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}
        try{writer.write(declaracion+"->proc"+(dot++)+";\n");}catch(Exception e){}}'proc'
		{try{writer.write(declaracion+"->declProc"+(dot)+";\n");}catch(Exception e){}}declProc
	;

tipo
	returns[ Simbolo.TipoSubyacente tsub]:
	{
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->int"+(dot++)+";\n");}catch(Exception e){}}}
	INT
		{$tsub=Simbolo.TipoSubyacente.INT;}
	|
	{
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->boolean"+(dot++)+";\n");}catch(Exception e){}}}
	BOOLEAN
		{ $tsub=Simbolo.TipoSubyacente.BOOLEAN;}
	|
	{
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->string"+(dot++)+";\n");}catch(Exception e){}}}
	STRING
		{ $tsub=Simbolo.TipoSubyacente.STRING;}
	;

// Variables y constantes
declaracionVar[Simbolo.TipoSubyacente tsub]:
	{
    String declaracionVar="declaracionVar"+(dot++);}
	Identificador {
		try{
			ts.inserta($Identificador.getText(),
				new Simbolo($Identificador.getText(),
				null,Simbolo.Tipo.VAR,$tsub));
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", la variable "
				+ $Identificador.getText()+" ya ha sido declarada\n");
		}
		// DOT
		try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText()+"];\n");}catch(Exception e){}}
        {try{writer.write(declaracionVar+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}
	}
	(
		{try{writer.write(declaracionVar+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}}
	'='
		{try{writer.write(declaracionVar+"->initVar"+(dot)+";\n");}catch(Exception e){}}
	initVar
	{
		if($initVar.tsub != $tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", tipos incompatibles \n"+
			"encontrado: "+$initVar.tsub+" esperado: "+$tsub+"\n");
		}
	}
	)?
		{try{writer.write(declaracionVar+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}
	';'
	;

declaracionConst[Simbolo.TipoSubyacente tsub]:
	{
        String declaracionConst="declaracionConst"+(dot++);}
	Identificador
	{
		try{
			ts.inserta($Identificador.getText(), new Simbolo($Identificador.getText(),null,Simbolo.Tipo.CONST,$tsub));
		}catch(Exception ex){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", la variable "+$Identificador.getText()+
			" ya ha sido declarada\n");
		}
		// DOT
		try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}}
        {try{writer.write(declaracionConst+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}}
        {try{writer.write(declaracionConst+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}
	}
	'='
		{try{writer.write(declaracionConst+"->initConst"+(dot)+";\n");}catch(Exception e){}}
	initConst
		{try{writer.write(declaracionConst+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}
	';'
	{
		 if($initConst.tsub != $tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()+", tipos incompatibles \n"+
			"encontrado: "+$initConst.tsub+" esperado: "+$tsub+"\n");
		 }
	}
	;

initVar
	returns[Simbolo.TipoSubyacente tsub]:
	{
        String initVar="initVar"+(dot++);}
        {try{writer.write(initVar+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{$tsub = $expr.tsub;}
	;

initConst
	returns[Simbolo.TipoSubyacente tsub]:
	{
        String initConst="initConst"+(dot++);}
        {try{writer.write(initConst+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{$tsub = $expr.tsub; }
	;

// Funciones y procedimientos
declFunc:
	{
        String declFunc="declFunc"+(dot++);}
        {try{writer.write(declFunc+"->encabezadoFunc"+(dot)+";\n");}catch(Exception e){}}
	encabezadoFunc
		{try{writer.write(declFunc+"->cuerpoFunc"+(dot)+";\n");}catch(Exception e){}}
	cuerpoFunc[$encabezadoFunc.metodo]
	;

encabezadoFunc
	returns[Simbolo metodo]:
	{
        String encabezadoFunc="encabezadoFunc"+(dot++);}
        {try{writer.write(encabezadoFunc+"->identificadorMetFunc"+(dot)+";\n");}catch(Exception e){}}
	identificadorMetFunc
		{try{writer.write(encabezadoFunc+"->tipo"+(dot)+";\n");}catch(Exception e){}}
	tipo
	{
		try{
			$identificadorMetFunc.metodo.setTs($tipo.tsub);
			$metodo = $identificadorMetFunc.metodo;
			ts.inserta($identificadorMetFunc.metodo.getId(), $identificadorMetFunc.metodo);
		}catch (TablaSimbolos.exceptionTablaSimbolos e){
			errores += ("ERROR SEMANTICO - Línea: " + $identificadorMetFunc.linea + ": " + e.getMessage()+"\n");
		}
	}
	;

cuerpoFunc[Simbolo metodo]:
{
		String cuerpoFunc="cuerpoFunc"+(dot++);}
		{try{writer.write(cuerpoFunc+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[$metodo]
	|
	{
		String cuerpoFunc="cuerpoFunc"+(dot++);
		try{writer.write(cuerpoFunc+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}
	}
	';'
	;

declProc:
	{
        String declProc="declProc"+(dot++);
        try{writer.write(declProc+"->encabezadoProc"+(dot)+";\n");}catch(Exception e){}
	}
	encabezadoProc
		{try{writer.write(declProc+"->cuerpoProc"+(dot)+";\n");}catch(Exception e){}}
	cuerpoProc[$encabezadoProc.metodo]
	;

encabezadoProc
	returns[Simbolo metodo]:
	{
        String encabezadoProc="encabezadoProc"+(dot++);
        try{writer.write(encabezadoProc+"->identificadorMetProc"+(dot)+";\n");}catch(Exception e){}
	}
	identificadorMetProc
	{
		try{
			$metodo = $identificadorMetProc.metodo;
			ts.inserta($identificadorMetProc.metodo.getId(), $identificadorMetProc.metodo);
		}catch (TablaSimbolos.exceptionTablaSimbolos e){
			errores += ("ERROR SEMANTICO - Línea: " + $identificadorMetProc.linea + ": " + e.getMessage()+"\n");
		}
	}
	;

cuerpoProc[Simbolo metodo]:
	{
        String cuerpoProc="cuerpoProc"+(dot++);
        try{writer.write(cuerpoProc+"->bloque"+(dot)+";\n");}catch(Exception e){}
	}
	bloque[$metodo]
	|
	{
        String cuerpoProc="cuerpoProc"+(dot++);
        try{writer.write(cuerpoProc+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}
	}
	';'
	;

identificadorMetFunc
	returns[Simbolo metodo, int linea]:
	{
		String identificadorMetFunc="identificadorMetFunc"+(dot++);
		try{writer.write(identificadorMetFunc+"->"+$Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}
	}
	Identificador
	{
		$metodo = new Simbolo($Identificador.getText(), null, Simbolo.Tipo.FUNC, Simbolo.TipoSubyacente.NULL);
		// DOT
		try{writer.write(identificadorMetFunc+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}
	}
	'('
		{try{writer.write(identificadorMetFunc+"->parametros"+(dot)+";\n");}catch(Exception e){}}
	parametros[$metodo]?
		{try{writer.write(identificadorMetFunc+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
	;

identificadorMetProc
	returns[Simbolo metodo, int linea]:
	{
		String identificadorMetProc="identificadorMetProc"+(dot++);
		try{
			writer.write(identificadorMetProc+"->"+$Identificador.getText() +(dot)+"[label="
			+$Identificador.getText() +"];\n");
		}
		catch(Exception e){}
	}
	Identificador
	{
		$metodo = new Simbolo($Identificador.getText(), null, Simbolo.Tipo.PROC, Simbolo.TipoSubyacente.NULL);
		// DOT
		try{writer.write(identificadorMetProc+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}
	}
	'('
	{
		try{writer.write(identificadorMetProc+"->parametros"+(dot)+";\n");}catch(Exception e){}
	}
	parametros[$metodo]?
	{
		try{writer.write(identificadorMetProc+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}
	}
	')'
	;

parametros[Simbolo ant]:
	{
		String parametros="parametros"+(dot++);
		try{writer.write(parametros+"->parametro"+(dot)+";\n");}catch(Exception e){}
	}
	parametro
		{try{writer.write(parametros+"->COMMA"+(dot++)+";\n");}catch(Exception e){}}
	','
	{
		$ant.setNext($parametro.s);
		// DOT
		try{writer.write(parametros+"->parametros"+(dot)+";\n");}catch(Exception e){}
	}
	parametros[$ant.getNext()]
	|
	{
		String parametros="parametros"+(dot++);
		try{writer.write(parametros+"->parametro"+(dot)+";\n");}catch(Exception e){}
	}
	parametro
	{
		$ant.setNext($parametro.s);
		$parametro.s.setNext(null);
	}
	;

parametro
	returns[Simbolo s]:
	{
		String parametro="parametro"+(dot++);
		try{writer.write(parametro+"->tipo"+(dot)+";\n");}catch(Exception e){}
	}
	tipo
		{try{writer.write(parametro+"->identificadoVar"+(dot)+";\n");}catch(Exception e){}}
	identificadorVar
	{
		$s = new Simbolo($identificadorVar.id, null, Simbolo.Tipo.ARG, $tipo.tsub);
	}
	;

identificadorVar
	returns[String id]:
	{
		String identificadorVar="identificadorVar"+(dot++);
		try{
			writer.write(identificadorVar+"->"+$Identificador.getText() +(dot)+"[label="
			+$Identificador.getText() +"];\n");
		}catch(Exception e){}
	}
	Identificador
	{
		$id = $Identificador.getText();
	}
	;

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
		// DOT
    	String bloque="bloque"+(dot++);
    	try{writer.write(bloque+"->BEGIN"+(dot++)+";\n");}catch(Exception e){}
	}
	'{'
		{try{writer.write(bloque+"->exprsBloque"+(dot)+";\n");}catch(Exception e){}}
	exprsBloque?
		{try{writer.write(bloque+"->END"+(dot++)+";\n");}catch(Exception e){}}
	'}'
	{
		ts = ts.saleBloque();
		if($met != null){
			if($met.getT() == Simbolo.Tipo.FUNC){
				if(!returnenc){
					errores += ("ERROR SEMANTICO: falta return para la función "
					+ $met.getId() + "\n");
				}
			} else if ($met.getT() == Simbolo.Tipo.PROC){
				if(returnenc){
					errores += ("ERROR SEMANTICO: encontrado return para el procedimiento "
					+ $met.getId() + "\n");
				}
			}
			returnreq = false;
			returnenc = false;
			tiporeturn = null;
		}
	}
	;

exprsBloque:
	{
		String exprsBloque="exprsBloque"+(dot++);
		try{writer.write(exprsBloque+"->exprDeBloque"+(dot)+";\n");}catch(Exception e){}
	}
	exprDeBloque+
	;

exprDeBloque:
	{
		String exprsDeBloque="exprsDeBloque"+(dot++);
		try{writer.write(exprsDeBloque+"->sentDeclVarLocal"+(dot)+";\n");}catch(Exception e){}
	}
	sentDeclVarLocal
	|
	{
		String exprsDeBloque="exprsDeBloque"+(dot++);
		try{writer.write(exprsDeBloque+"->sent"+(dot)+";\n");}catch(Exception e){}
	}
	sent
	;

sentDeclVarLocal:
	{
		String sentDeclVarLocal="sentDeclVarLocal"+(dot++);
		try{writer.write(sentDeclVarLocal+"->declaracionVarLocal"+(dot)+";\n");}catch(Exception e){}
	}
	declaracionVarLocal[Simbolo.Tipo.VAR]
	;

declaracionVarLocal[Simbolo.Tipo t]:
	{
		String declaracionVarLocal="declaracionVarLocal"+(dot++);
		try{writer.write(declaracionVarLocal+"->tipo"+(dot)+";\n");}catch(Exception e){}
	}
	tipo
		{try{writer.write(declaracionVarLocal+"->declaracionVar"+(dot)+";\n");}catch(Exception e){}}
	declaracionVar[$tipo.tsub]
	;

sents: sents sent | sent;

sent:
	{
		String sent="sent"+(dot++);
    	try{writer.write(sent+"->sentExpr"+(dot)+";\n");}catch(Exception e){}
	}
	sentExpr
	|
	{
		boolean reqaux = returnreq;
		boolean encaux = returnenc;
		returnreq = false;
		// DOT
		String sent="sent"+(dot++);
    	try{writer.write(sent+"->IF"+(dot++)+";\n");}catch(Exception e){}
	}
	IF
		{try{writer.write(sent+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sent+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sent+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sent+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
			errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
			"La expresión debe ser de tipo BOOLEAN\n");
		}
		returnreq = reqaux;
		returnenc = encaux;
	}
	|
	{
		String sent="sent"+(dot++);
		try{writer.write(sent+"->IF"+(dot++)+";\n");}catch(Exception e){}
	}
	IF
		{try{writer.write(sent+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sent+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sent+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sent+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
				errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
				"La expresión debe ser de tipo BOOLEAN\n");
		}
		boolean primerreturn = returnenc;
		returnenc = false;
		// DOT
		try{writer.write(sent+"->ELSE"+(dot)+";\n");}catch(Exception e){}
	}
	ELSE
		{try{writer.write(sent+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if(!(primerreturn && returnenc)){
			returnenc = false;
		}
	}
	|
	{
		boolean reqaux = returnreq;
		boolean encaux = returnenc;
		returnreq = false;
		// DOT
		String sent="sent"+(dot++);
   		try{writer.write(sent+"->WHILE"+(dot++)+";\n");}catch(Exception e){}
	}
	WHILE
		{try{writer.write(sent+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sent+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sent+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sent+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
			errores += ("ERROR SEMANTICO - Línea: " +$WHILE.getLine()+"\n"+
			"La expresión debe ser de tipo BOOLEAN\n");
		}
		returnreq = reqaux;
		returnenc = encaux;
	}
	|
	{
		String sent="sent"+(dot++);
		try{writer.write(sent+"->RETURN"+(dot++)+";\n");}catch(Exception e){}
	}
	RETURN
		{try{writer.write(sent+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sent+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}
	';'
	 {
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
	}
	;

sentExpr:
	{
		String sentExpr="sentExpr"+(dot++);
		try{writer.write(sentExpr+"->exprSent"+(dot)+";\n");}catch(Exception e){}
	}
	exprSent
		{try{writer.write(sentExpr+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}
	';'
	;

exprSent:
	{
		String exprSent="exprSent"+(dot++);
		try{writer.write(exprSent+"->asignacion"+(dot)+";\n");}catch(Exception e){}
	}
	asignacion
	|
	{
		String exprSent="exprSent"+(dot++);
		try{writer.write(exprSent+"->sentInvocaMet"+(dot)+";\n");}catch(Exception e){}
	}
	sentInvocaMet
	;

sentIf:
	{
		boolean reqaux = returnreq;
		boolean encaux = returnenc;
		returnreq = false;
		// DOT
		String sentIf="sentIf"+(dot++);
    	try{writer.write(sentIf+"->IF"+(dot++)+";\n");}catch(Exception e){}
	}
	IF
		{try{writer.write(sentIf+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sentIf+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sentIf+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sentIf+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
			errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
			"La expresión debe ser de tipo BOOLEAN\n");
		}
		returnreq = reqaux;
		returnenc = encaux;
	}
	;

sentIfElse:
	{
		String sentIfElse="sentIfElse"+(dot++);
		try{writer.write(sentIfElse+"->IF"+(dot++)+";\n");}catch(Exception e){}
	}
	IF
		{try{writer.write(sentIfElse+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sentIfElse+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sentIfElse+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sentIfElse+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
				errores += ("ERROR SEMANTICO - Línea: " +$IF.getLine()+"\n"+
				"La expresión debe ser de tipo BOOLEAN\n");
		}
		boolean primerreturn = returnenc;
		returnenc = false;
		// DOT
		try{writer.write(sentIfElse+"->bloque"+(dot)+";\n");}catch(Exception e){}
	}
	ELSE
		{try{writer.write(sentIfElse+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if(!(primerreturn && returnenc)){
			returnenc = false;
		}
	}
	;

sentWhile:
	{
		boolean reqaux = returnreq;
		boolean encaux = returnenc;
		returnreq = false;
		// DOT
		String sentWhile="sentWhile"+(dot++);
   		try{writer.write(sentWhile+"->WHILE"+(dot++)+";\n");}catch(Exception e){}
	}
	WHILE
		{try{writer.write(sentWhile+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}
	'('
		{try{writer.write(sentWhile+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sentWhile+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
		{try{writer.write(sentWhile+"->bloque"+(dot)+";\n");}catch(Exception e){}}
	bloque[null]
	{
		if($expr.tsub != Simbolo.TipoSubyacente.BOOLEAN){
			errores += ("ERROR SEMANTICO - Línea: " +$WHILE.getLine()+"\n"+
			"La expresión debe ser de tipo BOOLEAN\n");
		}
		returnreq = reqaux;
		returnenc = encaux;
	}
	;

sentReturn:
	{
		String sentReturn="sentReturn"+(dot++);
		try{writer.write(sentReturn+"->RETURN"+(dot++)+";\n");}catch(Exception e){}
	}
	RETURN
		{try{writer.write(sentReturn+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(sentReturn+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}
	';'
	 {
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
	}
	;

sentInvocaMet
	returns[Simbolo.TipoSubyacente tsub]:
		{String sentInvocaMet="sentInvocaMet"+(dot++);}
	Identificador
	{
		try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}
   		try{writer.write(sentInvocaMet+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}
    	try{writer.write(sentInvocaMet+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}
	}
	'('
	{
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
	}
	(
		{try{writer.write(sentInvocaMet+"->argumentos"+(dot)+";\n");}catch(Exception e){}}
	argumentos[$Identificador.getText(), $Identificador.getLine()] {
		argEnc=true;
	}
	)?
		{try{writer.write(sentInvocaMet+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
	{
		try{
			if(!argEnc && ($Identificador.getText().equals("print")
			|| ts.consulta($Identificador.getText()).getNext()!= null)){
				errores+=("ERROR SEMANTICO - Línea: "+$Identificador.getLine()
				+", faltan parámetros para "+$Identificador.getText()+"\n");
			}
		} catch(TablaSimbolos.exceptionTablaSimbolos e) {
			errores += (e.getMessage()+"\n");
		}
	}
	;

argumentos[String nombre, int linea]:
	{
		Simbolo metodo=null;
		boolean demasiadosArg=false;
		try{
			metodo=ts.consulta($nombre).getNext();
		}catch(TablaSimbolos.exceptionTablaSimbolos ex){
			errores+=("ERROR SEMANTICO - Línea: "+$linea+", error con la tabla de símbolos: "
			+ex.getMessage()+"\n");
		}
		// DOT
		String argumentos="argumentos"+(dot++);
    	try{writer.write(argumentos+"->expr"+(dot)+";\n");}catch(Exception e){}
	}
	expr
	{
		if($nombre.equals("print")){
			String print = "print" + $expr.tsub;
			try{
				Simbolo.TipoSubyacente tprint = ts.consulta(print).getNext().getTs();
			} catch (TablaSimbolos.exceptionTablaSimbolos e){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", al invocar "+ $nombre
				+" no se esperaba un " + $expr.tsub + "\n");
			}
		}else {
			if(metodo==null){
				demasiadosArg=true;
				errores+=("ERROR SEMANTICO - Línea "+$linea+"\n");
			}

			if(metodo==null){
				demasiadosArg=true;
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", "+ $nombre
				+"tiene demasiados argumentos" + "\n");
			}else{
				if(metodo.getTs()!=$expr.tsub){
					errores+=("ERROR SEMANTICO - Línea: "+$linea+", tipos incompatibles\n"+
					"encontrado: "+$expr.tsub+" esperado "+metodo.getTs()+"\n");
				}
				metodo=metodo.getNext();
			}
		}
 	}
	(
		{try{writer.write(argumentos+"->COMMA"+(dot++)+";\n");}catch(Exception e){}}
	','
		{try{writer.write(argumentos+"->argumentos"+(dot)+";\n");}catch(Exception e){}}
	expr
	{
		if(metodo == null || $nombre.equals("print")){
			if(!demasiadosArg){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", "+ $nombre
				+"tiene demasiados argumentos" + "\n");
				demasiadosArg = true;
			}
		}
		if(metodo != null){
			if(metodo.getTs() != $expr.tsub){
				errores+=("ERROR SEMANTICO - Línea: "+$linea+", al invocar"+ $nombre
				+"se esperaba un " + metodo.getTs() + " y se ha encontrado un " + $expr.tsub + "\n");
			}
			metodo = metodo.getNext();
		}
	}
	)*
	{
		if(metodo != null){
		errores+=("ERROR SEMANTICO - Línea: "+$linea+", a "+ $nombre +"le faltan argumentos"
		+ "\n");
		}
	}
	;

asignacion
	returns[ Simbolo.TipoSubyacente tsub ]:
	{
		String asignacion="asignacion"+(dot++);
	}
	Identificador
	{
		try{
			writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");
			writer.write(asignacion+"->"+$Identificador.getText() +(dot++)+";\n");
			writer.write(asignacion+"->IGUAL"+(dot++)+";\n");
		}catch(Exception e){}
	}
	'='
		{try{writer.write(asignacion+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
	{
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
	}
	;

expr
	returns[ Simbolo.TipoSubyacente tsub]:
	{
		String expr="expr"+(dot++);
		try{writer.write(expr+"->exprCondOr"+(dot)+";\n");}catch(Exception e){}
	}
	exprCondOr
		{ $tsub=$exprCondOr.tsub;}
	|
	{
   		String expr="expr"+(dot++);
  		try{writer.write(expr+"->asignacion"+(dot)+";\n");}catch(Exception e){}
	}
	asignacion
		{ $tsub=$asignacion.tsub;}
	;

exprCondOr
	returns[ Simbolo.TipoSubyacente tsub]:
	{
		String exprCondOr="exprCondOr"+(dot++);
		try{writer.write(exprCondOr+"->exprCondAnd"+(dot)+";\n");}catch(Exception e){}
	}
	exprCondAnd
		{try{writer.write(exprCondOr+"->exprCondOr_"+(dot)+";\n");}catch(Exception e){}}
	exprCondOr_
	{
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
	}
	;

exprCondOr_
	returns[ Simbolo.TipoSubyacente tsub]:
	{
		String exprCondOr_="exprCondOr_"+(dot++);
		try{writer.write(exprCondOr_+"->OR"+(dot++)+";\n");}catch(Exception e){}
	}
	OR
		{try{writer.write(exprCondOr_+"->exprCondAnd"+(dot)+";\n");}catch(Exception e){}}
	exprCondAnd
		{try{writer.write(exprCondOr_+"->exprCondOr_"+(dot)+";\n");}catch(Exception e){}}
	exprCondOr_
	{
		if($exprCondAnd.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
			"encontrado: "+$exprCondAnd.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=Simbolo.TipoSubyacente.BOOLEAN;
	}
	|	//lambda
	{
		String exprCondOr_="exprCondOr_"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}
		try{writer.write(exprCondOr_+"->lambda"+(dot++)+";\n");}catch(Exception e){}
	}
	;

exprCondAnd
	returns[ Simbolo.TipoSubyacente tsub]:
	{
		String exprCondAnd="exprCondAnd"+(dot++);
		try{writer.write(exprCondAnd+"->exprComp"+(dot)+";\n");}catch(Exception e){}
	}
	exprComp
		{try{writer.write(exprCondAnd+"->exprCondAnd_"+(dot)+";\n");}catch(Exception e){}}
	exprCondAnd_
	{
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
	}
	;

exprCondAnd_
	returns[ Simbolo.TipoSubyacente tsub]:
	{
    	String exprCondAnd_="exprCondAnd_"+(dot++);
		try{writer.write(exprCondAnd_+"->AND"+(dot++)+";\n");}catch(Exception e){}
	}
	AND
		{try{writer.write(exprCondAnd_+"->exprComp"+(dot)+";\n");}catch(Exception e){}}
	exprComp
		{try{writer.write(exprCondAnd_+"->exprCondAnd_"+(dot)+";\n");}catch(Exception e){}}
	exprCondAnd_
	{
		if($exprComp.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipo incorrecto\n"+
			"encontrado: "+$exprComp.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=Simbolo.TipoSubyacente.BOOLEAN;
	}
	| 	//lambda
	{
		String exprCondAnd_="exprCondAnd_"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}
		try{writer.write(exprCondAnd_+"->lambda"+(dot++)+";\n");}catch(Exception e){}
	}
	;
exprComp
	returns[ Simbolo.TipoSubyacente tsub]:
	{
   		String exprComp="exprComp"+(dot++);
    	try{writer.write(exprComp+"->exprSuma"+(dot)+";\n");}catch(Exception e){}
	}
	exprSuma
		{try{writer.write(exprComp+"->exprComp_"+(dot)+";\n");}catch(Exception e){}}
	exprComp_
	{
		if($exprComp_.tsub!=null){
			if($exprSuma.tsub!=$exprComp_.tsub){
				errores+=("ERROR SEMANTICO - comparación de tipos incompatibles\n"+
				"encontrado: "+$exprComp_.tsub+" esperado: "+$exprSuma.tsub+"\n");
			}
			$tsub=Simbolo.TipoSubyacente.BOOLEAN;
		}else{
			$tsub=$exprSuma.tsub;
		}
	}
	;

exprComp_
	returns[ Simbolo.TipoSubyacente tsub]:
		{String exprComp_="exprComp_"+(dot++);}
	OPREL
	{
		try{writer.write("OPREL"+(dot)+"[label=\""+$OPREL.getText() +"\"];\n");}catch(Exception e){}
		try{writer.write(exprComp_+"->"+"OPREL"+(dot++)+";\n");}catch(Exception e){}
    	try{writer.write(exprComp_+"->exprSuma"+(dot)+";\n");}catch(Exception e){}
	}
	exprSuma
		{try{writer.write(exprComp_+"->exprComp_"+(dot)+";\n");}catch(Exception e){}}
	exprComp_
	{
		if($exprSuma.tsub==Simbolo.TipoSubyacente.BOOLEAN && !($OPREL.getText().equals("==") || $OPREL.getText().equals("!="))){
			errores+=("ERROR SEMANTICO - Línea: "+$OPREL.getLine()+", comparación incompatible con tipo BOOLEAN\n");
		}
		if($exprComp_.tsub!=null && $exprSuma.tsub!=$exprComp_.tsub){
			errores+=("ERROR SEMANTICO - Línea: "+$OPREL.getLine()+", comparación de tipos incompatibles\n"+
			"encontrado: "+$exprComp_.tsub+" esperado: "+$exprSuma.tsub+"\n");
		}
		$tsub=$exprSuma.tsub;
	}
	|	//lambda
	{
		String exprComp_="exprComp"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}
		try{writer.write(exprComp_+"->lambda"+(dot++)+";\n");}catch(Exception e){}
	}
	;

exprSuma
	returns[ Simbolo.TipoSubyacente tsub]:
	{
		String exprSuma="exprSuma"+(dot++);
		try{writer.write(exprSuma+"->exprMult"+(dot)+";\n");}catch(Exception e){}
	}
	exprMult
		{try{writer.write(exprSuma+"->exprSuma_"+(dot)+";\n");}catch(Exception e){}}
	exprSuma_
	{
		if($exprSuma_.tsub!=null && $exprMult.tsub!=$exprSuma_.tsub){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprSuma_.tsub+" esperado: "+$exprMult.tsub+"\n");
		}
		$tsub=$exprMult.tsub;
	}
	;

exprSuma_
	returns[ Simbolo.TipoSubyacente tsub]:
		{String exprSuma="exprSuma"+(dot++);}
	OpBinSum
	{
		try{writer.write("OpBinSum"+(dot)+"[label=\""+$OpBinSum.getText() +"\"];\n");}catch(Exception e){}
   		try{writer.write(exprSuma+"->"+"OpBinSum"+(dot++)+";\n");}catch(Exception e){}
    	try{writer.write(exprSuma+"->exprMult"+(dot)+";\n");}catch(Exception e){}
	}
	exprMult
		{try{writer.write(exprSuma+"->exprSuma_"+(dot)+";\n");}catch(Exception e){}}
	exprSuma_
	{
		if($exprMult.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprMult.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprMult.tsub;
	}
	|	//lambda
	{
		String exprSuma_="exprSuma"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}
		try{writer.write(exprSuma_+"->lambda"+(dot++)+";\n");}catch(Exception e){}
	}
	;

exprMult
	returns[ Simbolo.TipoSubyacente tsub ]:
	{
		String exprMult="exprMult"+(dot++);
		try{writer.write(exprMult+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}
	}
	exprUnaria
		{try{writer.write(exprMult+"->exprMult_"+(dot)+";\n");}catch(Exception e){}}
	exprMult_
	{
		if($exprMult_.tsub!=null && $exprUnaria.tsub!=$exprMult_.tsub){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprMult_.tsub+" esperado: "+$exprUnaria.tsub+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	;

exprMult_
	returns[ Simbolo.TipoSubyacente tsub ]:
		{String exprMult_="exprMult_"+(dot++);}
	MULT
	{
		try{writer.write("MULT"+(dot)+"[label=\""+$MULT.getText() +"\"];\n");}catch(Exception e){}
		try{writer.write(exprMult_+"->"+"MULT"+(dot++)+";\n");}catch(Exception e){}
		try{writer.write(exprMult_+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}
	}
	exprUnaria
		{try{writer.write(exprMult_+"->exprMult_"+(dot)+";\n");}catch(Exception e){}}
	exprMult_
	{
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - Línea: "+$MULT.getLine()+", tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	|
		{String exprMult_="exprMult_"+(dot++);}
	DIV
	{
		try{writer.write("DIV"+(dot)+"[label=\""+$DIV.getText() +"\"];\n");}catch(Exception e){}
		try{writer.write(exprMult_+"->"+"DIV"+(dot++)+";\n");}catch(Exception e){}
		try{writer.write(exprMult_+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}
	}
	exprUnaria
		{try{writer.write(exprMult_+"->exprMult_"+(dot)+";\n");}catch(Exception e){}}
	exprMult_
	{
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - Línea: "+$DIV.getLine()+", tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	| //lambda
	{
		String exprMult_="exprMult_"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}
		try{writer.write(exprMult_+"->lambda"+(dot++)+";\n");}catch(Exception e){}
	}
	;

exprUnaria
	returns[ Simbolo.TipoSubyacente tsub ]:
		{String exprUnaria="exprUnaria"+(dot++);}
	OpBinSum
	{
		try{writer.write("OpBinSum"+(dot)+"[label=\""+$OpBinSum.getText() +"\"];\n");}catch(Exception e){}
		try{writer.write(exprUnaria+"->"+"OpBinSum"+(dot++)+";\n");}catch(Exception e){}
		try{writer.write(exprUnaria+"->exprNeg"+(dot)+";\n");}catch(Exception e){}
	}
	exprNeg
	{
		if($exprNeg.tsub!=Simbolo.TipoSubyacente.INT){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprNeg.tsub+" esperado: "+Simbolo.TipoSubyacente.INT+"\n");
		}
		$tsub=$exprNeg.tsub;
	}
	|
	{
		String exprUnaria="exprUnaria"+(dot++);
		try{writer.write(exprUnaria+"->exprNeg"+(dot)+";\n");}catch(Exception e){}
	}
	exprNeg
		{ $tsub=$exprNeg.tsub; }
	;

exprNeg
	returns[ Simbolo.TipoSubyacente tsub ]:
	{
    	String exprNeg="exprNeg"+(dot++);
    	try{writer.write(exprNeg+"->NOT"+(dot++)+";\n");}catch(Exception e){}
	}
	NOT
		{try{writer.write(exprNeg+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}}
	exprUnaria
	{
		if($exprUnaria.tsub!=Simbolo.TipoSubyacente.BOOLEAN){
			errores+=("ERROR SEMANTICO - tipos incompatibles\n"+
			"encontrado: "+$exprUnaria.tsub+" esperado: "+Simbolo.TipoSubyacente.BOOLEAN+"\n");
		}
		$tsub=$exprUnaria.tsub;
	}
	|
	{
		String exprNeg="exprNeg"+(dot++);
		try{writer.write(exprNeg+"->exprPostfija"+(dot)+";\n");}catch(Exception e){}
	}
	exprPostfija
	{ $tsub=$exprPostfija.tsub; }
	;

exprPostfija
	returns[ Simbolo.TipoSubyacente tsub ]:
	{
		String exprPostfija="exprPostfija"+(dot++);
		try{writer.write(exprPostfija+"->primario"+(dot)+";\n");}catch(Exception e){}
	}
	primario
		{ $tsub=$primario.tsub; }
	|
		{String exprPostfija="exprPostfija"+(dot++);}
	Identificador
	{
		try{
			Simbolo s=ts.consulta($Identificador.getText());
                        if(s!=null){
                            $tsub=s.getTs();
                        }
		}catch(TablaSimbolos.exceptionTablaSimbolos ex){
			errores+=("ERROR SEMANTICO - "+ex.getMessage()+"\n");
		}
		// DOT
		try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}
    	try{writer.write(exprPostfija+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}
	}
	|
	{
		String exprPostfija="exprPostfija"+(dot++);
		try{writer.write(exprPostfija+"->sentInvocaMet"+(dot)+";\n");}catch(Exception e){}
	}
	sentInvocaMet
	{ $tsub=$sentInvocaMet.tsub; }
	;

primario
	returns[ Simbolo.TipoSubyacente tsub ]:
	{
		String primario="primario"+(dot++);
		try{writer.write(primario+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}
	}
	'('
		{try{writer.write(primario+"->expr"+(dot)+";\n");}catch(Exception e){}}
	expr
		{try{writer.write(primario+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}
	')'
	{ $tsub=$expr.tsub; }
	|
	{
    	String primario="primario"+(dot++);
    	try{writer.write(primario+"->literal"+(dot)+";\n");}catch(Exception e){}
	}
	literal
	{ $tsub=$literal.tsub; }
	;

literal
	returns[ Simbolo.TipoSubyacente tsub ]:
		{String literal="literal"+(dot++);}
	LiteralInteger
	{
		$tsub=Simbolo.TipoSubyacente.INT;
		// DOT
		try{writer.write($LiteralInteger.getText() +(dot)+"[label="+$LiteralInteger.getText() +"];\n");}catch(Exception e){}
		try{writer.write(literal+"->"+$LiteralInteger.getText() +(dot++)+";\n");}catch(Exception e){}
	}
	|
		{String literal="literal"+(dot++);}
	LiteralBoolean
	{
		$tsub=Simbolo.TipoSubyacente.BOOLEAN;
		try{writer.write($LiteralBoolean.getText() +(dot)+"[label="+$LiteralBoolean.getText() +"];\n");}catch(Exception e){}
    	try{writer.write(literal+"->"+$LiteralBoolean.getText() +(dot++)+";\n");}catch(Exception e){}
	}
	|
		{String literal="literal"+(dot++);}
	LiteralString
	{
		$tsub=Simbolo.TipoSubyacente.STRING;
		try{writer.write($LiteralString.getText() +(dot)+"[label="+$LiteralString.getText() +"];\n");}catch(Exception e){}
    	try{writer.write(literal+"->"+$LiteralString.getText() +(dot++)+";\n");}catch(Exception e){}
	}
	;

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
Identificador: LETRA LETRADIGITO*;

fragment LETRA: [a-zA-Z$_];

fragment LETRADIGITO: [a-zA-Z$_0-9];

// Comentarios y espacios en blanco
WS: [ \r\n\t]+ -> skip;

BLOCK_COMMENT: '/*' .*? '*/' -> skip;

LINE_COMMENT: '#' ~[\r\n]* -> skip;