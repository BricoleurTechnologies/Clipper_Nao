({
    doInit : function(component, event, helper) {
        var flow = component.find("flowData");
        var inputVariables = [
            { name : "RecordId", type : "String", value: component.get('v.recordId') },
            { name : "flagValue", type : "Boolean", value: true }];
       
            
        flow.startFlow("Get_Contact_from_Xero_NoPersonAccount",inputVariables);
        
    },
    
    statusChange : function (component, event) {
        if (event.getParam('status') === "FINISHED_SCREEN") {
            $A.get("e.force:closeQuickAction").fire();
        }
    }
})