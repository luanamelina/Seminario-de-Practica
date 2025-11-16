/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.io.IOException;
import java.sql.SQLException;
import javafx.beans.property.SimpleStringProperty;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.Alert;
import javafx.scene.control.Button;
import javafx.scene.control.ButtonType;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.TextField;
import javafx.scene.layout.GridPane;

/**
 *
 * @author luana
 */
public class MatchController {

    @FXML private TableView<MatchRow> tblMatches;
    @FXML private TableColumn<MatchRow, String> colMRonda;
    @FXML private TableColumn<MatchRow, String> colMMesa;
    @FXML private TableColumn<MatchRow, String> colMJugadorA;
    @FXML private TableColumn<MatchRow, String> colMJugadorB;
    @FXML private TableColumn<MatchRow, String> colMResultado;
    @FXML private TableColumn<MatchRow, String> colMEstado;
    @FXML private TableColumn<MatchRow, Void>   colMRegistrar;
    @FXML private Label lblTorneoTitulo;

    private final ObservableList<MatchRow> datosMatches = FXCollections.observableArrayList();

    @FXML
    private void initialize() {
        if (tblMatches == null) return;

        if (DuelModel.torneoEnEdicion != null && lblTorneoTitulo != null) {
            DuelRow t = DuelModel.torneoEnEdicion;
            lblTorneoTitulo.setText(t.getNombre());
        }

        colMRonda.setCellValueFactory(c -> new SimpleStringProperty(String.valueOf(c.getValue().getRonda())));
        colMMesa.setCellValueFactory(c -> new SimpleStringProperty(String.valueOf(c.getValue().getMesa())));
        colMJugadorA.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getJugadorA()));
        colMJugadorB.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getJugadorB()));
        colMResultado.setCellValueFactory(c -> new SimpleStringProperty(formatearResultado(c.getValue())));
        colMEstado.setCellValueFactory(c -> new SimpleStringProperty(c.getValue().getEstado()));

        colMRegistrar.setCellFactory(col -> new TableCell<>() {
            private final Button btn = new Button("Registrar");
            {
                btn.setOnAction(e -> {
                    MatchRow row = getTableView().getItems().get(getIndex());
                    abrirDialogoResultado(row);
                });
            }
            @Override
            protected void updateItem(Void item, boolean empty) {
                super.updateItem(item, empty);
                setGraphic(empty ? null : btn);
            }
        });
        tblMatches.setItems(datosMatches);
        cargarMatches();
    }

    private String formatearResultado(MatchRow m) {
        String a = m.getPuntajeA() == null ? "" : String.valueOf(m.getPuntajeA());
        String b = m.getPuntajeB() == null ? "" : String.valueOf(m.getPuntajeB());
        return (a.isEmpty() && b.isEmpty()) ? "" : (a + " - " + b);
    }

    private void cargarMatches() {
        datosMatches.clear();
        try {
            long torneoId = DuelModel.torneoEnEdicion != null ? DuelModel.torneoEnEdicion.getId() : 0;
            if (torneoId == 0) return;
            datosMatches.addAll(DuelModel.listarMatches(torneoId));
        } catch (SQLException e) {
            mostrarSqlError(e);
        }
    }

    private void abrirDialogoResultado(MatchRow m) {
        Dialog<ButtonType> dialog = new Dialog<>();
        dialog.setTitle("Registrar resultado");
        dialog.getDialogPane().getButtonTypes().addAll(ButtonType.OK, ButtonType.CANCEL);

        GridPane grid = new GridPane();
        grid.setHgap(10);
        grid.setVgap(10);

        TextField tfP1 = new TextField(m.getPuntajeA() == null ? "" : String.valueOf(m.getPuntajeA()));
        TextField tfP2 = new TextField(m.getPuntajeB() == null ? "" : String.valueOf(m.getPuntajeB()));
        ComboBox<String> cbRes = new ComboBox<>();
        cbRes.getItems().setAll("P1", "P2", "EMPATE", "BYE");
        String estado = String.valueOf(m.getEstado());
        String valorInicial;

        switch (estado) {
            case "P1":
            case "P2":
            case "EMPATE":
            case "BYE":
                valorInicial = estado;
                break;
            default:
                valorInicial = "P1";
                break;
        }

        cbRes.getSelectionModel().select(valorInicial);
        grid.addRow(0, new Label("Jugador A (P1) gana:"), tfP1);
        grid.addRow(1, new Label("Jugador B (P2) gana:"), tfP2);
        grid.addRow(2, new Label("Resultado:"), cbRes);

        dialog.getDialogPane().setContent(grid);

        var res = dialog.showAndWait();
        if (res.isPresent() && res.get() == ButtonType.OK) {
            try {
                int p1 = tfP1.getText().isBlank() ? 0 : Integer.parseInt(tfP1.getText().trim());
                int p2 = tfP2.getText().isBlank() ? 0 : Integer.parseInt(tfP2.getText().trim());
                String enumRes = cbRes.getValue();

                DuelModel.registrarResultado(m.getId(), p1, p2, enumRes);

                m.setPuntajeA(p1);
                m.setPuntajeB(p2);
                m.setEstado(enumRes);
                tblMatches.refresh();

                DuelRow t = DuelModel.torneoEnEdicion;
                if (t != null && "BRACKET".equalsIgnoreCase(t.getModalidad())) {
                    cargarMatches();
                }

            } catch (NumberFormatException nfe) {
                MiscController.alert(Alert.AlertType.WARNING, "Dato inválido",
                        "Los puntajes deben ser números enteros.");
            } catch (SQLException e) {
                mostrarSqlError(e);
            }
        }
    }

    private void mostrarSqlError(SQLException e) {
        String msg = "45000".equals(e.getSQLState()) && e.getMessage() != null
                ? e.getMessage()
                : (e.getMessage() != null ? e.getMessage() : e.toString());
        MiscController.alert(Alert.AlertType.ERROR, "Error SQL", msg);
    }

    @FXML
    private void volverListadoTorneos() throws IOException {
        App.setRoot("duelListRecordScreen");
    }
    
    @FXML
    private void generarSiguienteRonda() {
        try {
            long torneoId = DuelModel.torneoEnEdicion.getId();
            DuelModel.generarSiguienteRonda(torneoId);
            MiscController.alert(Alert.AlertType.INFORMATION,
                    "Ronda generada",
                    "La siguiente ronda fue creada correctamente.");
            cargarMatches();
        } catch (SQLException e) {
            String msg = (e.getMessage() != null) ? e.getMessage() : e.toString();
            MiscController.alert(Alert.AlertType.ERROR,
                    "Error SQL al generar la ronda", msg);
        }
    }
    
    @FXML
    private void abrirClasificacion() throws IOException {
        App.setRoot("duelClassificationScreen");
    }
}
