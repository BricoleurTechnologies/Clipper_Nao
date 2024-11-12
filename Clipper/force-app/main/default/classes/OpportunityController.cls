public without sharing class OpportunityController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpps(String oppId)
    {
        List<Opportunity> oppList = [SELECT Id, Name, StageName, CloseDate FROM Opportunity
                                             WHERE Id =: oppId];
        return oppList;
    }
}