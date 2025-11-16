/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

/**
 *
 * @author luana
 */

public class UsuarioRow {
    private long id;
    private String nombres;
    private String apellidos;
    private String email;
    private boolean esAdmin;
    private String usuario;
    private boolean activo;
    private String inscripto = "No";

    public UsuarioRow(long id, String nombres, String apellidos, String email,
                      boolean esAdmin, String usuario, boolean activo) {
        this.id = id;
        this.nombres = nombres;
        this.apellidos = apellidos;
        this.email = email;
        this.esAdmin = esAdmin;
        this.usuario = usuario;
        this.activo = activo;
    }

    public long getId() { return id; }
    public String getNombres() { return nombres; }
    public String getApellidos() { return apellidos; }
    public String getEmail() { return email; }
    public boolean isEsAdmin() { return esAdmin; }
    public String getUsuario() { return usuario; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
    public String getInscripto() { return inscripto; }
    public void setInscripto(String inscripto) { this.inscripto = inscripto; }
}
