public without sharing class OrderPickPdfController {

    String objectName;
    String childObjName;
    String recordId;
    public List<Order_Pick__c> recordList {get; set;}
    public String logoUrl {get; set;}

    public OrderPickPdfController() {
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
        childObjName = ApexPages.currentPage().getParameters().get('childSObjectType');
        logoUrl = ApexPages.currentPage().getParameters().get('pdfLogo');
        String relFields = '';
        recordList = (List<Order_Pick__c>) DocTemplateGenUtil.getRecords(objectName, childObjName, relFields, recordId);
    }
}