/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.scene.layout.AnchorPane;
import javafx.util.Callback;

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
    
    //Form Editar Torneo
    @FXML private TextField editNombreTorneo;
    @FXML private DatePicker editInicio;
    @FXML private TextField editIdDuel;
    
    //Listado Torneo
    @FXML private TableView<DuelRow> tblTorneos;
    @FXML private TableColumn<DuelRow, String> colNombre;
    @FXML private TableColumn<DuelRow, String> colModalidad;
    @FXML private TableColumn<DuelRow, String> colEstado;
    @FXML private TableColumn<DuelRow, String> colInicio;
    @FXML private TableColumn<DuelRow, String> colMaxJugadores;
    @FXML private TableColumn<DuelRow, String> colActivo;
    @FXML private TableColumn<DuelRow, Void>   colEditar;
    @FXML private TableColumn<DuelRow, Void>   colVer;
    @FXML private TableColumn<DuelRow, Void>   colInscribir;
    @FXML private TableColumn<DuelRow, Void>   colToggle;
    
    private final ObservableList<DuelRow> datos = FXCollections.observableArrayList();
    private final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    
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
    public void abrirEditarTorneo() throws IOException {
        App.setRoot("duelEditRecordScreen");
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

    if (duelNewRecord != null) {
        cmbModalidad.getItems().setAll("SUIZO", "ROUND_ROBIN", "BRACKET");

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
    }

    if (tblTorneos != null) {
        colNombre.setCellValueFactory(c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getNombre()));
        colModalidad.setCellValueFactory(c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getModalidad()));
        colEstado.setCellValueFactory(c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getEstado()));
        colInicio.setCellValueFactory(c -> {
            var dt = c.getValue().getInicio();
            String s = (dt == null) ? "" : FMT.format(dt);
            return new javafx.beans.property.SimpleStringProperty(s);
        });
        colMaxJugadores.setCellValueFactory(c -> {
            Integer n = c.getValue().getMaxJugadores();
            return new javafx.beans.property.SimpleStringProperty(n == null ? "" : String.valueOf(n));
        });
        colActivo.setCellValueFactory(c ->
                new javafx.beans.property.SimpleStringProperty(c.getValue().isActivo() ? "Sí" : "No"));

        addButtonToColumnDuel(colEditar, "Editar", row -> {
            try {
                DuelModel.torneoEnEdicion = row;
                abrirEditarTorneo();
            } catch (IOException e) {
                e.printStackTrace();
                MiscController.alert(Alert.AlertType.ERROR, "Error",
                        "No se pudo abrir la pantalla de edición:\n" + e.getMessage());
            }
            
        });
        
        addButtonToColumnDuel(colVer, "Ver", row -> {
            System.out.println("Editar torneo id=" + row.getId());
            // App.setRoot("duelEditRecordScreen");
        });
        
        addButtonToColumnDuel(colInscribir, "Inscribir Jugadores", row -> {
            System.out.println("Editar torneo id=" + row.getId());
            // App.setRoot("duelEditRecordScreen");
        });

        addButtonToColumnDuel(colToggle, "Activar/Desactivar", row -> {
            try {
                boolean nuevo = !row.isActivo();
                DuelModel.cambiarEstadoActivo(row.getId(), nuevo);
                row.setActivo(nuevo);
                tblTorneos.refresh();
                MiscController.alert(Alert.AlertType.INFORMATION, "Estado actualizado",
                        "El torneo ahora está " + (nuevo ? "Activo" : "Inactivo") + ".");
            } catch (SQLException e) {
                MiscController.alert(Alert.AlertType.ERROR, "Error",
                        "No se pudo actualizar el estado:\n" + e.getMessage());
            }
        });

        cargarTorneos();
        tblTorneos.setItems(datos);
    }
    
    if (editNombreTorneo != null) {
        DuelRow t = DuelModel.torneoEnEdicion;
        if (t != null) {
            editIdDuel.setText(String.valueOf(t.getId()));
            editNombreTorneo.setText(t.getNombre());
            editInicio.setValue(t.getInicio() != null ? t.getInicio().toLocalDate() : null);
        }
    }

}
    
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
    
    @FXML
    private void editarTorneo() {
        Integer id = Integer.parseInt(editIdDuel.getText());
        String nombre = editNombreTorneo.getText().trim();
        LocalDate fechaInicio = editInicio.getValue();

        if (nombre.isEmpty()) {
            MiscController.alert(Alert.AlertType.WARNING, "Campos incompletos",
                    "Completá todos los campos.");
            return;
        }

        try {
            int filas = DuelModel.editarTorneo(
                   id, nombre, fechaInicio
            );

            if (filas > 0) {
                MiscController.alert(Alert.AlertType.INFORMATION, "Éxito",
                        "Torneo editado correctamente.");
                limpiarFormularioTorneoEditar();
                abrirListadoTorneo();
            } else {
                MiscController.alert(Alert.AlertType.WARNING, "Aviso",
                        "No se editó ningún registro.");
            }
        } catch (Exception e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "Ocurrió un error al editar el torneo:\n" + e.getMessage());
        }
    }
    
    private void cargarTorneos() {
        datos.clear();
        try {
            List<DuelRow> lista = DuelModel.listarTorneos();
            datos.addAll(lista);
        } catch (SQLException e) {
            e.printStackTrace();
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "No se pudo cargar el listado de torneos:\n" + e.getMessage());
        }
    }

    private void addButtonToColumnDuel(TableColumn<DuelRow, Void> column, String caption,
                                   java.util.function.Consumer<DuelRow> onClick) {
        Callback<TableColumn<DuelRow, Void>, TableCell<DuelRow, Void>> factory = col -> new TableCell<>() {
            private final Button btn = new Button(caption);
            {
                btn.setOnAction(e -> {
                    DuelRow row = getTableView().getItems().get(getIndex());
                    onClick.accept(row);
                });
                btn.setMaxWidth(Double.MAX_VALUE);
            }
            @Override
            protected void updateItem(Void item, boolean empty) {
                super.updateItem(item, empty);
                setGraphic(empty ? null : btn);
            }
        };
        column.setCellFactory(factory);
    }
    
    private void limpiarFormularioTorneo() {
        txtNombreTorneo.clear();
        cmbModalidad.getSelectionModel().clearSelection();
        dpInicio.setValue(null);
        txtMaxJugadores.clear();
        lblRecomendacion.setText("");
    }
    
        private void limpiarFormularioTorneoEditar() {
        editNombreTorneo.clear();
        editInicio.setValue(null);
        editIdDuel.clear();
    }
    
    
}
