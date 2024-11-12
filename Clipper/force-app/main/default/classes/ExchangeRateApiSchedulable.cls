/**
 * @date May-21-2024
 * @author Bricoleur Technologies
 * @description Schedulable class for ExchangeRateApiClass
 */

global class ExchangeRateApiSchedulable implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        ExchangeRateApiClass.fetchLatestExchangeRate();
    }
}