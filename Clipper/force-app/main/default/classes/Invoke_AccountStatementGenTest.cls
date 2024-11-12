/**
 * @description Test class for Invoke_AccountStatementGen
 * @author Bricoleur Technologies
 * @date Nov-7-2024
 */
@isTest
public class Invoke_AccountStatementGenTest {
    
    @IsTest
    static void invokeAccStmntGen(){
        
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Invoke_AccountStatementGen.Request req = new Invoke_AccountStatementGen.Request();
        req.selectedAccs = [SELECT Id, Name FROM Account WHERE Id =: acc.Id LIMIT 1];

        Test.startTest();
            Invoke_AccountStatementGen.generateAndAttachPDF(new List<Invoke_AccountStatementGen.Request> {req});
        Test.stopTest();    

        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Record_ID__c =: acc.Id LIMIT 1];
        System.assert(cv != null);
    }
}