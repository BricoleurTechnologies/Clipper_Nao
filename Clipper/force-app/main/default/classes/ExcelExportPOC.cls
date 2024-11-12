public with sharing class ExcelExportPOC {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpp(String oppId) {
        return [SELECT Id, Name, CloseDate, StageName FROM Opportunity WHERE Id =: oppId];
    }
}