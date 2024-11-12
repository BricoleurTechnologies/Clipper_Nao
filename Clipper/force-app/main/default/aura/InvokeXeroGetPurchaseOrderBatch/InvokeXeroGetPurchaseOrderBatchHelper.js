({
	/**
   * Call Apex Server-Side method in Promise
   */
    sendRequest : function(component, methodName, params){
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get(methodName);
            action.setParams(params);
            action.setCallback(self, function(res) {
                var state = res.getState();
                if(state === 'SUCCESS') {
                    resolve(res.getReturnValue());        
                    $A.get("e.force:closeQuickAction").fire();
                    
                } else if(state === 'ERROR') {
                    reject(action.getError())        
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
        }));
    },   
})