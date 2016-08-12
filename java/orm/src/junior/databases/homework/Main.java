package junior.databases.homework;

import junior.databases.homework.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

public class Main {
    private static Connection connection = null;

    public static void main(String[] args) throws SQLException, ClassNotFoundException {
        initDatabase();

        Entity.setDatabase(connection);

        Tag tag = new Tag();
        tag.setName("ID TEST");

        tag.save();

        tag.setName("ID TEST 2");
        tag.save();
    }
    private static void initDatabase() throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");

        connection = DriverManager.getConnection(
                    "jdbc:postgresql://localhost:5432/orm", "postgres",
                    "1");
        System.out.println("Connection established!");

    }
}
