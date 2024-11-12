trigger slack_Project_Component on Project_Component__c (after insert, after update, before delete) {
	if(trigger.isAfter && trigger.isInsert || trigger.isAfter && trigger.isUpdate || trigger.isBefore && trigger.isDelete) {
		slackv2__.utilities.startSubscriptionQueue(trigger.newMap, trigger.oldMap, trigger.operationType, 'Project_Component__c');
	}
}