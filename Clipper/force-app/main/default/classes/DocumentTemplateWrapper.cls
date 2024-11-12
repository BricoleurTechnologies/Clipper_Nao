public class DocumentTemplateWrapper {
    public SObject record { get; set; }
    
    public DocumentTemplateWrapper(SObject record) {
        this.record = record;
    }

    // Method to get a field value dynamically
    public String getFieldValue(String fieldName) {
        return (String)record.get(fieldName);
    }

    // Method to get all field names dynamically
    public Map<String, String> getAllFieldValues() {
        Map<String, String> fieldValues = new Map<String, String>();
        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
        
        for (String fieldName : fields.keySet()) {
            fieldValues.put(fieldName, getFieldValue(fieldName));
        }
        return fieldValues;
    }
}