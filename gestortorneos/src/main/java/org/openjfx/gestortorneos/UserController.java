/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.io.IOException;
import javafx.fxml.FXML;
import javafx.scene.control.*;

import javafx.util.Callback;

import java.sql.*;
import java.util.List;
import javafx.scene.layout.AnchorPane;

/**
 *
 * @author luana
 */
public class UserController {
    
    //Form Crear Usuario
    @FXML private TextField txtNombres;
    @FXML private TextField txtApellidos;
    @FXML private TextField txtEmail;
    @FXML private CheckBox chkEsAdmin;
    @FXML private TextField txtUsuario;
    @FXML private TextField txtPassword;
    
    //Tabla Usuarios
    @FXML private AnchorPane userListRecord;
    @FXML private TableView<UsuarioRow> tblUsuarios;
    @FXML private TableColumn<UsuarioRow, String>  colNombres;
    @FXML private TableColumn<UsuarioRow, String>  colApellidos;
    @FXML private TableColumn<UsuarioRow, String>  colEmail;
    @FXML private TableColumn<UsuarioRow, String>  colUsuario;
    @FXML private TableColumn<UsuarioRow, String>  colAdmin;
    @FXML private TableColumn<UsuarioRow, String>  colActivo;
    @FXML private TableColumn<UsuarioRow, Void>    colEditar;
    @FXML private TableColumn<UsuarioRow, Void>    colToggle;
    
    //Funciones UI
    @FXML
    public void menuMain() throws IOException {
        App.setRoot("mainMenuScreen");
    }
    @FXML
    public void abrirCrearUsuario() throws IOException {
        App.setRoot("userNewRecordScreen");
    }
    @FXML
    public void abrirListadoUsuario() throws IOException {
        App.setRoot("userListRecordScreen");
    }
    
    //Funciones Forms
    @FXML
    private void guardarUsuarioNuevo() {
        String nombres = txtNombres.getText().trim();
        String apellidos = txtApellidos.getText().trim();
        String email = txtEmail.getText().trim();
        String usuario = txtUsuario.getText().trim();
        String passwordHash = txtPassword.getText();
        boolean esAdmin = chkEsAdmin.isSelected();

        if (nombres.isEmpty() || apellidos.isEmpty() || email.isEmpty()) {
            MiscController.alert(Alert.AlertType.WARNING, "Campos incompletos",
                    "Completá todos los campos.");
            return;
        }
        else if ( chkEsAdmin.isSelected() &&( usuario.isEmpty() || passwordHash.isEmpty())){
            MiscController.alert(Alert.AlertType.WARNING, "Campos incompletos",
                    "Asignale un usuario y contraseña al usuario Administrador.");
            return;
        }

        try {
            int filas = UserModel.crearUsuario(
                    nombres, apellidos, email, usuario, passwordHash, esAdmin
            );

            if (filas > 0) {
                MiscController.alert(Alert.AlertType.INFORMATION, "Éxito",
                        "Usuario creado correctamente.");
                limpiarFormulario();
            } else {
                MiscController.alert(Alert.AlertType.WARNING, "Aviso",
                        "No se insertó ningún registro.");
            }
        } catch (Exception e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error",
                    "Ocurrió un error al crear el usuario:\n" + e.getMessage());
        }
    }
    
    private void limpiarFormulario() {
        txtNombres.clear();
        txtApellidos.clear();
        txtEmail.clear();
        txtUsuario.clear();
        txtPassword.clear();
        chkEsAdmin.setSelected(false);
    }
    
    @FXML
    private final javafx.collections.ObservableList<UsuarioRow> datos =
        javafx.collections.FXCollections.observableArrayList();
    
    @FXML
    private void initialize() {
        /*if (tblUsuarios == null) {
            throw new IllegalStateException("Faltan fx:id en el FXML para la tabla/columnas.");
        }*/
        
        if (userListRecord != null && "userListRecord".equals(userListRecord.getId())) {

        colNombres.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getNombres()) );
        colApellidos.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getApellidos()) );
        colEmail.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getEmail()) );
        colUsuario.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getUsuario()) );
        colAdmin.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().isEsAdmin() ? "Sí" : "No") );
        colActivo.setCellValueFactory( c -> new javafx.beans.property.SimpleStringProperty(c.getValue().isActivo() ? "Sí" : "No") );

        addButtonToColumn(colEditar, "Editar", row -> {
            System.out.println("Editar usuario id=" + row.getId());
        });

        addButtonToColumn(colToggle, "Activar/Desactivar", row -> {
            try {
                boolean nuevo = !row.isActivo();
                UserModel.cambiarEstadoUsuario(row.getId(), nuevo);
                row.setActivo(nuevo);
                tblUsuarios.refresh();
                MiscController.alert(Alert.AlertType.INFORMATION, "Estado actualizado",
                        "El usuario ahora está " + (nuevo ? "Activo" : "Inactivo") + ".");
            } catch (SQLException e) {
                MiscController.alert(Alert.AlertType.ERROR, "Error", "No se pudo actualizar el estado:\n" + e.getMessage());
            }
        });

        cargarUsuarios();
        tblUsuarios.setItems(datos);
    } }
    
    private void cargarUsuarios() {
        datos.clear();
        try {
            List<UsuarioRow> lista = UserModel.listarUsuarios();
            datos.addAll(lista);
        } catch (SQLException e) {
            MiscController.alert(Alert.AlertType.ERROR, "Error", "No se pudo cargar el listado:\n" + e.getMessage());
        }
    }
    
    private void addButtonToColumn(TableColumn<UsuarioRow, Void> column, String caption,
                                   java.util.function.Consumer<UsuarioRow> onClick) {
        Callback<TableColumn<UsuarioRow, Void>, TableCell<UsuarioRow, Void>> factory = col -> new TableCell<>() {
            private final Button btn = new Button(caption);
            {
                btn.setOnAction(e -> {
                    UsuarioRow row = getTableView().getItems().get(getIndex());
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
    
}
