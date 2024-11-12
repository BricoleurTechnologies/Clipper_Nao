@isTest
public class slack_tst_PMT_Project {
	@isTest 
	static void testTrigger() {
		inov8__PMT_Project__c obj0 = new inov8__PMT_Project__c(
			inov8__Level_of_Effort__c = 'Small'
		);
		insert obj0;
	}
}