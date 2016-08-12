package junior.databases.homework;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.*;
import java.sql.*;
import java.util.Date;

public abstract class Entity {
    private static String DELETE_QUERY   = "DELETE FROM \"%1$s\" WHERE %1$s_id=?";
    private static String INSERT_QUERY   = "INSERT INTO \"%1$s\" (%2$s) VALUES (%3$s) RETURNING %1$s_id;--";
    private static String LIST_QUERY     = "SELECT * FROM \"%s\"";
    private static String SELECT_QUERY   = "SELECT * FROM \"%1$s\" WHERE %1$s_id=?";
    private static String CHILDREN_QUERY = "SELECT * FROM \"%1$s\" WHERE %2$s_id=?";
    private static String SIBLINGS_QUERY = "SELECT * FROM \"%1$s\" NATURAL JOIN \"%2$s\" WHERE %3$s_id=?";
    private static String UPDATE_QUERY   = "UPDATE \"%1$s\" SET %2$s WHERE %1$s_id=?";

    private static int STATEMENT_ID_INDEX = 1;

    private static Connection db = null;

    protected boolean isLoaded = false;
    protected boolean isModified = false;
    private String table = null;
    private int id = 0;
    protected Map<String, Object> fields = new HashMap<String, Object>();


    public Entity() {
        this.table = getClass().getSimpleName().toLowerCase();
    }

    public Entity(Integer id) {
        this.id = id;
        this.table = getClass().getSimpleName().toLowerCase();
    }

    public static final void setDatabase(Connection connection) {
        if ( connection != null ) {
            db = connection;
        }
    }

    public final int getId() {
        return id;
    }

    public final java.util.Date getCreated() {
        return getDate(table + "_created");
    }

    public final java.util.Date getUpdated() {
        return getDate(table + "_updated");
    }

    public final Object getColumn(String name) {
        load();
        return fields.get(table + "_" + name);
    }

    public final <T extends Entity> T getParent(Class<T> cls) {
        // get parent id from fields as <classname>_id, create and return an instance of class T with that id
        load();
        Integer parendId = (Integer) fields.get(cls.getSimpleName().toLowerCase() + "_id");
        Constructor<T> constructor = null;
        try {
            constructor = cls.getConstructor(Integer.class);
            return (T) constructor.newInstance(parendId);
        } catch (NoSuchMethodException | InstantiationException | InvocationTargetException | IllegalAccessException e) {
            e.printStackTrace();
        }
        return null;
    }

    public final <T extends Entity> List<T> getChildren(Class<T> cls) {
        String query = String.format(CHILDREN_QUERY, cls.getSimpleName().toLowerCase(), table);
        return selectFromAssociatedTable(cls, query);
    }

    public final <T extends Entity> List<T> getSiblings(Class<T> cls) {
        String siblingName = cls.getSimpleName().toLowerCase();
        String query = String.format(SIBLINGS_QUERY, getJoinTableName(table, siblingName), siblingName, table);
        return selectFromAssociatedTable(cls, query);
    }

    public final void setColumn(String name, Object value) {
        fields.put(table + "_" + name, value);
    }

    public final void setParent(String name, Integer id) {
        fields.put(name + "_id", id);
    }

