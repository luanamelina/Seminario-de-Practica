/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

/**
 *
 * @author luana
 */
public class MatchRow {
    private long id;
    private long torneoId;
    private int ronda;
    private int mesa;
    private String jugadorA;
    private String jugadorB;
    private Integer puntajeA;
    private Integer puntajeB;
    private String estado;

    public MatchRow(long id, long torneoId, int ronda, int mesa,
                    String jugadorA, String jugadorB,
                    Integer puntajeA, Integer puntajeB, String estado) {
        this.id = id;
        this.torneoId = torneoId;
        this.ronda = ronda;
        this.mesa = mesa;
        this.jugadorA = jugadorA;
        this.jugadorB = jugadorB;
        this.puntajeA = puntajeA;
        this.puntajeB = puntajeB;
        this.estado = estado;
    }

    public long getId() { return id; }
    public long getTorneoId() { return torneoId; }
    public int getRonda() { return ronda; }
    public int getMesa() { return mesa; }
    public String getJugadorA() { return jugadorA; }
    public String getJugadorB() { return jugadorB; }
    public Integer getPuntajeA() { return puntajeA; }
    public Integer getPuntajeB() { return puntajeB; }
    public String getEstado() { return estado; }

    public void setPuntajeA(Integer v) { this.puntajeA = v; }
    public void setPuntajeB(Integer v) { this.puntajeB = v; }
    public void setEstado(String e) { this.estado = e; }
}
