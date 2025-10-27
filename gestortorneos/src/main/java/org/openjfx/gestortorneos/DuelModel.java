/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.sql.*;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

import static org.openjfx.gestortorneos.DatabaseController.conexion;

/**
 *
 * @author luana
 */
public class DuelModel {
    
    public static int crearTorneo(String nombre,
                                  String modalidad,
                                  LocalDate fechaInicio,
                                  Integer maxJugadores) throws SQLException {

        final String sql = "{CALL sp_Torneo_Crear(?, ?, ?, ?)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setString(1, nombre);
            cs.setString(2, modalidad);

            if (fechaInicio != null) {
                Timestamp ts = Timestamp.valueOf(fechaInicio.atStartOfDay());
                cs.setTimestamp(3, ts);
            } else {
                cs.setNull(3, Types.TIMESTAMP);
            }

            if (maxJugadores != null) {
                cs.setInt(4, maxJugadores);
            } else {
                cs.setNull(4, Types.INTEGER);
            }

            boolean hasResult = cs.execute();

            if (hasResult) {
                try (ResultSet rs = cs.getResultSet()) {
                    if (rs.next()) {
                        rowCount = rs.getInt("ROW_COUNT");
                    }
                }
            } else {
                int updateCount = cs.getUpdateCount();
                rowCount = (updateCount >= 0) ? updateCount : 0;
            }

            System.out.println("Torneo creado. Filas afectadas: " + rowCount);
        }

        return rowCount;
    }
    
}
