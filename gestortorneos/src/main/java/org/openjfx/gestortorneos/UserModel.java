/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import static org.openjfx.gestortorneos.DatabaseController.conexion;

/**
 *
 * @author luana
 */
public class UserModel {
    public static UsuarioRow usuarioEnEdicion;
    public static int crearUsuario(String nombres,
                                   String apellidos,
                                   String email,
                                   String usuario,
                                   String passwordHash,
                                   boolean esAdmin) {

        String sql = "{CALL sp_Usuario_Crear(?, ?, ?, ?, ?, ?)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setString(1, nombres);
            cs.setString(2, apellidos);
            cs.setString(3, email);
            cs.setString(4, usuario);
            cs.setString(5, passwordHash);
            cs.setBoolean(6, esAdmin);
            
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
            System.err.println("Error al crear usuario: " + e.getMessage());
        }
        return rowCount;
    }
    
    public static int editarUsuario(Integer id,
                                   String nombres,
                                   String apellidos,
                                   String email) {

        String sql = "{CALL sp_Usuario_Editar(?, ?, ?, ?)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setInt(1, id);
            cs.setString(2, nombres);
            cs.setString(3, apellidos);
            cs.setString(4, email);            

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
            System.err.println("Error al editar usuario: " + e.getMessage());
        }
        return rowCount;
    }
    
    public static List<UsuarioRow> listarUsuarios() throws SQLException {
        List<UsuarioRow> usuarios = new ArrayList<>();

        String sql = "CALL sp_usuario_traer(0, '', '', 0, 0)";

        try (PreparedStatement ps = conexion.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                UsuarioRow u = new UsuarioRow(
                        rs.getLong("id"),
                        rs.getString("nombres"),
                        rs.getString("apellidos"),
                        rs.getString("email"),
                        rs.getBoolean("es_admin"),
                        rs.getString("usuario"),
                        rs.getBoolean("activo")
                );
                usuarios.add(u);
            }
        }
        return usuarios;
    }
    
    public static boolean cambiarEstadoUsuario(long id, boolean nuevoEstado) throws SQLException {
        String sql = "UPDATE usuario SET activo = ? WHERE id = ?";
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setBoolean(1, nuevoEstado);
            ps.setLong(2, id);
            return ps.executeUpdate() > 0;
        }
    }
}
