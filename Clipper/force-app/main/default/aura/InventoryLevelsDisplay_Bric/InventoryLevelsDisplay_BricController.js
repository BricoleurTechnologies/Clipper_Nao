({	
    init: function (cmp, event, helper) {
        cmp.set('v.columnsList', [            
            {label: 'Product', fieldName: 'Product_Name__c', type: 'text'},
            {label: 'Location', fieldName: 'Location_Name__c', type: 'text'},
            {label: 'Quantity', fieldName: 'Quantity__c', type: 'number'},
            {label: 'As At Date', fieldName: 'As_At_Date__c', type: 'date'}
        ]);
        cmp.set('v.data',cmp.get('v.data'));

    }
})