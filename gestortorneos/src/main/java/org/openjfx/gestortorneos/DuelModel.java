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
                Integer maxJug = (Integer) rs.getObject("max_jugadores");
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
    
    public static int registrarJugador(long torneoId, long usuarioId) {
        String sql = "{CALL sp_Inscripcion_Crear(?, ?)}";
        int rowCount = 0;

        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setLong(1, torneoId);
            cs.setLong(2, usuarioId);

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

            System.out.println("Jugador registrado. Filas afectadas: " + rowCount);
        } catch (SQLException e) {
            System.err.println("Error al registrar jugador: " + e.getMessage());
        }
        return rowCount;
    }
    
    public static void iniciarTorneo(long torneoId) throws SQLException {
        String sql = "{CALL sp_Torneo_GenerarEstructura(?)}";
        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setLong(1, torneoId);
            cs.execute();
        }
    }

    public static List<MatchRow> listarMatches(long torneoId) throws SQLException {
        String sql =
            "SELECT m.id, " +
            "       r.torneo_id, " +
            "       r.numero AS ronda_num, " +
            "       m.mesa, " +
            "       ua.nombres AS jugadorA, " +
            "       ub.nombres AS jugadorB, " +
            "       m.p1_wins, " +
            "       m.p2_wins, " +
            "       m.resultado " +
            "FROM match_ m " +
            "JOIN ronda r     ON r.id = m.ronda_id " +
            "LEFT JOIN usuario ua ON ua.id = m.player1_id " +
            "LEFT JOIN usuario ub ON ub.id = m.player2_id " +
            "WHERE r.torneo_id = ? " +
            "ORDER BY r.numero ASC, m.mesa ASC, m.id ASC";

        List<MatchRow> lista = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setLong(1, torneoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new MatchRow(
                        rs.getLong("id"),
                        rs.getLong("torneo_id"),
                        rs.getInt("ronda_num"),
                        rs.getInt("mesa"),
                        rs.getString("jugadorA"),
                        rs.getString("jugadorB"),
                        (Integer) rs.getObject("p1_wins"),
                        (Integer) rs.getObject("p2_wins"),
                        rs.getString("resultado")
                    ));
                }
            }
        }
        return lista;
    }


    public static Long registrarResultado(long matchId, int p1Wins, int p2Wins, String resultadoEnum)
            throws SQLException {
        String sql = "{CALL sp_Match_RegistrarResultado(?, ?, ?, ?)}";
        try (CallableStatement cs = conexion.prepareCall(sql)) {
            cs.setLong(1, matchId);
            cs.setInt(2, p1Wins);
            cs.setInt(3, p2Wins);
            cs.setString(4, resultadoEnum);

            boolean hasRes = cs.execute();
            if (hasRes) {
                try (ResultSet rs = cs.getResultSet()) {
                    if (rs.next()) {
                        return (Long) rs.getObject(1);
                    }
                }
            }
        }
        return null;
    }
    
    public static int generarSiguienteRonda(long torneoId) throws SQLException {
        String sql = "{ CALL sp_Torneo_GenerarSiguienteRonda(?) }";
        try (CallableStatement cs = DatabaseController.conexion.prepareCall(sql)) {
            cs.setLong(1, torneoId);
            cs.execute();
            return 1; 
        }
    }
    
    public static List<ClassificationRow> listarClasificacion(long torneoId) throws SQLException {
        List<ClassificationRow> lista = new ArrayList<>();

        String sql = "SELECT c.usuario_id, c.puntos, c.posicion, " +
                     "       CONCAT(u.nombres, ' ', u.apellidos) AS jugador " +
                     "FROM clasificacion c " +
                     "JOIN usuario u ON u.id = c.usuario_id " +
                     "WHERE c.torneo_id = ? AND c.activo = 1 " +
                     "ORDER BY c.posicion ASC";

        try (PreparedStatement ps = DatabaseController.conexion.prepareStatement(sql)) {
            ps.setLong(1, torneoId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new ClassificationRow(
                            rs.getLong("usuario_id"),
                            rs.getString("jugador"),
                            rs.getInt("puntos"),
                            rs.getObject("posicion") != null ? rs.getInt("posicion") : null
                    ));
                }
            }
        }

        return lista;
    } 
    
    public static List<ClassificationRow> clasificacionBracket(long torneoId) throws SQLException {
        List<ClassificationRow> lista = new ArrayList<>();
        
        String sqlFinal =
            "SELECT m.id, m.player1_id, m.player2_id, m.ganador_id, " +
            "       r.numero AS ronda_final " +
            "FROM match_ m " +
            "JOIN ronda r ON r.id = m.ronda_id " +
            "WHERE r.torneo_id = ? " +
            "  AND r.numero = (SELECT MAX(numero) FROM ronda WHERE torneo_id = ?) " +
            "  AND m.activo = 1 " +
            "LIMIT 1";

        long p1Final = 0, p2Final = 0, ganadorFinal = 0;
        int numeroFinal = 0;

        try (PreparedStatement ps = DatabaseController.conexion.prepareStatement(sqlFinal)) {
            ps.setLong(1, torneoId);
            ps.setLong(2, torneoId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return lista;
                }
                p1Final = rs.getLong("player1_id");
                p2Final = rs.getLong("player2_id");
                ganadorFinal = rs.getLong("ganador_id");
                numeroFinal = rs.getInt("ronda_final");
            }
        }

        long subcampeonId = (ganadorFinal == p1Final) ? p2Final : p1Final;

        String sqlNombre = "SELECT CONCAT(nombres, ' ', apellidos) FROM usuario WHERE id = ?";

        String nombreGanador;
        String nombreSubcampeon;

        try (PreparedStatement ps = DatabaseController.conexion.prepareStatement(sqlNombre)) {
            ps.setLong(1, ganadorFinal);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                nombreGanador = rs.getString(1);
            }

            ps.setLong(1, subcampeonId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                nombreSubcampeon = rs.getString(1);
            }
        }

        lista.add(new ClassificationRow(ganadorFinal,nombreGanador,0,1));
        lista.add(new ClassificationRow(subcampeonId,nombreSubcampeon,0,2));

        int rondaSemis = numeroFinal - 1;

        if (rondaSemis > 0) {
            String sqlSemis =
                "SELECT m.player1_id, m.player2_id, m.ganador_id " +
                "FROM match_ m " +
                "JOIN ronda r ON r.id = m.ronda_id " +
                "WHERE r.torneo_id = ? " +
                "  AND r.numero = ? " +
                "  AND m.activo = 1";

            try (PreparedStatement ps = DatabaseController.conexion.prepareStatement(sqlSemis)) {
                ps.setLong(1, torneoId);
                ps.setInt(2, rondaSemis);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        long p1 = rs.getLong("player1_id");
                        long p2 = rs.getLong("player2_id");
                        long ganador = rs.getLong("ganador_id");

                        long perdedor = (ganador == p1) ? p2 : p1;

                        if (perdedor != 0) {
                            String nombrePerdedor;
                            try (PreparedStatement ps2 = DatabaseController.conexion.prepareStatement(sqlNombre)) {
                                ps2.setLong(1, perdedor);
                                try (ResultSet rs2 = ps2.executeQuery()) {
                                    rs2.next();
                                    nombrePerdedor = rs2.getString(1);
                                }
                            }
                            lista.add(new ClassificationRow(perdedor,nombrePerdedor,0,3));
                        }
                    }
                }
            }
        }

        return lista;
    }

}
