({
    invoke : function(component, event, helper) {
        console.log('URL : ' +component.get('v.URL') );
        window.open(component.get('v.URL'),'_blank');
	}
})