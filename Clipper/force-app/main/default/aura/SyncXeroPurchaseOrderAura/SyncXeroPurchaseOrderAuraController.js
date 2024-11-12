({
    doInit : function(component, event, helper) {
        var flow = component.find("flowData");
        var inputVariables = [
            { name : "recordId", type : "String", value: component.get('v.recordId') }];
        flow.startFlow("Sync_Order_to_Xero_Purchase_Order",inputVariables);
        
    },
    
    statusChange : function (component, event) {
        if (event.getParam('status') === "FINISHED_SCREEN") {
            $A.get("e.force:closeQuickAction").fire();
        }
    }
})