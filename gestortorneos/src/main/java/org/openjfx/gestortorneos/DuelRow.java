/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.time.LocalDateTime;

/**
 *
 * @author luana
 */
public class DuelRow {
    private long id;
    private String nombre;
    private String modalidad;
    private String estado;
    private LocalDateTime inicio;
    private Integer maxJugadores;
    private boolean activo;

    public DuelRow(long id, String nombre, String modalidad, String estado,
                   LocalDateTime inicio, Integer maxJugadores, boolean activo) {
        this.id = id;
        this.nombre = nombre;
        this.modalidad = modalidad;
        this.estado = estado;
        this.inicio = inicio;
        this.maxJugadores = maxJugadores;
        this.activo = activo;
    }

    public long getId() { return id; }
    public String getNombre() { return nombre; }
    public String getModalidad() { return modalidad; }
    public String getEstado() { return estado; }
    public LocalDateTime getInicio() { return inicio; }
    public Integer getMaxJugadores() { return maxJugadores; }
    public boolean isActivo() { return activo; }

    public void setEstado(String estado) { this.estado = estado; }
    public void setActivo(boolean activo) { this.activo = activo; }
}