/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

/**
 *
 * @author luana
 */

import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import java.io.IOException;
import java.sql.SQLException;

public class ClassificationController {

    @FXML private TableView<ClassificationRow> tblClasificacion;
    @FXML private TableColumn<ClassificationRow, String> colPosicion;
    @FXML private TableColumn<ClassificationRow, String> colJugador;
    @FXML private TableColumn<ClassificationRow, String> colPuntos;
    @FXML private Label lblTituloTorneo;

    @FXML
    private void initialize() {
        if (tblClasificacion == null) return;

        DuelRow t = DuelModel.torneoEnEdicion;
        if (t != null) {
            lblTituloTorneo.setText(t.getNombre());
        }

        colPosicion.setCellValueFactory(
                c -> new SimpleStringProperty(
                        c.getValue().getPosicion() != null ?
                        c.getValue().getPosicion().toString() : "-"
                )
        );

        colJugador.setCellValueFactory(
                c -> new SimpleStringProperty(c.getValue().getJugador())
        );

        colPuntos.setCellValueFactory(
                c -> new SimpleStringProperty(String.valueOf(c.getValue().getPuntos()))
        );

        cargar();
    }

    private void cargar() {
        try {
            DuelRow t = DuelModel.torneoEnEdicion;
            if (t == null) return;

            if ("BRACKET".equalsIgnoreCase(t.getModalidad())) {
                tblClasificacion.setItems(
                    FXCollections.observableArrayList(
                        DuelModel.clasificacionBracket(t.getId())
                    )
                );
            } else {
                tblClasificacion.setItems(
                    FXCollections.observableArrayList(
                        DuelModel.listarClasificacion(t.getId())
                    )
                );
            }

        } catch (SQLException e) {
            MiscController.alert(Alert.AlertType.ERROR,
                    "Error al cargar clasificación", e.getMessage());
        }
    }

    @FXML
    private void volverVistaTorneo() throws IOException {
        DuelRow t = DuelModel.torneoEnEdicion;

        switch (t.getModalidad()) {
            case "SUIZO":
                App.setRoot("duelMatchesSwissScreen");
                break;
            case "ROUND_ROBIN":
                App.setRoot("duelMatchesRrScreen");
                break;
            case "BRACKET":
                App.setRoot("duelMatchesBracketScreen");
                break;
            default:
                App.setRoot("duelListRecordScreen");
        }
    }
}
