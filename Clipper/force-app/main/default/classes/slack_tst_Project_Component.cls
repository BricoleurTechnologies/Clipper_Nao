@isTest
public class slack_tst_Project_Component {
	@isTest 
	static void testTrigger() {
		Project__c obj1 = new Project__c();
		insert obj1;

		Project_Component__c obj0 = new Project_Component__c(
			Project__c = obj1.Id
		);
		insert obj0;
	}
}