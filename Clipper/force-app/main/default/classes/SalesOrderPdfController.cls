public class SalesOrderPdfController {
    
    String objectName;
    String childObjName;
    String recordId;
    public List<Order> recordList {get; set;}

    public SalesOrderPdfController() {
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
        childObjName = ApexPages.currentPage().getParameters().get('childSObjectType');
        recordList = (List<Order>) DocTemplateGenUtil.getRecords(objectName, childObjName, recordId);
    }
}