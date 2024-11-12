({
    doInit: function(component, event, helper) {
        //var dismissActionPanel = $A.get("e.force:closeQuickAction");
        //dismissActionPanel.fire();
        var navigate = component.get("v.navigateFlow");
        navigate("NEXT");
        //$A.get('e.force:refreshView').fire();
    }
})