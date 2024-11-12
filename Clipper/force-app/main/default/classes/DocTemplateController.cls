/**
 * @description Controller for NAO VF Doc Templates
 * @author Bricoleur Technologies
 * @date Aug-15-2024
 */

public class DocTemplateController {

    public static List<sObject> getRecords(String objName, String childObjName, String recordId) {
        String childQry = SchemaHelper.getObjSubquery(objName, childObjName);
        String qry = SchemaHelper.getObjectQuery(objName, childQry)+' WHERE Id = \''+recordId+'\'';
        return Database.query(qry);
    }

}