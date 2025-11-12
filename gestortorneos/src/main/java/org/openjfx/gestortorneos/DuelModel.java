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
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import static org.openjfx.gestortorneos.DatabaseController.conexion;

/**
 *
 * @author luana
 */
public class DuelModel {
    public static DuelRow torneoEnEdicion;
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
    
    public static int editarTorneo(Integer id,
                                   String nombre,
                                   LocalDate inicio) {

        String sql = "{CALL sp_Torneo_Editar(?, ?, ?)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setInt(1, id);
            cs.setString(2, nombre);
            if (inicio != null) {
                Timestamp ts = Timestamp.valueOf(inicio.atStartOfDay());
                cs.setTimestamp(3, ts);
            } else {
                cs.setNull(3, Types.TIMESTAMP);
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

            System.out.println("Filas afectadas: " + rowCount);
            System.out.println(cs);

        } catch (SQLException e) {
            System.err.println("Error al editar torneo: " + e.getMessage());
        }

        return rowCount;
    }
    
    public static List<DuelRow> listarTorneos() throws SQLException {
        List<DuelRow> lista = new ArrayList<>();
        String sql = "SELECT id, nombre, modalidad, estado, inicio, max_jugadores, activo " +
                     "FROM torneo ORDER BY id DESC";

        try (PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Long id = rs.getLong("id");
                String nombre = rs.getString("nombre");
                String modalidad = rs.getString("modalidad");
                String estado = rs.getString("estado");
                Timestamp ts = rs.getTimestamp("inicio");
                LocalDateTime inicio = (ts != null) ? ts.toLocalDateTime() : null;
                Integer maxJug = (Integer) rs.getObject("max_jugadores"); // permite NULL
                boolean activo = rs.getBoolean("activo");

                lista.add(new DuelRow(id, nombre, modalidad, estado, inicio, maxJug, activo));
            }
        }
        return lista;
    }

    public static boolean cambiarEstadoActivo(long id, boolean nuevo) throws SQLException {
        String sql = "UPDATE torneo SET activo = ? WHERE id = ?";
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setBoolean(1, nuevo);
            ps.setLong(2, id);
            return ps.executeUpdate() > 0;
        }
    }
    
}
