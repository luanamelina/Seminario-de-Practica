/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.collections.*;
import java.sql.SQLException;
import java.util.List;

public class RegistrationController {

    @FXML private TableView<UsuarioRow> tblJugadores;
    @FXML private TableColumn<UsuarioRow, Long> colId;
    @FXML private TableColumn<UsuarioRow, String> colNombres;
    @FXML private TableColumn<UsuarioRow, String> colApellidos;
    @FXML private TableColumn<UsuarioRow, String> colEmail;
    @FXML private TableColumn<UsuarioRow, Void> colAccion;

    private long torneoId;

    public void setTorneoId(long id) {
        this.torneoId = id;
        cargarUsuariosActivos();
    }

    private void cargarUsuariosActivos() {
        ObservableList<UsuarioRow> lista = FXCollections.observableArrayList();
        try {
            List<UsuarioRow> usuarios = UserModel.listarUsuarios();
            for (UsuarioRow u : usuarios) {
                if (u.isActivo()) lista.add(u);
            }
        } catch (SQLException e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "No se pudo cargar el listado de usuarios:\n" + e.getMessage());
        }
        colId.setCellValueFactory(new PropertyValueFactory<>("id"));
        colNombres.setCellValueFactory(new PropertyValueFactory<>("nombres"));
        colApellidos.setCellValueFactory(new PropertyValueFactory<>("apellidos"));
        colEmail.setCellValueFactory(new PropertyValueFactory<>("email"));

        agregarBotonInscribir();
        tblJugadores.setItems(lista);
    }

    private void agregarBotonInscribir() {
        colAccion.setCellFactory(param -> new TableCell<>() {
            private final Button btn = new Button("Inscribir");
            {
                btn.setOnAction(e -> {
                    UsuarioRow usuario = getTableView().getItems().get(getIndex());
                    inscribirJugador(usuario.getId());
                });
            }
            @Override
            protected void updateItem(Void item, boolean empty) {
                super.updateItem(item, empty);
                setGraphic(empty ? null : btn);
            }
        });
    }

    private void inscribirJugador(long usuarioId) {
        try {
            int filas = DuelModel.registrarJugador(torneoId, usuarioId);
            if (filas > 0) {
                MiscController.alert(Alert.AlertType.INFORMATION, "Éxito",
                        "Jugador inscrito correctamente.");
            } else {
                MiscController.alert(Alert.AlertType.WARNING, "Aviso",
                        "No se realizó la inscripción. El jugador ya estaba inscrito o el torneo está lleno.");
            }
        } catch (Exception e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "Error al inscribir jugador:\n" + e.getMessage());
        }
    }

    @FXML
    private void abrirListadoTorneo() {
        try {
            App.setRoot("duelListRecordScreen");
        } catch (Exception e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "No se pudo volver al listado de torneos:\n" + e.getMessage());
        }
    }
}
