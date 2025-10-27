module org.openjfx.gestortorneos {
    requires javafx.controls;
    requires javafx.fxml;
	requires java.sql;
	requires org.mariadb.jdbc;



    opens org.openjfx.gestortorneos to javafx.fxml;
    exports org.openjfx.gestortorneos;
}
