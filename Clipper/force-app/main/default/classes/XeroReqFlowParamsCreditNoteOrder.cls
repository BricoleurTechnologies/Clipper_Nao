public class XeroReqFlowParamsCreditNoteOrder {
    	//Credit Note
    @AuraEnabled @InvocableVariable public String SalesforceID;
    @AuraEnabled @InvocableVariable public String Type;
    @AuraEnabled @InvocableVariable public String ContactId;
    @AuraEnabled @InvocableVariable public List<XeroReqFlowLineItemParams> LineItems;
    @AuraEnabled @InvocableVariable public String Date_x;
    @AuraEnabled @InvocableVariable public String DeliveryDate;
    @AuraEnabled @InvocableVariable public String LineAmountTypes;
    @AuraEnabled @InvocableVariable public String Reference;
    @AuraEnabled @InvocableVariable public String CurrencyCode;
    @AuraEnabled @InvocableVariable public String CurrencyRate;
    @AuraEnabled @InvocableVariable public String Status;
    @AuraEnabled @InvocableVariable public String CreditNoteID;
    @AuraEnabled @InvocableVariable public Boolean AllocateInvoice;
    @AuraEnabled @InvocableVariable public Decimal Amount;
    @AuraEnabled @InvocableVariable public String InvoiceID;
    @AuraEnabled @InvocableVariable public List<XeroReqFlowInvoiceItemParams> Invoice;
}