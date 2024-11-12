/**
 * @description Controller for AccountStatementPDF visualforce page; renders data in the page
 * @author JP Sulit
 * @date Oct-28-2024 (Created)
 */
public with sharing class AccStatementPdfController {

    String objectName;
    String childObjName;
    String recordId;
    public List<Account> recordList {get; set;}
    public List<Invoice__c> invoiceList {get; set;}
    public String logoUrl {get; set;}

    public AccStatementPdfController() {
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
        childObjName = ApexPages.currentPage().getParameters().get('childSObjectType');
        logoUrl = ApexPages.currentPage().getParameters().get('pdfLogo');
        String relFields = '';
        recordList = (List<Account>) DocTemplateGenUtil.getRecords(objectName, childObjName, relFields, recordId);
        String invoiceQry = SchemaHelper.getObjectQuery('Invoice__c','');
        invoiceQry += ' WHERE Account_Bric__c = \''+recordId+'\' AND RecordType.DeveloperName = \'Invoice\' AND Invoice_Amount_Inc_GST__c > 0 ORDER BY Invoice_Date_bric__c ASC';
        invoiceList = (List<Invoice__c>) DocTemplateGenUtil.getSecuredAccessRecords(Database.query(invoiceQry));
    }
}