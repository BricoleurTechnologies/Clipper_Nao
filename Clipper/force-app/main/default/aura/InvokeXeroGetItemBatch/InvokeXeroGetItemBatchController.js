({
	doInit : function(component, event, helper) {
        var params = {};
        helper.sendRequest(component,'c.RunXeroGetItemBatch',params);
	}
})