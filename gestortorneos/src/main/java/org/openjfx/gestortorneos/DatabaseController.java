/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 *
 * @author luana
 */
public class DatabaseController {
    private static final String URL = "jdbc:mariadb://localhost:3306/sistematorneos";
    private static final String USUARIO = "root";
    private static final String PASSWORD = "";

    public static Connection conexion;

    public static Connection crearConexion() {
        if (conexion == null) {
            try {
                conexion = DriverManager.getConnection(URL, USUARIO, PASSWORD);
                System.out.println("Conexion establecida con MariaDB.");
            } catch (SQLException e) {
                System.err.println("Error al conectar: " + e.getMessage());
            }
        }
        return conexion;
    }
    
    public static void cerrarConexion() {
        if (conexion != null) {
            try {
                if (!conexion.isClosed()) {
                    conexion.close();
                    System.out.println("Conexion cerrada correctamente.");
                }
            } catch (SQLException e) {
                System.err.println("Error al cerrar la conexion: " + e.getMessage());
            } finally {
                conexion = null;
            }
        } else {
            System.out.println("No hay conexion activa para cerrar.");
        }
    }
}