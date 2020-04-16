parser grammar vajaDOT;

options { tokenVocab=vajaLexer; }

@header {
	package antlrprocesador;
    import java.io.*;
	import java.util.*;
}

@parser::members 
{
	Writer writer;
	int dot = 0;
}
//{try{writer.write('string'+"->'nombretoken'"+(dot++)+";\n");}catch(Exception e){}}
//{try{writer.write('string'+"->"+$Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}}
programaPrincipal
    :  
    {
        try{
            writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("arbol.dot"), "utf-8"));
            writer.write("digraph G {");
        }catch (Exception e){}
            String programaPrincipal="programaPrincipal"+(dot++);
    }
    declaracion[programaPrincipal]* EOF
    {
        try{
            writer.write("}");
            writer.close();
        }catch (Exception e){}
    }
	;

declaracion[String padre]
    :   {
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}}
        {try{writer.write(declaracion+"->var"+(dot++)+";\n");}catch(Exception e){}} 'var'
        {try{writer.write(declaracion+"->tipo"+(dot)+";\n");}catch(Exception e){}} tipo 
        {try{writer.write(declaracion+"->declaracionVar"+(dot)+";\n");}catch(Exception e){}} declaracionVar
	|	
    {
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}}
        {try{writer.write(declaracion+"->const"+(dot++)+";\n");}catch(Exception e){}} 'const' 
        {try{writer.write(declaracion+"->tipo"+(dot)+";\n");}catch(Exception e){}} tipo 
        {try{writer.write(declaracion+"->declaracionConst"+(dot)+";\n");}catch(Exception e){}} declaracionConst
	|	
    {
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}}
        {try{writer.write(declaracion+"->func"+(dot++)+";\n");}catch(Exception e){}} 'func' 
        {try{writer.write(declaracion+"->declFunc"+(dot)+";\n");}catch(Exception e){}} declFunc
	|	
    {
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}}
        {try{writer.write(declaracion+"->proc"+(dot++)+";\n");}catch(Exception e){}} 'proc' 
        {try{writer.write(declaracion+"->declProc"+(dot)+";\n");}catch(Exception e){}} declProc
	|
    {
        dot++;
        String declaracion="declaracion"+(dot++);
        try{writer.write($padre+"->"+declaracion+";\n");}catch(Exception e){}}	
        {try{writer.write(declaracion+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}} ';'
	;

tipo
    :
    {
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->int"+(dot++)+";\n");}catch(Exception e){}}} INT 
	|	{
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->boolean"+(dot++)+";\n");}catch(Exception e){}}} BOOLEAN
	|	{
        String tipo ="tipo"+(dot++);
        {try{writer.write(tipo+"->string"+(dot++)+";\n");}catch(Exception e){}}} STRING 
	;

/*
declaracioVariable
	:	{
		String declaracioVAR="declaracioVariable"+(dot++);}
		 Identificador 
		 {try{writer.write($Identificador.text+(dot)+"[label="+$Identificador.text+"];\n");}catch(Exception e){}}
		 {try{writer.write(declaracioVAR+"->"+$Identificador.text+(dot++)+";\n");}catch(Exception e){}} (
		 	{try{writer.write(declaracioVAR+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}} ASSIGN 
		 	{try{writer.write(declaracioVAR+"->initVariable"+(dot)+";\n");}catch(Exception e){}} initVariable)?
	;*/ 
declaracionVar
	:	
    {
    String declaracionVar="declaracionVar"+(dot++);}
        Identificador
        {try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText()+"];\n");}catch(Exception e){}} 
        {try{writer.write(declaracionVar+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}}(
            {try{writer.write(declaracionVar+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}}'=' 
            {try{writer.write(declaracionVar+"->initVar"+(dot)+";\n");}catch(Exception e){}}initVar)? 
        {try{writer.write(declaracionVar+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}';'
	;

declaracionConst 
    :	{
        String declaracionConst="declaracionConst"+(dot++);}
        Identificador 
        {try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}} 
        {try{writer.write(declaracionConst+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}}
        {try{writer.write(declaracionConst+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}} '=' 
        {try{writer.write(declaracionConst+"->initConst"+(dot)+";\n");}catch(Exception e){}} initConst 
        {try{writer.write(declaracionConst+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}} ';'
    ;

initVar
	:	{
        String initVar="initVar"+(dot++);}
        {try{writer.write(initVar+"->expr"+(dot)+";\n");}catch(Exception e){}}expr 
	;

initConst
	:	{
        String initConst="initConst"+(dot++);}
        {try{writer.write(initConst+"->expr"+(dot)+";\n");}catch(Exception e){}}expr 
	;

declFunc
	:	{
        String declFunc="declFunc"+(dot++);}
        {try{writer.write(declFunc+"->encabezadoFunc"+(dot)+";\n");}catch(Exception e){}}encabezadoFunc 
        {try{writer.write(declFunc+"->cuerpoFunc"+(dot)+";\n");}catch(Exception e){}}cuerpoFunc 
	;

encabezadoFunc
	:	{
        String encabezadoFunc="encabezadoFunc"+(dot++);}
        {try{writer.write(encabezadoFunc+"->identificadorMetFunc"+(dot)+";\n");}catch(Exception e){}} identificadorMetFunc 
        {try{writer.write(encabezadoFunc+"->tipo"+(dot)+";\n");}catch(Exception e){}} tipo
	;

cuerpoFunc 
	:	{
        String cuerpoFunc="cuerpoFunc"+(dot++);}
        {try{writer.write(cuerpoFunc+"->bloque"+(dot)+";\n");}catch(Exception e){}}bloque
	|	{
        String cuerpoFunc="cuerpoFunc"+(dot++);}
        {try{writer.write(cuerpoFunc+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}';'
	;

declProc
	:	{
        String declProc="declProc"+(dot++);}
        {try{writer.write(declProc+"->encabezadoProc"+(dot)+";\n");}catch(Exception e){}}encabezadoProc 
        {try{writer.write(declProc+"->cuerpoProc"+(dot)+";\n");}catch(Exception e){}}cuerpoProc
	;

encabezadoProc
	:	{
        String encabezadoProc="encabezadoProc"+(dot++);}
        {try{writer.write(encabezadoProc+"->identificadorMetProc"+(dot)+";\n");}catch(Exception e){}} identificadorMetProc
	;

cuerpoProc
	:	{
        String cuerpoProc="cuerpoProc"+(dot++);}
        {try{writer.write(cuerpoProc+"->bloque"+(dot)+";\n");}catch(Exception e){}}bloque
	|	{
        String cuerpoProc="cuerpoProc"+(dot++);}
        {try{writer.write(cuerpoProc+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}';'
	;

identificadorMetFunc 
	:	
    {
    String identificadorMetFunc="identificadorMetFunc"+(dot++);}
    {try{writer.write(identificadorMetFunc+"->"+$Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}} Identificador 
	{try{writer.write(identificadorMetFunc+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '(' 
    {try{writer.write(identificadorMetFunc+"->parametros"+(dot)+";\n");}catch(Exception e){}} parametros? 
    {try{writer.write(identificadorMetFunc+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')'
	;

identificadorMetProc
	:	
    {
    String identificadorMetProc="identificadorMetProc"+(dot++);}
    {try{writer.write(identificadorMetProc+"->"+$Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}} Identificador 
	{try{writer.write(identificadorMetProc+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '(' 
    {try{writer.write(identificadorMetProc+"->parametros"+(dot)+";\n");}catch(Exception e){}} parametros? 
    {try{writer.write(identificadorMetProc+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')'
	;

parametros
	:	{
    String parametros="parametros"+(dot++);}
    {try{writer.write(parametros+"->parametro"+(dot)+";\n");}catch(Exception e){}} parametro 
    {try{writer.write(parametros+"->COMMA"+(dot++)+";\n");}catch(Exception e){}} ','  
    {try{writer.write(parametros+"->parametros"+(dot)+";\n");}catch(Exception e){}} parametros
	|	{
    String parametros="parametros"+(dot++);}
    {try{writer.write(parametros+"->parametro"+(dot)+";\n");}catch(Exception e){}} parametro 
	;

parametro
	: 	{
    String parametro="parametro"+(dot++);}
    {try{writer.write(parametro+"->tipo"+(dot)+";\n");}catch(Exception e){}} tipo 
    {try{writer.write(parametro+"->identificadoVar"+(dot)+";\n");}catch(Exception e){}} identificadorVar
	;

identificadorVar 
	:	{
    String identificadorVar="identificadorVar"+(dot++);}
    {try{writer.write(identificadorVar+"->"+$Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}}Identificador
	;

bloque
	:	{
    String bloque="bloque"+(dot++);}
    {try{writer.write(bloque+"->BEGIN"+(dot++)+";\n");}catch(Exception e){}}'{' 
    {try{writer.write(bloque+"->exprsBloque"+(dot)+";\n");}catch(Exception e){}} exprsBloque?
    {try{writer.write(bloque+"->END"+(dot++)+";\n");}catch(Exception e){}}'}'
	;

exprsBloque
	:	{
    String exprsBloque="exprsBloque"+(dot++);}
    {try{writer.write(exprsBloque+"->exprDeBloque"+(dot)+";\n");}catch(Exception e){}} exprDeBloque+
	;

exprDeBloque
	:	{
    String exprsDeBloque="exprsDeBloque"+(dot++);}
    {try{writer.write(exprsDeBloque+"->sentDeclVarLocal"+(dot)+";\n");}catch(Exception e){}} sentDeclVarLocal
	|	
    {
    String exprsDeBloque="exprsDeBloque"+(dot++);}
    {try{writer.write(exprsDeBloque+"->sent"+(dot)+";\n");}catch(Exception e){}} sent
	;

sentDeclVarLocal
	:	{
    String sentDeclVarLocal="sentDeclVarLocal"+(dot++);}
    {try{writer.write(sentDeclVarLocal+"->declaracionVarLocal"+(dot)+";\n");}catch(Exception e){}} declaracionVarLocal 
	;

declaracionVarLocal 
	:	{
    String declaracionVarLocal="declaracionVarLocal"+(dot++);}
    {try{writer.write(declaracionVarLocal+"->tipo"+(dot)+";\n");}catch(Exception e){}} tipo 
    {try{writer.write(declaracionVarLocal+"->declaracionVar"+(dot)+";\n");}catch(Exception e){}} declaracionVar
	;

sent
	:	{
    String sent="sent"+(dot++);}
    {try{writer.write(sent+"->bloque"+(dot)+";\n");}catch(Exception e){}} bloque
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentVacia"+(dot)+";\n");}catch(Exception e){}} sentVacia
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentExpr"+(dot)+";\n");}catch(Exception e){}} sentExpr
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentIf"+(dot)+";\n");}catch(Exception e){}} sentIf
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentIfElse"+(dot)+";\n");}catch(Exception e){}} sentIfElse
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentWhile"+(dot)+";\n");}catch(Exception e){}} sentWhile
	|	
    {String sent="sent"+(dot++);}
    {try{writer.write(sent+"->sentReturn"+(dot)+";\n");}catch(Exception e){}} sentReturn
	;

sentVacia
:	{
    String sentVacia="sentVacia"+(dot++);}
    {try{writer.write(sentVacia+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}} ';'
;

sentExpr
	:	{
    String sentExpr="sentExpr"+(dot++);}
    {try{writer.write(sentExpr+"->exprSent"+(dot)+";\n");}catch(Exception e){}} exprSent 
    {try{writer.write(sentExpr+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}}';'
	;

exprSent
	:	{
    String exprSent="exprSent"+(dot++);}
    {try{writer.write(exprSent+"->asignacion"+(dot)+";\n");}catch(Exception e){}} asignacion
	|	
    {
    String exprSent="exprSent"+(dot++);}
    {try{writer.write(exprSent+"->sentInvocaMet"+(dot)+";\n");}catch(Exception e){}} sentInvocaMet
	;

sentIf
	:	{
    String sentIf="sentIf"+(dot++);}
    {try{writer.write(sentIf+"->IF"+(dot++)+";\n");}catch(Exception e){}} IF 
    {try{writer.write(sentIf+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '('
    {try{writer.write(sentIf+"->expr"+(dot)+";\n");}catch(Exception e){}} expr 
    {try{writer.write(sentIf+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')' 
    {try{writer.write(sentIf+"->bloque"+(dot)+";\n");}catch(Exception e){}} bloque
	;

sentIfElse
	:	{
    String sentIf="sentIf"+(dot++);}
    {try{writer.write(sentIf+"->IF"+(dot++)+";\n");}catch(Exception e){}} IF 
    {try{writer.write(sentIf+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '('
    {try{writer.write(sentIf+"->expr"+(dot)+";\n");}catch(Exception e){}} expr 
    {try{writer.write(sentIf+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')' 
    {try{writer.write(sentIf+"->bloque"+(dot)+";\n");}catch(Exception e){}} bloque
    {try{writer.write(sentIf+"->ELSE"+(dot++)+";\n");}catch(Exception e){}} ELSE 
    {try{writer.write(sentIf+"->bloque"+(dot)+";\n");}catch(Exception e){}} bloque
	;

sentWhile
	:	{
    String sentWhile="sentWhile"+(dot++);}
    {try{writer.write(sentWhile+"->WHILE"+(dot++)+";\n");}catch(Exception e){}} WHILE
    {try{writer.write(sentWhile+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '('
    {try{writer.write(sentWhile+"->expr"+(dot)+";\n");}catch(Exception e){}} expr 
    {try{writer.write(sentWhile+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')' 
    {try{writer.write(sentWhile+"->bloque"+(dot)+";\n");}catch(Exception e){}} bloque
	;

sentReturn
	:	{
    String sentReturn="sentReturn"+(dot++);}
    {try{writer.write(sentReturn+"->RETURN"+(dot++)+";\n");}catch(Exception e){}} RETURN 
    {try{writer.write(sentReturn+"->expr"+(dot)+";\n");}catch(Exception e){}} expr 
    {try{writer.write(sentReturn+"->PUNTOYCOMA"+(dot++)+";\n");}catch(Exception e){}} ';'
	;

sentInvocaMet
	:	{
    String sentInvocaMet="sentInvocaMet"+(dot++);}
    Identificador 
    {try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}} 
    {try{writer.write(sentInvocaMet+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}} 
    {try{writer.write(sentInvocaMet+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}} '(' (
        {try{writer.write(sentInvocaMet+"->argumentos"+(dot)+";\n");}catch(Exception e){}} argumentos)? 
    {try{writer.write(sentInvocaMet+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}} ')'
	;

argumentos 
	: 	{
    String argumentos="argumentos"+(dot++);}
    {try{writer.write(argumentos+"->expr"+(dot)+";\n");}catch(Exception e){}} expr  (
        {try{writer.write(argumentos+"->COMMA"+(dot++)+";\n");}catch(Exception e){}} ',' 
        {try{writer.write(argumentos+"->argumentos"+(dot)+";\n");}catch(Exception e){}} expr)* 
	;

asignacion returns [ Simbolo.TipoSubyacente tsub ]
	:   {
    String asignacion="asignacion"+(dot++);}
    Identificador 
    {try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}}
    {try{writer.write(asignacion+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}} 	 
    {try{writer.write(asignacion+"->IGUAL"+(dot++)+";\n");}catch(Exception e){}} '=' 
    {try{writer.write(asignacion+"->expr"+(dot)+";\n");}catch(Exception e){}} expr 
	;

expr 
	:	{
    String expr="expr"+(dot++);}
    {try{writer.write(expr+"->exprCondOr"+(dot)+";\n");}catch(Exception e){}} exprCondOr 
	|	
    {
    String expr="expr"+(dot++);}
    {try{writer.write(expr+"->asignacion"+(dot)+";\n");}catch(Exception e){}} asignacion
	;

exprCondOr 
	:	{
    String exprCondOr="exprCondOr"+(dot++);}
    {try{writer.write(exprCondOr+"->exprCondAnd"+(dot)+";\n");}catch(Exception e){}} exprCondAnd 
    {try{writer.write(exprCondOr+"->exprCondOr_"+(dot)+";\n");}catch(Exception e){}} exprCondOr_ 
	;

exprCondOr_ 
	:{
    String exprCondOr_="exprCondOr_"+(dot++);}
    {try{writer.write(exprCondOr_+"->OR"+(dot++)+";\n");}catch(Exception e){}} OR 
    {try{writer.write(exprCondOr_+"->exprCondAnd"+(dot)+";\n");}catch(Exception e){}} exprCondAnd 
    {try{writer.write(exprCondOr_+"->exprCondOr_"+(dot)+";\n");}catch(Exception e){}} exprCondOr_ 	
	|	{
		String exprCondOr_="exprCondOr_"+(dot++);
		try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}}
		{try{writer.write(exprCondOr_+"->lambda"+(dot++)+";\n");}catch(Exception e){}}
	;

exprCondAnd 
	: {
    String exprCondAnd="exprCondAnd"+(dot++);}
    {try{writer.write(exprCondAnd+"->exprComp"+(dot)+";\n");}catch(Exception e){}} exprComp 
    {try{writer.write(exprCondAnd+"->exprCondAnd_"+(dot)+";\n");}catch(Exception e){}} exprCondAnd_ 
	;

exprCondAnd_
	: {
    String exprCondAnd_="exprCondAnd_"+(dot++);}
    {try{writer.write(exprCondAnd_+"->AND"+(dot++)+";\n");}catch(Exception e){}} AND
    {try{writer.write(exprCondAnd_+"->exprComp"+(dot)+";\n");}catch(Exception e){}} exprComp 
    {try{writer.write(exprCondAnd_+"->exprCondAnd_"+(dot)+";\n");}catch(Exception e){}} exprCondAnd_ 
    |	
    {
    String exprCondAnd_="exprCondAnd_"+(dot++);
    try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}}
    {try{writer.write(exprCondAnd_+"->lambda"+(dot++)+";\n");}catch(Exception e){}}
	;

exprComp 
	:	{
    String exprComp="exprComp"+(dot++);}
    {try{writer.write(exprComp+"->exprSuma"+(dot)+";\n");}catch(Exception e){}} exprSuma 
    {try{writer.write(exprComp+"->exprComp_"+(dot)+";\n");}catch(Exception e){}} exprComp_ 
	;

exprComp_
    :	{
    String exprComp_="exprComp_"+(dot++);}
    Comparador 
    {try{writer.write("Comparador"+(dot)+"[label=\""+$Comparador.getText() +"\"];\n");}catch(Exception e){}}
    {try{writer.write(exprComp_+"->"+"Comparador"+(dot++)+";\n");}catch(Exception e){}} 	  
    {try{writer.write(exprComp_+"->exprSuma"+(dot)+";\n");}catch(Exception e){}} exprSuma 
    {try{writer.write(exprComp_+"->exprComp_"+(dot)+";\n");}catch(Exception e){}} exprComp_ 
    |	
    {
    String exprComp_="exprComp"+(dot++);
    try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}}
    {try{writer.write(exprComp_+"->lambda"+(dot++)+";\n");}catch(Exception e){}}
    ;
exprSuma 
	:	{
    String exprSuma="exprSuma"+(dot++);}
    {try{writer.write(exprSuma+"->exprMult"+(dot)+";\n");}catch(Exception e){}} exprMult 
    {try{writer.write(exprSuma+"->exprSuma_"+(dot)+";\n");}catch(Exception e){}} exprSuma_ 
	;

exprSuma_
	:	{
    String exprSuma="exprSuma"+(dot++);}
    OpBinSum
    {try{writer.write("OpBinSum"+(dot)+"[label=\""+$OpBinSum.getText() +"\"];\n");}catch(Exception e){}} 
    {try{writer.write(exprSuma+"->"+"OpBinSum"+(dot++)+";\n");}catch(Exception e){}} 
    {try{writer.write(exprSuma+"->exprMult"+(dot)+";\n");}catch(Exception e){}} exprMult 
    {try{writer.write(exprSuma+"->exprSuma_"+(dot)+";\n");}catch(Exception e){}} exprSuma_ 
    |	
    {
    String exprSuma_="exprSuma"+(dot++);
    try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}}
    {try{writer.write(exprSuma_+"->lambda"+(dot++)+";\n");}catch(Exception e){}}
	;

exprMult 
	:   {
    String exprMult="exprMult"+(dot++);}
    {try{writer.write(exprMult+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}} exprUnaria 
    {try{writer.write(exprMult+"->exprMult_"+(dot)+";\n");}catch(Exception e){}} exprMult_ 
	;

exprMult_ 
	:   {
    String exprMult_="exprMult_"+(dot++);}
    MULT
    {try{writer.write("MULT"+(dot)+"[label=\""+$MULT.getText() +"\"];\n");}catch(Exception e){}} 
    {try{writer.write(exprMult_+"->"+"MULT"+(dot++)+";\n");}catch(Exception e){}} 
    {try{writer.write(exprMult_+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}} exprUnaria 
    {try{writer.write(exprMult_+"->exprMult_"+(dot)+";\n");}catch(Exception e){}} exprMult_ 
    |
    {   
    String exprMult_="exprMult_"+(dot++);}
    DIV
    {try{writer.write("DIV"+(dot)+"[label=\""+$DIV.getText() +"\"];\n");}catch(Exception e){}} 
    {try{writer.write(exprMult_+"->"+"DIV"+(dot++)+";\n");}catch(Exception e){}} 
    {try{writer.write(exprMult_+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}} exprUnaria 
    {try{writer.write(exprMult_+"->exprMult_"+(dot)+";\n");}catch(Exception e){}} exprMult_ 
    |
    {
    String exprMult_="exprMult_"+(dot++);
    try{writer.write("lambda"+(dot)+"[label=lambda];\n");}catch(Exception e){}}
    {try{writer.write(exprMult_+"->lambda"+(dot++)+";\n");}catch(Exception e){}}
	;

exprUnaria 
	:	{
    String exprUnaria="exprUnaria"+(dot++);}
    OpBinSum
    {try{writer.write("OpBinSum"+(dot)+"[label=\""+$OpBinSum.getText() +"\"];\n");}catch(Exception e){}} 
    {try{writer.write(exprUnaria+"->"+"OpBinSum"+(dot++)+";\n");}catch(Exception e){}} 
    {try{writer.write(exprUnaria+"->exprNeg"+(dot)+";\n");}catch(Exception e){}} exprNeg 
	|	
    {
    String exprUnaria="exprUnaria"+(dot++);}
    {try{writer.write(exprUnaria+"->exprNeg"+(dot)+";\n");}catch(Exception e){}} exprNeg 
	;

exprNeg 
	:	{
    String exprNeg="exprNeg"+(dot++);}
    {try{writer.write(exprNeg+"->NOT"+(dot++)+";\n");}catch(Exception e){}} NOT 
    {try{writer.write(exprNeg+"->exprUnaria"+(dot)+";\n");}catch(Exception e){}} exprUnaria 
	|	
    {
    String exprNeg="exprNeg"+(dot++);}
    {try{writer.write(exprNeg+"->exprPostfija"+(dot)+";\n");}catch(Exception e){}} exprPostfija 
	;

exprPostfija 
	:	{
    String exprPostfija="exprPostfija"+(dot++);}
    {try{writer.write(exprPostfija+"->primario"+(dot)+";\n");}catch(Exception e){}} primario
	|
    {
    String exprPostfija="exprPostfija"+(dot++);}	
    Identificador 
    {try{writer.write($Identificador.getText() +(dot)+"[label="+$Identificador.getText() +"];\n");}catch(Exception e){}} 	
    {try{writer.write(exprPostfija+"->"+$Identificador.getText() +(dot++)+";\n");}catch(Exception e){}} 	 
	|	
    {
    String exprPostfija="exprPostfija"+(dot++);}
    {try{writer.write(exprPostfija+"->sentInvocaMet"+(dot)+";\n");}catch(Exception e){}} sentInvocaMet 
    ;

primario 
	:	{
    String primario="primario"+(dot++);}
    {try{writer.write(primario+"->LPAREN"+(dot++)+";\n");}catch(Exception e){}}'(' 
    {try{writer.write(primario+"->expr"+(dot)+";\n");}catch(Exception e){}}expr 
    {try{writer.write(primario+"->RPAREN"+(dot++)+";\n");}catch(Exception e){}}')' 
	|	
    {
    String primario="primario"+(dot++);}
    {try{writer.write(primario+"->literal"+(dot)+";\n");}catch(Exception e){}} literal 
	;

literal 
	:	
    {
    String literal="literal"+(dot++);}	
    LiteralInteger 
    {try{writer.write($LiteralInteger.getText() +(dot)+"[label="+$LiteralInteger.getText() +"];\n");}catch(Exception e){}}
    {try{writer.write(literal+"->"+$LiteralInteger.getText() +(dot++)+";\n");}catch(Exception e){}} 
	|	
    {
    String literal="literal"+(dot++);}	
    LiteralBoolean 
    {try{writer.write($LiteralBoolean.getText() +(dot)+"[label="+$LiteralBoolean.getText() +"];\n");}catch(Exception e){}}
    {try{writer.write(literal+"->"+$LiteralBoolean.getText() +(dot++)+";\n");}catch(Exception e){}} 
	|	
    {
    String literal="literal"+(dot++);}	
    LiteralString 
    {try{writer.write($LiteralString.getText() +(dot)+"[label="+$LiteralString.getText() +"];\n");}catch(Exception e){}}
    {try{writer.write(literal+"->"+$LiteralString.getText() +(dot++)+";\n");}catch(Exception e){}} 
	;