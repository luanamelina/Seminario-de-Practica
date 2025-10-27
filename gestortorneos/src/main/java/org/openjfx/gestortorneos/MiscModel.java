/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import static org.openjfx.gestortorneos.DatabaseController.conexion;
/**
 *
 * @author luana
 */
public class MiscModel {
    public static int crearSesionAdmin(String usuario,
                                   String password) {

        String sql = "{CALL sp_Usuario_Traer(0, ?, ?, 1, 1)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setString(1, usuario);
            cs.setString(2, password);

            boolean hasResult = cs.execute();

            if (hasResult) {
                try (ResultSet rs = cs.getResultSet()) {
                    if (rs.next()) {
                        rowCount = rs.getInt("es_admin");
                    }
                }
            } else {
                int updateCount = cs.getUpdateCount();
                rowCount = (updateCount >= 0) ? updateCount : 0;
            }

        } catch (SQLException e) {
            System.err.println("Error al iniciar sesion: " + e.getMessage());
        }

        return rowCount;
    }
}