    private void load() {
        if ( !isLoaded ) {
            try {
                ResultSet resultSet = selectById(this.id);
                if ( resultSet.next() ) {
                    fields = resultSetToMap(resultSet);
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            isLoaded = true;
        }
    }

    private void insert() throws SQLException {
        if ( !fields.isEmpty() ) {
            String[] fieldsAndValues = fieldsToStrings();

            Statement statement = db.createStatement();
            String query = String.format(INSERT_QUERY, table, fieldsAndValues[0], fieldsAndValues[1]);
            statement.execute(query, Statement.RETURN_GENERATED_KEYS);

            ResultSet generatedKey = statement.getGeneratedKeys();
            generatedKey.next();
            id = generatedKey.getInt(1);
        }
    }

    private void update() throws SQLException {
        if ( !fields.isEmpty() ) {
            String querySetPart = buildUpdateQuerySetPart();
            String query = String.format(UPDATE_QUERY, table, querySetPart);

            getPreparedStatement(query).execute();
        }
    }

    public final void delete() throws SQLException {
        String query = String.format(DELETE_QUERY, table);
        getPreparedStatement(query).execute();
    }

    public final void save() throws SQLException {
        if ( id == 0 ) {
            insert();
            return;
        }
        update();
    }

    protected static <T extends Entity> List<T> all(Class<T> cls) {
        ResultSet rows = null;
        try {
            rows = selectAll(cls);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rowsToEntities(cls, rows);
    }

    private static Collection<String> genPlaceholders(int size) {
        return genPlaceholders(size, "?");
    }

    private static Collection<String> genPlaceholders(int size, String placeholder) {
        if ( size <= 0 ) {
            throw new IllegalArgumentException();
        }

        Collection<String> placeholders = new ArrayList<>();

        for ( int i = 1; i <= size; i++ ) {
            placeholders.add(placeholder);
        }

        return placeholders;
    }

    private static String getJoinTableName(String leftTable, String rightTable) {
        if ( leftTable.compareTo(rightTable) < 0 )
            return leftTable + "__" + rightTable;

        return rightTable + "__" + leftTable;
    }

    private java.util.Date getDate(String column) {
        load();
        return new Date(((Integer) fields.get(column)).longValue());
    }

    private static String join(Collection<String> sequence) {
        return join(sequence, ", ");
    }

    private static String join(Collection<String> sequence, String glue) {
        if ( sequence.size() <= 0 ) {
            throw new IllegalArgumentException();
        }

        StringBuilder sb = new StringBuilder();
        Iterator<String> iterator = sequence.iterator();

        for ( int i = 1; i < sequence.size(); i++ ) {
            sb.append(iterator.next()).append(glue);
        }
        sb.append(iterator.next());

        return sb.toString();
    }

    private static <T extends Entity> List<T> rowsToEntities(Class<T> cls, ResultSet rows){
        List<T> entities = new ArrayList<>();

        try {
            while ( rows.next() ) {
                entities.add((T) rowToEntity(cls, rows));
            }
        } catch (SQLException | IllegalAccessException | InstantiationException e) {
            e.printStackTrace();
        }

        return entities;
    }

    private ResultSet selectById(int id) throws SQLException {
        String query = String.format(SELECT_QUERY, table, table);

        PreparedStatement statement = db.prepareStatement(query);
        statement.setInt(STATEMENT_ID_INDEX, id);

        return  statement.executeQuery();
    }

    private PreparedStatement getPreparedStatement(String query) throws SQLException {
        PreparedStatement statement = db.prepareStatement(query);
        statement.setInt(STATEMENT_ID_INDEX, id);

        return statement;
    }

    private static ResultSet selectAll(Class<?> cls) throws SQLException {
        String query = String.format(LIST_QUERY, cls.getSimpleName().toLowerCase());

        return db.createStatement().executeQuery(query);
    }

    private static Map<String, Object> resultSetToMap(ResultSet resultSet) throws SQLException {
        Map<String, Object> map = new HashMap<>();

        int columnCount = resultSet.getMetaData().getColumnCount();

        for (int i = 1; i <= columnCount; i++) {
            String columnName = resultSet.getMetaData().getColumnName(i);
            Object columnValue = resultSet.getObject(i);
            map.put(columnName, columnValue);
        }

        return map;
    }

    private static <T extends Entity> Entity rowToEntity(Class<T> cls, ResultSet resultSet)
            throws SQLException, IllegalAccessException, InstantiationException {

        Entity entity = cls.newInstance();
        entity.fields = resultSetToMap(resultSet);
        entity.id = (Integer) entity.fields.get(cls.getSimpleName().toLowerCase() + "_id");
        entity.table = cls.getSimpleName().toLowerCase();
        entity.isLoaded = true;

        return entity;
    }

    private String fieldsToQueryString(Set<String> fields) {
        String[] fieldsArray = new String[fields.size()];

        return formatQueryString(fields.toArray(fieldsArray));
    }

    private String valuesToQueryString(Object[] values) {
        String[] valuesArray = new String[values.length];

        for ( int i = 0; i < values.length; i++ ) {
            if ( values[i] instanceof String ) {
                valuesArray[i] = String.format("\'%s\'", values[i]);
            } else {
                valuesArray[i] = values[i].toString();
            }

        }

        return formatQueryString(valuesArray);
    }

    private String formatQueryString(String[] stringArray) {
        String arrayString = Arrays.toString(stringArray);

        return arrayString.substring(1, arrayString.length() - 1);
    }

    private String[] fieldsToStrings() {
        String queryStrings[] = new String[2];

        queryStrings[0] = fieldsToQueryString(fields.keySet());
        queryStrings[1] = valuesToQueryString(fields.values().toArray());

        return queryStrings;
    }

    private String buildUpdateQuerySetPart() {
        StringBuilder querySetPartBuilder = new StringBuilder();

        for ( Map.Entry pair : fields.entrySet() ) {
            querySetPartBuilder.append(pairToUpdateQuerySetPart(pair));
        }

        return formatUpdateQuerySetPart(querySetPartBuilder);
    }

    private String pairToUpdateQuerySetPart(Map.Entry pair) {
        String queryPart = new String();

        if ( pair.getValue() instanceof String )
            queryPart = String.format("%s = \'%s\', ", pair.getKey(), pair.getValue());
        else
            queryPart = String.format("%s = %s, ", pair.getKey(), pair.getValue());

        return queryPart;

    }

    private String formatUpdateQuerySetPart(StringBuilder sb) {
        String querySetPart = sb.toString();
        return querySetPart.substring(0, querySetPart.length() - 2);
    }

    private <T extends Entity> List<T> selectFromAssociatedTable(Class<T> cls, String query) {
        try {
            ResultSet resultSet = getPreparedStatement(query).executeQuery();
            return rowsToEntities(cls, resultSet);
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
}
