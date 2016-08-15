import yaml

class Generator:
    createTableQueryHeaderPattern = "CREATE TABLE {0} ({0}_id serial NOT NULL PRIMARY KEY, "
    createTableQueryFieldsPattern = "{}_{} {}, "
    createTableTimestampsFieldsPattern = "{0}_created timestamp, {0}_updated timestamp"
    createTablePrimaryKeyPattern = "PRIMARY KEY ({}_id)"

    createFunctionPattern = "CREATE FUNCTION {}_timpestamp() RETURNS TRIGGER AS $$ BEGIN NEW.{}_{} = now(); RETURN NEW; END; $$ language 'plpgsql';"
    createTriggerPattern = "CREATE TRIGGER {}_trigger BEFORE {} ON {} FOR EACH ROW EXECUTE PROCEDURE {}_timpestamp();"

    foreignKeyFieldSeparator = "_id INTEGER"

    def getDDL(self, filePath):
        aList = []
        
        parsedYamlTree = self.parseYaml(filePath)
        tables = parsedYamlTree.keys()

        for table in tables:
            tableName = table.lower()

            aList.append(self.generateCreateTableStatement(parsedYamlTree, table))
            # aList.append(self.createFunctionPattern.format("insert", tableName, "created"))
            # aList.append(self.createFunctionPattern.format("update", tableName, "updated"))
            # aList.append(self.createTriggerPattern.format("insert", "INSERT", tableName, "insert"))
            # aList.append(self.createTriggerPattern.format("update", "UPDATE", tableName, "update"))

        return aList

    def parseYaml(self, filePath):
        with open(filePath, 'r') as stream:
            try:
                return yaml.load(stream)
            except yaml.YAMLError as exc:
                print(exc)

    def generateCreateTableStatement(self, parsedYamlTree, currentTable):
        tableName = currentTable.lower()
        fieldsTree = parsedYamlTree[currentTable]["fields"]
        fieldNames = fieldsTree.keys()

        query = [ 
        self.createTableQueryHeaderPattern.format(tableName), 
        self.generateTableFieldsString(tableName, fieldsTree), 
        self.createTableTimestampsFieldsPattern.format(tableName), 
        self.getOneToManyRealations(parsedYamlTree, currentTable) 
        ]

        return ''.join(query) + ");"

    def generateTableFieldsString(self, tableName, fieldsTree):
        fieldNames = fieldsTree.keys()

        return "{}, " \
            .format(",".join(map(lambda fieldName: "{}_{} {}" \
            .format(tableName, fieldName, fieldsTree[fieldName]), fieldNames)))

    def getOneToManyRealations(self, parsedYamlTree, currentTable):
        try:
            relations = parsedYamlTree[currentTable]["relations"]
        except KeyError as e:
            return ""

        oneToManyList = [ entity for (entity, relationType) in relations.iteritems() if relationType == "one" ]

        if not oneToManyList:
            return ""

        filteredList = self.filterOneToManyRealtions(parsedYamlTree, oneToManyList, currentTable)

        if not filteredList:
            return ""

        foreignKeysFields = ", ".join(map(lambda el: el + "_id integer", filteredList))
        foreignKeys = ", ".join(map(lambda el: "FOREIGN KEY({0}_id) REFERENCES {0}({0}_id)".format(el), filteredList))
        
        return ", {}, {}".format(foreignKeysFields, foreignKeys)

    def filterOneToManyRealtions(self, parsedYamlTree, oneToManyList, currentTable):
        filteredList = []

        for relation in oneToManyList:
            try:
                if parsedYamlTree[relation]["relations"][currentTable] == "many":
                    filteredList.append(relation.lower())
            except KeyError as e:
                print currentTable + ": incorrect relation with " + str(e)
            except TypeError as e:
                print relation +  " has no relation type with " + currentTable

        return filteredList



gen = Generator()
l = gen.getDDL("example.yaml")
print l
