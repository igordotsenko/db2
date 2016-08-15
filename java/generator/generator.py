import yaml

class Generator:
    createTableQueryHeaderPattern = "CREATE TABLE {0} ({0}_id serial NOT NULL PRIMARY KEY, "
    createTableQueryFieldsPattern = "{}_{} {}, "
    createTableTimestampsFieldsPattern = "{0}_created timestamp, {0}_updated timestamp"
    createTablePrimaryKeyPattern = "PRIMARY KEY ({}_id)"

    createFunctionPattern = "CREATE FUNCTION {}_timpestamp() RETURNS TRIGGER AS $$ BEGIN NEW.{}_{} = now(); RETURN NEW; END; $$ language 'plpgsql';"
    createTriggerPattern = "CREATE TRIGGER {}_trigger BEFORE {} ON {} FOR EACH ROW EXECUTE PROCEDURE {}_timpestamp();"

    crossTablesPattern = "CREATE TABLE {0}_{1} ({0}_id integer NOT NULL, {1}_id integer NOT NULL);"

    manyToManySet = set()

    def getDDL(self, filePath):
        aList = []
        
        parsedYamlTree = self.parseYaml(filePath)

        if not parsedYamlTree:
            return "File is empty"

        tables = parsedYamlTree.keys()

        for table in tables:
            tableName = table.lower()

            aList.append(self.generateCreateTableStatement(parsedYamlTree, table))

            
            
            aList.append(self.createFunctionPattern.format("insert", tableName, "created"))
            aList.append(self.createFunctionPattern.format("update", tableName, "updated"))
            aList.append(self.createTriggerPattern.format("insert", "INSERT", tableName, "insert"))
            aList.append(self.createTriggerPattern.format("update", "UPDATE", tableName, "update"))

            self.getManyToManyRelatios(parsedYamlTree, table)

        aList.append(self.generateCrossTableStatements())

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
        oneToManyList = self.getRelationsList(parsedYamlTree, currentTable,  "one")

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

    def getManyToManyRelatios(self, parsedYamlTree, currentTable):
        manyToManyList = self.getRelationsList(parsedYamlTree, currentTable, "many")
        filteredSet = self.filterManyToManyRelations(parsedYamlTree, manyToManyList, currentTable)


    def filterManyToManyRelations(self, parsedYamlTree, manyToManyList, currentTable):
        for relation in manyToManyList:
            try:
                oppositeRelation = parsedYamlTree[relation]["relations"][currentTable]

                if oppositeRelation == "many" and relation != currentTable:
                    self.manyToManySet.add( (relation.lower(), currentTable.lower()) )
            except KeyError as e:
                print currentTable + ": incorrect relation with " + str(e)
            except TypeError as e:
                print relation +  " has no relation type with " + currentTable

    def generateCrossTableStatements(self):
        crossTables = []

        self.manyToManySet = set((a, b) if a <= b else (b, a) for a, b in self.manyToManySet)

        for tab_a, tab_b in self.manyToManySet:
            crossTables.append(self.crossTablesPattern.format(tab_a, tab_b))

        return " ".join(crossTables)


    def getRelations(self, parsedYamlTree, currentTable):
        try:
            return parsedYamlTree[currentTable]["relations"]
        except KeyError as e:
            return None

    def getRelationsList(self, parsedYamlTree, currentTable, relationTypeName):
        relations = self.getRelations(parsedYamlTree, currentTable)

        if not relations:
            return ""

        return self.getRelationEntetiesList(relations, relationTypeName)

    def getRelationEntetiesList(self, relations, relationTypeName):
        return [ entity for (entity, relationType) in relations.iteritems() if relationType == relationTypeName ]




gen = Generator()
l = gen.getDDL("example.yaml")
print l
