@isTest
public without sharing class SchemaHelperTest {
    @IsTest
    static void schemaTest(){
        
        Test.startTest();
            SchemaHelper.GetRecordTypeIdByDeveloperName('Order', 'Sales_Order'); 
            SchemaHelper.getObjectQuery('Order', ''); 
            SchemaHelper.getObjSubquery('Account', 'Contact');    
        Test.stopTest();
        
    }
}