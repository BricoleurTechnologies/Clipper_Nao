({
	doInit : function(component, event, helper) {
        var params = {};
        helper.sendRequest(component,'c.RunXeroGetPOBatch',params);
	}
})