/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package org.openjfx.gestortorneos;

import java.io.IOException;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.control.*;

/**
 *
 * @author luana
 */
public class MiscController {
    
    //Form Iniciar Sesion
    @FXML private TextField txtUsuarioLogin;
    @FXML private TextField pssPassword;
    
    //Funciones de Interfaz
    @FXML
    public void abrirMenu() throws IOException {
        App.setRoot("mainMenuScreen");
    }
    
    @FXML
    private void cerrarSesion() throws IOException {
        App.setRoot("loginScreen");
    }
    
    @FXML
    private void abrirMenuTorneos() throws IOException {
        App.setRoot("duelMenuScreen");
    }
    
    @FXML
    private void abrirMenuUsuarios() throws IOException {
        App.setRoot("userListRecordScreen");
    }
    
    //Alertas
    public static void alert(Alert.AlertType type, String title, String content) {
        if (Platform.isFxApplicationThread()) {
            showAlert(type, title, content);
        } else {
            Platform.runLater(() -> showAlert(type, title, content));
        }
    }

    private static void showAlert(Alert.AlertType type, String title, String content) {
        Alert a = new Alert(type);
        a.setTitle(title);
        a.setHeaderText(null);
        a.setContentText(content);
        a.showAndWait();
    }
    
    //Funciones Forms
    @FXML
    private void iniciarSesion() {
        String usuario = txtUsuarioLogin.getText().trim();
        String password = pssPassword.getText().trim();

        if (usuario.isEmpty() || password.isEmpty()) {
            alert(Alert.AlertType.WARNING, "Campos incompletos",
                    "Completá todos los campos.");
            return;
        }

        try {
            int filas = MiscModel.crearSesionAdmin(
                    usuario, password
            );

            if (filas > 0) {
                alert(Alert.AlertType.INFORMATION, "Éxito",
                       "¡Bienvenido/a " + usuario + "!");
                limpiarFormularioLogin();
                abrirMenu();
            } else {
                alert(Alert.AlertType.WARNING, "Aviso",
                        "Por favor, revisar que todos los campos estén correctos.");
            }
        } catch (Exception e) {
            alert(Alert.AlertType.ERROR, "Error",
                    "Ocurrió un error al iniciar sesión:\n" + e.getMessage());
        }
    }
    
    private void limpiarFormularioLogin() {
        txtUsuarioLogin.clear();
        pssPassword.clear();
    }
}
