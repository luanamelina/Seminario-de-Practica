/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

/**
 *
 * @author luana
 */
public class ClassificationRow {
    private long usuarioId;
    private String jugador;
    private int puntos;
    private Integer posicion;

    public ClassificationRow(long usuarioId,
                             String jugador,
                             int puntos,
                             Integer posicion) {
        this.usuarioId = usuarioId;
        this.jugador = jugador;
        this.puntos = puntos;
        this.posicion = posicion;
    }

    public long getUsuarioId() { return usuarioId; }
    public String getJugador() { return jugador; }
    public int getPuntos() { return puntos; }
    public Integer getPosicion() { return posicion; }

    public void setJugador(String j) { this.jugador = j; }
    public void setPuntos(int p) { this.puntos = p; }
    public void setPosicion(Integer p) { this.posicion = p; }
}