/**
 * @description Utility class for NAO VF Doc Templates
 * @author Bricoleur Technologies
 * @date Aug-16-2024
 * [1] JP Sulit - Nov-6-2024 - Added function to strip inaccessible fields in an sObjectList
 */

 public class DocTemplateGenUtil {

    public static List<sObject> getRecords(String objName, String childObjName, String relFields, String recordId) {
        String childQry = SchemaHelper.getObjSubquery(objName, childObjName);
        if(String.isNotBlank(relFields)) {
            childQry += ','+relFields+' ';
        }
        String qry = SchemaHelper.getObjectQuery(objName, childQry)+' WHERE Id = \''+recordId+'\'';
        return getSecuredAccessRecords(Database.query(qry));
    }

    public static String getObjectNameById(Id recordId) {
        SObjectType sObjectType = recordId.getSObjectType();
        return sObjectType.getDescribe().getName();
    }

    //[1] JP Sulit - Nov-6-2024 - Added function to strip inaccessible fields in an sObjectList
    public static List<sObject> getSecuredAccessRecords(List<sObject> sObjectList) {
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, sObjectList);
        return (List<sObject>) securityDecision.getRecords();
    }
}