/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.io.IOException;
import java.time.LocalDate;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;

/**
 *
 * @author luana
 */
public class DuelController {
    
    //Form Crear Torneo
    @FXML private TextField txtNombreTorneo;
    @FXML private ComboBox<String> cmbModalidad;
    @FXML private DatePicker dpInicio;
    @FXML private TextField txtMaxJugadores;
    @FXML private Label lblRecomendacion;
    @FXML private AnchorPane duelNewRecord;
    
    //Funciones UI
    @FXML
    public void menuTorneo() throws IOException {
        App.setRoot("duelMenuScreen");
    }
    
    @FXML
    public void abrirCrearTorneo() throws IOException {
        App.setRoot("duelNewRecordScreen");
    }
    
    @FXML
    public void abrirListadoTorneo() throws IOException {
        App.setRoot("duelListRecordScreen");
    }
    
    @FXML
    public void cerrarMenuTorneo() throws IOException {
        App.setRoot("mainMenuScreen");
        
    
    }
    
    //Funciones Forms
    @FXML
    private void initialize() {
        if (duelNewRecord != null && "duelNewRecord".equals(duelNewRecord.getId())) {
        // Carga de modalidades
        cmbModalidad.getItems().setAll("SUIZO", "ROUND_ROBIN", "BRACKET");

        // Listener para actualizar recomendación
        cmbModalidad.valueProperty().addListener((obs, oldVal, nueva) -> {
            if (nueva == null) {
                lblRecomendacion.setText("");
                return;
            }
            switch (nueva) {
                case "BRACKET":
                    lblRecomendacion.setText("Recomendación: potencia de 2 (8, 16, 32...).");
                    break;
                case "SUIZO":
                    lblRecomendacion.setText("Recomendación: flexible (8+ jugadores).");
                    break;
                case "ROUND_ROBIN":
                    lblRecomendacion.setText("Recomendación: grupos pequeños (4–10 es cómodo).");
                    break;
                default:
                    lblRecomendacion.setText("");
            }
        });
    }}
    
    @FXML
    private void guardarTorneoNuevo() {
        String nombre = txtNombreTorneo.getText().trim();
        String modalidad = cmbModalidad.getValue();
        LocalDate fechaInicio = dpInicio.getValue();
        String maxTxt = txtMaxJugadores.getText().trim();

        // Validaciones básicas
        if (nombre.isEmpty() || modalidad == null || modalidad.isEmpty()) {
            MiscController.alert(Alert.AlertType.WARNING, "Campos incompletos",
                    "Completá al menos Nombre y Modalidad.");
            return;
        }

        Integer maxJugadores = null;
        if (!maxTxt.isEmpty()) {
            try {
                maxJugadores = Integer.valueOf(maxTxt);
                if (maxJugadores <= 0) {
                    MiscController.alert(Alert.AlertType.WARNING, "Dato inválido",
                            "El N° de Jugadores debe ser un entero positivo.");
                    return;
                }
            } catch (NumberFormatException e) {
                MiscController.alert(Alert.AlertType.WARNING, "Dato inválido",
                        "El N° de Jugadores debe ser numérico.");
                return;
            }
        }

        try {
            int filas = DuelModel.crearTorneo(
                    nombre, modalidad, fechaInicio, maxJugadores
            );

            if (filas > 0) {
                MiscController.alert(Alert.AlertType.INFORMATION, "Éxito",
                        "Torneo creado correctamente.");
                limpiarFormularioTorneo();
            } else {
                MiscController.alert(Alert.AlertType.WARNING, "Aviso",
                        "No se insertó ningún registro.");
            }
        } catch (Exception e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "Ocurrió un error al crear el torneo:\n" + e.getMessage());
        }
    }
    
    private void limpiarFormularioTorneo() {
        txtNombreTorneo.clear();
        cmbModalidad.getSelectionModel().clearSelection();
        dpInicio.setValue(null);
        txtMaxJugadores.clear();
        lblRecomendacion.setText("");
    }
    
}
