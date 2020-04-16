package procesador;

public class Simbolo{
	private String id;
	private Simbolo next;
	private Tipo t;
	private TipoSubyacente ts;

	public Simbolo(String id, Simbolo next, Tipo t, TipoSubyacente ts){
		this.id=id;
		this.next=next;
		this.t=t;
		this.ts=ts;
	}

	public Simbolo(Simbolo s){
		this.id=s.id;
		this.next=s.next;
		this.t=s.t;
		this.ts=s.ts;
	}

	public enum Tipo{
		CONST,VAR,PROC,FUNC,ARG,NULO;
	}

	public enum TipoSubyacente{
		BOOLEAN,INT,STRING,NULL;
	}

	public String getId(){
		return id;
	}

	public Simbolo getNext(){
		return next;
	}

	public void setNext(Simbolo next){
		this.next=next;
	}

	public Tipo getT(){
		return t;
	}

	public TipoSubyacente getTs(){
		return ts;
	}

	public void setTs(TipoSubyacente ts){
		this.ts=ts;
	}
}