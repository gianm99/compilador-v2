package procesador;

/**
 * Simbolo. Clase que sirve para gestionar la información relacionada con los
 * símbolos que aparecen en el código fuente.
 * 
 * @author Gian Lucas Martín Chamorro
 * @author Jordi Antoni Sastre Moll
 */
public class Simbolo {
	private String id;
	private Simbolo next;
	private Tipo t;
	private TSub tsub;
	private boolean returnEncontrado;
	private String valor;
	private int nv;
	private Procedimiento np;

	public enum Tipo {
		CONST, VAR, PROC, FUNC, ARG, NULO;
	}

	public enum TSub {
		BOOLEAN, INT, STRING, NULL;
	}

	public Simbolo(String id, Simbolo next, Tipo t, TSub tsub) {
		this.id = id;
		this.next = next;
		this.t = t;
		this.tsub = tsub;
	}

	public Simbolo(Simbolo s) {
		this.id = s.id;
		this.next = s.next;
		this.t = s.t;
		this.tsub = s.tsub;
	}

	public Simbolo() {
	};

	public Procedimiento getNp() {
		return np;
	}

	public void setNp(Procedimiento np) {
		this.np = np;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public Simbolo getNext() {
		return next;
	}

	public void setNext(Simbolo next) {
		this.next = next;
	}

	public Tipo getT() {
		return t;
	}

	public void setT(Tipo t) {
		this.t = t;
	}

	public TSub getTsub() {
		return tsub;
	}

	public void setTsub(TSub tsub) {
		this.tsub = tsub;
	}

	public boolean isReturnEncontrado() {
		return returnEncontrado;
	}

	public void setReturnEncontrado(boolean returnEncontrado) {
		this.returnEncontrado = returnEncontrado;
	}

	public String getValor() {
		return valor;
	}

	public void setValor(String valor) {
		this.valor = valor;
	}

	public int getNv() {
		return nv;
	}

	public void setNv(int nv) {
		this.nv = nv;
	}
}
