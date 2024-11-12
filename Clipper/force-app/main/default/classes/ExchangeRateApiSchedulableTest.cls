/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Test class for ExchangeRateApiSchedulable
 */

@isTest
public class ExchangeRateApiSchedulableTest {
    @IsTest
    static void executeTest() {
        
        Test.startTest();
            String cronExpression = '0 0 0 15 5 ? 2025'; // Cron expression for May 15, 2025 at midnight
            String jobId = System.schedule('Test Scheduled Job', cronExpression, new ExchangeRateApiSchedulable());
        Test.stopTest();        

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
        FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals(cronExpression, ct.CronExpression, 'Cron expression should match the scheduled expression');
       
    }
}