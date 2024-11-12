public class OrderPdfController {
    
    String objectName;
    String childObjName;
    String recordId;
    public List<Order> recordList {get; set;}
    public String logoUrl {get; set;}

    public OrderPdfController() {
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
        childObjName = ApexPages.currentPage().getParameters().get('childSObjectType');
        logoUrl = ApexPages.currentPage().getParameters().get('pdfLogo');
        String relFields = 'BillToContact.Name,BillToContact.Email,BillToContact.Phone,Account.Owner.Name';
        recordList = (List<Order>) DocTemplateGenUtil.getRecords(objectName, childObjName, relFields, recordId);
    }
}