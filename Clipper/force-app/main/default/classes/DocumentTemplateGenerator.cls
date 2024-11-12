/**
 * @description Generates document templates for NAO
 * @author Bricoleur Technologies
 * @date Aug-15-2024
 */

public class DocumentTemplateGenerator {
    
    public List<SObject> SObjectListToShow {get;set;}
    public String objectName {get;set;}
    public String recordId {get;set;}

    public DocumentTemplateGenerator() {
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
    }
}